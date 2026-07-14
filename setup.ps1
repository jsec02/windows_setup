# ================================================================================
# =                                  SETUP.PS1                                   =
# ================================================================================

function Set-KeyboardSettings {
    $KeyboardSettings = @{
        KeyboardDelay = 0
        KeyboardSpeed = 31
    }

    $KeyboardSettings.GetEnumerator() | ForEach-Object {
        Set-ItemProperty -Path 'HKCU:\Control Panel\Keyboard' -Name $_.Key -Value $_.Value
    }
}

function Main {
    Set-KeyboardSettings
}

Main
