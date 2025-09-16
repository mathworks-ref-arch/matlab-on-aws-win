<powershell>
# Copyright 2024-2025 The MathWorks, Inc.
#
# This script is executed by Packer during deployment of the build instance.
# It enables WinRM via HTTPs, which Packer uses to provision the instance.
# Example configuration: https://developer.hashicorp.com/packer/docs/communicators/winrm#examples
# Set Administrator password
net user '${winrm_username}' '${winrm_password}'
wmic useraccount where "name='${winrm_username}'" set PasswordExpires=FALSE

# Delete existing listeners
winrm delete winrm/config/listener?Address=*+Transport=HTTP 2>$Null
winrm delete winrm/config/listener?Address=*+Transport=HTTPS 2>$Null

# Get the local hostname and create a self-signed certificate for WinRM HTTPS
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem).Name
$Cert = New-SelfSignedCertificate -DnsName $Hostname -CertStoreLocation Cert:\LocalMachine\My

# Get the thumbprint
$Thumbprint = $Cert.Thumbprint

# Create the WinRM HTTPS listener on given port and configure setting
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$Hostname`"; CertificateThumbprint=`"$Thumbprint`"; Port=`"${winrm_port}`"}"
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'
winrm set winrm/config '@{MaxTimeoutms="7200000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

# Configure UAC to allow privilege elevation in remote shells
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'LocalAccountTokenFilterPolicy' -Value 1 -Force

# Open Windows Firewall for WinRM HTTPS
if (-not (Get-NetFirewallRule -DisplayName "WinRM HTTPS ${winrm_port}" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "WinRM HTTPS ${winrm_port}" -Direction Inbound -Action Allow -Protocol TCP -LocalPort ${winrm_port}
}

# Restart WinRM service
Stop-Service -Name WinRM -Force
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM
</powershell>
