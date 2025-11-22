$action = New-ScheduledTaskAction `
    -Execute "C:\Windows\System32\conhost.exe" `
    -Argument "--headless kanata --cfg C:\Users\bwilliams\.config\kanata\kanata.kbd"

$trigger = New-ScheduledTaskTrigger -AtLogOn

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatters `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName "Kanata" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Kanata keyboard remapper"

Write-Host "Kanata task created successfully"
