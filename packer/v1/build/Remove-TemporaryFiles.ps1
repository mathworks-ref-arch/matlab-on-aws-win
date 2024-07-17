<#
.SYNOPSIS
    Cleans up residual files remaining from Packer.

.DESCRIPTION
    This script serves as the final step in the AMI building process, responsible for cleaning up residual files, including the installer files downloaded during the build scripts.

.EXAMPLE
    Remove-TemporaryBuildFiles

.NOTES
    Copyright 2023-2024 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>

function Remove-TemporaryBuildFiles {
    Write-Output 'Starting Remove-TemporaryBuildFiles...'

    Remove-Item C:\Windows\Temp\packer-*.ps1
    Remove-Item C:\Windows\Temp\script-*.ps1
    Remove-Item C:\Windows\Temp\config -Force -Recurse

    Remove-Item 'C:\Windows\Temp\amazon-cloudwatch-agent.msi'
    Remove-Item 'C:\Windows\Temp\nice-dcv-server.msi'
    Remove-Item 'C:\Windows\Temp\MicrosoftEdgeEnterpriseX64.msi'

    Write-Output 'Done with Remove-TemporaryBuildFiles.'
}

function Clear-TemporaryLogContents {
    Write-Output 'Starting Clear-TemporaryLogContents...'

    if (Test-Path 'C:\ProgramData\Amazon\EC2-Windows\Launch\Log\UserDataExecution.log') {
        Clear-Content C:\ProgramData\Amazon\EC2-Windows\Launch\Log\UserDataExecution.log
    }

    if (Test-Path 'C:\ProgramData\Amazon\EC2-Windows\Launch\Log\Ec2Launch.log') {
        Clear-Content C:\ProgramData\Amazon\EC2-Windows\Launch\Log\Ec2Launch.log
    }

    Write-Output 'Done with Clear-TemporaryLogContents.'
}



try {
    $ErrorActionPreference = 'Stop'
    Remove-TemporaryBuildFiles
    Clear-TemporaryLogContents
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Remove-TemporaryFiles': $ScriptPath. Error: $_"
    throw
}