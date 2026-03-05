<#
.SYNOPSIS
    Cleans up residual files and configurations remaining from the Packer build process.
.DESCRIPTION
    This script serves as the final step in the AMI building process. It is responsible for cleaning up residual files,
    log files, and temporary SSH configurations to produce a clean, secure base image.
.EXAMPLE
    Remove-TemporaryBuildFiles
.NOTES
    Copyright 2023-2026 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered will cause the script to stop.
#>
function Remove-TemporaryBuildFiles {
    Write-Output 'Starting Remove-TemporaryBuildFiles...'
    Remove-Item C:\Windows\Temp\packer-*.ps1 -ErrorAction SilentlyContinue
    Remove-Item C:\Windows\Temp\script-*.ps1 -ErrorAction SilentlyContinue
    Remove-Item C:\Windows\Temp\startup -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item C:\Windows\Temp\runtime -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item C:\Windows\Temp\config -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item 'C:\Windows\Temp\amazon-cloudwatch-agent.msi' -ErrorAction SilentlyContinue
    Remove-Item 'C:\Windows\Temp\nice-dcv-server.msi' -ErrorAction SilentlyContinue
    Remove-Item 'C:\Windows\Temp\MicrosoftEdgeEnterpriseX64.msi' -ErrorAction SilentlyContinue
    Get-ChildItem "C:\Users" -Directory | ForEach-Object {
        Remove-Item "$($_.FullName)\AppData\Local\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
    Write-Output 'Done with Remove-TemporaryBuildFiles.'
}

function Remove-OpenSshConfiguration {
    Write-Output 'Starting Remove-OpenSshConfiguration...'
    
    # Clear the temporary public key from the central administrators key file.
    $AuthKeysFile = 'C:\ProgramData\ssh\administrators_authorized_keys'
    if (Test-Path $AuthKeysFile) {
        Write-Output "Clearing content of $AuthKeysFile..."
        Clear-Content $AuthKeysFile
    }

    # Delete the instance-specific SSH host keys.
    # This forces new, unique keys to be generated on the first boot of any instance launched from this AMI.
    Write-Output "Deleting SSH host keys from C:\ProgramData\ssh\..."
    Remove-Item C:\ProgramData\ssh\ssh_host_*_key -ErrorAction SilentlyContinue
    Remove-Item C:\ProgramData\ssh\ssh_host_*_key.pub -ErrorAction SilentlyContinue

    Write-Output 'Done with Remove-OpenSshConfiguration.'
}

try {
    $ErrorActionPreference = 'Stop'
    Remove-TemporaryBuildFiles
    Remove-OpenSshConfiguration
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred during cleanup script execution: $ScriptPath. Error: $_"
    throw
}
