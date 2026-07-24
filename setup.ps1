# ================================================================================
# =                                    SETUP                                     =
# ================================================================================

function Invoke-MicrosoftActivationScripts {
    # https://github.com/massgravel/microsoft-activation-scripts
    Invoke-WebRequest -Uri 'https://get.activated.win' | Invoke-Expression
}

function Invoke-Win11Debloat {
    # https://github.com/raphire/win11debloat
    & ([scriptblock]::Create((Invoke-RestMethod "https://debloat.raphi.re/")))
}

function Uninstall-OneDrive {
    if (Test-Path "$env:systemroot\System32\OneDriveSetup.exe") {
        & "$env:systemroot\System32\OneDriveSetup.exe" /uninstall
    }

    if (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
        & "$env:systemroot\SysWOW64\OneDriveSetup.exe" /uninstall
    }
}

function Disable-UCPD {
    # UCPD Service blocks TaskbarDa registry key creation, forcing Widgets to be active
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\UCPD' -Name 'Start' -Value 4
}

function Set-FileExplorerSettings {
    $Mapping = @{
        'Hidden'      = 1
        'HideFileExt' = 0
    }

    $Mapping.GetEnumerator() | ForEach-Object {
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name $_.Key -Value $_.Value
    }
}

function Set-TaskbarSettings {
    $Keys = @(
        'TaskbarAl',
        'ShowTaskViewButton'
    )

    foreach ($Key in $Keys) {
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name $Key -Value 0
    }
}

function Set-DarkMode {
    $Keys = @(
        'AppsUseLightTheme',
        'SystemUsesLightTheme'
    )

    foreach ($Key in $Keys) {
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name $Key -Value 0
    }
}

function Set-KeyboardSettings {
    $Mapping = @{
        'KeyboardDelay' = 0
        'KeyboardSpeed' = 31
    }

    $Mapping.GetEnumerator() | ForEach-Object {
        Set-ItemProperty -Path 'HKCU:\Control Panel\Keyboard' -Name $_.Key -Value $_.Value
    }
}

function Disable-EnhancedPointerPrecision {
    $Keys = @(
        'MouseSpeed',
        'MouseThreshold1'
        'MouseThreshold2'
    )

    foreach ($Key in $Keys) {
        Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name $Key -Value 0
    }
}

function Set-Background {
    $Mapping = @(
        @{ 'Path' = 'HKCU:\Control Panel\Colors';  'Name' = 'Background';     'Value' = '0 0 0' }
        @{ 'Path' = 'HKCU:\Control Panel\Desktop'; 'Name' = 'Wallpaper';      'Value' = '' }
        @{ 'Path' = 'HKCU:\Control Panel\Desktop'; 'Name' = 'WallpaperStyle'; 'Value' = '10' }
    )

    $Mapping | ForEach-Object {
        Set-ItemProperty -Path $_.Path -Name $_.Name -Value $_.Value
    }
}

function Clear-Desktop {
    Get-ChildItem 'C:\Users\Public\Desktop' -Force |
        Where-Object {$_.Name -ne 'desktop.ini' } |
        Remove-Item -Force
}

function Initialize-WinGetClient {
    Install-Module Microsoft.WinGet.Client -Scope CurrentUser
    Import-Module Microsoft.WinGet.Client
}

function Install-WinGetPackageWithRetry {
    param (
        [Parameter(Mandatory)]
        [string]$Id,

        [string]$Mode,

        [string]$Version
    )

    # For some reason, both winget.exe and Install-WinGetPackage sometimes
    # fail to install programs in elevated contexts

    $Parameters = @{ Id = $Id }

    if ($Mode) {
        $Parameters.Mode = $Mode
    }

    if ($Version) {
        $Parameters.Version = $Version
    }

    do {
        Install-WinGetPackage @Parameters | Tee-Object -Variable Result
    } while ($Result.Status -ne 'Ok')
}

function Initialize-Git {
    Install-WinGetPackageWithRetry -Id Git.Git
}

function Initialize-Python {
    Install-WinGetPackageWithRetry -Id Python.Python.3.14
}

function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
}

function Initialize-Parsers {
    git clone https://github.com/jsec02/parsers.git
}

function Initialize-Inventory {
    pip3 install pyyaml --break-system-packages

    git clone https://github.com/jsec02/windows_inventory.git

    Rename-Item -Path windows_inventory -NewName inventory
}

function Install-WingetPackages {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Hostname
    )

    $Ids = (python "$HOME\parsers\inventory.py" packages $Hostname winget) -split ' '

    if ($LASTEXITCODE -ne 0) {
        throw "Inventory lookup failed"
    }

    # Hardcode games and gaming platforms to use their interactive installers
    # in order to specify installation location to the isolated Games (D:) drive
    $InteractiveIds = @(
        'Valve.Steam',
        'RiotGames.LeagueOfLegends.NA'
    )

    foreach ($Id in $Ids) {
        if ($InteractiveIds -contains $Id) {
            Install-WinGetPackageWithRetry -Id $Id -Mode Interactive
        } else {
            Install-WinGetPackageWithRetry -Id $Id
        }
    }
}

function Install-PipPackages {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Hostname
    )

    $Packages = python "$HOME\parsers\inventory.py" packages $Hostname pip3

    pip3 install $Packages --break-system-packages
}

function Install-Packages {
    $Hostname = $Env:COMPUTERNAME.ToLowerInvariant()

    Install-WingetPackages -Hostname $Hostname
    Install-PipPackages -Hostname $Hostname
}

function Initialize-Restic {
    # Pin restic to 0.16.4 because it's the latest version avaliable on winget before
    # https://github.com/restic/restic/pull/4708
    # This commit introduces a mechanism which backs up SecurityDescriptors of files
    # This is problematic during restores on new machines because SID's of old local accounts
    # will never match with that of new local accounts
    # There exists a remark on the aforementioned commit mentioning that a separate PR can address
    # the valid use case where one does not want to backup/restore SecurityDescriptors
    # No such PR has been merged yet
    # Further dicussion on this topic can be seen here
    # https://github.com/restic/restic/issues/5257

    # Should this problem get resolved, we can delete this separate Initialize-Restic function,
    # add restic.restic to inventory.yaml, and remove the version parameter from the
    # Install-WinGetPackageWithRetry wrapper
    Install-WinGetPackageWithRetry -Id restic.restic -Version 0.16.4
}

function Read-Secrets {
    while ($true) {
        $Env:RESTIC_REPOSITORY = Read-Host -Prompt 'Enter Restic repository'
        $Env:RESTIC_PASSWORD = Read-Host -Prompt 'Enter Restic password'
        $Env:B2_ACCOUNT_ID = Read-Host -Prompt 'Enter B2 account ID'
        $Env:B2_ACCOUNT_KEY = Read-Host -Prompt 'Enter B2 account key'

        restic snapshots 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            return
        }

        Write-Host 'Invalid credentials'
    }
}

function Restore-FromRestic {
    $Output = python "$HOME\parsers\inventory.py" tags windows

    foreach ($Line in $Output) {
        # Ignore $Parts[0], the sudo flag is not needed on windows
        $Parts = $Line -split ' '
        $Tag = $Parts[1]

        restic restore latest:/C --host windows --tag $Tag --target C:\
    }
}

function Invoke-Linksync {
    "$HOME\powershell\scripts\linksync.ps1"
}

function Initialize-TLDR {
    tldr --update
}

function Set-RunOnce {
    New-ItemProperty `
        -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' `
        -Name 'WindowsSetup' `
        -Value 'powershell.exe -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/jsec02/windows_setup/master/setup.ps1 | Invoke-Expression"'
}

function Set-State {
    param(
        [Parameter(Mandatory)]
        [int]$Stage
    )

    $Path = 'HKLM:\Software\Windows Setup'

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path
    }

    Set-ItemProperty -Path $Path -Name 'Stage' -Value $Stage
}

function Disable-TaskbarWidgets {
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarDa' -PropertyType DWord -Value 0
}

function Disable-StartupApps {
    $Keys = @(
        'Discord',
        'Steam'
    )

    foreach ($Key in $Keys) {
        Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $Key
    }
}

function Enable-HyperV {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
}

function Enable-WSL {
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
}

function Install-WSL {
    wsl --install archlinux
}

function Initialize-Network {
    # Create new VM switch bound to the "Wi-Fi" network adapter
    # This along with networkingMode=bridged and vmSwitch=WSL in $HOME\.wslconfig
    # are required for bridged mode to function properly
    New-VMSwitch -Name "WSL" -NetAdapterName "Wi-Fi" -AllowManagementOS $true

    # Upload speed is throttled when the network adapter is in bridged mode
    # The fix is to disable Large Send Offload V2
    # https://learn.microsoft.com/en-us/answers/questions/4182017/windows-upload-throttled-when-network-adapter-is-i
    Disable-NetAdapterLso -Name "Network Bridge"

    # Configure IP address and default gateway
    New-NetIPAddress -InterfaceAlias "vEthernet (WSL)" -IPAddress 10.0.0.10 -PrefixLength 24 -DefaultGateway 10.0.0.1

    # Configure custom DNS with cloudflare fallback
    Set-DnsClientServerAddress -InterfaceAlias "vEthernet (WSL)" -ServerAddresses ("10.0.0.30","2607:fea8:28cf:3700:2ecf:67ff:fe13:f06","1.1.1.1","2606:4700:4700::1111")
}

function Remove-State {
    Remove-Item -Path 'HKLM:\Software\Windows Setup'
}

function Start-StageOne {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
    Invoke-MicrosoftActivationScripts
    Invoke-Win11Debloat
    Uninstall-OneDrive
    Disable-UCPD
    Set-FileExplorerSettings
    Set-TaskbarSettings
    Set-DarkMode
    Set-KeyboardSettings
    Disable-EnhancedPointerPrecision
    Set-Background
    Clear-Desktop
    Initialize-WinGetClient
    Initialize-Git
    Initialize-Python
    Update-Path
    Initialize-Parsers
    Initialize-Inventory
    Install-Packages
    Initialize-Restic
    Update-Path
    Read-Secrets
    Restore-FromRestic
    Invoke-Linksync
    Update-Help -ErrorAction SilentlyContinue
    Initialize-TLDR
    Set-RunOnce
    Set-State -Stage 2
    Restart-Computer -Confirm
}

function Start-StageTwo {
    Disable-TaskbarWidgets
    Disable-StartupApps
    Enable-HyperV
    Enable-WSL
    Set-RunOnce
    Set-State -Stage 3
    Restart-Computer -Confirm
}

function Start-StageThree {
    Install-WSL
    Initialize-Network
    Remove-State
}

function Invoke-Main {
    $StatePath = 'HKLM:\Software\Windows Setup'

    if (Test-Path $StatePath) {
        $Stage = (Get-ItemProperty -Path $StatePath).Stage
        if ($Stage -eq 2) {
            Start-StageTwo
        } elseif ($Stage -eq 3) {
            Start-StageThree
        }
    } else {
        Start-StageOne
    }
}

Invoke-Main
