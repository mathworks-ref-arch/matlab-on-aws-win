# Copyright 2025-2026 The MathWorks, Inc.
#
# EC2Launch v2 user_data: enableOpenSsh turns on the OpenSSH server (WS2025 ships
# it pre-installed but disabled). It leaves DefaultShell as cmd.exe, so the second
# task sets PowerShell as the SSH default shell (persisted in the image).
version: 1.1
tasks:
  - task: enableOpenSsh
  - task: executeScript
    inputs:
      - frequency: once
        type: powershell
        runAs: localSystem
        content: |-
          $ErrorActionPreference = 'Stop'
          $SSHRegPath = 'HKLM:\SOFTWARE\OpenSSH'
          if (-not (Test-Path $SSHRegPath)) { New-Item -Path $SSHRegPath -Force | Out-Null }
          New-ItemProperty -Path $SSHRegPath -Name DefaultShell -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force
