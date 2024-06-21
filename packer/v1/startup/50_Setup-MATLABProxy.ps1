<#
.SYNOPSIS
    Enables matlab-proxy to enable browser access to MATLAB.

.DESCRIPTION
    Creates self-signed certificates for secure communication via matlab-proxy. 
    Sets up matlab-proxy's authentication token to expect the user's VM password.
    Adds a firewall rule to allow matlab-proxy traffic.
    Invokes a task that starts matlab-proxy in the background.

.PARAMETER EnableBrowserAccess
    (Required) Check to determine if the user has enabled browser access.

.PARAMETER AuthToken
    (Required) Used to set the auth-token required to access MATLAB in a browser. Value is equivalent to the system password.

.EXAMPLE
    Set-MATLABProxy -EnableBrowserAccess "Yes" -AuthToken "<AUTH-TOKEN>"

.NOTES
    Copyright 2024 The MathWorks Inc.
#>

function Set-MATLABProxy {

    param(
        [Parameter(Mandatory = $true)]  
        [string] $EnableBrowserAccess,
        
        [Parameter(Mandatory = $true)]
        [string] $AuthToken
    )

    Write-Output 'Starting Set-MATLABProxy...'

    # Generate the SSL certificate for matlab-proxy to use TLS
    $MatlabProxyDataPath = "$Env:ProgramData\MathWorks\matlab-proxy"
    New-Item $MatlabProxyDataPath -Type Directory

    $CertPath = "$MatlabProxyDataPath\certificate.pem"
    $KeyPath = "$MatlabProxyDataPath\private_key.pem"

    if ((-not (Test-Path $CertPath)) -or (-not (Test-Path $KeyPath))) {
        if (Test-Path $CertPath) {
            Remove-Item -Path $CertPath
        }
        if (Test-Path $KeyPath) {
            Remove-Item -Path $KeyPath
        }
        py "$Env:ProgramFiles\MathWorks\matlab-proxy\generate-certificate.py"
        Move-Item -Path "$Env:ProgramFiles\MathWorks\matlab-proxy\private_key.pem" -Destination $KeyPath
        Move-Item -Path "$Env:ProgramFiles\MathWorks\matlab-proxy\certificate.pem" -Destination $CertPath
    }

    # Set up token-authentication for matlab-proxy
    if ($AuthToken) {
        $LaunchFile = "$Env:ProgramFiles\MathWorks\matlab-proxy\Start-MatlabProxy.ps1"
        $PasswordDec = "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$AuthToken'))"

        (Get-Content $LaunchFile -Raw) -Replace '# \$Env:MWI_AUTH_TOKEN=', ('$Env:MWI_AUTH_TOKEN=' + $PasswordDec) | Set-Content $LaunchFile
    }

    # Open a firewall rule for matlab-proxy (only required on Windows)
    $RuleName = "matlab-proxy - Allow TCP"
    if (-not (Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Protocol TCP -LocalPort 8123 -Action Allow
    }

    # Start matlab-proxy
    if ($EnableBrowserAccess -eq "Yes") {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"C:\Program Files\MathWorks\matlab-proxy\Start-MATLABProxy.ps1`"" -WindowStyle Hidden
    }

    Write-Output 'Done with Set-MATLABProxy.'
    
}

try {
    Set-MATLABProxy -EnableBrowserAccess $Env:EnableMATLABProxy -AuthToken $Env:Password
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script: $ScriptPath. Error: $_"
    throw
}
