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
    Copyright 2020-2024 The MathWorks, Inc.
#>
function Set-DDUX {

    Write-Output 'Starting Set-DDUX...'

    [Environment]::SetEnvironmentVariable('MW_CONTEXT_TAGS', 'MATLAB:AWS:V1', [System.EnvironmentVariableTarget]::Machine)
    [Environment]::SetEnvironmentVariable('MW_DDUX_FORCE_ENABLE', $true, [System.EnvironmentVariableTarget]::Machine)

    $ResponseInstanceId = Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id
    $ResponseRegion = Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/placement/region
    $MWAppTagGroup = aws ec2 describe-tags --filters "Name=resource-id,Values=$ResponseInstanceId" 'Name=key,Values=mw-app' --region "$ResponseRegion"
    $MWAppTag = (Write-Output $MWAppTagGroup | ConvertFrom-Json).Tags.Value

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
