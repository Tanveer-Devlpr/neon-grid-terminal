# NEON//GRID Community — one atomic three-pane Windows Terminal command.
param([ValidateSet('Shell','Remote')][string]$Mode = 'Shell', [switch]$DryRun)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
foreach ($name in @('hud.png','shell.png','watch.png')) {
  if (-not (Test-Path -LiteralPath (Join-Path $root ('assets\' + $name)))) {
    throw ('Missing NEON//GRID asset: ' + $name)
  }
}
$wt = Get-Command wt.exe -ErrorAction Stop
$command = if ($Mode -eq 'Remote') { 'NEON GRID REMOTE COMMAND' } else { 'NEON GRID SHELL COMMAND' }
$actions = '-w 0 new-tab -p "NEON GRID HUD"'
$actions += ' ; split-pane -H -s 0.60 -p "' + $command + '"'
$actions += ' ; split-pane -V -s 0.305 -p "NEON GRID WATCH"'
$actions += ' ; move-focus left'
if ($DryRun) { Write-Output ('NEON_GRID_ACTIONS=' + $actions); return }
Start-Process -FilePath $wt.Source -ArgumentList $actions -ErrorAction Stop | Out-Null
# This bootstrap profile has closeOnExit=always. The three new panes stay open.
