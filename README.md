### windows_setup

### Bypass Microsoft Account Requirement

To bypass the Microsoft account requirement during initial Windows 11 setup, disconnect from the internet and press `Shift + F10` to open Command Prompt, then enter `start ms-cxh:localonly`.

### Usage

This script assumes a user account is setup and logged in. Additionally, you can run this script with elevated privileges to avoid User Account Control pop-ups. 

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/jsec02/windows_setup/master/setup.ps1 | Invoke-Expression
```

Run this command after reboot to complete WSL setup:

```powershell
wsl --install archlinux
```
