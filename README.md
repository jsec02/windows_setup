### windows_setup

### Bypass Microsoft Account Requirement

To bypass the Microsoft account requirement during initial Windows 11 setup, press `Shift + F10` to open Command Prompt, then enter `start ms-cxh:localonly`.

### Usage

This script must be run as administrator and assumes a user account is setup and logged in.

This is a three stage script, requiring two restarts. You will be prompted when it's time to restart.

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/jsec02/windows_setup/master/setup.ps1 | Invoke-Expression
```
