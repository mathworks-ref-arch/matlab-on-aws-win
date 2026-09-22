<#
.SYNOPSIS
    Enables MATLAB DDUX to allow MathWorks to gain insights into how this product is being used.

.DESCRIPTION
    The script sets environment variables to enable MathWorks to gain insights into the usage of this product, aiding in the improvement of MATLAB.
    It's important to note that your content and information within your files are not shared with MathWorks.
    To opt out of this service, simply delete this file.

.EXAMPLE
    Set-DDUX

.NOTES
    Copyright 2020-2026 The MathWorks, Inc.
#>
function Set-DDUX {

    Write-Output 'Starting Set-DDUX...'

    [Environment]::SetEnvironmentVariable('MW_CONTEXT_TAGS', 'MATLAB:AWS:V1', [System.EnvironmentVariableTarget]::Machine)
    [Environment]::SetEnvironmentVariable('MW_DDUX_FORCE_ENABLE', $true, [System.EnvironmentVariableTarget]::Machine)

    # Fetch the mw-app instance tag from IMDS (instance metadata tags must be enabled on the instance).
    $Token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "300"} -Method PUT -Uri http://169.254.169.254/latest/api/token
    $InstanceTags = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $Token} -Method GET -Uri http://169.254.169.254/latest/meta-data/tag-sets/instance

    # A JSON response is auto-parsed into an object; fall back to parsing a raw string.
    if ($InstanceTags -is [string]) {
        $InstanceTags = $InstanceTags | ConvertFrom-Json
    }
    $MWAppTag = $InstanceTags.'mw-app'

    if ( $MWAppTag -eq 'cloudcenter' ) {
        [Environment]::SetEnvironmentVariable('MW_CONTEXT_TAGS', 'MATLAB:AWS:V1,MATLAB:CLOUD_CENTER:V1', [System.EnvironmentVariableTarget]::Machine)
    }

    Write-Output 'Done with Set-DDUX.'
}


try {
    Set-DDUX
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "WARNING - An error occurred while running script 'Set-DDUX': $ScriptPath. Error: $_"
}
