<#
.SYNOPSIS
    Enables matlab-proxy to enable browser access to MATLAB.

.DESCRIPTION
    Sets up matlab-proxy's authentication token to expect the user's VM password.
    Adds a firewall rule to allow matlab-proxy traffic.
    Starts matlab-proxy in the background.

.PARAMETER EnableBrowserAccess
    (Required) Check to determine if the user has enabled browser access.

.PARAMETER AuthToken
    (Required) Used to set the auth-token required to access MATLAB in a browser. Value is equivalent to the system password.

.EXAMPLE
    Set-MATLABProxy -EnableBrowserAccess "Yes" -AuthToken "<AUTH-TOKEN>"

.NOTES
    Copyright 2024-2026 The MathWorks, Inc.
#>

$LAUNCH_FILE = "$Env:ProgramFiles\MathWorks\matlab-proxy\Start-MatlabProxy.ps1"
$MATLAB_PROXY_PORT = "8123"

# This refarch always runs matlab-proxy as the Administrator user, which is the
# default set in the launch script. The function below is retained, but not called,
# so that support for a configurable user can be enabled here in the future without
# restructuring this script.
# function Set-MATLABProxyUser {
#     param(
#         [Parameter(Mandatory = $true)]
#         [string] $Username
#     )
#
#     # Set the user that matlab-proxy runs MATLAB as
#     (Get-Content $LAUNCH_FILE -Raw) -Replace '\$USER = "Administrator"', ('$USER = "' + $Username + '"') | Set-Content $LAUNCH_FILE
# }

function Set-MATLABProxyAuthToken {
    param(
        [Parameter(Mandatory = $true)]
        [string] $AuthToken
    )

    # Set up token-authentication for matlab-proxy
    $PasswordDec = "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$AuthToken'))"
    (Get-Content $LAUNCH_FILE -Raw) -Replace '# \$Env:MWI_AUTH_TOKEN=', ('$Env:MWI_AUTH_TOKEN=' + $PasswordDec) | Set-Content $LAUNCH_FILE
}

function Set-MATLABProxyFirewallRule {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Port
    )

    # Open a firewall rule for matlab-proxy (only required on Windows)
    $RuleName = "matlab-proxy - Allow TCP"
    if (-not (Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow
    }
}

function Start-MATLABProxy {
    # Launch the matlab-proxy startup script in the background
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$LAUNCH_FILE`"" -WindowStyle Hidden
}

function Set-MATLABProxy {

    param(
        [Parameter(Mandatory = $true)]
        [string] $EnableBrowserAccess,

        [Parameter(Mandatory = $true)]
        [string] $Port,

        [Parameter(Mandatory = $true)]
        [string] $AuthToken
    )

    Write-Output 'Starting Set-MATLABProxy...'

    if ($EnableBrowserAccess -eq "Yes") {
        # Set-MATLABProxyUser -Username $Env:Username
        Set-MATLABProxyAuthToken -AuthToken $AuthToken
        Set-MATLABProxyFirewallRule -Port $Port
        Start-MATLABProxy
    }

    Write-Output 'Done with Set-MATLABProxy.'
}

try {
    Set-MATLABProxy -EnableBrowserAccess $Env:EnableMATLABProxy -Port $MATLAB_PROXY_PORT -AuthToken $Env:Password
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script: $ScriptPath. Error: $_"
    throw
}
