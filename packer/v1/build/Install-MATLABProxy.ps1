<#
.SYNOPSIS
    Installs the matlab-proxy Python package.

.DESCRIPTION
    Installs the matlab-proxy Python package.

.PARAMETER Version
    matlab-proxy version number. e.g. 0.10.0

.EXAMPLE
    Install-MATLABProxy -Version "0.10.0"

.LINK
    https://github.com/mathworks/matlab-proxy

.NOTES
    Copyright 2024 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>

function Install-MATLABProxy {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Version
    )

    Write-Output 'Starting Install-MATLABProxy...'
    & $Env:ProgramFiles\Python310\python.exe -m pip install matlab-proxy==$Version

    Write-Output 'Moving the SSL certificate generator and launcher script to the right directory...'
    $RuntimeSource = 'C:\Windows\Temp\runtime'
    
    $DestinationFolder = "$Env:ProgramFiles\MathWorks\matlab-proxy"
    
    New-Item $DestinationFolder -Type Directory
    Copy-Item "$RuntimeSource\Start-MatlabProxy.ps1" -Destination "$DestinationFolder\Start-MatlabProxy.ps1"
    Copy-Item "$RuntimeSource\generate-certificate.py" -Destination "$DestinationFolder\generate-certificate.py"
    
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
