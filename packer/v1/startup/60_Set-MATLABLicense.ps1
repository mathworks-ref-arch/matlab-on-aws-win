<#
.SYNOPSIS
    Configures MATLAB licensing.

.DESCRIPTION
    Configures MATLAB licensing.

.PARAMETER MATLABRoot
    (Required) Root folder for MATLAB.

.PARAMETER MLMLicenseFile
    (Optional) The path to the MATLAB license file. If no value is specified, MATLAB will be configured to use online licensing.

.EXAMPLE
    Set-MATLABLicense -MATLABRoot "<MATLAB_ROOT_FOLDER>" -MLMLicenseFile "<PATH_TO_MATLAB_LICENSE_FILE>"

.NOTES
    Copyright 2023 The MathWorks Inc.
#>

function Set-MATLABLicense {

    param(
        [Parameter(Mandatory = $true)]
        [string] $MATLABRoot,

        [Parameter()]
        [string] $MLMLicenseFile
    )

    Write-Output 'Starting Set-MATLABLicense...'

    If ($MATLABRoot -and ($MLMLicenseFile -match '\d+@.+')) {
        Write-Output 'License MATLAB using Network License Manager'
        $OnlineLicensePath = "$MATLABRoot\licenses\license_info.xml"
        If (Test-Path $OnlineLicensePath) { Remove-Item $OnlineLicensePath }

        $Port, $Hostname = $MLMLicenseFile.split('@')
        $LicenseContent = "SERVER $Hostname 123456789ABC $Port`r`nUSE_SERVER"
        Set-Content -Path "$MATLABRoot\licenses\network.lic" -Value $LicenseContent -NoNewline
    }
    Else {
        Write-Output 'License MATLAB using Online Licensing'
    }

    Write-Output 'Done with Set-MATLABLicense.'
}


try {
    Set-MATLABLicense -MATLABRoot $Env:MATLABRoot -MLMLicenseFile $Env:MLMLicenseFile
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Set-MATLABLicense': $ScriptPath. Error: $_"
    throw
}
