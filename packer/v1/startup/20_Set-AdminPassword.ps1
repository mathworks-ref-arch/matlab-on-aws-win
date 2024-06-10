<#
.SYNOPSIS
    Sets up the machine for use by its administrators.

.DESCRIPTION
    Prepares the machine for use by administrators. Additional machine-level setup can be included here as required.

.PARAMETER AdminPass
    (Required) admin password.

.EXAMPLE
    Set-AdminPassword -AdminPass "<ADMIN_PASSWORD>"

.NOTES
    Copyright 2023 The MathWorks Inc.
#>
function Set-AdminPassword {

    param(
        [Parameter(Mandatory = $true)]
        [string] $AdminPass
    )

    Write-Output 'Starting Set-AdminPassword...'

    $PasswordDec = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($AdminPass))
    net user Administrator $PasswordDec

    Write-Output 'Done with Set-AdminPassword.'
}

try {
    Set-AdminPassword -AdminPass $Env:Password
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Set-AdminPassword': $ScriptPath. Error: $_"
    throw
}
