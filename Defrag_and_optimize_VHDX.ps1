# script provenant de : https://github.com/davidande/AUTO-DEFRAG-AND-OPTIMIZE-UPD
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
$VHDXPath = '\\localhost\users_profils$'
 
# VHDX à exclure             
$VHDXExclusion = 'UVHD-template.vhdx'

# Pourcentage de fragmentation max avant action
$VHDXfragmax = 10

# Traitement
$VHDXS = Get-ChildItem $VHDXPath -Recurse -Filter *.vhdx | Where-Object {$_.name -NotContains $VHDXExclusion} | Select-Object -ExpandProperty fullname

foreach ($VHDX in $VHDXS){
$VHDXPROP = Get-VHD $VHDX -ErrorAction Ignore
    
    $VHDXDEFRAG = $VHDXPROP.FragmentationPercentage
    if ($VHDXDEFRAG -igt $VHDXfragmax){
    mount-VHD $VHDX
    write-host "Traitement de" $VHDX -ForegroundColor Cyan
    Start-Sleep -Seconds 3
    $Drivebrut= Get-Partition (Get-DiskImage -ImagePath $VHDX).number | Get-Volume
    $Drivefinal = $Drivebrut.DriveLetter + ':'
    defrag $Drivefinal /h /x
    defrag $Drivefinal /h /k /l
    defrag $Drivefinal /h /x
    defrag $Drivefinal /h /k
    dismount-vhd $VHDX
    Start-Sleep -Seconds 3
    optimize-vhd $VHDX -Mode Full
    write-host "Le disque" $VHDX "a été optimisé" -ForegroundColor Cyan
    }
    else {
    write-host "Le disque" $VHDX "n'est pas assez fragmenté pour être traité" -ForegroundColor Green
    }
}
exit
