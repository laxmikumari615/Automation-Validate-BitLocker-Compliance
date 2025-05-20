<#
.SYNOPSIS
    Check Bitlocker Compliance - Remediation Script
    OS Support: Windows 8 and above
.DESCRIPTION
    This Worklet is designed to grant an Admin the ability to check the Bitlocker compliance of a device that falls
    within the defined range of System Types during the evaluation script. If this Worklet was ran manually, the system
    type check will be ignored and all and devices will report drive status to the activity log.
#>

# Count Drives and initialize lists for later output
$encCount = 0
$encrypted = @()
$unencrypted = @()

#Get BitLocker status for All Drives
try
{
    $encryption = Get-BitLockerVolume -ErrorAction Stop
}
catch
{
    Write-Output "Unable to determine BitLocker status"
}

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

# Output drive statuses so the can be seen in the Activity Log
Write-Output "Encrypted and Protected Drives: $encrypted"
Write-Output "-- Unencrypted or Unprotected Status Drives: $unencrypted"
