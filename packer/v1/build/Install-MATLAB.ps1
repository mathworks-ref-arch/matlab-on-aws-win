<#
.SYNOPSIS
    Installs MATLAB using MPM.

.LINK
    https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md

.NOTES
    Copyright 2020-2025 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>


function Install-MATLABUsingMPM {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Release,

        [Parameter(Mandatory = $true)]
        [string] $Products,

        [Parameter(Mandatory = $false)]
        [string] $SourceURL
    )

    Write-Output 'Starting Install-MATLABUsingMPM...'
    Set-Location -Path $Env:TEMP

    # As a best practice, downloading the latest version of mpm before calling it.
    Write-Output 'Downloading mpm ...'
    Invoke-WebRequest -OutFile "$Env:TEMP\mpm.exe" -Uri 'https://www.mathworks.com/mpm/win64/mpm'

    $MpmLogFilePath = "$Env:TEMP\mathworks_$Env:USERNAME.log"

    Write-Output 'Installing products ...'
    $ProductsList = $Products -Split ' '

    # Determine if --doc flag should be added
    $UseDocFlag = $Release -in @('R2022b', 'R2022a')
    $DocFlag = if ($UseDocFlag) { "--doc" } else { "" }

    try {
        if ( $SourceURL.length -eq 0 ) {
            & "$Env:TEMP\mpm.exe" install `
                --release $Release `
                --products $ProductsList `
                $DocFlag
        }
        else {
            # Dot-sourcing the Mount-DataDriveUtils script
            . 'C:\Windows\Temp\config\matlab\Mount-DataDriveUtils.ps1'

            # Setup extra volume to mount drive containing MATLAB source files
            $MATLABSourceDrive = 'X'
            $MATLABSourcePath = 'X:\matlab_source'

            Mount-DataDrive -DriveToMount "$MATLABSourceDrive"
            Get-MATLABSourceFiles -SourceURL $SourceURL -Destination "$MATLABSourcePath"

            # The source path must contain an archives folder that mpm uses for installation
            $SourcePath = Get-ChildItem -Path "$MATLABSourcePath" -Directory -Recurse -Filter 'archives' | Select-Object -First 1 -ExpandProperty FullName

            if (-not $SourcePath) {
                throw 'Failed to find MATLAB source files at the specified location'
            }

            & "$Env:TEMP\mpm.exe" install `
                --source=$SourcePath `
                --products $ProductsList `
                $DocFlag

            Dismount-DataDrive -DriveLetter "$MATLABSourceDrive"

        }
    }
    catch {
        if (Test-Path $MpmLogFilePath) {
            Get-Content -Path $MpmLogFilePath
        }

        throw
    }


    Write-Output 'Removing mpm ...'
    Remove-Item "$Env:TEMP/mpm.exe"

    if (Test-Path $MpmLogFilePath) {
        Remove-Item $MpmLogFilePath
    }

    Write-Output 'Done with Install-MATLABUsingMPM.'
}


function Initialize-MATLAB {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Release
    )

    Write-Output 'Starting Initialize-MATLAB ...'

    Write-Output "Copy license_info.xml file to enable MHLM licensing by default, create license directory if doesn't exist"
    $DestinationLicenseFolder = "$Env:ProgramFiles\MATLAB\$Release\licenses"
    if (!(Test-Path -Path $DestinationLicenseFolder)) {
        New-Item $DestinationLicenseFolder -Type Directory
    }
    Copy-Item 'C:\Windows\Temp\config\matlab\license_info.xml' -Destination $DestinationLicenseFolder

    Write-Output 'Set firewall rules for MATLAB'
    New-NetFirewallRule -DisplayName "MATLAB $Release" -Name "MATLAB $Release" -Action Allow -Program "C:\program files\matlab\$Release\bin\win64\matlab.exe"
    New-NetFirewallRule -DisplayName 'mw_olm' -Name 'mw_olm' -Action Allow -Program "C:\program files\matlab\$Release\bin\win64\mw_olm.exe"
    powershell -inputformat none -outputformat none -NonInteractive -Command "Add-MpPreference -ExclusionPath 'C:\Program Files\MATLAB'"

    Write-Output 'Set registry keys to disable pop-ups in Windows'
    New-Item -Path 'HKLM:\System\CurrentControlSet\Control\Network\NewNetworkWindowOff\'

    Write-Output 'Install MathWorks SSL Certificate ...'
    Install-Certificates -Url 'https://licensing.mathworks.com'

    Write-Output 'Move msa.ini file for Startup Accelerator'
    if ($Release -ge 'R2021b') {
        Copy-Item "C:\Windows\Temp\config\matlab\startup-accelerator\$Release\msa.ini" -Destination 'C:\ProgramData\MathWorks\msa.ini'
    }

    Write-Output 'Generate Toolbox cache xml if MATLAB version is greater than or equal to 2021b'
    # Toolbox cache generation is supported from R2021b onwards.
    if ($Release -ge 'R2021b') {
        & 'C:\Program Files\Python310\python.exe' C:\Windows\Temp\config\matlab\generate_toolbox_cache.py "C:\Program Files\MATLAB\$Release" "C:\Program Files\MATLAB\$Release\toolbox\local"
    }
    else {
        Write-Host "Unable to generate Toolbox cache xml as version $Release is less than R2021b."
    }

    Write-Output 'Done with Initialize-MATLAB.'
}


function Install-Certificates {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Url
    )

    Write-Output 'Starting Install-Certificates ...'

    $WebRequest = [Net.WebRequest]::CreateHttp($Url)
    $WebRequest.AllowAutoRedirect = $true
    $Chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    # Request website
    try { $WebRequest.GetResponse() } catch {}

    # Creates Certificate
    $Certificate = $WebRequest.ServicePoint.Certificate.Handle

    # Build chain
    $Chain.Build($Certificate)
    $Cert = $Chain.ChainElements[$Chain.ChainElements.Count - 1].Certificate
    $Bytes = $Cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    Set-Content -Value $Bytes -Encoding byte -Path 'C:\Windows\Temp\mathworks_root_ca.cer'

    # Install the certificate
    Import-Certificate -FilePath 'C:\Windows\Temp\mathworks_root_ca.cer' -CertStoreLocation 'Cert:\LocalMachine\Root'

    # Cleanup
    [Net.ServicePointManager]::ServerCertificateValidationCallback = $null
    Remove-Item 'C:\Windows\Temp\mathworks_root_ca.cer'

    Write-Output 'Done with Install-Certificates.'
}

function Add-DesktopShortcut {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Release
    )

    Write-Output 'Starting Add-DesktopShortcut ...'

    Write-Output 'Remove AWS EC2 desktop shortcuts.'
    Remove-Item -Path 'C:\Users\Administrator\Desktop\*.website'

    Write-Output 'Add MATLAB shortcut in Desktop for all users.'
    Copy-Item -Path "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\MATLAB $Release\MATLAB $Release.lnk" -Destination 'C:\Users\Public\Desktop'

    Write-Output 'Done with Add-DesktopShortcut.'
}


function Install-MATLAB {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Release,

        [Parameter(Mandatory = $true)]
        [string] $Products,

        [Parameter(Mandatory = $false)]
        [string] $SourceURL
    )

    Install-MATLABUsingMPM -Release $Release -Products $Products -SourceURL $SourceURL
    Initialize-MATLAB -Release $Release
    Add-DesktopShortcut -Release $Release
}


try {
    $ErrorActionPreference = 'Stop'

    Install-MATLAB -Release $Env:RELEASE -Products $Env:PRODUCTS -SourceURL $Env:MATLAB_SOURCE_URL
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Install-MATLAB': $ScriptPath. Error: $_"
    throw
}
