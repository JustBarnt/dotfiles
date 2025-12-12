$env:TERM = "xterm-256color"
$env:PSMODULEPATH += ";$ENV:USERPROFILE\.config\PowerShell\modules"

Import-Module GithubReleases

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
$jiracreds = New-Object System.Management.Automation.PSCredential($ENV:JIRA_USER, (ConvertTo-SecureString $ENV:JIRA_TOKEN -AsPlainText -Force)) 

# enable starship
Invoke-Expression (&starship init powershell)

Set-Alias vim nvim
