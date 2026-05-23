# Refresh Flutter app on phone (RZCYA1S0LGL) or web fallback.
#
# FAST (default) — seconds, for small Dart/UI changes:
#   .\tools\refresh_app.ps1
#   .\tools\refresh_app.ps1 -Reload    # hot reload (r)
#   .\tools\refresh_app.ps1 -Restart   # hot restart (R) — same as default
#
# SLOW — full clean build + reinstall (~1–2 min); only when needed:
#   .\tools\refresh_app.ps1 -Force
#
# First call starts a background debug session (~1 min). Later calls only hot reload/restart.
# In Cursor: Flutter extension → Hot Reload on save is even faster.
param(
  [switch]$Force,
  [switch]$Reload,
  [switch]$Restart
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Port = 7357
$Url = "http://localhost:$Port"
$PidFile = Join-Path $ProjectRoot ".flutter_run.pid"
$CmdFile = Join-Path $ProjectRoot ".flutter_hot_cmd"
$SessionScript = Join-Path $ProjectRoot "tools\flutter_debug_session.ps1"
$DeviceId = "RZCYA1S0LGL"
$Package = "com.example.bakery_shop_app"
$LogOut = Join-Path $ProjectRoot "tools\flutter_run.out.log"
$LogErr = Join-Path $ProjectRoot "tools\flutter_run.err.log"

function Stop-FlutterRun {
  if (Test-Path $CmdFile) {
    "q" | Set-Content $CmdFile -Encoding utf8 -NoNewline
    Start-Sleep -Seconds 2
  }
  if (Test-Path $PidFile) {
    $oldPid = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($oldPid -match '^\d+$') {
      Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
  }
  Remove-Item (Join-Path $ProjectRoot ".flutter_vm_url") -Force -ErrorAction SilentlyContinue
}

function Get-SupabaseDartDefineArgs {
  param([string]$Root)
  $syncScript = Join-Path $Root "tools\sync_dart_defines.ps1"
  if (-not (Test-Path $syncScript)) { return @() }
  $outFile = & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript -ProjectRoot $Root
  if ([string]::IsNullOrWhiteSpace($outFile) -or -not (Test-Path $outFile)) { return @() }
  return @("--dart-define-from-file=$outFile")
}

function Test-FlutterRunAlive {
  if (-not (Test-Path $PidFile)) { return $false }
  $pidText = Get-Content $PidFile -ErrorAction SilentlyContinue
  if ($pidText -notmatch '^\d+$') { return $false }
  return $null -ne (Get-Process -Id ([int]$pidText) -ErrorAction SilentlyContinue)
}

function Get-FlutterRunLogText {
  $log = ""
  if (Test-Path $LogOut) { $log += Get-Content $LogOut -Raw -ErrorAction SilentlyContinue }
  if (Test-Path $LogErr) { $log += Get-Content $LogErr -Raw -ErrorAction SilentlyContinue }
  return $log
}

function Wait-ForHotResult {
  param(
    [string]$Key,
    [int]$TimeoutSec = 25
  )
  $before = (Get-Item $LogOut -ErrorAction SilentlyContinue).Length
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 400
    $log = Get-FlutterRunLogText
    if ($Key -eq 'r' -and $log -match 'Reloaded \d+ of \d+ libraries') { return $true }
    if ($Key -eq 'R' -and $log -match 'Restarted application') { return $true }
    if ($log -match 'BUILD FAILED|Exception|Error:') { return $false }
    $len = (Get-Item $LogOut -ErrorAction SilentlyContinue).Length
    if ($len -gt $before + 20) {
      if ($Key -eq 'r' -and $log -match 'Reloaded') { return $true }
      if ($Key -eq 'R' -and $log -match 'Restarted') { return $true }
    }
  }
  return $false
}

function Send-HotCommand {
  param([ValidateSet('r', 'R')][string]$Key)
  $label = if ($Key -eq 'r') { 'Hot reload' } else { 'Hot restart' }
  Write-Host "$label..."
  $Key | Set-Content $CmdFile -Encoding utf8 -NoNewline
  if (Wait-ForHotResult -Key $Key) {
    Write-Host "$label OK."
    return $true
  }
  Write-Host "$label sent (check phone; see $LogOut if nothing changes)."
  return $true
}

function Start-DebugSession {
  param([string[]]$SupabaseArgs)

  Stop-FlutterRun
  Write-Host "Starting debug session on $DeviceId (~1 min first time)..."
  if ($SupabaseArgs.Count -gt 0) {
    $env:PEYMI_DART_DEFINES = $SupabaseArgs -join "`n"
  } else {
    Remove-Item Env:PEYMI_DART_DEFINES -ErrorAction SilentlyContinue
  }
  $proc = Start-Process -FilePath "powershell" `
    -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $SessionScript) `
    -WorkingDirectory $ProjectRoot `
    -WindowStyle Hidden `
    -PassThru

  $deadline = (Get-Date).AddMinutes(6)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
    $log = Get-FlutterRunLogText
    if ($log -match "Flutter run key commands") {
      Write-Host "Debug session ready (PID in $PidFile). Next refresh will be fast."
      return $true
    }
    if ($log -match "BUILD FAILED|No supported devices") {
      Write-Host $log
      return $false
    }
    if (-not (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue)) {
      if ($log -match "BUILD FAILED|Error") { Write-Host $log; return $false }
    }
  }
  Write-Host "Timed out. See $LogOut and $LogErr"
  return $false
}

Set-Location $ProjectRoot

$supabaseArgs = Get-SupabaseDartDefineArgs -Root $ProjectRoot
if ($supabaseArgs.Count -gt 0) {
  Write-Host "Supabase: using SUPABASE_URL + ANON_KEY from .env"
} else {
  Write-Host "Supabase: not configured - add SUPABASE_ANON_KEY to .env"
}

$devices = flutter devices 2>&1 | Out-String
$useAndroid = $devices -match $DeviceId
$hotKey = if ($Reload) { 'r' } else { 'R' }

if ($Force) {
  Stop-FlutterRun
  Write-Host "Force refresh: clean build + debug APK (Supabase dart-defines from .env)..."
  flutter clean | Out-Host
  flutter pub get | Out-Host
  $buildArgs = @("build", "apk", "--debug") + $supabaseArgs
  & flutter @buildArgs | Out-Host
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  $apk = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-debug.apk"
  if ($useAndroid) {
    adb -s $DeviceId shell am force-stop $Package 2>$null
    adb -s $DeviceId uninstall $Package 2>$null
    adb -s $DeviceId install -r $apk | Out-Host
    adb -s $DeviceId shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n "$Package/.MainActivity" | Out-Host
    Write-Host "Force refresh done on $DeviceId. Run .\tools\refresh_app.ps1 once to start fast hot reload."
  } else {
    Write-Host "APK built: $apk"
    Write-Host "Phone $DeviceId not connected - connect USB, enable debugging, then run:"
    Write-Host ('  adb -s ' + $DeviceId + ' install -r "' + $apk + '"')
    Write-Host "Or run .\tools\refresh_app.ps1 -Force again when the device appears in flutter devices."
  }
  exit 0
}

if ($useAndroid) {
  if (-not (Test-FlutterRunAlive)) {
    if (-not (Start-DebugSession -SupabaseArgs $supabaseArgs)) { exit 1 }
    Write-Host "App is on device. Run again after code changes for fast hot refresh."
    exit 0
  }
  if (Send-HotCommand -Key $hotKey) { exit 0 }
  Write-Host "Hot refresh failed. Try .\tools\refresh_app.ps1 -Force"
  exit 1
}

# --- Web fallback ---
Stop-FlutterRun
$logWebOut = Join-Path $ProjectRoot "tools\flutter_web.out.log"
$logWebErr = Join-Path $ProjectRoot "tools\flutter_web.err.log"
if (Test-Path $logWebOut) { Remove-Item $logWebOut -Force -ErrorAction SilentlyContinue }
if (Test-Path $logWebErr) { Remove-Item $logWebErr -Force -ErrorAction SilentlyContinue }

Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }

$webArgs = @("run", "-d", "web-server", "--web-port=$Port", "--web-hostname=localhost") + $supabaseArgs
$proc = Start-Process -FilePath "flutter" `
  -ArgumentList $webArgs `
  -WorkingDirectory $ProjectRoot `
  -PassThru `
  -RedirectStandardOutput $logWebOut `
  -RedirectStandardError $logWebErr `
  -WindowStyle Hidden

$proc.Id | Set-Content $PidFile

$deadline = (Get-Date).AddMinutes(3)
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 2
  $log = ""
  if (Test-Path $logWebOut) { $log += Get-Content $logWebOut -Raw -ErrorAction SilentlyContinue }
  if (Test-Path $logWebErr) { $log += Get-Content $logWebErr -Raw -ErrorAction SilentlyContinue }
  if ($log -match "is being served at") {
    Start-Process $Url
    Write-Host "Phone not connected. App at $Url"
    exit 0
  }
  if ($log -match "Failed|Error:") {
    Write-Host $log
    exit 1
  }
}
Write-Host "Web server did not start in time."
exit 1
