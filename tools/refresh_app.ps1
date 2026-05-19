# Restarts the Flutter app on a connected Android phone (preferred) or web fallback.
# Usage: .\tools\refresh_app.ps1          — hot restart via flutter run
#        .\tools\refresh_app.ps1 -Force  — clean build, reinstall APK, launch
#
# Supabase: create .env in project root (see .env.example) with SUPABASE_URL + SUPABASE_ANON_KEY.
param([switch]$Force)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Port = 7357
$Url = "http://localhost:$Port"
$PidFile = Join-Path $ProjectRoot ".flutter_run.pid"
$DeviceId = "RZCYA1S0LGL"
$Package = "com.example.bakery_shop_app"

function Stop-FlutterRun {
  if (Test-Path $PidFile) {
    $oldPid = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($oldPid -match '^\d+$') {
      Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
  }
}

function Get-SupabaseDartDefineArgs {
  param([string]$Root)
  $envFile = Join-Path $Root ".env"
  if (-not (Test-Path $envFile)) { return @() }

  $url = $null
  $anon = $null
  $publicBase = $null
  foreach ($line in Get-Content $envFile) {
    $t = $line.Trim()
    if ($t -eq '' -or $t.StartsWith('#')) { continue }
    if ($t -match '^SUPABASE_URL=(.+)$') { $url = $Matches[1].Trim().Trim('"').Trim("'") }
    if ($t -match '^SUPABASE_ANON_KEY=(.+)$') { $anon = $Matches[1].Trim().Trim('"').Trim("'") }
    if ($t -match '^PUBLIC_STORE_BASE_URL=(.+)$') { $publicBase = $Matches[1].Trim().Trim('"').Trim("'") }
  }

  if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($anon)) { return @() }
  if ($anon -match 'your_anon|paste|replace|PASTE') { return @() }

  $defines = @(
    "--dart-define=SUPABASE_URL=$url",
    "--dart-define=SUPABASE_ANON_KEY=$anon"
  )
  if (-not [string]::IsNullOrWhiteSpace($publicBase)) {
    $defines += "--dart-define=PUBLIC_STORE_BASE_URL=$publicBase"
  }
  return $defines
}

Set-Location $ProjectRoot
Stop-FlutterRun

$supabaseArgs = Get-SupabaseDartDefineArgs -Root $ProjectRoot
if ($supabaseArgs.Count -gt 0) {
  Write-Host "Supabase: using SUPABASE_URL + ANON_KEY from .env"
} else {
  Write-Host "Supabase: not configured - add SUPABASE_ANON_KEY to .env for Create Store in Settings"
}

$devices = flutter devices 2>&1 | Out-String
$useAndroid = $devices -match $DeviceId

if ($useAndroid -and $Force) {
  Write-Host "Force refresh: clean build + reinstall on $DeviceId..."
  flutter clean | Out-Host
  flutter pub get | Out-Host
  $buildArgs = @("build", "apk", "--debug") + $supabaseArgs
  & flutter @buildArgs | Out-Host
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  adb -s $DeviceId shell am force-stop $Package 2>$null
  adb -s $DeviceId uninstall $Package 2>$null
  adb -s $DeviceId install -r (Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-debug.apk") | Out-Host
  adb -s $DeviceId shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n "$Package/.MainActivity" | Out-Host
  Write-Host "Force refresh done. App opened on phone ($DeviceId)."
  exit 0
}

if ($useAndroid) {
  $logOut = Join-Path $ProjectRoot "tools\flutter_run.out.log"
  $logErr = Join-Path $ProjectRoot "tools\flutter_run.err.log"
  $runArgs = @("run", "-d", $DeviceId) + $supabaseArgs
  $proc = Start-Process -FilePath "flutter" `
    -ArgumentList $runArgs `
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
$webArgs = @("run", "-d", "web-server", "--web-port=$Port", "--web-hostname=localhost") + $supabaseArgs
$proc = Start-Process -FilePath "flutter" `
  -ArgumentList $webArgs `
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
