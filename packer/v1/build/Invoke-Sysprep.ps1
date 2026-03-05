<#
.SYNOPSIS
    Invokes Microsoft tool Sysprep to capture custom Windows images.

.DESCRIPTION
    Invokes the Microsoft tool Sysprep to capture custom Windows images. Note that this script exclusively
    supports "Microsoft Windows Server 2022 Datacenter" and "Microsoft Windows Server 2019 Datacenter".

.EXAMPLE
    Invoke-Sysprep

.NOTES
    Copyright 2023-2026 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>
function Invoke-Sysprep {
    Write-Output 'Starting Invoke-Sysprep...'

    $WindowsVersion = (Get-ComputerInfo).OsName

    if ($WindowsVersion -eq 'Microsoft Windows Server 2022 Datacenter') {
        # Ec2launch v2 for Windows Server 2022
        # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2launch-v2-settings.html#ec2launch-v2-cli
        & "$env:ProgramFiles\Amazon\EC2Launch\ec2launch.exe" reset --clean
        & "$env:ProgramFiles\Amazon\EC2Launch\ec2launch.exe" sysprep --clean
    }
    elseif ($WindowsVersion -eq 'Microsoft Windows Server 2019 Datacenter') {
        # Ec2launch v1 for Windows Server 2019
        & "$Env:ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1" -Schedule
        & "$Env:ProgramData\Amazon\EC2-Windows\Launch\Scripts\SysprepInstance.ps1" -NoShutdown
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
