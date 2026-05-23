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
  "DEMO_STORE_SLUG"
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

$lines = foreach ($key in $allowedKeys) {
  if ($values.ContainsKey($key)) { "$key=$($values[$key])" }
}
$lines | Set-Content $outFile -Encoding utf8
Write-Output $outFile
