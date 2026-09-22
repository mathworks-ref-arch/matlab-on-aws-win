<#
.SYNOPSIS
    Installs the matlab-proxy Python package.

.DESCRIPTION
    Installs the matlab-proxy Python package.

.PARAMETER Version
    matlab-proxy version number (e.g. "0.10.0"), or "latest" to install the most recent version available on PyPI.

.EXAMPLE
    Install-MATLABProxy -Version "latest"

.LINK
    https://github.com/mathworks/matlab-proxy

.NOTES
    Copyright 2024-2026 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>

function Install-MATLABProxy {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Version
    )

    Write-Output 'Starting Install-MATLABProxy...'
    if ($Version -eq 'latest') {
        & $Env:ProgramFiles\Python\python.exe -m pip install matlab-proxy
    }
    else {
        & $Env:ProgramFiles\Python\python.exe -m pip install matlab-proxy==$Version
    }
    $InstalledVersion = & $Env:ProgramFiles\Python\python.exe -m pip show matlab-proxy | Select-String '^Version:' | ForEach-Object { ($_ -split '\s+')[1] }
    Write-Output "Installed matlab-proxy version: $InstalledVersion"

    Write-Output 'Moving the SSL certificate generator and launcher script to the right directory...'
    $RuntimeSource = 'C:\Windows\Temp\runtime'
    
    $DestinationFolder = "$Env:ProgramFiles\MathWorks\matlab-proxy"
    
    New-Item $DestinationFolder -Type Directory
    Copy-Item "$RuntimeSource\Start-MatlabProxy.ps1" -Destination "$DestinationFolder\Start-MatlabProxy.ps1"
    
    Write-Output 'Done with Install-MATLABProxy.'   
}

try {
    $ErrorActionPreference = 'Stop'
    Install-MATLABProxy -Version $Env:MATLAB_PROXY_VERSION
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script: $ScriptPath. Error: $_"
    throw
}
