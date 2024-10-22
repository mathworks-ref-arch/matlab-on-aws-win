<#
.SYNOPSIS
    Installs MATLAB Support Packages using MPM.

.LINK
    https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md

.NOTES
    Copyright 2024 The MathWorks, Inc.
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
            aws s3 cp $SourceURL "$Env:TEMP\spkg.zip"
            Expand-Archive -Path "$Env:TEMP\spkg.zip" -DestinationPath $Env:TEMP\spkg_source -Force
            Move-Item -Path "$Env:ProgramData\MathWorks\VersionInfo.xml" -Destination "$Env:TEMP\spkg_source"
            Remove-Item -Path "$Env:TEMP\spkg.zip"

            & "$Env:TEMP\mpm.exe" install `
                --source=$Env:TEMP\spkg_source\archives `
                --products $ProductsList

            Remove-Item -Path $Env:TEMP\spkg_source -Recurse -Force
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
