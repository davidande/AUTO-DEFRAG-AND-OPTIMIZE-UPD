###################################################################################
# Script provenant de : https://github.com/davidande/AUTO-DEFRAG-AND-OPTIMIZE-UPD #
###################################################################################

<# Vérification et installation si besoin des cmdlets Hyper-V (fonctionnalité Windows)

# Pour une éxécution depuis un serveur
$fonctionnalite = Get-WindowsFeature -Name Hyper-V-PowerShell
if (-not $feature.Installed) {
    Install-WindowsFeature -Name Hyper-V-PowerShell
}

# Pour une execution depuis un poste
$feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell
if ($feature.State -ne 'Enabled') {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell -All
}
#>

# Chemin des VHDX
$VHDXPath = '\\serveur-appli\users_profils$'

# VHDX à exclure
$VHDXExclusion = 'UVHD-template.vhdx'

# Pourcentage de fragmentation max avant action
$VHDXfragmax = 0

# Traitement
$VHDXS = Get-ChildItem $VHDXPath -Recurse -Filter *.vhdx | Where-Object {$_.name -NotContains $VHDXExclusion} | Select-Object -ExpandProperty fullname

foreach ($VHDX in $VHDXS) {
    $VHDXPROP = Get-VHD $VHDX -ErrorAction Ignore

    $VHDXDEFRAG = $VHDXPROP.FragmentationPercentage

    # Vérifier si le VHD est déjà monté ou utilisé
    $isMounted = Get-Disk | Where-Object { $_.Path -eq $VHDX }
    $isUsed = Test-Path $VHDX -PathType Leaf

    if ($isMounted -or (-not $isUsed)) {
        Write-Host "Le disque $VHDX est déjà monté ou utilisé par un autre processus. Passage au suivant..." -ForegroundColor Yellow
        continue
    }

    try {
        Mount-VHD $VHDX -ErrorAction Stop
        Write-Host "Traitement de $VHDX" -ForegroundColor Cyan
        Start-Sleep -Seconds 3

        $Drivebrut = Get-Partition (Get-DiskImage -ImagePath $VHDX).Number | Get-Volume
        $Drivefinal = $Drivebrut.DriveLetter + ':'

        defrag $Drivefinal /h /x
        defrag $Drivefinal /h /k /l
        defrag $Drivefinal /h /x
        defrag $Drivefinal /h /k

        Dismount-VHD $VHDX -ErrorAction Stop
        Start-Sleep -Seconds 3

        Optimize-VHD $VHDX -Mode Full -ErrorAction Stop
        Write-Host "Le disque $VHDX a été optimisé" -ForegroundColor Cyan
    } catch {
        Write-Host "Erreur lors du traitement du disque $VHDX : $_" -ForegroundColor Red
    }
}

exit
