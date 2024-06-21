<#
.SYNOPSIS
    Invokes MATLAB startup accelerator.

.DESCRIPTION
    Invokes MATLAB startup accelerator.

.PARAMETER MATLABRoot
    (Required) Root folder for MATLAB.

.EXAMPLE
    Invoke-MATLABStartupAccelerator -MATLABRoot "<MATLAB_ROOT_FOLDER>"

.NOTES
    Copyright 2020-2024 The MathWorks Inc.
#>

function Invoke-MATLABStartupAccelerator {

    param(
        [Parameter(Mandatory = $true)]
        [string] $MATLABRoot
    )

    Write-Output 'Starting Invoke-MATLABStartupAccelerator...'

    if ($MATLABRoot) {
        & "$MATLABRoot\bin\win64\MATLABStartupAccelerator.exe" 64 $MATLABRoot "$Env:ProgramData\MathWorks\msa.ini" "$Env:ProgramData\MathWorks\msa.log"
    }

    Write-Output 'Done with Invoke-MATLABStartupAccelerator.'
}



try {
    Invoke-MATLABStartupAccelerator -MATLABRoot $Env:MATLABRoot
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "WARNING - An error occurred while running script 'Invoke-MATLABStartupAccelerator': $ScriptPath. Error: $_"
}
