<#
.SYNOPSIS
    Invokes MSH startup accelerator.

.DESCRIPTION
    Invokes MSH startup accelerator.

.PARAMETER MATLABRoot
    (Required) Root folder for MATLAB.

.EXAMPLE
    Invoke-MSHStartupAccelerator -MATLABRoot "<MATLAB_ROOT_FOLDER>"

.NOTES
    Copyright 2024 The MathWorks, Inc.
#>

function Invoke-MSHStartupAccelerator {

    param(
        [Parameter(Mandatory = $true)]
        [string] $MATLABRoot
    )
        
    Write-Output 'Starting Invoke-MSHStartupAccelerator...'

    $ServiceHostPath = "C:\Program Files\MathWorks\ServiceHost"
    $IniFilePath = "$Env:TEMP\mshsa.ini"
    $LogFilePath = "$Env:ProgramData\MathWorks\mshsa.log"
    
    # Find all files within the ServiceHostPath directory, and output their full paths to the IniFilePath
    if (Test-Path -Path $ServiceHostPath) {
        Get-ChildItem -Path $ServiceHostPath -File -Recurse | ForEach-Object {
            $_.FullName.Replace("$ServiceHostPath\", "")
        } | Out-File -FilePath $IniFilePath -Encoding UTF8 -Force
    
        # Execute the MATLABStartupAccelerator on MSH file list
        if ($MATLABRoot -and $?) {
            & "$MATLABRoot\bin\win64\MATLABStartupAccelerator.exe" 64 $ServiceHostPath $IniFilePath $LogFilePath
        }
    }   
    else {

        Write-Output 'ServiceHostPath does not exist.'
    }
    
    Write-Output 'Done with Invoke-MSHStartupAccelerator.'
}



try {
    Invoke-MSHStartupAccelerator -MATLABRoot $Env:MATLABRoot
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "WARNING - An error occurred while running script 'Invoke-MSHStartupAccelerator': $ScriptPath. Error: $_"
}
