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
    Copyright 2020-2025 The MathWorks, Inc.
#>
function Test-AWSEndpoint {
    param(
        [Parameter(Mandatory)]
        [string]$Endpoint,
        [int]$Port = 443,
        [int]$TimeoutSeconds = 5
    )

    try {
        $Response = Test-NetConnection -ComputerName $Endpoint -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue -TimeoutSeconds $TimeoutSeconds
        return [bool]$Response.TcpTestSucceeded
    } catch {
        Write-Host "Error connecting to $Endpoint : $($_.Exception.Message)"
    }
    
    return $false
}

function Set-DDUX {

    Write-Output 'Starting Set-DDUX...'

    [Environment]::SetEnvironmentVariable('MW_CONTEXT_TAGS', 'MATLAB:AWS:V1', [System.EnvironmentVariableTarget]::Machine)
    [Environment]::SetEnvironmentVariable('MW_DDUX_FORCE_ENABLE', $true, [System.EnvironmentVariableTarget]::Machine)

    $Token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "120"} -Method PUT -Uri http://169.254.169.254/latest/api/token
    $ResponseInstanceId = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/instance-id
    $ResponseRegion = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/placement/region
    $AWSDomain = "amazonaws.com"
    if ($ResponseRegion -like "cn-*") { 
        $AWSDomain = "amazonaws.com.cn" 
    }

    $EC2Endpoint = "ec2.$ResponseRegion.$AWSDomain"

    if (-not (Test-AWSEndpoint -Endpoint "$EC2Endpoint")) {
        Write-Output "AWS EC2 Endpoint $EC2Endpoint is not reachable. Skipping DDUX tag check."
        return
    }

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
