#!/usr/bin/env pwsh

# Abort on any error
$ErrorActionPreference = 'Stop'

# --- Configuration ---
$defaultConfig = 'default'
$configSuffix  = '.conf.yaml'
$dotbotDir     = 'dotbot'
$dotbotBin     = 'bin/dotbot'

# --- Determine script directory and switch into it ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $scriptDir

# --- Ensure submodule is initialized & up‑to‑date ---
git submodule update --init --recursive $dotbotDir

# --- Build list of configs: 'default' plus any passed arguments ---
$configs = @($defaultConfig) + $args

# --- Path to the dotbot executable/script ---
$dotbotBinPath = Join-Path -Path (Join-Path $scriptDir $dotbotDir) -ChildPath $dotbotBin

# --- Invoke dotbot for each config ---
foreach ($conf in $configs) {
    & $dotbotBinPath -d $scriptDir -c "$conf$configSuffix"
}
