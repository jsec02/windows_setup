# ================================================================================
# =                                  SETUP.PS1                                   =
# ================================================================================

function Disable-UCPD {
    # UCPD Service blocks TaskbarDa registry key creation, forcing Widgets to be active
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\UCPD' -Name 'Start' -Value 4
}

function Set-TaskbarSettings {
    $TaskbarKeys = @(
        'TaskbarAl',
        'ShowTaskViewButton'
    )

    foreach ($Key in $TaskbarKeys) {
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name $Key -Value 0
    }
}

function Set-DarkMode {
    $ThemeKeys = @(
        "AppsUseLightTheme",
        "SystemUsesLightTheme"
    )

    foreach ($Key in $ThemeKeys) {
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name $Key -Value 0
    }
}

function Set-KeyboardSettings {
    $KeyboardSettings = @{
        'KeyboardDelay' = 0
        'KeyboardSpeed' = 31
    }

    $KeyboardSettings.GetEnumerator() | ForEach-Object {
        Set-ItemProperty -Path 'HKCU:\Control Panel\Keyboard' -Name $_.Key -Value $_.Value
    }
}

function Install-Programs {
    $Ids = @(
        '7zip.7zip',
        'Atuinsh.Atuin',
        'Deskflow.Deskflow',
        'Discord.Discord',
        'Fastfetch-cli.Fastfetch',
        'Git.Git',
        'Microsoft.PowerToys',
        'Microsoft.Powershell', 
        'Microsoft.WSL',
        'Mozilla.Firefox'
        'Neovim.Neovim',
        'Python.Python.3.14',
        'RazerInc.RazerInstaller.Synapse4',
        'Valve.Steam',
        'VideoLAN.VLC',
        'WiresharkFoundation.Wireshark',
        'Zellij.Zellij',
        'dbrgn.tealdeer',
        'jeffvli.Feishin',
        'qBittorrent.qBittorrent',
        'sxyazi.yazi',
        'yt-dlp.yt-dlp'
    )

    & winget install $Ids
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
        -Name 'Setup' `
        -Value 'powershell.exe -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/jsec02/windows_setup/master/setup.ps1 | Invoke-Expression"'
}

function Set-State {
    New-Item -Path 'HKCU:\Software\Setup'
}

function Confirm-Restart {
    Write-Host 'PreRestart stage has completed. PostRestart will automatically run after restart.'

    Restart-Computer -Confirm
}

function Disable-TaskbarWidgets {
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarDa' -PropertyType DWord -Value 0
}

function Install-WSL {
    wsl --install archlinux
}

function Remove-State {
    Remove-Item -Path 'HKCU:\Software\Setup'
}

function Start-Setup {
    Set-ExecutionPolicy RemoteSigned
    Disable-UCPD
    Set-TaskbarSettings
    Set-DarkMode
    Set-KeyboardSettings
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
}

function Main {
    if (Test-Path 'HKCU:\Software\Setup') {
        Resume-Setup
    } else {
        Start-Setup
    }
}

Main
