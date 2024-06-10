<#
.SYNOPSIS
    Waits until instance profile is attached to the EC2 instance.

.DESCRIPTION
    Waits until the instance profile is attached to the EC2 instance. For additional information regarding EC2 instance profiles,
    please refer to https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html

.EXAMPLE
    Confirm-InstanceProfile

.NOTES
    Copyright 2020-2024 The MathWorks Inc.
#>
function Confirm-InstanceProfile {

    Write-Output 'Starting Confirm-InstanceProfile...'

    $StatusCode = $null
    $Response = $null
    while ($StatusCode -ne 200) {
        try {
            $Response = Invoke-WebRequest -UseBasicParsing -Uri http://169.254.169.254/latest/meta-data/iam/info
            $StatusCode = $Response.StatusCode
            Start-Sleep -Milliseconds 100
        }
        catch {
            $StatusCode = $_.Exception.Response.StatusCode.value__
        }
    }
    Write-Output 'Found information about attached instance profile:' ($Response.Content | ConvertFrom-Json).InstanceProfileArn

    Write-Output 'Done with Confirm-InstanceProfile.'
}


try {
    Confirm-InstanceProfile
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running 'Confirm-InstanceProfile' script: $ScriptPath. Error: $_"
    throw
}
