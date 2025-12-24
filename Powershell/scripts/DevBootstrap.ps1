# Install the following applications via winget
# Powershell Core (AKA Powershell)
# SQLServer Developer
# SQL Server Managment Studio
# ODBC Driver 17 and 18
# Git
# Node Version Manager (NVM)- Should also bootstrap with latest LTS Node Version
# Notepad++
# LLVM
# .NET SDK (7-10?)
# PHP
# PhpVersion Manager (Powershell Module)
# TortoiseSVN
# SVN CLI
# SysinternalsSuite

# NOTE: I would like to be able to install Visual Studio Community Edition: but I need to find if there is a way 
#       to install the specific items we need with the installation as well.
#       E.G. I may be able to use winget install Microsoft.VisualStudio.2026.Professional -i

[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter]
  [string] $CommSysDir = "CommSys",

  # Install Rust Related Packages
  [Parameter()]
  [Switch] $Rust,
  
  # Install GoLang Related Packages
  [Parameter()]
  [Switch] $GoLang,

  # Install Python Related Packages
  [Parameter()]
  [Switch] $Python,

  # Install Zed Editor
  [Parameter()]
  [Switch] $Zed,

  # Install VSCode Editor
  [Parameter()]
  [Switch] $VSCode,

  # Install Neovim
  [Parameter()]
  [Switch] $Neovim
)

function ConvertTo-SentenceCase {
  [CmdletBinding()]
  param(
    [Parameter]
    [string] $InputSring
  )
  
  if ([string]::IsNullOrEmpty($InputSring)) {
    return $InputString
  }

  return $InputString.Substring(0,1).ToUpper() + $InputSring.Substring(1).ToLower()
}

function Get-InstallDir  {
  [CmdletBinding()]
  Param([Parameter][string] $Path)
  $InstallDir = ""
  ConvertTo-SentenceCase -InputSring $Path -OutVariable InstallPath

  $devDrive = Get-PSDrive -PSProvider FileSystem | 
              Where-Object { $_.Name -notin @('C', 'G', 'P') } |
              Select-Object -First 1.Root
  
  if ($devDrive) {
    $InstallDir = Join-Path $devDrive.Root $InstallPath
  } else {
    $InstallDir = Join-Path "C:\Dev\" $InstallPath
  }
  return $InstallDir
}

function Install-Applications {
  Write-Host "Installing applications via Winget..."
  $Apps = @(
    @{ Name = "Node Version Manager"; Id = "CoreyButler.NVMforWindows" },
    @{ Name = "Git"; Id = "Git.Git" },
    @{ Name = "Notepad++"; Id = "Notepad++.Notepad++" },
    @{ Name = "TortoiseSVN"; Id = "TortoiseSVN.TortoiseSVN" },
    @{ Name = "Microsoft ODBC Driver 18 for SQL Server"; Id = "Microsoft.msodbcsql.18" },
    @{ Name = "LLVM"; Id = "LLVM.LLVM" },
    @{ Name = "Microsoft .NET SDK 8.0"; Id = "Microsoft.DotNet.SDK.8" },
    @{ Name = "Microsoft .NET SDK 9.0"; Id = "Microsoft.DotNet.SDK.9" },
    @{ Name = "Microsoft .NET SDK 10.0"; Id = "Microsoft.DotNet.SDK.10" },
    @{ Name = "PowerShell"; Id = "Microsoft.PowerShell" },
    @{ Name = "Windows Terminal Preview"; Id = "Microsoft.WindowsTerminal.Preview" }
    @{ Name = "SQL Server 2022 Developer"; Id = "Microsoft.SQLServer.2022.Developer" }
    @{ Name = "SQL Server Management Studio"; Id = "Microsoft.SQLServerManagementStudio.22" }
  )

  foreach($app in $Apps) {
    Write-Host "`nInstalling $($app.Name)..." -ForegroundColor Cyan
    try {
      winget install --id $app.Id
      if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $($app.Name) installed successfully" -ForegroundColor Green
      } else {
        Write-Host "✗ $($app.Name) installation returned code $LASTEXITCODE" -ForegroundColor Red
      }
    } catch {
      Write-Host "✗ Error installing $($app.Name): $_" -ForegroundColor Red
    }
  }
}

function Install-OptionalApplications {
  [CmdletBinding()]
  param()

  if ($Rust.IsPresent) {
    # Install Rust
  }
}









###########################
#    START MAIN SCRIPT    #
###########################

<#
  .SYNOPSIS Bootstraps developer PC with necessary installs and commsys related applications from
          version control
#>

$InstallDir = Get-InstallDir -Path $CommSysDir

Install-OptionalApplications
