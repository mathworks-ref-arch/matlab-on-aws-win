<#
.SYNOPSIS
    Sets the Support Package root directory for MATLAB.

.DESCRIPTION
    Configures the Support Package root directory using the sprootsettingwriter utility.
    This is required for installing support packages in MATLAB R2024b and later.

.PARAMETER Release
    MATLAB Release version number. e.g. R2025a

.PARAMETER Destination
    The target directory for Support Package root.

.PARAMETER MATLABRoot
    The MATLAB installation root directory.

.NOTES
    Copyright 2025-2026 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>

function Set-SupportPackageRoot {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Release,

        [Parameter(Mandatory = $true)]
        [string] $Destination,

        [Parameter(Mandatory = $true)]
        [string] $MATLABRoot
    )

    if ( $Release -gt "R2024b" ) {
        $SprootWriterPath = Join-Path -Path "${MATLABRoot}" -ChildPath "bin\win64\sprootsettingwriter.exe"
        New-Item -Path "${Destination}" -ItemType Directory -Force | Out-Null    
        & "${SprootWriterPath}" -matlabroot "$MATLABRoot" -sproot "${Destination}"
    }

}

try {
    $ErrorActionPreference = 'Stop'

    Set-SupportPackageRoot -Release $Env:RELEASE -Destination "C:\ProgramData\MATLAB\$Env:RELEASE" -MATLABRoot "C:\Program Files\MATLAB\$Env:RELEASE"
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Set-SupportPackageRoot': $ScriptPath. Error: $_"
    throw
}
