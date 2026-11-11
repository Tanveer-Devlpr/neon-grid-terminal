# Restore original default and remove only NEON//GRID Community Terminal profiles.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$statePath = Join-Path $root 'install-state.json'
$settings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (Test-Path -LiteralPath $statePath) {
  $saved = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($saved.settingsPath) { $settings = [string]$saved.settingsPath }
}
if (-not (Test-Path -LiteralPath $settings)) { throw 'Windows Terminal settings were not found.' }
$ids = @(
  '{bc41f770-8e42-4a5f-8881-cc00aa03f001}',
  '{bc41f770-8e42-4a5f-8881-cc00aa03f002}',
  '{bc41f770-8e42-4a5f-8881-cc00aa03f003}',
  '{bc41f770-8e42-4a5f-8881-cc00aa03f004}',
  '{bc41f770-8e42-4a5f-8881-cc00aa03f005}',
  '{bc41f770-8e42-4a5f-8881-cc00aa03f006}'
)
$backupDir = Join-Path $root 'backups'
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$backup = Join-Path $backupDir ('settings-before-uninstall-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
Copy-Item -LiteralPath $settings -Destination $backup -ErrorAction Stop
$j = Get-Content -LiteralPath $settings -Raw -Encoding UTF8 | ConvertFrom-Json
$state = $null
if (Test-Path -LiteralPath $statePath) { $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json }
if ($j.defaultProfile -in $ids) {
  if ($state -and $state.originalDefault -and ($state.originalDefault -notin $ids)) {
    $j.defaultProfile = $state.originalDefault
  } else {
    $j.defaultProfile = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
  }
}
$j.profiles.list = @($j.profiles.list | Where-Object { $_.guid -notin $ids })
$j.schemes = @($j.schemes | Where-Object { $_.name -notin @('NeonGridCommunity','NeonGridCommunityRemote') })
if ($j.PSObject.Properties['actions']) { $j.actions = @($j.actions | Where-Object { $_.id -ne 'User.NeonGridCommunityRemote' }) }
if ($j.PSObject.Properties['keybindings']) { $j.keybindings = @($j.keybindings | Where-Object { $_.id -ne 'User.NeonGridCommunityRemote' }) }
$json = ConvertTo-Json -InputObject $j -Depth 80
[IO.File]::WriteAllText($settings,$json,(New-Object Text.UTF8Encoding($false)))
Write-Output ('NEON//GRID profiles removed. Settings backup: ' + $backup)
Write-Output ('Package files retained for manual removal: ' + $root)
Write-Output 'Close old NEON tabs before deleting the package folder.'
