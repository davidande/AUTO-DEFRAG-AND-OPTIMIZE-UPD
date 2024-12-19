# AUTO-DEFRAG-AND-OPTIMIZE-UPD
Powershell scipt to auto defrag and optimize VHDX

This script do:

- Check if Windows feature Microsoft-Hyper-V-Management-PowerShell is installed

- Install the feature if necessary

- List all the VHDX disks (not attached) from a path (variable)
  
- Exclude some VHDX not needed (variable)

- Mount, Defrag and Optimize if fragmented level is high (variable)
  
