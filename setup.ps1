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

function Read-RestartConfirmation {
    Write-Host "Windows setup has completed. Registry changes require a restart."
    $RestartConfirmed = (Read-Host "Would you like to restart now? (y/n)").Trim().ToLower()

    if ($RestartConfirmed -eq "y") {
        Write-Host "Restarting now..."
        Start-Sleep -Seconds 2
        Restart-Computer
    }
}

function Main {
    Set-KeyboardSettings
    Read-RestartConfirmation
}

Main
