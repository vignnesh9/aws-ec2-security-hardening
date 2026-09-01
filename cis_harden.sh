#!/bin/bash
# cis_harden.sh
# Automates the 15 CIS Debian Benchmark controls applied in this project.
# Run as: sudo bash cis_harden.sh

set -e

echo "[+] Applying SSH hardening controls..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?Protocol.*/Protocol 2/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

echo "[+] Ensuring automatic security updates are installed..."
sudo apt install -y unattended-upgrades

echo "[+] Installing and configuring UFW firewall..."
sudo apt install -y ufw
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw --force enable
sudo ufw status

echo "[+] Installing AIDE (file integrity monitoring)..."
sudo apt install -y aide
sudo aideinit

echo "[+] Correcting file permissions..."
sudo chmod 644 /etc/passwd
sudo chmod 640 /etc/shadow

echo "[+] Confirming sudo use_pty is enabled..."
if ! sudo grep -q "^Defaults.*use_pty" /etc/sudoers; then
    echo "Defaults use_pty" | sudo EDITOR='tee -a' visudo
fi

echo "[+] CIS hardening complete. Review /etc/passwd for any unused accounts manually."
