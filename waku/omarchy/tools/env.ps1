# The Omarchy port's part of start.ps1 in the repo root. Runs in the launcher's scope: $PortDir and $Dev are set,
# and $PortFlags may be assigned (extra waku arguments).
$env:HOME = Join-Path $PortDir 'state\home'        # theme files and user config live here, not in the real profile
$env:OMARCHY_PATH = $PortDir
$env:QT_FORCE_STDERR_LOGGING = '1'
# Git for Windows' bash and find first (the shell runs bash scripts), then komorebi for workspaces.
$env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH + ';C:\Program Files\komorebi\bin'
# the saved theme (Catppuccin the first time), and the previews the theme switcher lists
& (Join-Path $PortDir 'tools\theme-apply.ps1') -Prepare
& (Join-Path $PortDir 'tools\theme-apply.ps1') | Out-Null
