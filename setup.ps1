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

function Enable-HyperV {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
}

function Install-Programs {
    $Ids = (python "$HOME/parsers/inventory.py" packages windows winget) -split ' '

    $InteractiveIds = @(
        'Valve.Steam',
        'RiotGames.LeagueOfLegends.NA'
    )

    # Microsoft.WinGet.Client seems to be more realiable than shelling out to winget.exe in elevated contexts
    Install-Module Microsoft.WinGet.Client -Scope CurrentUser
    Import-Module Microsoft.WinGet.Client

    foreach ($Id in $Ids) {
        if ($InteractiveIds -contains $Id) {
            Install-WinGetPackage -Id $Id -Mode Interactive
        } else {
            Install-WinGetPackage -Id $Id
        }
    }
}

function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
}

function Enable-WSL {
    wsl --install --no-distribution
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
    New-Item -Path 'HKLM:\Software\WindowsSetup'
}

function Confirm-Restart {
    Write-Host 'PreRestart stage has completed. PostRestart will automatically run after restart.'

    Restart-Computer -Confirm
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

function Install-WSL {
    wsl --install archlinux
}

function Remove-State {
    Remove-Item -Path 'HKLM:\Software\WindowsSetup'
}

function Start-Setup {
    Set-ExecutionPolicy RemoteSigned
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
    Enable-HyperV
    Install-Programs
    Update-Path
    Enable-WSL
    Initialize-TLDR
    Set-RunOnce
    Set-State
    Confirm-Restart
}

function Resume-Setup {
    Disable-TaskbarWidgets
    Install-WSL
    Remove-State
}

function Main {
    if (Test-Path 'HKLM:\Software\WindowsSetup') {
        Resume-Setup
    } else {
        Start-Setup
    }
}

Main
