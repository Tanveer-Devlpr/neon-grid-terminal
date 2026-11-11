# NEON//GRID Community — static upper dashboard, no animations or system polling.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $root 'assets\hud.png'))) { throw 'Missing NEON//GRID HUD image.' }
$state = Join-Path $env:TEMP 'NeonGridCommunity'
New-Item -ItemType Directory -Path $state -Force | Out-Null
Set-Content -LiteralPath (Join-Path $state 'hud.ready') -Value "$PID|$([DateTime]::UtcNow.ToString('o'))"
$esc = [char]27
try {
  [Console]::Write("$esc" + '[?25l')
  while ($true) { Start-Sleep -Seconds 30 }
} finally {
  try { [Console]::Write("$esc" + '[?25h') } catch {}
}
