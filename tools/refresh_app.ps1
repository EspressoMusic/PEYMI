# Restarts the Flutter app on a connected Android phone (preferred) or web fallback.
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Port = 7357
$Url = "http://localhost:$Port"
$PidFile = Join-Path $ProjectRoot ".flutter_run.pid"
$DeviceId = "RZCYA1S0LGL"

function Stop-FlutterRun {
  if (Test-Path $PidFile) {
    $oldPid = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($oldPid -match '^\d+$') {
      Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
  }
}

Set-Location $ProjectRoot
Stop-FlutterRun

$devices = flutter devices 2>&1 | Out-String
$useAndroid = $devices -match $DeviceId

if ($useAndroid) {
  $logOut = Join-Path $ProjectRoot "tools\flutter_run.out.log"
  $logErr = Join-Path $ProjectRoot "tools\flutter_run.err.log"
  $proc = Start-Process -FilePath "flutter" `
    -ArgumentList "run", "-d", $DeviceId `
    -WorkingDirectory $ProjectRoot `
    -PassThru `
    -RedirectStandardOutput $logOut `
    -RedirectStandardError $logErr `
    -WindowStyle Hidden

  $proc.Id | Set-Content $PidFile

  $deadline = (Get-Date).AddMinutes(6)
  $ready = $false
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 3
    $log = ""
    if (Test-Path $logOut) { $log += Get-Content $logOut -Raw -ErrorAction SilentlyContinue }
    if (Test-Path $logErr) { $log += Get-Content $logErr -Raw -ErrorAction SilentlyContinue }
    if ($log -match "Flutter run key commands") {
      $ready = $true
      break
    }
    if ($log -match "BUILD FAILED|No supported devices") {
      Write-Host $log
      exit 1
    }
  }

  if (-not $ready) {
    Write-Host "Android build did not finish in time. See $logOut and $logErr"
    exit 1
  }

  Write-Host "App installed on phone ($DeviceId). Check your device screen."
  exit 0
}

# Web fallback when phone is not connected
Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }

$logOut = Join-Path $ProjectRoot "tools\flutter_web.out.log"
$logErr = Join-Path $ProjectRoot "tools\flutter_web.err.log"
$proc = Start-Process -FilePath "flutter" `
  -ArgumentList "run", "-d", "web-server", "--web-port=$Port", "--web-hostname=localhost" `
  -WorkingDirectory $ProjectRoot `
  -PassThru `
  -RedirectStandardOutput $logOut `
  -RedirectStandardError $logErr `
  -WindowStyle Hidden

$proc.Id | Set-Content $PidFile

$deadline = (Get-Date).AddMinutes(3)
$ready = $false
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 2
  $log = ""
  if (Test-Path $logOut) { $log += Get-Content $logOut -Raw -ErrorAction SilentlyContinue }
  if (Test-Path $logErr) { $log += Get-Content $logErr -Raw -ErrorAction SilentlyContinue }
  if ($log -match "is being served at") {
    $ready = $true
    break
  }
  if ($log -match "Failed|Error:") {
    Write-Host $log
    exit 1
  }
}

if (-not $ready) {
  Write-Host "Flutter web server did not become ready in time. See $logOut and $logErr"
  exit 1
}

Start-Process $Url
Write-Host "Phone not connected. App refreshed at $Url (PID $($proc.Id))"
