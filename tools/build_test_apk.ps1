# Build Android test APK and copy to release/ for GitHub Releases upload.
# Usage: .\tools\build_test_apk.ps1

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

$defines = @()
if ($url -and $anon -and $anon -notmatch "your_anon") {
    $defines += "--dart-define=SUPABASE_URL=$url"
    $defines += "--dart-define=SUPABASE_ANON_KEY=$anon"
    $defines += "--dart-define=PUBLIC_STORE_BASE_URL=$publicBase"
    Write-Host "Building with Supabase + PUBLIC_STORE_BASE_URL from .env"
} else {
    Write-Host "Building without Supabase (add .env for full app)"
}

$buildArgs = @("build", "apk", "--debug") + $defines
& flutter @buildArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$src = Join-Path $root "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $src)) {
    Write-Error "APK not found: $src"
}

$outDir = Join-Path $root "release"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$dest = Join-Path $outDir "bizmi-test.apk"
Copy-Item $src $dest -Force

$sizeMb = [math]::Round((Get-Item $dest).Length / 1MB, 1)
Write-Host ""
Write-Host "APK ready:" -ForegroundColor Green
Write-Host "  Source:  $src"
Write-Host "  Upload:  $dest"
Write-Host "  Size:    ${sizeMb} MB"
Write-Host ""
Write-Host "Next: GitHub -> PEYMI -> Releases -> upload bizmi-test.apk"
Write-Host "Then set apkDownloadUrl in docs/config.js on GitHub."
