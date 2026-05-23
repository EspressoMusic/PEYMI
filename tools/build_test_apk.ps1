# Build Android APK for pilot testing and copy to release/.
# Default: obfuscated RELEASE (pilot). Use -Debug for fast debug APK.
#
# Usage:
#   .\tools\build_test_apk.ps1
#   .\tools\build_test_apk.ps1 -Debug

param(
  [switch]$Debug
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

function Get-EnvValue([string]$name) {
  $envFile = Join-Path $root ".env"
  if (-not (Test-Path $envFile)) { return $null }
  foreach ($line in Get-Content $envFile) {
    if ($line -match "^\s*#") { continue }
    if ($line -match "^\s*$name\s*=\s*(.+)\s*$") {
      return $Matches[1].Trim().Trim('"').Trim("'")
    }
  }
  return $null
}

$url = Get-EnvValue "SUPABASE_URL"
$anon = Get-EnvValue "SUPABASE_ANON_KEY"
$publicBase = Get-EnvValue "PUBLIC_STORE_BASE_URL"
if (-not $publicBase) { $publicBase = "https://espressomusic.github.io/PEYMI" }

$managerPin = Get-EnvValue "MANAGER_PIN"
$employeePin = Get-EnvValue "EMPLOYEE_PIN"

$defines = @()
if ($url -and $anon -and $anon -notmatch "your_anon") {
  $defines += "--dart-define=SUPABASE_URL=$url"
  $defines += "--dart-define=SUPABASE_ANON_KEY=$anon"
  $defines += "--dart-define=PUBLIC_STORE_BASE_URL=$publicBase"
  Write-Host "Dart-defines: Supabase + PUBLIC_STORE_BASE_URL"
}
if ($managerPin) {
  $defines += "--dart-define=MANAGER_PIN=$managerPin"
  Write-Host "Dart-define: MANAGER_PIN set"
}
if ($employeePin) {
  $defines += "--dart-define=EMPLOYEE_PIN=$employeePin"
  Write-Host "Dart-define: EMPLOYEE_PIN set"
}

$debugInfoDir = Join-Path $root "build\debug-info"
if (-not $Debug) {
  New-Item -ItemType Directory -Force -Path $debugInfoDir | Out-Null
}

if ($Debug) {
  Write-Host "Building DEBUG APK (no obfuscation)..."
  $buildArgs = @("build", "apk", "--debug") + $defines
  $apkName = "app-debug.apk"
  $outName = "bizmi-test-debug.apk"
} else {
  Write-Host "Building RELEASE APK (obfuscated)..."
  $buildArgs = @(
    "build", "apk", "--release",
    "--obfuscate",
    "--split-debug-info=$debugInfoDir"
  ) + $defines
  $apkName = "app-release.apk"
  $outName = "bizmi-pilot-release.apk"
}

& flutter @buildArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$src = Join-Path $root "build\app\outputs\flutter-apk\$apkName"
if (-not (Test-Path $src)) {
  Write-Error "APK not found: $src"
}

$outDir = Join-Path $root "release"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$dest = Join-Path $outDir $outName
Copy-Item $src $dest -Force

$sizeMb = [math]::Round((Get-Item $dest).Length / 1MB, 1)
Write-Host ""
Write-Host "APK ready:" -ForegroundColor Green
Write-Host "  Source:  $src"
Write-Host "  Upload:  $dest"
Write-Host "  Size:    ${sizeMb} MB"
if (-not $Debug) {
  Write-Host "  Symbols: $debugInfoDir (keep private — do not commit)"
}
Write-Host ""
Write-Host "Next: upload $outName to GitHub Releases or distribute to pilot testers."
