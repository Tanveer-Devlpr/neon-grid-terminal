# Isolated PowerShell installer test: never changes live Windows Terminal settings.
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$temp=Join-Path $env:TEMP ('NeonGridPackageTest-'+[guid]::NewGuid().ToString('N'))
$settings=Join-Path $temp 'settings.json'
$target=Join-Path $temp 'installed'
New-Item -ItemType Directory -Path $temp -Force | Out-Null
$sample=@'
{
 // Preserve existing user settings and ignore trailing commas.
 "defaultProfile": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
 "profiles": {
   "list": [{"guid":"{61c54bbd-c2c6-5271-96e7-009a87ff44bf}","name":"Windows PowerShell","background":"#101010",}],
 },
 "schemes": [],
 "actions": [],
 "keybindings": [],
}
'@
[IO.File]::WriteAllText($settings,$sample,(New-Object Text.UTF8Encoding($false)))
$env:NEONGRID_TEST_MODE='1'
$env:NEONGRID_SOURCE_DIR=$repo
$env:NEONGRID_SETTINGS_FILE=$settings
$env:NEONGRID_INSTALL_DIR=$target
try {
  # Fresh installation adds exactly four profiles and one scheme.
  & (Join-Path $repo 'install.ps1') | Out-Null
  $j=Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json
  if (@($j.profiles.list|Where-Object{$_.name -like 'NEON GRID*'}).Count -ne 4) { throw 'Expected exactly 4 NEON GRID profiles.' }
  if (@($j.schemes|Where-Object{$_.name -like 'NeonGridCommunity*'}).Count -ne 1) { throw 'Expected exactly one NEON color scheme.' }
  if (@($j.profiles.list|Where-Object{$_.name -eq 'Windows PowerShell'}).Count -ne 1) { throw 'Lost existing Windows PowerShell profile.' }
  if (@($j.keybindings|Where-Object{$_.id -like 'User.NeonGridCommunity*'}).Count -ne 0) { throw 'Unexpected theme shortcut.' }
  if (@($j.profiles.list|Where-Object{$_.name -match 'REMOTE'}).Count -ne 0){ throw 'Remote profile incorrectly installed.' }
  foreach($name in @('hud.png','shell.png','watch.png')){
    if((Get-FileHash (Join-Path $repo ('assets\'+$name))).Hash -ne (Get-FileHash (Join-Path $target ('assets\'+$name))).Hash){
      throw ('Asset checksum mismatch '+$name)
    }
  }
  if(Test-Path -LiteralPath (Join-Path $target 'scripts\Remote.ps1')) { throw 'Remote script unexpectedly shipped.' }
  Write-Output 'PASS: Four-profile fresh install, original profile retained.'

  # Simulate a v1.0.0 installation and verify migration removes only its discontinued entries.
  $j.profiles.list = @($j.profiles.list) + @(
    [pscustomobject]@{guid='{bc41f770-8e42-4a5f-8881-cc00aa03f002}';name='NEON GRID // REMOTE'},
    [pscustomobject]@{guid='{bc41f770-8e42-4a5f-8881-cc00aa03f005}';name='NEON GRID REMOTE COMMAND'}
  )
  $j.schemes=@($j.schemes)+@([pscustomobject]@{name='NeonGridCommunityRemote'})
  $j.actions=@($j.actions)+@([pscustomobject]@{id='User.NeonGridCommunityRemote';command=[pscustomobject]@{action='newTab';profile='{bc41f770-8e42-4a5f-8881-cc00aa03f002}'}})
  $j.keybindings=@($j.keybindings)+@([pscustomobject]@{id='User.NeonGridCommunityRemote';keys='ctrl+alt+r'})
  [IO.File]::WriteAllText($settings,(ConvertTo-Json -InputObject $j -Depth 80),(New-Object Text.UTF8Encoding($false)))
  Set-Content -LiteralPath (Join-Path $target 'scripts\Remote.ps1') -Value 'old public version file'
  & (Join-Path $repo 'install.ps1') | Out-Null
  $j=Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json
  if (@($j.profiles.list|Where-Object{$_.name -like 'NEON GRID*'}).Count -ne 4) { throw 'Upgrade left legacy profiles.' }
  if (@($j.schemes|Where-Object{$_.name -like 'NeonGridCommunity*'}).Count -ne 1) { throw 'Upgrade left legacy scheme.' }
  if (@($j.keybindings|Where-Object{$_.id -eq 'User.NeonGridCommunityRemote'}).Count) { throw 'Upgrade left legacy shortcut.' }
  if (@($j.actions|Where-Object{$_.id -eq 'User.NeonGridCommunityRemote'}).Count) { throw 'Upgrade left legacy action.' }
  if (Test-Path -LiteralPath (Join-Path $target 'scripts\Remote.ps1')) { throw 'Upgrade left old remote script.' }
  Write-Output 'PASS: v1.0.0 upgrade removes discontinued remote integration.'

  & (Join-Path $repo 'install.ps1') | Out-Null
  $j=Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json
  if (@($j.profiles.list|Where-Object{$_.name -like 'NEON GRID*'}).Count -ne 4) { throw 'Reinstall duplicated profiles.' }
  Write-Output 'PASS: Idempotent reinstall.'

  & (Join-Path $target 'scripts\Uninstall.ps1') | Out-Null
  $j=Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json
  if (@($j.profiles.list|Where-Object{$_.name -like 'NEON GRID*'}).Count) { throw 'Uninstall left NEON profiles.' }
  if ($j.defaultProfile -ne '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}') { throw 'Uninstall failed to restore previous default.' }
  Write-Output 'PASS: Uninstall restores original default.'
  Write-Output 'ALL TESTS PASSED'
} finally {
  Remove-Item Env:NEONGRID_TEST_MODE,Env:NEONGRID_SOURCE_DIR,Env:NEONGRID_SETTINGS_FILE,Env:NEONGRID_INSTALL_DIR -ErrorAction SilentlyContinue
  if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue}
}
