###################################################################################
# Script provenant de : https://github.com/davidande/AUTO-DEFRAG-AND-OPTIMIZE-UPD #
###################################################################################

# Vérifier la version du système d'exploitation
$osVersion = (Get-WmiObject Win32_OperatingSystem).Version

# Fonction pour installer les fonctionnalités Hyper-V
function Install-HyperVFeatures {
    param (
        [string]$FeatureName
    )

    $feature = Get-WindowsFeature -Name $FeatureName
    if (-not $feature.Installed) {
        Write-Host "Installation de la fonctionnalité $FeatureName..." -ForegroundColor Cyan
        Install-WindowsFeature -Name $FeatureName -IncludeManagementTools
    } else {
        Write-Host "La fonctionnalité $FeatureName est déjà installée." -ForegroundColor Green
    }
}

# Installation des fonctionnalités Hyper-V en fonction de la version du système
if ($osVersion -ge "6.3") { # Windows Server 2012 R2 et versions ultérieures
    Install-HyperVFeatures -FeatureName "Hyper-V"
    Install-HyperVFeatures -FeatureName "Hyper-V-PowerShell"
} else {
    Write-Host "La version du système d'exploitation n'est pas supportée pour l'installation automatique des fonctionnalités Hyper-V." -ForegroundColor Red
    exit 1
}

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
