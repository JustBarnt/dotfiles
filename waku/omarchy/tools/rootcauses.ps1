# Distinct terminal error of each failing chain in logs\loadcheck.txt, with counts.
param([int]$Top = 25, [string]$Log = (Join-Path $PSScriptRoot '..\logs\loadcheck.txt'))
Get-Content $Log | Where-Object { $_ -match '\|ERR\|' } | ForEach-Object {
  $parts = $_ -split '\|', 4
  $chain = $parts[3] -replace 'file:///\S*?/modules/qs/', ''
  $e = @($chain -split " ;; " | Where-Object { $_.Trim() }); $e[-1].Trim()
} | Group-Object | Sort-Object Count -Descending | Select-Object -First $Top | ForEach-Object { '{0,4}  {1}' -f $_.Count, $_.Name }
