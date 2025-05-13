<#
.SYNOPSIS
    Installs MATLAB Support Packages using MPM.

.LINK
    https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md

.NOTES
    Copyright 2024-2025 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>


function Install-MATLABSPKGUsingMPM {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Release,

        [Parameter(Mandatory = $true)]
        [string] $Products,

        [Parameter(Mandatory = $false)]
        [string] $SourceURL
    )

    Write-Output 'Starting Install-MATLABSPKGUsingMPM...'
    Set-Location -Path $Env:TEMP

    # As a best practice, downloading the latest version of mpm before calling it.
    Write-Output 'Downloading mpm ...'
    
    Invoke-WebRequest -OutFile "$Env:TEMP\mpm.exe" -Uri 'https://www.mathworks.com/mpm/win64/mpm'
    
    $MpmLogFilePath = "$Env:TEMP\mathworks_$Env:USERNAME.log"

    Write-Output 'Installing products ...'
    $ProductsList = $Products -Split ' '

    try {

        if ( $SourceURL.length -eq 0 ) {
            & "$Env:TEMP\mpm.exe" install `
                --release $Release `
                --products $ProductsList
        }
        else {
            # Dot-sourcing the Mount-DataDriveUtils script
            . 'C:\Windows\Temp\config\matlab\Mount-DataDriveUtils.ps1'

            # Setup extra volume to mount drive containing MATLAB Support Packages source files
            $SpkgSourceDrive = 'X'
            $SpkgSourcePath = 'X:\spkg_source'

            Mount-DataDrive -DriveToMount "$SpkgSourceDrive"
            Get-MATLABSourceFiles -SourceURL $SourceURL -Destination "$SpkgSourcePath"

            Copy-Item -Path "$Env:ProgramFiles\MATLAB\${Release}\VersionInfo.xml" -Destination "$SpkgSourcePath"

            $SourcePath = Get-ChildItem -Path "$SpkgSourcePath" -Directory -Recurse -Filter 'archives' | Select-Object -First 1 -ExpandProperty FullName

            if (-not $SourcePath) {
                throw 'Failed to find MATLAB source files at the specified location'
            }

            & "$Env:TEMP\mpm.exe" install `
                --source=$SourcePath `
                --products $ProductsList

            Dismount-DataDrive -DriveLetter "$SpkgSourceDrive"
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

    Write-Output 'Done with Install-MATLABSPKGUsingMPM.'
}

function Install-MATLABSupportPackages {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Release,

        [Parameter(Mandatory = $true)]
        [string] $Products,

        [Parameter(Mandatory = $false)]
        [string] $SourceURL
    )
    Install-MATLABSPKGUsingMPM -Release $Release -Products $Products -SourceURL $SourceURL
}


try {
    $ErrorActionPreference = 'Stop'
    
    if (-not "$Env:SPKGS"){
        Write-Output 'No support packages defined to be installed. Installation skipped.'
        exit 0
    }

    Install-MATLABSupportPackages -Release $Env:RELEASE -Products $Env:SPKGS -SourceURL $Env:SPKG_SOURCE_URL
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Install-MATLABSupportPackages': $ScriptPath. Error: $_"
    throw
}
