# Writes .dart_defines.env from .env (Flutter-safe keys only — no service_role / server secrets).
param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
$envFile = Join-Path $ProjectRoot ".env"
$outFile = Join-Path $ProjectRoot ".dart_defines.env"

# Keys that may be passed to Flutter via --dart-define-from-file.
$allowedKeys = @(
  "SUPABASE_URL",
  "SUPABASE_ANON_KEY",
  "PUBLIC_STORE_BASE_URL",
  "MANAGER_PIN",
  "EMPLOYEE_PIN",
  "STRIPE_PUBLISHABLE_KEY",
  "STRIPE_BACKEND_URL",
  "POLICY_VIDEO_URL",
  "LEGAL_ACCESSIBILITY_EMAIL",
  "LEGAL_OPERATOR_EMAIL",
  "LEGAL_ACCESSIBILITY_STATEMENT_URL",
  "DEMO_STORE_SLUG",
  "FIREBASE_PROJECT_ID",
  "FIREBASE_ANDROID_API_KEY",
  "FIREBASE_ANDROID_APP_ID",
  "FIREBASE_MESSAGING_SENDER_ID"
)

if (-not (Test-Path $envFile)) {
  if (Test-Path $outFile) { Remove-Item $outFile -Force }
  Write-Output ""
  exit 0
}

$values = @{}
foreach ($line in Get-Content $envFile) {
  $t = $line.Trim()
  if ($t -eq '' -or $t.StartsWith('#')) { continue }
  if ($t -notmatch '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') { continue }
  $key = $Matches[1]
  if ($allowedKeys -notcontains $key) { continue }
  $val = $Matches[2].Trim().Trim('"').Trim("'")
  if ([string]::IsNullOrWhiteSpace($val)) { continue }
  if ($key -eq 'SUPABASE_ANON_KEY' -and $val -match 'your_anon|paste|replace|PASTE') { continue }
  $values[$key] = $val
}

if (-not $values.ContainsKey('SUPABASE_URL') -or -not $values.ContainsKey('SUPABASE_ANON_KEY')) {
  if (Test-Path $outFile) { Remove-Item $outFile -Force }
  Write-Output ""
  exit 0
}

$lines = @(
  foreach ($key in $allowedKeys) {
    if ($values.ContainsKey($key)) { "$key=$($values[$key])" }
  }
)
# UTF-8 without BOM — BOM breaks Flutter --dart-define-from-file on the first key.
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($outFile, $lines, $utf8NoBom)

$embeddedPath = Join-Path $ProjectRoot "lib\core\supabase\supabase_embedded.dart"
$urlEsc = ($values['SUPABASE_URL'] -replace '\\', '\\\\' -replace "'", "\'")
$anonEsc = ($values['SUPABASE_ANON_KEY'] -replace '\\', '\\\\' -replace "'", "\'")
$embedded = @"
// Generated from .env by tools/sync_dart_defines.ps1 — do not edit manually.
abstract final class SupabaseEmbedded {
  static const url = '$urlEsc';
  static const anonKey = '$anonEsc';
}
"@
[System.IO.File]::WriteAllText($embeddedPath, $embedded, $utf8NoBom)
Write-Host "Wrote Supabase embed: $embeddedPath"

Write-Output $outFile
