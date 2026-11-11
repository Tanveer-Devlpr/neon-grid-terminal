# NEON//GRID Community — one-command installer for Windows Terminal.
# Public source: https://github.com/Tanveer-Devlpr/neon-grid-terminal
# Installation modifies only the current user's Windows Terminal settings and
# creates a new directory under %LOCALAPPDATA%\Programs\NeonGridTerminal.
# Requires Windows 10/11 and Windows PowerShell 5.1+.
$ErrorActionPreference = 'Stop'
$repo = 'Tanveer-Devlpr/neon-grid-terminal'
$source = $null
$temp = Join-Path ([IO.Path]::GetTempPath()) ('NeonGrid-Install-' + [guid]::NewGuid().ToString('N'))
$target = if ($env:NEONGRID_INSTALL_DIR) { $env:NEONGRID_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'Programs\NeonGridTerminal' }
$testing = $env:NEONGRID_TEST_MODE -eq '1'

# Windows Terminal settings use JSONC (comments / trailing commas).
# Preserve string contents, including URLs, while parsing JSONC.
if (-not ('NeonGridJsoncParser' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Text;
public static class NeonGridJsoncParser {
 public static string Clean(string src) {
  var output = new StringBuilder(src.Length);
  bool quote=false, escaped=false, line=false, block=false;
  for(int i=0;i<src.Length;i++){
   char ch=src[i], next=i+1<src.Length?src[i+1]:'\0';
   if(line){if(ch=='\r'||ch=='\n'){line=false;output.Append(ch);}continue;}
   if(block){if(ch=='*'&&next=='/'){block=false;i++;}continue;}
   if(quote){
    output.Append(ch);
    if(escaped)escaped=false;
    else if(ch=='\\')escaped=true;
    else if(ch=='"')quote=false;
    continue;
   }
   if(ch=='"'){quote=true;output.Append(ch);continue;}
   if(ch=='/'&&next=='/'){line=true;i++;continue;}
   if(ch=='/'&&next=='*'){block=true;i++;continue;}
   output.Append(ch);
  }
  string cleaned=output.ToString();output.Clear();quote=false;escaped=false;
  for(int i=0;i<cleaned.Length;i++){
   char ch=cleaned[i];
   if(quote){
    output.Append(ch);
    if(escaped)escaped=false;
    else if(ch=='\\')escaped=true;
    else if(ch=='"')quote=false;
    continue;
   }
   if(ch=='"'){quote=true;output.Append(ch);continue;}
   if(ch==','){
    int j=i+1;
    while(j<cleaned.Length&&char.IsWhiteSpace(cleaned[j]))j++;
    if(j<cleaned.Length&&(cleaned[j]=='}'||cleaned[j]==']'))continue;
   }
   output.Append(ch);
  }
  return output.ToString();
 }
}
'@
}

function Read-TerminalSettings([string]$path) {
  $raw = [IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)
  $json = [NeonGridJsoncParser]::Clean($raw)
  return ConvertFrom-Json -InputObject $json -ErrorAction Stop
}
function Ensure-Property($obj,[string]$name,$value) {
  if (-not $obj.PSObject.Properties[$name]) {
    $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value
  }
}
function Assert-Assets([string]$folder) {
  foreach ($name in @('hud.png','shell.png','watch.png')) {
    $p = Join-Path (Join-Path $folder 'assets') $name
    if (-not (Test-Path -LiteralPath $p)) { throw ('Required image missing: ' + $p) }
    if ((Get-Item -LiteralPath $p).Length -lt 100000) { throw ('Image is unexpectedly small: ' + $p) }
  }
}

try {
  if (-not $testing) {
    $terminal = Get-Command wt.exe -ErrorAction SilentlyContinue
    $package = Get-AppxPackage -Name 'Microsoft.WindowsTerminal' -ErrorAction SilentlyContinue
    if (-not $terminal -and -not $package) {
      $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
      if (-not $winget) { throw 'Windows Terminal not found. Install Windows Terminal from Microsoft Store and retry.' }
      Write-Host '[NEON//GRID] Installing Windows Terminal using winget...' -ForegroundColor Cyan
      & $winget.Source install --id Microsoft.WindowsTerminal --exact --accept-package-agreements --accept-source-agreements --silent
      if ($LASTEXITCODE -ne 0) { throw ('Windows Terminal installation failed. winget exit code: '+$LASTEXITCODE) }
    }
  }
  if (-not (Test-Path -LiteralPath $temp)) { New-Item -ItemType Directory -Path $temp -Force | Out-Null }
  if ($env:NEONGRID_SOURCE_DIR) {
    $source = $env:NEONGRID_SOURCE_DIR
  } else {
    $url = 'https://github.com/' + $repo + '/archive/refs/heads/main.zip'
    $zip = Join-Path $temp 'source.zip'
    Write-Host '[NEON//GRID] Downloading public theme package...' -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -ErrorAction Stop
    Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $temp 'unpacked') -Force
    $source = (Get-ChildItem (Join-Path $temp 'unpacked') -Directory | Select-Object -First 1).FullName
  }
  if (-not $source) { throw 'Could not locate downloaded package.' }
  Assert-Assets $source
  foreach ($name in @('Launch.ps1','Hud.ps1','Command.ps1','Watch.ps1','Uninstall.ps1')) {
    if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $source 'scripts') $name))) { throw ('Script missing: '+$name) }
  }
  $stable = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
  $preview = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'
  $unpackaged = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
  $settings = if ($env:NEONGRID_SETTINGS_FILE) { $env:NEONGRID_SETTINGS_FILE } elseif (Test-Path $stable) { $stable } elseif (Test-Path $preview) { $preview } elseif (Test-Path $unpackaged) { $unpackaged } else { $stable }
  New-Item -ItemType Directory -Path (Split-Path -Parent $settings) -Force | Out-Null

  $settingsExisted = Test-Path -LiteralPath $settings
  if ($settingsExisted) {
    $j = Read-TerminalSettings $settings
  } else {
    $j = [pscustomobject]@{'$schema'='https://aka.ms/terminal-profiles-schema';profiles=[pscustomobject]@{list=@()};schemes=@()}
  }
  Ensure-Property $j 'defaultProfile' $null
  Ensure-Property $j 'profiles' ([pscustomobject]@{list=@()})
  Ensure-Property $j.profiles 'list' @()
  Ensure-Property $j 'schemes' @()
  Ensure-Property $j 'actions' @()
  Ensure-Property $j 'keybindings' @()

  # Backup before changing any user's Terminal settings.
  $backupDir = Join-Path $target 'backups'
  New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
  $backup = Join-Path $backupDir ('settings-before-install-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.json')
  if ($settingsExisted) { Copy-Item -LiteralPath $settings -Destination $backup -ErrorAction Stop }

  $statePath = Join-Path $target 'install-state.json'
  $originalDefault = $j.defaultProfile
  if (Test-Path -LiteralPath $statePath) {
    try {
      $prev = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($prev.originalDefault) { $originalDefault = $prev.originalDefault }
    } catch {}
  }
  New-Item -ItemType Directory -Path $target -Force | Out-Null
  foreach ($dir in @('assets','scripts')) {
    $dst = Join-Path $target $dir
    New-Item -ItemType Directory -Path $dst -Force | Out-Null
    Copy-Item -Path (Join-Path (Join-Path $source $dir) '*') -Destination $dst -Recurse -Force -ErrorAction Stop
  }
  Assert-Assets $target
  # Remove a leftover optional runtime script when updating from v1.0.0.
  $oldRemoteScript = Join-Path (Join-Path $target 'scripts') 'Remote.ps1'
  if (Test-Path -LiteralPath $oldRemoteScript) { Remove-Item -LiteralPath $oldRemoteScript -Force -ErrorAction Stop }
  $legacyRemoteIds = @('{bc41f770-8e42-4a5f-8881-cc00aa03f002}','{bc41f770-8e42-4a5f-8881-cc00aa03f005}')
  $j.profiles.list = @($j.profiles.list | Where-Object { $_.guid -notin $legacyRemoteIds })
  $ids = @{
    shell='{bc41f770-8e42-4a5f-8881-cc00aa03f001}'
    hud='{bc41f770-8e42-4a5f-8881-cc00aa03f003}'
    command='{bc41f770-8e42-4a5f-8881-cc00aa03f004}'
    watch='{bc41f770-8e42-4a5f-8881-cc00aa03f006}'
  }
  $exe = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoProfile '
  $defs = @(
    @{key='shell';name='NEON GRID // SHELL';file='Launch.ps1';args='';image='hud.png';hidden=$false;pad='0';size=10;close='always'},
    @{key='hud';name='NEON GRID HUD';file='Hud.ps1';args='';image='hud.png';hidden=$true;pad='0';size=10;close='graceful'},
    @{key='command';name='NEON GRID SHELL COMMAND';file='Command.ps1';args='';image='shell.png';hidden=$true;pad='75, 95, 70, 80';size=11;close='graceful'},
    @{key='watch';name='NEON GRID WATCH';file='Watch.ps1';args='';image='watch.png';hidden=$true;pad='0';size=10;close='graceful'}
  )
  foreach ($def in $defs) {
    $script = Join-Path (Join-Path $target 'scripts') $def.file
    $args = '-ExecutionPolicy Bypass -File "' + $script + '"' + $def.args
    if ($def.key -eq 'command') { $args = '-NoExit ' + $args }
    $profile = [pscustomobject]@{
      guid=$ids[$def.key];name=$def.name;hidden=$def.hidden
      commandline=($exe+$args)
      startingDirectory='%USERPROFILE%'
      colorScheme='NeonGridCommunity'
      backgroundImage=(Join-Path (Join-Path $target 'assets') $def.image)
      backgroundImageOpacity=1.0;backgroundImageStretchMode='fill';backgroundImageAlignment='center'
      background='#040619';opacity=100;useAcrylic=$false;padding=$def.pad
      font=[pscustomobject]@{face='Cascadia Code';size=$def.size;weight='normal'}
      cursorShape='bar';closeOnExit=$def.close;suppressApplicationTitle=$true;tabTitle=$def.name
    }
    $j.profiles.list=@($j.profiles.list | Where-Object { $_.guid -ne $profile.guid }) + @($profile)
  }
  $scheme = [pscustomobject]@{
    name='NeonGridCommunity';background='#040619';foreground='#DDE9FC';cursorColor='#00EDFF'
    selectionBackground='#41416B';black='#02030D';red='#FF658E';green='#37E99E'
    yellow='#FFCA7F';blue='#528EF9';purple='#D777FF';cyan='#00E6F0';white='#DDE9FC'
    brightBlack='#65718A';brightRed='#FF79AB';brightGreen='#76FFBF';brightYellow='#FFE1A0'
    brightBlue='#86AFFF';brightPurple='#EEA1FF';brightCyan='#7DF9FF';brightWhite='#FFFFFF'
  }
  $j.schemes = @($j.schemes | Where-Object { $_.name -notin @('NeonGridCommunity','NeonGridCommunityRemote') }) + @($scheme)
  $j.defaultProfile = $ids.shell
  # Migration from v1.0.0: remove only that release's optional remote shortcut.
  $j.actions = @($j.actions | Where-Object { $_.id -ne 'User.NeonGridCommunityRemote' })
  $j.keybindings = @($j.keybindings | Where-Object { $_.id -ne 'User.NeonGridCommunityRemote' })
  $state = [pscustomobject]@{originalDefault=$originalDefault;installedUtc=[DateTime]::UtcNow.ToString('o');repository=$repo;settingsPath=$settings}
  [IO.File]::WriteAllText($statePath,($state|ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding($false)))
  $formatted = ConvertTo-Json -InputObject $j -Depth 80
  [IO.File]::WriteAllText($settings,$formatted,(New-Object Text.UTF8Encoding($false)))
  $verification = Read-TerminalSettings $settings
  $installedProfiles = @($verification.profiles.list | Where-Object { $_.guid -in @($ids.Values) })
  if ($installedProfiles.Count -ne 4 -or $verification.defaultProfile -ne $ids.shell) {
    if ($settingsExisted) { Copy-Item -LiteralPath $backup -Destination $settings -Force }
    else { Remove-Item -LiteralPath $settings -Force -ErrorAction SilentlyContinue }
    throw 'Settings verification failed; original settings restored.'
  }
  Write-Host '[NEON//GRID] Installed successfully.' -ForegroundColor Green
  Write-Output ('Installed files: '+$target)
  Write-Output ('Settings backup: '+$backup)
  if (-not $testing) {
    try {
      $launch = Get-Command wt.exe -ErrorAction SilentlyContinue
      if ($launch) { Start-Process -FilePath $launch.Source -ArgumentList '-w 0 new-tab -p "NEON GRID // SHELL"' -ErrorAction Stop | Out-Null }
      else { Write-Output 'Open Windows Terminal and select NEON GRID // SHELL.' }
    } catch { Write-Warning 'Theme installed. Open a new Windows Terminal window to activate it.' }
  }
} finally {
  if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
}
