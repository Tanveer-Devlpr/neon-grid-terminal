# NEON//GRID Community — decorative watch artwork. Status indicators are illustrative.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $root 'assets\watch.png'))) { throw 'Missing NEON//GRID watch image.' }
$state = Join-Path $env:TEMP 'NeonGridCommunity'
New-Item -ItemType Directory -Path $state -Force | Out-Null
Set-Content -LiteralPath (Join-Path $state 'watch.ready') -Value "$PID|$([DateTime]::UtcNow.ToString('o'))"
$esc = [char]27
try {
  [Console]::Write("$esc" + '[?25l')
  while ($true) { Start-Sleep -Seconds 30 }
} finally {
  try { [Console]::Write("$esc" + '[?25h') } catch {}
}
