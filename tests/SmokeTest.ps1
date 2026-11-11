# Offline Windows PowerShell 5.1+ test; NEVER edits the user's real Windows Terminal settings.
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$temp=Join-Path $env:TEMP ('NeonGridPackageTest-'+[guid]::NewGuid().ToString('N'))
$settings=Join-Path $temp 'settings.json'
$target=Join-Path $temp 'installed'
New-Item -ItemType Directory -Path $temp -Force|Out-Null
$sample=@'
{
 // JSONC comments, trailing commas and a non-theme original profile
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
  & (Join-Path $repo 'install.ps1')|Out-Null
  $j=Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json
  if (@($j.profiles.list|Where-Object{$_.name -like 'NEON GRID*'}).Count -ne 6) { throw 'Expected 6 profiles.' }
  if (@($j.schemes|Where-Object{$_.name -like 'NeonGridCommunity*'}).Count -ne 2) { throw 'Expected 2 schemes.' }
  if (@($j.profiles.list|Where-Object{$_.name -eq 'Windows PowerShell'}).Count -ne 1) { throw 'Original profile was lost.' }
  foreach($name in @('hud.png','shell.png','watch.png')){
    if((Get-FileHash (Join-Path $repo ('assets\'+$name))).Hash -ne (Get-FileHash (Join-Path $target ('assets\'+$name))).Hash){
      throw ('Asset checksum mismatch '+$name)
    }
  }
  Write-Output 'PASS: Fresh install from JSONC.'
  & (Join-Path $repo 'install.ps1')|Out-Null
  $j=Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json
  if (@($j.profiles.list|Where-Object{$_.name -like 'NEON GRID*'}).Count -ne 6){throw 'Reinstall duplicated profiles.'}
  Write-Output 'PASS: Idempotent reinstall.'
  & (Join-Path $target 'scripts\Uninstall.ps1')|Out-Null
  $j=Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json
  if (@($j.profiles.list|Where-Object{$_.name -like 'NEON GRID*'}).Count -ne 0){throw 'Uninstall left profiles.'}
  if ($j.defaultProfile -ne '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'){throw 'Uninstall did not restore previous default.'}
  Write-Output 'PASS: Uninstall and default restore.'
  Write-Output 'ALL TESTS PASSED'
} finally {
  Remove-Item Env:NEONGRID_TEST_MODE,Env:NEONGRID_SOURCE_DIR,Env:NEONGRID_SETTINGS_FILE,Env:NEONGRID_INSTALL_DIR -ErrorAction SilentlyContinue
  if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue}
}
