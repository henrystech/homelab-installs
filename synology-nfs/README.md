# Synology NFS Install Script (SSH Method)

This guide explains how to securely download and run the
`install_synology_nfs.sh` script over SSH with administrator privileges.

------------------------------------------------------------------------

# 🔒 Recommended Method (Best Practice Over SSH)

Instead of piping a remote script directly into `bash`, download it
first.\
This allows you to inspect the script before executing it.

## Step 1 --- Download the Script

``` bash
curl -fsSL -o install_synology_nfs.sh https://gitea.henrystech.dev/l0rdmusash1/bash-installs/src/branch/main/synology-nfs/install_synology_nfs.sh sudo | bash
```

## Step 2 --- Make It Executable

``` bash
chmod +x install_synology_nfs.sh
```

## Step 3 --- Run as Administrator

``` bash
sudo ./install_synology_nfs.sh
```

You will be prompted for your password if required.

------------------------------------------------------------------------

# 🚀 Quick Method (Direct Execution)

If you understand the risks and trust the source, you may execute
directly:

``` bash
curl -fsSL https://gitea.henrystech.dev/l0rdmusash1/bash-installs/raw/main/testscrips/install_synology_nfs.sh | sudo bash
```

⚠️ This method does not allow inspection before execution.

------------------------------------------------------------------------

# 🔎 Check Your Current User (Optional)

To verify whether you are already logged in as root:

``` bash
whoami
```

If the output is:

    root

You may omit `sudo` when running the script.

------------------------------------------------------------------------

# 🔧 Optional: Enable Passwordless sudo (Advanced / Lab Use Only)

If this system is private and secure, and you want to avoid password
prompts:

1.  Edit the sudoers file safely:

``` bash
sudo visudo
```

2.  Add the following line at the bottom:

```{=html}
<!-- -->
```
    yourusername ALL=(ALL) NOPASSWD: ALL

Save and exit.

⚠️ Only enable passwordless sudo on trusted systems.

------------------------------------------------------------------------

# ✅ Summary

  Scenario             Command
  -------------------- -----------------------------------------
  Safe & Recommended   Download → Inspect → `sudo ./script.sh`
  Quick Execution      `curl ... | sudo bash`
  Already root         `curl ... | bash`

------------------------------------------------------------------------

# Security Reminder

Always verify remote scripts before executing them with administrative
privileges.\
Running unverified scripts as root can compromise your system.
