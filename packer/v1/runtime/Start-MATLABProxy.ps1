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
    Copyright 2024 The MathWorks Inc.
    This script is invoked by Task Scheduler only.
#>
function Start-MATLABProxy {

    $Env:PATH="$Env:PATH;$Env:ProgramFiles\Python310\Scripts"
    $Env:MWI_APP_PORT='8123'
    $Env:MWI_SSL_CERT_FILE="$Env:ProgramData\MathWorks\matlab-proxy\certificate.pem"
    $Env:MWI_SSL_KEY_FILE="$Env:ProgramData\MathWorks\matlab-proxy\private_key.pem"
    $Env:MWI_ENABLE_TOKEN_AUTH='true'
    # $Env:MWI_AUTH_TOKEN=
    $Env:MWI_PROCESS_START_TIMEOUT='300'
    
    matlab-proxy-app
}

try {
    Start-MATLABProxy
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script: $ScriptPath. Error: $_"
    throw
}
