<powershell>
# Copyright 2025-2026 The MathWorks, Inc.
#
# Windows EC2 UserData Script for OpenSSH Configuration.
# Configures Windows Server to use OpenSSH for remote access instead of WinRM,
# for Packer builds on AWS EC2 instances.
# What this script does:
#   1. Installs and configures OpenSSH Server during startup
#   2. Enables public key authentication for SSH
#   3. Retrieves the EC2 instance's public key from the Instance Metadata Service
#   4. Saves the public key in administrators_authorized_keys file to allow SSH auth
#   5. Sets proper permissions on the file
# Reference:
#   https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement
function Enable-OpenSSh {
    Write-Output 'Starting Enable-OpenSSh...'
    Get-WindowsCapability -Online | Where-Object Name -Like 'OpenSSH*'
    $Name = (Get-WindowsCapability -Online | Where-Object Name -Like 'OpenSSH.Server*' | ForEach-Object { $_.Name })
    # Install the OpenSSH Server
    Add-WindowsCapability -Online -Name $Name
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    # Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify.
    if (!(Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
        Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    }
    else {
        Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
    }
    $SSHRegPath = 'HKLM:\SOFTWARE\OpenSSH'
    if (-not (Test-Path $SSHRegPath)) {
        Write-Output "OpenSSH registry path not found. Creating it..."
        New-Item -Path 'HKLM:\SOFTWARE' -Name 'OpenSSH' -Force
    }
    New-ItemProperty -Path $SSHRegPath -Name DefaultShell -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force
    Write-Output 'Done with Enable-OpenSSh.'
}

function Configure-SshForPacker {
    # Configuring the Packer builder machine to use Key-based auth
    # instead of password. See: https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement
    Write-Output 'Starting Configure-SshForPacker...'
    $SSHConfigFile = "C:\ProgramData\ssh\sshd_config"

    # Ensure PubkeyAuthentication is globally enabled.
    Write-Output "Ensuring PubkeyAuthentication is enabled in sshd_config..."
    (Get-Content $SSHConfigFile).replace('#PubkeyAuthentication yes', 'PubkeyAuthentication yes') | Set-Content $SSHConfigFile

    Write-Output "Restarting sshd service to apply configuration..."
    Restart-Service sshd

    # Place the public key in the central file used by sshd configuration.
    $AuthKeysFile = "C:\ProgramData\ssh\administrators_authorized_keys"
    Write-Output "Installing public key for Administrator into central file: $AuthKeysFile"
    
    $IMDS_Token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "60"} -Uri "http://169.254.169.254/latest/api/token" -Method PUT
    $PublicKey = (Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $IMDS_Token} -Uri "http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key").Trim()

    # Add the key to the central file. This will create the file if it doesn't exist.
    Add-Content -Path $AuthKeysFile -Value $PublicKey

    # Set the correct permissions for this shared file.
    Write-Output "Setting required file permissions on $AuthKeysFile..."
    icacls.exe $AuthKeysFile /reset
    icacls.exe $AuthKeysFile /inheritance:r
    icacls.exe $AuthKeysFile /grant "SYSTEM:F"
    icacls.exe $AuthKeysFile /grant "BUILTIN\Administrators:F"
    
    Write-Output 'Done with Configure-SshForPacker.'
}

try {
    $ErrorActionPreference = 'Stop'
    Enable-OpenSSh
    Configure-SshForPacker
}
catch {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Write-Output "ERROR - An error occurred while running script: $ScriptPath. Error: $_"
    throw
}
</powershell>