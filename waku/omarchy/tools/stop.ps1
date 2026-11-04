# Stops every running waku through the shared launcher, stop.ps1 in the repo root. Kept so the old path works.
param([switch]$DryRun)
& (Join-Path $PSScriptRoot '..\..\stop.ps1') -DryRun:$DryRun
