# NEON//GRID Community — interactive shell, no pane creation or global profile changes.
param([switch]$Remote)
$ErrorActionPreference = 'Continue'
try { Set-Location -LiteralPath $HOME } catch {}
$state = Join-Path $env:TEMP 'NeonGridCommunity'
New-Item -ItemType Directory -Path $state -Force | Out-Null
$mode = if ($Remote) { 'remote' } else { 'shell' }
Set-Content -LiteralPath (Join-Path $state ('command-' + $mode + '.ready')) -Value "$PID|$([DateTime]::UtcNow.ToString('o'))"
function global:prompt {
  $now = (Get-Date).ToString('hh:mm:ss tt')
  Write-Host ('  ' + $env:USERNAME + ' @ ' + $env:COMPUTERNAME + '  |  ' + $now) -ForegroundColor Cyan
  return '> '
}
function global:neon-remote {
  try { Start-Process -FilePath 'wt.exe' -ArgumentList '-w 0 new-tab -p "NEON GRID // REMOTE"' -ErrorAction Stop | Out-Null }
  catch { Write-Warning ('Unable to start remote tab: ' + $_.Exception.Message) }
}
function global:neon-remote-status {
  Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match '(?i)desktop-commander' } |
    Select-Object ProcessId, ParentProcessId | Format-Table
}
if ($Remote) {
  # Console host colors only affect this child process; not ordinary PowerShell.
  try {
    $Host.UI.RawUI.ForegroundColor = 'Cyan'
    $Host.PrivateData.ErrorForegroundColor = 'Magenta'
    $Host.PrivateData.WarningForegroundColor = 'Yellow'
    $Host.PrivateData.DebugForegroundColor = 'Cyan'
    $Host.PrivateData.VerboseForegroundColor = 'Green'
  } catch {}
  & (Join-Path $PSScriptRoot 'Remote.ps1')
}
