<#
.SYNOPSIS
    Installs NVIDIA GPU drivers.

.DESCRIPTION
    Downloads NVIDIA GPU drivers from the specified URL. Please note that:
        1) the driver versions may require modification between different MATLAB releases.
        2) this script be run on a GPU Instance type (e.g. p2.xlarge)

.PARAMETER NVidiaDriverInstallerUrl
    (Required) The URL for downloading NVIDIA GPU drivers.

.EXAMPLE
    Install-NVIDIADrivers  -NVidiaDriverInstallerUrl "https://example.com/nvidia-driver.exe"

.LINK
    https://uk.mathworks.com/help/parallel-computing/gpu-computing-requirements.html
.NOTES
    Copyright 2023 The MathWorks Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>

function Install-NVIDIADrivers {
    param(
        [Parameter(Mandatory = $true)]
        [string] $NVidiaDriverInstallerUrl
    )

    Write-Output 'Starting Install-NVIDIADrivers...'

    # Start in the temp folder
    Set-Location C:\Windows\Temp

    $StartTime = Get-Date

    $Output = 'C:\Windows\Temp\cuda.exe'
    (New-Object System.Net.WebClient).DownloadFile($NVidiaDriverInstallerUrl, $Output)
    Write-Output "NVIDIA drivers downloaded successfully. Time taken: $((Get-Date).Subtract($StartTime).Seconds) second(s)"

    # Install drivers - the instance should be rebooted prior to use
    Write-Output 'Installing NVIDIA Drivers ...'
    Start-Process -FilePath 'C:\Windows\Temp\cuda.exe' -ArgumentList '-s -noreboot -clean' -Wait -NoNewWindow

    Write-Output 'Done with Install-NVIDIADrivers.'
}


try {
    $ErrorActionPreference = 'Stop'
    Install-NVIDIADrivers -NVidiaDriverInstallerUrl $Env:NVIDIA_DRIVER_INSTALLER_URL
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Install-NVidiaDrivers': $ScriptPath. Error: $_"
    throw
}
