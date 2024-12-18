# avant toute chose ildfaut installer le module Hyper-v Powershell si ce n'est pas déja fait
# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell 

# chemin des VHDX
$VHDXPath = '\\localhost\users_profils$'
 
 # VHDX à exclure             
$VHDXExclusion = 'UVHD-template.vhdx'

# pourcentage de fragmentation max avant action
$VHDXfragmax = 10

# traitement
$VHDXS = Get-ChildItem $VHDXPath -Recurse -Filter *.vhdx | Where-Object {$_.name -NotContains $VHDXExclusion} | Select-Object -ExpandProperty fullname

foreach ($VHDX in $VHDXS){
$VHDXPROP = Get-VHD $VHDX -ErrorAction Ignore
    
    $VHDXDEFRAG = $VHDXPROP.FragmentationPercentage
    if ($VHDXDEFRAG -igt $VHDXfragmax){
    mount-VHD $VHDX
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
    }
}
exit
