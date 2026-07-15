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
    Set-ItemProperty `
        -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' `
        -Name 'Setup' `
        -Value 'powershell.exe -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/jsec02/windows_setup/master/setup.ps1 | Invoke-Expression"'
}

function Read-RestartConfirmation {
    Write-Host 'PreRestart stage has completed. PostRestart will automatically run after restart.'
    $RestartConfirmed = (Read-Host 'Would you like to restart now? (y/n)').Trim().ToLower()

    if ($RestartConfirmed -eq 'y') {
        Write-Host 'Restarting now...'
        Start-Sleep -Seconds 2
        Restart-Computer
    }
}

function Disable-TaskbarWidgets {
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarDa' -PropertyType DWord -Value 0
}

function Install-WSL {
    wsl --install archlinux
}

function Invoke-PreRestart {
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
    Read-RestartConfirmation
}

function Invoke-PostRestart {
    Disable-TaskbarWidgets
    Install-WSL
}

function Main {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('PreRestart', 'PostRestart')]
        [string]$Stage
    )

    & "Invoke-$Stage"
}

Main
