<#
.SYNOPSIS
    Check Bitlocker Compliance - Evaluation Script
    OS Support: Windows 8 and above
    Powershell: 4.0 and above
    Run Type: Evaluation or OnDemand
.DESCRIPTION
    This worklet is designed to grant an Admin the ability to check the Bitlocker compliance of a device that falls
    within the defined range of System Types. If this Worklet is ran manually, the system type check will be ignored
    and all and devices will report drive status to the activity log.

    Usage:
    There is only one variable to be modified in this worklet.

    $maxSystemtype: Set this variable to limit the maximum PCSystemType to evaluate. Currently the script is set
    to a value of 3 with will exclude devices with a PCSystemType higher than a workstation (ie:Servers). If you prefer
    to run this evaluation against all devices, then a value of '8' should be specified. Refer to the list below for
    reference and change $masSystemtype as needed.

    PCSystemType
    0 = Unknown
    1 = Desktop
    2 = Mobile
    3 = Workstation
    4 = Enterprise Server
    5 = SOHO Server
    6 = Appliance PC
    7 = Performance Server
    8 = Maximum

.EXAMPLE
    $maxSystemtype = '3'
.LINK
    https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.pcsystemtype?view=powershellsdk-1.1.0
.NOTES
    Author: Tony Wiese
    Date: March 19, 2021
#>

####### EDIT WITHIN THIS BLOCK #######
$maxSystemtype = '3'
######################################

$getSystype = (Get-CimInstance -ClassName Win32_ComputerSystem).PCSystemType

# Exit if systemtype is higher than $maxSystemtype
if ($getSystype -gt $maxSystemtype)
{
    Write-Output "Device Excluded"
    Exit 0
}

#Get BitLocker status for All Drives
try
{
    $encryption = Get-BitLockerVolume -ErrorAction Stop
}
catch
{
    Exit 1
}

# Count Drives and initialize lists for later output
$numDrives = $encryption.Count
$encCount = 0
$encrypted = @()
$unencrypted = @()

# Loop through each drive and see if it is Protected or Not
# Add to the appropriate list, Encrypted or Unencrypted
foreach ($drive in $encryption)
{
    $encStatus = $drive.ProtectionStatus
    $encInProgress = $drive.VolumeStatus
    if (($encStatus -match 'On') -or ($encInProgress -match "EncryptionInProgress"))
    {
        $encrypted += $drive.MountPoint
        $encCount++
    }
    else
    {
        $unencrypted += $drive.MountPoint
    }
}

# Determine Compliant based on if the number of Encrypted
# Drives matches the number of Total Drives
if ($encCount -eq $numDrives)
{
    Write-Output "Device Compliant"
    Exit 0
}
Write-Output "Not Compliant - Flagging for remediation"