<#
.SYNOPSIS
    Runs optional user command.

.DESCRIPTION
    Executes an optional user command. This script will run as the final step in the EC2 startup process,
    potentially overriding any changes applied in previous scripts.

.PARAMETER UserCommand
    (Optional) Optional user command.

.EXAMPLE
    Invoke-OptionalUserCommand -UserCommand "<OPTIONAL_USER_COMMAND>"

.NOTES
    Copyright 2023-2024 The MathWorks Inc.
#>

function Invoke-OptionalUserCommand {

    param(
        [Parameter()]
        [string] $UserCommand
    )

    Write-Output 'Starting Invoke-OptionalUserCommand...'

    Write-Output "$UserCommand"

    if ([string]::IsNullOrWhiteSpace("$UserCommand")) {
        Write-Output 'No optional user command was passed.'
    }
    else {
        Write-Output 'The passed string is an inline PowerShell command.'
        Invoke-Expression "$UserCommand"
    }

    Write-Output 'Done with Invoke-OptionalUserCommand.'
}


try {
    Invoke-OptionalUserCommand -UserCommand $Env:OptionalUserCommand
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script 'Invoke-OptionalUserCommand': $ScriptPath. Error: $_"
    throw
}


