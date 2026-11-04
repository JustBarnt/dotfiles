# Applies an Omarchy theme: renders the files the shell reads (colors.toml, shell.toml, theme.name) into
# the port's home. The shell watches them, so a running shell changes colours at once.
#   .\tools\theme-apply.ps1 tokyo-night
#   .\tools\theme-apply.ps1 -Prepare           copies every theme's preview for the picker, no theme change
# Works in Windows PowerShell 5.1 (the shell runs it) and PowerShell 7.
param([string]$Theme = '', [switch]$Prepare)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$home_ = Join-Path $root 'state\home'
$current = Join-Path $home_ '.local\state\omarchy\current'
$themeOut = Join-Path $current 'theme'
$utf8 = New-Object Text.UTF8Encoding $false
New-Item -ItemType Directory -Force $themeOut | Out-Null

# The picker lists <name>.png files; the theme's name is the file name.
$previews = Join-Path $home_ '.cache\omarchy\theme-selector\previews'
New-Item -ItemType Directory -Force $previews | Out-Null
foreach ($d in Get-ChildItem (Join-Path $root 'themes') -Directory) {
  $src = Join-Path $d.FullName 'preview.png'
  $dst = Join-Path $previews ($d.Name + '.png')
  if ((Test-Path $src) -and -not (Test-Path $dst)) { Copy-Item $src $dst }
}
if ($Prepare -and -not $Theme) { return }

# theme.name holds the folder name (tokyo-night): the picker matches it against its rows
$idFile = Join-Path $current 'theme.name'
if (-not $Theme) { $Theme = if (Test-Path $idFile) { (Get-Content $idFile -Raw).Trim() } else { 'catppuccin' } }
$colorsPath = Join-Path $root "themes\$Theme\colors.toml"
if (-not (Test-Path $colorsPath)) { throw "no such theme: $Theme" }

$colors = @{}
foreach ($line in Get-Content $colorsPath) {
  if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*"([^"]*)"') { $colors[$Matches[1]] = $Matches[2] }
}

function Resolve-Color([string]$name) { if ($colors.ContainsKey($name)) { $colors[$name] } else { $name } }

function Mix([string]$a, [string]$b, [string]$pct) {
  $p = [double]($pct.TrimEnd('%')) / 100.0
  $ca = (Resolve-Color $a).TrimStart('#'); $cb = (Resolve-Color $b).TrimStart('#')
  $out = '#'
  foreach ($i in 0, 2, 4) {
    $x = [Convert]::ToInt32($ca.Substring($i, 2), 16); $y = [Convert]::ToInt32($cb.Substring($i, 2), 16)
    $out += ('{0:x2}' -f [int][Math]::Round($x * $p + $y * (1 - $p)))
  }
  $out
}

$template = [IO.File]::ReadAllText((Join-Path $root 'default\themed\shell.toml.tpl'))
$text = [regex]::Replace($template, '\{\{\s*([^}]*?)\s*\}\}', {
  param($m)
  $parts = $m.Groups[1].Value -split '\s+'
  switch ($parts[0]) {
    'mix' { Mix $parts[1] $parts[2] $parts[3] }
    # the theme's Hyprland gradient has no Windows meaning: the first colour stands in for it
    'shell_gradient' { Resolve-Color $parts[2] }
    default { Resolve-Color $parts[0] }
  }
})
[IO.File]::WriteAllText((Join-Path $themeOut 'shell.toml'), ($text -replace "`r`n", "`n"), $utf8)
Copy-Item $colorsPath (Join-Path $themeOut 'colors.toml') -Force

[IO.File]::WriteAllText($idFile, $Theme + "`n", $utf8)
Write-Host "theme $Theme"
