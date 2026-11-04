# Writes a qmldir into every folder under modules\ that holds .qml files.
# URI = folder path relative to modules\, with dots. Idempotent: rewrites only on change.
param([string]$Modules = (Join-Path $PSScriptRoot '..\modules'))
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $Modules).Path.TrimEnd('\')
$written = 0; $same = 0
$folders = @(Get-ChildItem -LiteralPath $root -Recurse -Directory | Where-Object {
  Get-ChildItem -LiteralPath $_.FullName -Filter *.qml -File
})
foreach ($f in $folders) {
  $uri = $f.FullName.Substring($root.Length + 1).Replace('\', '.')
  $lines = @("module $uri")
  foreach ($q in (Get-ChildItem -LiteralPath $f.FullName -Filter *.qml -File | Sort-Object Name)) {
    $type = $q.BaseName
    if ($type -cnotmatch '^[A-Z]') { continue }
    $single = Select-String -LiteralPath $q.FullName -Pattern '^\s*pragma\s+Singleton\b' -Quiet
    $prefix = if ($single) { 'singleton ' } else { '' }
    $lines += "$prefix$type 1.0 $($q.Name)"
  }
  $text = ($lines -join "`n") + "`n"
  $path = Join-Path $f.FullName 'qmldir'
  if ((Test-Path -LiteralPath $path) -and ([IO.File]::ReadAllText($path) -ceq $text)) { $same++; continue }
  [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding $false))
  $written++
}
Write-Host "qmldir: $written written, $same unchanged, $($folders.Count) folders"
