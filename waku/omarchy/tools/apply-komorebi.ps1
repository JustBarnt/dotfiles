# Applies this port's komorebi settings: backs up the current komorebi.json, writes the one from this
# port's komorebi folder with the border colours of the current Omarchy theme, and sends the border,
# gap and workspace-name settings to the running komorebi (komorebic reload-configuration does not read
# komorebi.json; the file is read when komorebi starts). Run it from anywhere, and again after a theme
# change; -WhatIf shows what it would do, -KeepColours copies the file as shipped (Catppuccin).
[CmdletBinding(SupportsShouldProcess)]
param([string]$KomorebiHome = (Join-Path $env:USERPROFILE '.config\komorebi'), [switch]$KeepColours)
$ErrorActionPreference = 'Stop'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$name = Split-Path $port -Leaf
$source = Join-Path $port 'komorebi\komorebi.json'
$target = Join-Path $KomorebiHome 'komorebi.json'
$utf8 = New-Object Text.UTF8Encoding $false
$text = [IO.File]::ReadAllText($source)

if (-not $KeepColours) {
  # The theme the shell is on: theme-apply.ps1 copies its colors.toml here.
  $colorsPath = Join-Path $port 'state\home\.local\state\omarchy\current\theme\colors.toml'
  if (Test-Path -LiteralPath $colorsPath) {
    $c = @{}
    foreach ($line in Get-Content -LiteralPath $colorsPath) {
      if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*"(#[0-9a-fA-F]{6})"') { $c[$Matches[1]] = $Matches[2] }
    }
    $map = [ordered]@{ single = 'accent'; stack = 'accent'; monocle = 'accent'; floating = 'yellow'; unfocused = 'muted'; unfocused_locked = 'orange' }
    foreach ($key in $map.Keys) {
      $hex = $c[$map[$key]]
      if ($hex) { $text = [regex]::Replace($text, '("' + $key + '"\s*:\s*")#[0-9a-fA-F]{6}(")', { param($m) $m.Groups[1].Value + $hex + $m.Groups[2].Value }) }
    }
  } else {
    Write-Warning "no theme colours at $colorsPath; using the shipped ones"
  }
}

New-Item -ItemType Directory -Force -Path $KomorebiHome | Out-Null
if ((Test-Path -LiteralPath $target) -and ([IO.File]::ReadAllText($target) -ne $text)) {   # no backup of an identical file
  $backup = "$target.bak-before-$name-$(Get-Date -Format yyyyMMdd-HHmmss)"
  if ($PSCmdlet.ShouldProcess($target, "back up to $backup")) { Copy-Item -LiteralPath $target -Destination $backup }
}
if ($PSCmdlet.ShouldProcess($target, "write the $name settings")) {
  [IO.File]::WriteAllText($target, $text, $utf8)
  # komorebic reload-configuration only reloads the legacy .ahk/.ps1 setups, not komorebi.json, which is
  # read when komorebi starts. So the settings this port is about are also sent to the running komorebi.
  $cfg = $text | ConvertFrom-Json
  if ($cfg.border_width -ne $null) { & komorebic.exe border-width $cfg.border_width }
  if ($cfg.border_offset -ne $null) { & komorebic.exe border-offset "--" $cfg.border_offset }
  if ($cfg.border_style) { & komorebic.exe border-style $cfg.border_style.ToLower() }
  foreach ($kind in 'single', 'stack', 'monocle', 'unfocused', 'floating') {
    $hex = $cfg.border_colours.$kind
    if ($hex -match '^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$') {
      & komorebic.exe border-colour ([Convert]::ToInt32($Matches[1], 16)) ([Convert]::ToInt32($Matches[2], 16)) ([Convert]::ToInt32($Matches[3], 16)) --window-kind $kind
    }
  }
  $hex = $cfg.border_colours.unfocused_locked
  if ($hex -match '^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$') {
    & komorebic.exe border-colour ([Convert]::ToInt32($Matches[1], 16)) ([Convert]::ToInt32($Matches[2], 16)) ([Convert]::ToInt32($Matches[3], 16)) --window-kind unfocused-locked
  }
  # gaps and workspace names of the first monitor's workspaces
  $workspaces = @($cfg.monitors[0].workspaces)
  for ($i = 0; $i -lt $workspaces.Count; $i++) {
    & komorebic.exe workspace-padding 0 $i $cfg.default_workspace_padding
    & komorebic.exe container-padding 0 $i $cfg.default_container_padding
    if ($workspaces[$i].name) { & komorebic.exe workspace-name 0 $i $workspaces[$i].name }
  }
}
