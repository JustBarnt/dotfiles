# Install the following applications via winget
# Powershell Core (AKA Powershell) - Added a check for powershell
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
  [string] $DefaultDir = "CommSys",

  # LANGUAGES

  [Parameter(HelpMessage = "Install Rust and the Rust Toolchain")]
  [Switch] $Rust,
  [Parameter(HelpMessage = "Install Golang")]
  [Switch] $GoLang,
  [Parameter(HelpMessage = "Install Python")]
  [Switch] $Python,
  [Parameter(HelpMessage = "Install Node")]
  [Switch] $Node,
  [Parameter(HelpMessage = "Install C++ and C++ Tools")]
  [Switch] $CPlusPlus,

  # EDITORS
  
  [Parameter(HelpMessage = "Install VSCode the text editor")]
  [Switch] $VSCode
)

$OptionalApps = @{
  # Editors
  "VSCode"  = @{ Name = "Microsoft Visual Studio Code"; Id = "Microsoft.VisualStudioCode" };

  # Languages
  "CPlusPlus" = @(
    @{ Name = "CMake"; Id = "Kitware.CMake" },
    @{ Name = "LLVM"; Id = "LLVM.LLVM" },
    @{ Name = "WinLibs GCC Toolchain"; Id = "BrechtSanders.WinLibs.POSIX.MSVCRT"}
  );
  "Go"        = @{ Name = "Go Programming Language"; Id = "Golang.Go" };
  "Node"      = @(
    @{ Name   = "Node Version Manager"; Id = "CoreyButler.NVMforWindows" },
    @{ Name   = "pnpm"; Id = "pnpm.pnpm" }
  );
  "Python"    = @{ Name = "Python"; Id = "Python.Python.3.14" };
  "Rust"      = @{ Name = "Rust Development Toolchain"; Id = "Rustlang.Rustup" };
}

function Install-WithWinget {
  [CmdletBinding()] param ([string] $Id, [string] $Name)
  try {
    Write-Host "`nInstalling $($app.Name)..." -ForegroundColor Cyan
    winget install --id $Id --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
      Write-Host "✓ $($Name) installed successfully" -ForegroundColor Green
    } else {
      Write-Host "✗ $($Name) installation returned code $LASTEXITCODE" -ForegroundColor Red
    }
  } catch {
    Write-Host "✗ Error installing $($Name): $_" -ForegroundColor Red
  }
}

function ConvertTo-SentenceCase {
  [CmdletBinding()]
  param(
    [Parameter]
    [string] $InputString
  )
  
  if ([string]::IsNullOrEmpty($InputSring)) {
    return $InputString
  }

  return $InputString.Substring(0,1).ToUpper() + $InputString.Substring(1).ToLower()
}

function Get-InstallDir  {
  [CmdletBinding()] Param([Parameter][string] $Path)

  $InstallDir = ""
  $InstallPath = ConvertTo-SentenceCase -InputSring $Path

  $devDrive = Get-PSDrive -PSProvider FileSystem | 
              Where-Object { $_.Name -notin @('C', 'G', 'P') } |
              Select-Object -First 1
  
  if ($devDrive) {
    $InstallDir = Join-Path $devDrive.Root $InstallPath
  } else {
    $InstallDir = Join-Path "C:\Dev\" $InstallPath
  }
  return $InstallDir
}

function Install-Applications {
  Write-Host "`nInstalling applications via Winget..."
  $opts = @()
  $coreApps = @(
    @{ Name = "Git"; Id = "Git.Git" },
    @{ Name = "Notepad++"; Id = "Notepad++.Notepad++" },
    @{ Name = "TortoiseSVN"; Id = "TortoiseSVN.TortoiseSVN" },
    @{ Name = "Microsoft ODBC Driver 18 for SQL Server"; Id = "Microsoft.msodbcsql.18" },
    @{ Name = "Microsoft .NET SDK 8.0"; Id = "Microsoft.DotNet.SDK.8" },
    @{ Name = "Microsoft .NET SDK 9.0"; Id = "Microsoft.DotNet.SDK.9" },
    @{ Name = "Microsoft .NET SDK 10.0"; Id = "Microsoft.DotNet.SDK.10" },
    @{ Name = "Windows Terminal Preview"; Id = "Microsoft.WindowsTerminal.Preview" },
    @{ Name = "SQL Server 2022 Developer"; Id = "Microsoft.SQLServer.2022.Developer" },
    @{ Name = "SQL Server Management Studio"; Id = "Microsoft.SQLServerManagementStudio.22" }
  )

  # Add Powershell Core to the list of items to install
  if ($PSVersionTable.PSEdition -ne 'Core') {
    $coreApps += @{ Name = "PowerShell"; Id = "Microsoft.PowerShell" }
  }

  # Optional Languages
  if ($Rust)      { $opts += $OptionalApps["Rust"]      }
  if ($GoLang)    { $opts += $OptionalApps["Go"]        }
  if ($Python)    { $opts += $OptionalApps["Python"]    }
  if ($Node)      { $opts += $OptionalApps["Node"]      }
  if ($CPlusPlus) { $opts += $OptionalApps["CPlusPlus"] }

  # Optional Editors
  if ($VSCode) { $opts += $OptionalApps["VSCode"] }

  $Apps = $coreApps + $opts

  foreach($app in $Apps) {
    Install-WithWinget -Id $app.Id -Name $app.Name
  }
}

function Install-VS {
  Write-Host "`nInstalling Visual Studio Community 2026"
  try {
    winget install --id Microsoft.VisualStudio.Community `
      --accept-package-agreements --accept-source-agreements `
      --override "--passive --wait --config .vsconfig"
  } catch {
    Write-Host "✗ Installation failed while installing Visual Studio: $_" -ForegroundColor Red
  }
}

function Install-CommSys {
  $InstallDir = Get-InstallDir -Path $DefaultDir
  Write-Host "`nCommSys tools and applications will be installed to: $InstallDir" -ForegroundColor Cyan

}

###########################
#    START MAIN SCRIPT    #
###########################

<#
  .SYNOPSIS Bootstraps developer PC with necessary installs and commsys related applications from
          version control
#>

# Install General Applications
Install-Applications

# Install Visual Studio
Install-VS

# Install CommSys Tools and Applications
Install-CommSys

Write-Host "`n✓ Bootstrap script completed!" -ForegroundColor Green
