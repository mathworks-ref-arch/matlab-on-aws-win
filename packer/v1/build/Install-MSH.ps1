<#
.SYNOPSIS
    Installs MathWorks Service Host application (MSH).

.DESCRIPTION
    Installs MathWorks Service Host application (MSH).

.PARAMETER Release
    MATLAB Release version number. e.g. R2023a

.EXAMPLE
    Install-MSH -Release "R2023b"

.LINK
    https://www.mathworks.com/matlabcentral/answers/1815365-how-do-i-uninstall-and-reinstall-mathworks-service-host?s_tid=srchtitle

.NOTES
    Copyright 2026 The MathWorks, Inc.
    The function sets $ErrorActionPreference to 'Stop' to ensure that any errors encountered during the installation process will cause the script to stop and throw an error.
#>
function Install-MSH {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Release
    )

    Write-Output 'Starting Install-MSH...'

    if ( $Release -ge 'R2023a' ) {
        $MSH_TMP = 'C:\Windows\Temp'
        $MSH_ROOT = 'C:\Program Files\MathWorks\ServiceHost'
        $MSH_URL = 'https://www.mathworks.com/MathWorksServiceHost/win64/managed.zip'

        (New-Object System.Net.WebClient).DownloadFile($MSH_URL, "$MSH_TMP\win64.zip")

        # Create the installation dir
        mkdir -f $MSH_ROOT

        # Expand the installation scripts
        Write-Output 'Expanding MSH archive ...'
        Expand-Archive "$MSH_TMP\win64.zip" -DestinationPath $MSH_ROOT
        Get-ChildItem $MSH_ROOT

        # Set environment variables for logging
        $Env:MW_DIAGNOSTIC_DEST = "file=$MSH_TMP\ServiceHost.log"
        $Env:MW_DIAGNOSTIC_SPEC = '.*=fatal,critical,error,warning'

        # Run the MSH post install steps and wait until execution has finished
        Write-Output 'Run MSH post install steps'
        $MshProcess = (Start-Process -FilePath 'C:\Program Files\MathWorks\ServiceHost\bin\win64\mlcpostinstall.exe' -PassThru)
        $MshProcess.WaitForExit()

        # Check the exit code of mlcpostinstall.exe
        if ($MshProcess.ExitCode -ne 0) {
            Write-Output "mlcpostinstall.exe exited with code $MshProcess.ExitCode"
            Get-Content $MSH_TMP\ServiceHost.log
            exit $MshProcess.ExitCode
        }

        Write-Output 'Create ServiceHost startup shortcut'
        $Shell = New-Object -ComObject WScript.Shell
        $Shortcut = $Shell.CreateShortcut('C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\MathWorksServiceHost.lnk')
        $Shortcut.TargetPath = "$MSH_ROOT\bin\win64\MathWorksServiceHost.exe"
        $Shortcut.Arguments = 'service --realm-id companion@prod@production'
        $Shortcut.Save()

        # Cleanup
        Remove-Item -Path "$MSH_TMP\win64.zip"
        Remove-Item -Path "$MSH_TMP\ServiceHost.log"
        Remove-Item Env:\MW_DIAGNOSTIC_DEST
        Remove-Item Env:\MW_DIAGNOSTIC_SPEC

    }
    else {
        Write-Output 'MSH is not available for releases before R2023a.'
    }

    Write-Output 'Done with Install-MSH.'
}



try {
    $ErrorActionPreference = 'Stop'
    Install-MSH -Release $Env:RELEASE
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script: $ScriptPath. Error: $_"
    throw
}
