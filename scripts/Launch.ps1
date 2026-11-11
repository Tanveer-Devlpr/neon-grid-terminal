# NEON//GRID Community - atomic three-pane layout, no optional remote integration.
param([switch]$DryRun)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
foreach ($name in @('hud.png','shell.png','watch.png')) {
  if (-not (Test-Path -LiteralPath (Join-Path $root ('assets\' + $name)))) {
    throw ('Missing NEON//GRID asset: ' + $name)
  }
}
$wt = Get-Command wt.exe -ErrorAction Stop
$actions = '-w 0 new-tab -p "NEON GRID HUD"'
$actions += ' ; split-pane -H -s 0.60 -p "NEON GRID SHELL COMMAND"'
$actions += ' ; split-pane -V -s 0.305 -p "NEON GRID WATCH"'
$actions += ' ; move-focus left'
if ($DryRun) { Write-Output ('NEON_GRID_ACTIONS=' + $actions); return }
Start-Process -FilePath $wt.Source -ArgumentList $actions -ErrorAction Stop | Out-Null
# Bootstrap closes automatically; the three panes remain open.
