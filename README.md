### windows_setup

### Bypass Microsoft Account Requirement

To bypass the Microsoft account requirement during initial Windows 11 setup, press `Shift + F10` to open Command Prompt, then enter `start ms-cxh:localonly`.

### Usage

This script must be run as administrator and assumes a user account is setup, logged in, and in the home directory.

This is a three stage script, requiring two restarts. You will be prompted when it's time to restart.

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/jsec02/windows_setup/master/setup.ps1 | Invoke-Expression
```

<!-- CODE_STATISTICS_START -->

### Code Statistics

```
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
PowerShell                       1             94             46            321
Markdown                         1             13              4             27
-------------------------------------------------------------------------------
SUM:                             2            107             50            348
-------------------------------------------------------------------------------
```
<!-- CODE_STATISTICS_END -->

<!-- PROJECT_STRUCTURE_START -->

### Project Structure

```
windows_setup
├── README.md
└── setup.ps1

1 directory, 2 files
```
<!-- PROJECT_STRUCTURE_END -->
