# Commands Reference — AWS EC2 Security Hardening Project

Full command set used across the project, organized by phase.

---

## Lynis — Installation, Troubleshooting & Audit

**Install:**
```bash
sudo apt install lynis -y
```

**Issue encountered:** `lynis show version` returned `command not found` despite the package reporting as already installed.

**Diagnostic steps:**
```bash
lynis show version              # command not found
which lynis                     # empty output — confirms PATH visibility issue
dpkg -L lynis | grep bin        # confirms actual binary location: /usr/sbin/lynis
sudo /usr/sbin/lynis show version   # confirms the tool works via full path
```

**Root cause:** Lynis installs to `/usr/sbin/`, which is included in root's PATH but excluded from a regular user's PATH by default on Debian.

**Resolution:** run with `sudo`, which resolves the correct PATH.

**Run the full audit:**
```bash
sudo lynis audit system
```

**Fixing the "vulnerable packages" warning:**
```bash
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
```

---

## rkhunter — Malware/Rootkit Scanner (Lynis suggestion: HRDN-7230)

```bash
sudo apt install rkhunter -y
sudo rkhunter --update
sudo rkhunter --propupd
```

---

## fail2ban — Brute-Force Protection (Lynis suggestion: DEB-0880)

```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo fail2ban-client status     # verify it's running
```

---

## Apache — Directory Listing Vulnerability Fix

**Locate the relevant configuration block:**
```bash
sudo grep -n "Directory /var/www" /etc/apache2/apache2.conf
```

**View the block to confirm its content:**
```bash
sudo sed -n '169,173p' /etc/apache2/apache2.conf
```

**Apply the fix:**
```bash
sudo sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/apache2/apache2.conf
```

**Verify the change saved:**
```bash
sudo grep -A 4 "Directory /var/www" /etc/apache2/apache2.conf
```

**Restart Apache to apply the change:**
```bash
sudo systemctl restart apache2
```

**Create a test folder to prove the fix works:**
```bash
sudo touch /var/www/html/testfolder/somefile.txt
```

**Test in browser:**
```
http://<your-EC2-public-IP>/testfolder/
```
Expected result after the fix: no directory listing is shown (403 Forbidden or similar), instead of a raw file listing.

---

## cis_harden.sh — Automation Script

**Create the script:**
```bash
nano cis_harden.sh
```

**Make it executable:**
```bash
chmod +x cis_harden.sh
```

**Run it:**
```bash
sudo bash cis_harden.sh
```

---

## AWS Inspector — Planned Steps (not yet executed)

1. Enable AWS Inspector
2. Run first scan
3. Review vulnerability findings
4. Identify high severity issues
5. Apply patches
6. Re-scan to confirm remediation
7. Scan container images (optional — if using ECR)
