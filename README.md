# aws-ec2-security-hardening
Hands-on AWS EC2 security hardening: least-privilege IAM, CIS Benchmark compliance, CloudWatch/CloudTrail logging, and vulnerability remediation with Lynis, rkhunter, and fail2ban

# Securing the Cloud: Least Privilege, Hardening, and Vulnerability Management on AWS

A hands-on cloud security project: standing up a real, public-facing AWS EC2 web server, then securing it end-to-end — identity and access, logging and auditability, CIS Benchmark compliance, and vulnerability scanning and remediation.

Built as part of hands-on portfolio work targeting SOC Analyst, IAM Analyst, and Cloud Security roles.

---

## Project Overview

**Goal:** launch a real EC2 web server, then apply layered security controls — access restriction, least-privilege identity, monitoring, compliance hardening, and vulnerability scanning — verifying each one rather than assuming it worked.

| Component | Detail |
|---|---|
| Compute | AWS EC2, Debian 13 |
| Web Server | Apache |
| Identity | Dedicated IAM user (no root usage) |
| Logging | CloudWatch, CloudTrail |
| Compliance | CIS Debian Benchmark (15 controls) |
| Vulnerability Scanning | Lynis, rkhunter, fail2ban |

---

## Toolkit

**Cloud Platform & Identity**
- AWS EC2
- AWS IAM

**Monitoring & Auditing**
- AWS CloudWatch
- AWS CloudTrail
- AWS GuardDuty (attempted — blocked by pending account verification)

**Compliance Hardening**
- CIS Benchmark (Debian)
- UFW (firewall)
- AIDE (file integrity monitoring)
- unattended-upgrades (automatic patching)

**Vulnerability Management**
- Lynis (security auditing)
- rkhunter (malware/rootkit scanner)
- fail2ban (brute-force protection)

**Application Layer**
- Apache HTTP Server

**Automation**
- Bash scripting (`cis_harden.sh`)

**Reference Framework**
- OWASP Top 10 for Cloud Security

---

## Phase 1 — Standing Up the Target

- Created a dedicated AWS IAM user (no work performed under root)
- Launched an EC2 instance running Debian 13
- Configured Apache as a basic web server
- Result: a live, publicly reachable webpage

---

## Phase 2 — Locking Down Access: SSH & Least-Privilege IAM

**SSH restriction:** default configuration allowed SSH from any IP. Restricted via the instance's Security Group to a single known IP address, then verified the restriction held.

**Least-privilege IAM policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances"
      ],
      "Resource": "arn:aws:ec2:us-east-2:577137986572:instance/i-0b7e1e5d71fe8b991"
    }
  ]
}
```

**Verification:** tested the policy against a *different*, out-of-scope instance and confirmed a clean, specific Access Denied — proof the scope actually holds, not just that the policy was written correctly.

---

## Phase 3 — Logging & Auditability: CloudWatch & CloudTrail

- **CloudWatch** configured for baseline infrastructure monitoring
- **CloudTrail** used to independently verify two events:
  1. A console login (user, timestamp, source IP, MFA status)
  2. The denied `StopInstances` attempt from Phase 2 — CloudTrail's audit record shows the exact error (`Client.UnauthorizedOperation`) and reason

**Known limitation:** GuardDuty enablement was blocked by a pending AWS account verification requirement (up to 24 hours to process). This is an account-side limitation, not a configuration failure. CloudWatch and CloudTrail fulfilled the logging/monitoring requirement in the interim.

---

## Phase 4 — CIS Benchmark Hardening (15 Controls)

All 15 controls applied and verified directly on the instance via SSH.

| # | Control | Command(s) Used | Status |
|---|---|---|---|
| 1 | Disable root SSH login | `PermitRootLogin no` | Applied |
| 2 | Disable password authentication | `PasswordAuthentication no` | Applied |
| 3 | Enforce SSH Protocol 2 | `Protocol 2` | Applied |
| 4 | Limit authentication attempts | `MaxAuthTries 3` | Applied |
| 5 | Auto-disconnect idle sessions (interval) | `ClientAliveInterval 300` | Applied |
| 6 | Auto-disconnect idle sessions (count) | `ClientAliveCountMax 0` | Applied |
| 7 | Disable empty passwords | `PermitEmptyPasswords no` | Applied |
| 8 | Automatic security updates | `sudo apt install unattended-upgrades -y` | Already present |
| 9 | Install & enable firewall (UFW) | `sudo apt install ufw -y; sudo ufw allow 22/tcp; sudo ufw allow 80/tcp; sudo ufw enable` | Applied |
| 10 | Verify firewall rules | `sudo ufw status` | Verified |
| 11 | File integrity monitoring (AIDE) | `sudo apt install aide -y; sudo aideinit` | Applied |
| 12 | Permissions on /etc/passwd | `sudo chmod 644 /etc/passwd` | Applied |
| 13 | Permissions on /etc/shadow | `sudo chmod 640 /etc/shadow` | Applied |
| 14 | sudo commands use pty | `Defaults use_pty` (via visudo) | Already present |
| 15 | Disable unused login shells | Reviewed `/etc/passwd` for all accounts | Already compliant |

**Verification:** after applying the SSH controls, confirmed a brand-new SSH connection succeeded with zero password prompt — proving key-only authentication was correctly enforced.

---

## Phase 5 — Vulnerability Scanning: Lynis, rkhunter & fail2ban

**Issue encountered:** `lynis show version` returned `command not found` despite `apt install lynis` reporting it was already installed.

**Diagnostic steps:**
```bash
which lynis                    # empty — confirms PATH visibility issue
dpkg -L lynis | grep bin       # confirms actual binary location: /usr/sbin/lynis
sudo /usr/sbin/lynis show version   # confirms the tool itself works via full path
```

**Root cause:** Lynis installs to `/usr/sbin/`, which is in root's PATH but excluded from a regular user's PATH by default on Debian.

**Resolution:** run Lynis with `sudo` (which resolves `/usr/sbin` correctly).

**Findings from the full audit:**
1. **Missing security repository** (`PKGS-7388`) — manually verified `/etc/apt/sources.list.d/debian.sources` and confirmed the `trixie-security` repo was correctly configured using Debian's newer DEB822 format, which this specific Lynis check didn't yet recognize. **Determined to be a false positive; no action needed.**
2. **Vulnerable packages found** (`PKGS-7392`) — patched:
   ```bash
   sudo apt update
   sudo apt upgrade -y
   sudo apt dist-upgrade -y
   ```

**Suggestions acted on:**
- **HRDN-7230** (missing malware scanner) → installed rkhunter:
  ```bash
  sudo apt install rkhunter -y
  sudo rkhunter --update
  sudo rkhunter --propupd
  ```
- **DEB-0880** (missing brute-force protection) → installed fail2ban:
  ```bash
  sudo apt install fail2ban -y
  sudo systemctl enable fail2ban
  sudo systemctl start fail2ban
  ```

**Result: hardening index improved from 69 to 70.**

---

## Phase 6 — Application Fix + Automation

**Apache directory listing vulnerability:**

Found: `Options Indexes FollowSymLinks` in the `/var/www` directory block — allowing anyone to browse raw directory contents with no index page present.

```bash
# Locate the config
sudo grep -n "Directory /var/www" /etc/apache2/apache2.conf

# Apply the fix
sudo sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/apache2/apache2.conf

# Verify the change
sudo grep -A 4 "Directory /var/www" /etc/apache2/apache2.conf

# Restart Apache
sudo systemctl restart apache2
```

**Verification:** created a test folder and confirmed the browser could no longer list its contents.

**Automation:** packaged all 15 CIS controls from Phase 4 into a single reusable script, `cis_harden.sh`, so the entire hardening checklist can be reapplied to future instances in one command instead of manually repeating 15 steps.

---

## OWASP Top 10 for Cloud Security — Mapping

| # | OWASP Cloud Risk | Related CWE(s) | Addressed in this project? |
|---|---|---|---|
| 1 | Insecure Identities, Credentials, Secrets, and Access Management | CWE-798, CWE-287, CWE-306, CWE-522, CWE-259, CWE-269 | ✅ Least-privilege IAM policy, SSH key-only auth |
| 2 | Insecure Interfaces and APIs | CWE-20, CWE-79, CWE-89, CWE-352, CWE-918 | ❌ Not directly tested |
| 3 | Misconfiguration and Inadequate Change Control | CWE-16, CWE-276, CWE-732, CWE-250 | ✅ Apache directory listing fix |
| 4 | Lack of Cloud Security Architecture and Strategy | CWE-657, CWE-668, CWE-284 | ✅ CIS Benchmark framework applied |
| 5 | Insecure Software Development | CWE-20, CWE-79, CWE-89, CWE-502, CWE-94 | ❌ Not directly tested |
| 6 | Unsecured Third-Party Resources | CWE-829, CWE-1104, CWE-1357 | ❌ Not directly tested |
| 7 | System Vulnerabilities | CWE-1104, CWE-119, CWE-787, CWE-416 | ✅ Lynis scan, patching, rkhunter/fail2ban |
| 8 | Accidental Cloud Data Disclosure | CWE-200, CWE-201, CWE-359, CWE-312 | ❌ Not directly tested |
| 9 | Misconfiguration of Cloud Services | CWE-16, CWE-732, CWE-284, CWE-276 | ✅ Partially — one Apache misconfiguration found and fixed |
| 10 | Insufficient Cloud Security Monitoring and Incident Response | CWE-778, CWE-223, CWE-117 | ✅ CloudWatch + CloudTrail configured and verified |

---

## Key Findings

1. **A written policy isn't proof it works.** The IAM least-privilege policy was only confirmed effective by testing it against an out-of-scope resource and capturing the resulting Access Denied via CloudTrail.
2. **Not every scanner finding is a real issue.** Lynis flagged a missing security repository that turned out to be a false positive — Debian's newer DEB822 source format wasn't recognized by that specific check. Verifying manually before "fixing" it avoided an unnecessary change.
3. **Account-level blockers are worth documenting honestly.** GuardDuty couldn't be enabled due to a pending AWS account verification step — noted as a known limitation rather than skipped silently.
4. **Manual hardening doesn't scale.** Packaging the 15 CIS controls into `cis_harden.sh` turns a one-time manual exercise into a reusable, repeatable process.

---

## Repository Contents

- `/docs` — full lab report and command reference
- `/scripts` — `cis_harden.sh` automation script
- `/policies` — IAM policy JSON, fail2ban and CIS-related configs

---

## About

Built as hands-on portfolio work for SOC Analyst, IAM Analyst, and Cloud Security roles.

**Connect:** [LinkedIn](https://www.linkedin.com/in/vigneshgk9securityanalyst/)
