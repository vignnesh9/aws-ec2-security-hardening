# Apache Directory Listing Vulnerability — Findings & Fix

## What Was Found

Apache's default configuration on the project's EC2 instance included the following directive:

```
Options Indexes FollowSymLinks
```

The `Indexes` option tells Apache: if a directory is requested and no index file (e.g. `index.html`) exists inside it, display a generated listing of every file in that directory instead.

## Why This Is a Risk

Directory listing is a common but often-overlooked misconfiguration. Its risk depends entirely on what's actually stored in the web root:

- Files never meant to be public (backups, config files, `.env` files, old versions of scripts) can be exposed simply because they exist inside a directory without an index page.
- It also reveals the server's internal file structure to anyone browsing it, which can help an attacker understand what's running and plan further attacks.
- This maps directly to **OWASP Top 10 for Cloud Security — Category 3: Misconfiguration and Inadequate Change Control** (CWE-16, CWE-276, CWE-732, CWE-250).

## How It Was Confirmed

1. Located the relevant `<Directory>` block in Apache's config:
   ```bash
   sudo grep -n "Directory /var/www" /etc/apache2/apache2.conf
   ```
2. Viewed the block directly to confirm the `Indexes` option was present:
   ```bash
   sudo sed -n '169,173p' /etc/apache2/apache2.conf
   ```

## The Fix

Removed the `Indexes` option, leaving `FollowSymLinks` in place (still needed for normal site functionality):

```bash
sudo sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/apache2/apache2.conf
```

Verified the change actually saved:

```bash
sudo grep -A 4 "Directory /var/www" /etc/apache2/apache2.conf
```

Restarted Apache to apply the change:

```bash
sudo systemctl restart apache2
```

## Verifying the Fix Actually Worked

Rather than assuming the config change was sufficient, the fix was tested directly:

1. Created a test folder with no index file:
   ```bash
   sudo touch /var/www/html/testfolder/somefile.txt
   ```
2. Visited `http://<EC2-public-IP>/testfolder/` in a browser.

**Before the fix:** the browser displayed a full file listing of the folder's contents.
**After the fix:** the browser returned a Forbidden response instead of listing the folder's contents — confirming the misconfiguration was closed.

## Takeaway

A single misconfigured directive (`Options Indexes`) — left over from Apache's default configuration rather than intentionally set — was enough to expose the file structure of any directory without an index page. Finding and fixing this kind of default misconfiguration is a common, high-value task in real cloud security work, and it's easy to overlook without actively auditing configuration files rather than just checking that a service "works."
