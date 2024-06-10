<#
.SYNOPSIS
    Makes EBS volumes available (including NVMe instance store volumes).

.DESCRIPTION
    Once the EBS volume is made available for use, you can access it just like any other volume.
    Any data written to this file system is directed to the EBS volume and remains transparent to applications utilizing the device.

.EXAMPLE
    Initialize-EBSVolume

.LINK
    https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ebs-using-volumes.html

.NOTES
    Copyright 2023 The MathWorks Inc.
#>
function Initialize-EBSVolume {

    Write-Output 'Starting Initialize-EBSVolume...'

    Stop-Service -Name ShellHWDetection

    Get-Disk | Where-Object PartitionStyle -EQ 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Data' -Confirm:$false

    Start-Service -Name ShellHWDetection

    Write-Output 'Done with Initialize-EBSVolume.'
}


try {
    Initialize-EBSVolume
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Initialize-EBSVolume': $ScriptPath. Error: $_"
    throw
}
