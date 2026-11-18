$env:TERM = "xterm-256color"
$env:PSMODULEPATH += ";$ENV:USERPROFILE\.config\PowerShell\modules"

oh-my-posh init pwsh | Invoke-Expression

Set-Alias vim nvim
