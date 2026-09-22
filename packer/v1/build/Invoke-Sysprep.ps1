<#
.SYNOPSIS
    Invokes Microsoft tool Sysprep to capture custom Windows images.

.DESCRIPTION
    Invokes the Microsoft tool Sysprep to capture custom Windows images. Note that this script exclusively
    supports Windows Server 2022 / 2025 (EC2Launch v2).

.EXAMPLE
    Invoke-Sysprep

.NOTES
    Copyright 2023-2026 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>
function Invoke-Sysprep {
    Write-Output 'Starting Invoke-Sysprep...'

    $WindowsVersion = (Get-ComputerInfo).OsName

    if ($WindowsVersion -match 'Microsoft Windows Server (2022|2025)') {
        # Ec2launch v2 for Windows Server 2022 and 2025
        # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2launch-v2-settings.html#ec2launch-v2-cli
        & "$env:ProgramFiles\Amazon\EC2Launch\ec2launch.exe" reset --clean
        & "$env:ProgramFiles\Amazon\EC2Launch\ec2launch.exe" sysprep --clean
    }
    else {
        throw "Unsupported platform: $WindowsVersion"
    }

    Write-Output 'Done with Invoke-Sysprep.'
}


try {
    $ErrorActionPreference = 'Stop'
    Invoke-Sysprep
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Invoke-Sysprep': $ScriptPath. Error: $_"
    throw
}
