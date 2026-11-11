# NEON//GRID Community - interactive PowerShell command pane.
$ErrorActionPreference = 'Continue'
try { Set-Location -LiteralPath $HOME } catch {}
$state = Join-Path $env:TEMP 'NeonGridCommunity'
New-Item -ItemType Directory -Path $state -Force | Out-Null
Set-Content -LiteralPath (Join-Path $state 'command-shell.ready') -Value "$PID|$([DateTime]::UtcNow.ToString('o'))"
function global:prompt {
  $now = (Get-Date).ToString('hh:mm:ss tt')
  Write-Host ('  ' + $env:USERNAME + ' @ ' + $env:COMPUTERNAME + '  |  ' + $now) -ForegroundColor Cyan
  return '> '
}
