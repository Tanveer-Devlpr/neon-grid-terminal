# Optional Desktop Commander Remote launcher. No tokens, accounts or keys bundled.
$ErrorActionPreference = 'Continue'
$clients = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue | Where-Object {
  $line = [string]$_.CommandLine
  $line -match '(?i)desktop-commander' -and $line -match '(?i)\sremote(?:\s|$)'
})
if ($clients.Count -gt 0) {
  Write-Host '[NEON LINK] Existing Desktop Commander Remote detected.' -ForegroundColor Green
  Write-Host ('[PID] ' + (($clients | Select-Object -ExpandProperty ProcessId) -join ', ')) -ForegroundColor Cyan
  Write-Host '[SAFE] Existing session preserved; no duplicate launched.' -ForegroundColor Yellow
  return
}
$npx = Get-Command npx.cmd -ErrorAction SilentlyContinue
if (-not $npx) {
  Write-Warning 'Optional Remote requires Node.js (https://nodejs.org/) and Desktop Commander account setup.'
  Write-Host 'The NEON//GRID shell works without Desktop Commander.' -ForegroundColor Cyan
  return
}
Write-Host '[NEON LINK] Starting Desktop Commander Remote...' -ForegroundColor Cyan
Write-Host 'Authentication and permission setup are handled by Desktop Commander.' -ForegroundColor DarkGray
& $npx.Source '@wonderwhy-er/desktop-commander@latest' 'remote'
Write-Host ('Remote client exit code: ' + $LASTEXITCODE) -ForegroundColor Yellow
