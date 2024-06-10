<#
.SYNOPSIS
    This script installs the latest NVIDIA Grid Drivers on compatible instances.

.DESCRIPTION
    NVIDIA GRID drivers are certified to provide optimal performance for visualization applications
    that render content such as 3D models or high-resolution videos. A possible use case for the same
    would be if you plan to use Automated Driving toolbox to run simulations in a rich 3D-environment (Unreal Engine).
    The GRID drivers are only supported for G5, G4dn, and G3 GPU instances.

.EXAMPLE
    C:\Windows\NVIDIADrivers > ./Install-NVIDIAGridDriver.ps1
    This will install GRID drivers on compatible instance types and restart the VM after confirmation from the user.

.EXAMPLE
    C:\Windows\NVIDIADrivers > ./Install-NVIDIAGridDriver.ps1 'reboot'
    Running the script with the reboot parameter will directly restart the VM after installation of GRID drivers.

.LINK
    https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/install-nvidia-driver.html

.NOTES
    Copyright 2023 The MathWorks Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>

function Install-NVidiaGridDrivers {

    Write-Output 'Installing NVidia Grid Drivers ...'

    Start-Transcript -Path 'C:\Windows\NVIDIADrivers\grid-drivers-installation.log'

    # Invoke instance meta-data service to retrieve the instance type of the running VM
    $InstanceType = $(Invoke-WebRequest -UseBasicParsing -Uri http://169.254.169.254/latest/meta-data/instance-type).Content

    # Extract class from the instance type
    $InstanceClass = $InstanceType.Split('.')[0]

    # List of instances classes that support GRID drivers
    $AllowedClasses = $(Get-Content -Path 'C:\Windows\NVIDIADrivers\instances-supporting-grid-drivers.txt')
    $AllowedClasses = $AllowedClasses.Split(',')

    # Get Windows Server version number. ex: 2019, 2022 ...
    $WindowsVersion = (Get-ComputerInfo).OsName
    $VersionNumber = ($WindowsVersion -split '\s+')[3]

    $VersionPattern = '^20[1-9][0-9]$'

    if ($VersionNumber -notmatch $VersionPattern) {
        throw "Unsupported platform: $WindowsVersion"
    }

    if ($AllowedClasses.Contains($InstanceClass)) {
        Write-Output "Installing GRID Drivers...`n`n"
        $InstallerPath = 'C:\Windows\NVIDIADrivers\latest'
        $SetupFile = $(Get-ChildItem -Path $InstallerPath -Filter "*server$VersionNumber*").Name
        Write-Output "Using setup file $SetupFile present under $InstallerPath `n`n"
        Start-Process "$InstallerPath\$SetupFile" -ArgumentList "-s -n -log:`"C:\Windows\NVIDIADrivers\logs`" -loglevel:6" -Wait -NoNewWindow
        Write-Output "GRID Drivers installed successfully`n`n"
    }
    else {
        Write-Output 'Incompatible instance class. GRID Drivers installation is not required.'
        return
    }

    # Depending on the arguments passed to the script, handle restart of the EC2 instance
    if ($Args.Count -eq 0) {
        $UserChoice = $(Read-Host "A restart is required to complete installation of NVIDIA GRID Drivers. `nPlease enter your choice below- `n`n1. To restart your VM now `n0. To do it manually later`n`nEnter your choice")
    }
    else {
        $UserChoice = $Args[0]
    }

    if (($UserChoice -eq '1') -or ($UserChoice -eq 'reboot')) {
        Write-Output 'Rebooting instance to complete installation of GRID Drivers'
        Restart-Computer -Confirm:$false
    }
    elseif ($UserChoice -eq '0') {
        Write-Output 'Restart to be done manually by user'
    }

    Stop-Transcript

    Write-Output 'NVidia Grid Drivers installed successfully.'
}


try {
    $ErrorActionPreference = 'Stop'
    Install-NVidiaGridDrivers
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script: $ScriptPath. Error: $_"
    throw
}
