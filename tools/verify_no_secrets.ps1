# Fails if tracked files look like they contain secrets (run before push).
# Usage: .\tools\verify_no_secrets.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$fail = $false

$trackedEnv = git ls-files .env .env.local .env.production 2>$null
if ($trackedEnv) {
  Write-Host "FAIL: .env file(s) tracked in git:" -ForegroundColor Red
  $trackedEnv | ForEach-Object { Write-Host "  $_" }
  $fail = $true
}

$trackedConfig = git ls-files docs/config.js hosting/bizmi/public/config.js 2>$null
if ($trackedConfig) {
  Write-Host "FAIL: generated config.js tracked in git (remove with git rm --cached):" -ForegroundColor Red
  $trackedConfig | ForEach-Object { Write-Host "  $_" }
  $fail = $true
}

# Literal secret values / hardcoded credentials (not env var names in docs).
$valuePatterns = @(
  'sk_live_[0-9a-zA-Z]{8,}',
  'sk_test_[0-9a-zA-Z]{8,}',
  'SUPABASE_SERVICE_ROLE_KEY\s*=\s*eyJ',
  'TWILIO_AUTH_TOKEN\s*=\s*[0-9a-f]{8,}',
  'STRIPE_SECRET_KEY\s*=\s*sk_',
  "creatorPassword\s*=\s*'[^']+'",
  "_managerPassword\s*=\s*'[^']+'",
  'Shilo2001'
)

$files = git ls-files '*.dart' '*.ts' '*.js' '*.json' '*.ps1' '*.yaml' '*.yml' 2>$null
foreach ($file in $files) {
  if ($file -match '^tools/') { continue }
  if ($file -match '^server/|^supabase/functions/') { continue }
  $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
  if (-not $content) { continue }
  foreach ($pat in $valuePatterns) {
    if ($content -match $pat) {
      Write-Host "FAIL: suspicious value pattern '$pat' in $file" -ForegroundColor Red
      $fail = $true
      break
    }
  }
}

if ($fail) { exit 1 }
Write-Host "OK: no obvious secrets in tracked files." -ForegroundColor Green
