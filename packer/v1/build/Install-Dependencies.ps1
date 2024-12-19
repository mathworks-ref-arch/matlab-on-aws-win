<#
.SYNOPSIS
    Installs dependencies for reference architecture features.

.DESCRIPTION
    The Install-Dependencies function installs the required dependencies for the application.

.PARAMETER PythonInstallerUrl
    The URL for the Python installer.

.PARAMETER DcvInstallerUrl
    The URL for the NICE DCV installer.

.NOTES
    Copyright 2023-2024 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>


function Install-AwsCli {
    Write-Output 'Starting Install-AwsCli ...'

    Start-Process -FilePath MsiExec -ArgumentList '/i https://awscli.amazonaws.com/AWSCLIV2.msi /qn' -Wait
    $Env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
    aws --version

    Write-Output 'Done with Install-AwsCli.'
}

function Install-CloudWatchAgent {
    # Reference: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-commandline-fleet.html
    Write-Output 'Starting Install-CloudWatchAgent ...'

    Write-Output 'Downloading CloudWatch agent ...'
    $DownloadLink = 'https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi'
    $InstallerFile = 'C:\Windows\Temp\amazon-cloudwatch-agent.msi'
    (New-Object System.Net.WebClient).DownloadFile($DownloadLink, $InstallerFile)

    Write-Output 'Installing CloudWatch agent ...'
    # Installs under "C:\Program Files\Amazon\AmazonCloudWatchAgent" by default
    Start-Process msiexec.exe -Wait -ArgumentList '/i C:\Windows\Temp\amazon-cloudwatch-agent.msi /quiet /norestart /l*v C:\Windows\Temp\cloudwatch_agent_msi.log'


    Write-Output 'Done with Install-CloudWatchAgent.'
}

function Install-DotNetFramework35 {
    Write-Output 'Starting Install-DotNetFramework35 ...'

    Install-WindowsFeature Net-Framework-Core -source \\network\share\sxs

    Write-Output 'Done with Install-DotNetFramework35.'
}


function Get-NVidiaGridDrivers {
    # Reference: https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/install-nvidia-driver.html#nvidia-GRID-driver
    # Download NVIDIA grid drivers. A user of the reference architecture can choose to install them using the script Install-NVIDIAGridDriver.ps1

    param(
        [Parameter(Mandatory = $true)]
        [string] $GridDriverVersion
    )

    Write-Output 'Starting Get-NVidiaGridDrivers ...'

    $Bucket = 'ec2-windows-nvidia-drivers'
    $KeyPrefix = "grid-$GridDriverVersion"
    $LocalPath = 'C:\Windows\NVIDIADrivers\'

    # Create a new folder to store scripts and installers related to NVIDIA GRID drivers
    New-Item -Path $LocalPath -ItemType Directory

    Write-Output 'Copying NVIDIA GRID drivers ...'
    $Objects = Get-S3Object -BucketName $Bucket -KeyPrefix $KeyPrefix -Region us-east-1
    foreach ($Object in $Objects) {
        $LocalFileName = $Object.Key
        '---- ' + $LocalFileName + ' ----'
        if ($LocalFileName -ne '' -and $Object.Size -ne 0) {
            $LocalFilePath = Join-Path $LocalPath $LocalFileName
            Copy-S3Object -BucketName $Bucket -Key $Object.Key -LocalFile $LocalFilePath -Region us-east-1
        }
    }

    # Move GRID Drivers installation script to the directory created above
    Move-Item -Path 'C:\Windows\Temp\runtime\Install-NVIDIAGridDriver.ps1' -Destination 'C:\Windows\NVIDIADrivers\Install-NVIDIAGridDriver.ps1'
    Set-Content -Path 'C:\Windows\NVIDIADrivers\instances-supporting-grid-drivers.txt' -Value 'g3,g4dn,g5'
    Set-Content -Path 'C:\Windows\NVIDIADrivers\grid-driver-version.txt' -Value $GridDriverVersion

    Write-Output 'Done with Get-NVidiaGridDrivers.'
}

function Install-UnrealEngineDependencies {
    Write-Output 'Sleeping for 300 seconds to ensure system is ready for DirectX installation.'
    Start-Sleep -Seconds 300
    Write-Output 'Starting Install-UnrealEngineDependencies ...'
    Install-DirectX

    Write-Output 'Done with Install-UnrealEngineDependencies.'
}


function Disable-TemporaryFoldersPerSession {
    Write-Output 'Starting Disable-TemporaryFoldersPerSession ...'

    # Prevent Windows from creating non-deterministic %tmp% folder as its important for all MATLAB logs to be in one place.
    # Reference: https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-terminalserver
    New-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'PerSessionTempDir' -PropertyType DWord -Value 0 -Force

    Write-Output 'Done with Disable-TemporaryFoldersPerSession.'
}


function Install-NICEDCV {
    param(
        [Parameter(Mandatory = $true)]
        [string] $DcvInstallerUrl
    )

    # Reference: https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-wininstall.html

    Write-Output 'Starting Install-NICEDCV...'

    Write-Output 'Download NiceDCV installer'
    $InstallerFile = 'C:\Windows\Temp\nice-dcv-server.msi'
    (New-Object System.Net.WebClient).DownloadFile($DcvInstallerUrl, $InstallerFile)

    Write-Output 'Silent Install NiceDCV installer with default OWNER=Administrator'
    Start-Process msiexec.exe -Wait -ArgumentList '/i C:\Windows\Temp\nice-dcv-server.msi /quiet /norestart /l*v C:\Windows\Temp\dcv_install_msi.log AUTOMATIC_SESSION_OWNER=Administrator'

    Start-Sleep -s 10

    Write-Output 'Set the Maximum number of concurrent clients per session'
    # Reference: https://docs.aws.amazon.com/dcv/latest/adminguide/config-param-ref-modify.html#config-param-ref-win
    New-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::\HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\session-management\automatic-console-session' -Name 'max-concurrent-clients' -PropertyType DWord -Value 1 -Force

    Write-Output 'Enable NiceDCV clipboard feature'
    New-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::\HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\clipboard' -Name 'enabled' -PropertyType DWord -Value 1 -Force

    Write-Output "Enable file sharing between local and instance's desktop"
    New-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::\HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\session-management\automatic-console-session' -Name 'storage-root' -PropertyType String -Value '%home%' -Force

    Write-Output 'Set max resolution to (4096, 2160) for NICE DCV'
    New-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::\HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\display' -Name 'max-head-resolution' -PropertyType String -Value '(4096, 2160)' -Force

    New-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::\HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\display' -Name 'web-client-max-head-resolution' -PropertyType String -Value '(4096, 2160)' -Force

    Write-Output 'Put the NICE DCV executable on path'
    $Env:PATH = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
    [Environment]::SetEnvironmentVariable('PATH', $Env:PATH + ';C:\Program Files\NICE\DCV\Server\bin', [EnvironmentVariableTarget]::Machine)

    Write-Output 'Done with Install-NICEDCV.'
}

function Install-SSMAgent {
    # Reference https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-install-win.html
    Write-Output 'Starting Install-SSMAgent...'

    Write-Output 'Downloading latest SSM Agent ...'
    Invoke-WebRequest https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/windows_amd64/AmazonSSMAgentSetup.exe -OutFile C:\Windows\Temp\SSMAgent_latest.exe

    Write-Output 'Amazon SSM Agent Installer downloaded successfully. Installing ...'
    Stop-Service AmazonSSMAgent
    Start-Process -FilePath C:\Windows\Temp\SSMAgent_latest.exe -ArgumentList '/S'

    Write-Output 'Restarting Amazon SSM Agent ...'
    Restart-Service AmazonSSMAgent

    Write-Output 'Done with Install-SSMAgent.'
}

function Install-EdgeBrowser {
    Write-Output 'Starting Install-EdgeBrowser...'

    # Due to an issue for Global Mutex Lock, a sleep of 5 mins seems to be sufficient before installation of Edge.
    # The global mutex lock issue is only appearing during packer build, but not reproducible when running manually.
    # Microsoft Edge Download Page: https://www.microsoft.com/en-us/edge/business/download
    Write-Output 'Waiting for 5 minutes to resolve Global Mutex Lock issue ...'
    Start-Sleep -s 300

    Write-Output 'Downloading Edge browser msi file ...'
    $InstallerFile = 'C:\Windows\Temp\MicrosoftEdgeEnterpriseX64.msi'
    # To locate the URL, open a Chrome browser and go to the Microsoft webpage dedicated to downloading the Edge browser.
    # https://www.microsoft.com/en-us/edge/business/download?form=MA13FJ
    # Select the "Download for Windows 64-bit" option. As the file begins to download, access your
    # browser's "Full download history" (the name of this feature may vary across browsers, but we're using Chrome as an example).
    # Identify the file currently downloading, right-click on its link, and choose "Copy link address."
    (New-Object System.Net.WebClient).DownloadFile('https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/246e4bf2-8ad8-446b-b247-6fa0390a105e/MicrosoftEdgeEnterpriseX64.msi', $InstallerFile)

    Write-Output 'Installing Edge browser ...'
    Start-Process msiexec.exe -Wait -ArgumentList '/i C:\Windows\Temp\MicrosoftEdgeEnterpriseX64.msi /quiet /norestart /l*v C:\Windows\Temp\edge_install_msi.log'

    Write-Output 'Done with Install-EdgeBrowser.'
}

function Install-DirectX {
    Write-Output 'Starting Install-DirectX...'

    Write-Output 'Downloading DirectX installer ...'
    (New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe', 'C:\Windows\Temp\dxwebsetup.exe')

    Write-Output 'DirectX Installer downloaded successfully. Installing ...'
    Start-Process 'C:\Windows\Temp\dxwebsetup.exe' -ArgumentList '-q' -Wait

    Write-Output 'DirectX installed successfully.'

    Write-Output 'Done with Install-DirectX.'
}

function Install-Python {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonInstallerUrl
    )

    Write-Output 'Starting Install-Python...'

    Invoke-WebRequest -Uri $PythonInstallerUrl -OutFile 'C:\Windows\Temp\python.exe'

    Write-Output 'Python Installer downloaded successfully. Installing ...'
    Start-Process 'C:\Windows\Temp\python.exe' -Wait -ArgumentList '/quiet InstallAllUsers=1'

    Write-Output 'Done with Install-Python.'
}

function Install-Dependencies {
    param(
        [Parameter(Mandatory = $true)]
        [string] $PythonInstallerUrl,

        [Parameter(Mandatory = $true)]
        [string] $DcvInstallerUrl,

        [Parameter(Mandatory = $true)]
        [string] $GridDriverVersion
    )

    Install-AwsCli
    Install-CloudWatchAgent
    Install-DotNetFramework35
    Install-UnrealEngineDependencies
    Get-NVidiaGridDrivers -GridDriverVersion $GridDriverVersion
    Disable-TemporaryFoldersPerSession
    Install-NICEDCV -DcvInstallerUrl $DcvInstallerUrl
    Install-SSMAgent
    Install-EdgeBrowser
    Install-Python -PythonInstallerUrl $PythonInstallerUrl
}


try {
    $ErrorActionPreference = 'Stop'
    Install-Dependencies -PythonInstallerUrl $Env:PYTHON_INSTALLER_URL -DcvInstallerUrl $Env:DCV_INSTALLER_URL -GridDriverVersion $Env:NVIDIA_GRID_DRIVER_VERSION
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Install-Dependencies': $ScriptPath. Error: $_" 
}
