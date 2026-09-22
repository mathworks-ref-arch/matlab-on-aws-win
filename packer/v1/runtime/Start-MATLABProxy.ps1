<#
.SYNOPSIS
    Configures and launches matlab-proxy.

.DESCRIPTION
    Configures and launches matlab-proxy.

.EXAMPLE
    Start-MATLABProxy

.LINK
    https://github.com/mathworks/matlab-proxy/blob/main/Advanced-Usage.md

.NOTES
    Copyright 2024-2026 The MathWorks, Inc.
    This script is launched in the background during instance startup. Its stdout/stderr
    (including matlab-proxy-app output) is captured to $Env:ProgramData\MathWorks\matlab-proxy.log
    so it can be inspected after the fact and shipped to CloudWatch.
#>


# Set user for matlab-proxy.
$USER = "$Env:USERNAME"

function Start-MATLABProxy {

    $Env:PATH="$Env:PATH;$Env:ProgramFiles\Python\Scripts"
    $Env:MWI_APP_PORT='8123'
    $Env:MWI_ENABLE_SSL='true'
    $Env:MWI_ENABLE_TOKEN_AUTH='true'
    # $Env:MWI_AUTH_TOKEN=
    $Env:MWI_PROCESS_START_TIMEOUT='300'

    # Start MATLAB in the user's Documents folder.
    $MATLAB_STARTUP_FOLDER = "C:\Users\$USER\Documents"
    New-Item -ItemType Directory -Force -Path $MATLAB_STARTUP_FOLDER | Out-Null
    $Env:MWI_MATLAB_STARTUP_SCRIPT = "cd $MATLAB_STARTUP_FOLDER"

    # matlab-proxy-app writes to stdout/stderr; redirect both so they land in the transcript.
    matlab-proxy-app *>&1
}

$LogPath = "$Env:ProgramData\MathWorks\matlab-proxy.log"
Start-Transcript -Path $LogPath -Append | Out-Null

try {
    Start-MATLABProxy
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script: $ScriptPath. Error: $_"
    throw
}
finally {
    Stop-Transcript | Out-Null
}
