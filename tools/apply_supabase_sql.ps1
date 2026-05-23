# Apply a SQL file to the linked Supabase project (remote).
# Requires ONE of:
#   SUPABASE_ACCESS_TOKEN in .env  (https://supabase.com/dashboard/account/tokens)
#   SUPABASE_DB_PASSWORD in .env    (Project Settings → Database → password)
#
# Usage:
#   .\tools\apply_supabase_sql.ps1
#   .\tools\apply_supabase_sql.ps1 -SqlFile supabase\migrations\20260520120000_business_store_terms.sql

param(
  [string]$SqlFile = (Join-Path (Split-Path -Parent $PSScriptRoot) "supabase\APPLY_STORE_TERMS.sql")
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root ".env"
if (-not (Test-Path $envFile)) { throw ".env not found at $envFile" }

$url = $null
$accessToken = $null
$dbPassword = $null
foreach ($line in Get-Content $envFile) {
  $t = $line.Trim()
  if ($t -eq '' -or $t.StartsWith('#')) { continue }
  if ($t -match '^SUPABASE_URL=(.+)$') { $url = $Matches[1].Trim().Trim('"').Trim("'") }
  if ($t -match '^SUPABASE_ACCESS_TOKEN=(.+)$') { $accessToken = $Matches[1].Trim().Trim('"').Trim("'") }
  if ($t -match '^SUPABASE_DB_PASSWORD=(.+)$') { $dbPassword = $Matches[1].Trim().Trim('"').Trim("'") }
}

if (-not $url) { throw "SUPABASE_URL missing in .env" }
$ref = ($url -replace '^https://', '' -replace '\.supabase\.co.*$', '').Trim()
if ($ref -eq '') { throw "Could not parse project ref from SUPABASE_URL" }

$sql = Get-Content $SqlFile -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($sql)) { throw "SQL file is empty: $SqlFile" }

Write-Host "Project: $ref"
Write-Host "SQL file: $SqlFile"

function Test-StoreTermsColumn {
  param([string]$BaseUrl, [string]$AnonKey)
  $headers = @{ apikey = $AnonKey; Authorization = "Bearer $AnonKey" }
  try {
    Invoke-RestMethod -Uri "$BaseUrl/rest/v1/businesses?select=store_terms&limit=1" -Headers $headers -Method Get | Out-Null
    return $true
  } catch {
    return $false
  }
}

# Already applied?
$anon = $null
foreach ($line in Get-Content $envFile) {
  if ($line -match '^SUPABASE_ANON_KEY=(.+)$') { $anon = $Matches[1].Trim().Trim('"').Trim("'") }
}
if ($anon -and (Test-StoreTermsColumn -BaseUrl $url -AnonKey $anon)) {
  Write-Host "OK: businesses.store_terms already exists."
  exit 0
}

if ($accessToken -and $accessToken -notmatch 'your_|paste|replace') {
  Write-Host "Applying via Supabase Management API..."
  $body = @{ query = $sql } | ConvertTo-Json -Compress
  Invoke-RestMethod `
    -Uri "https://api.supabase.com/v1/projects/$ref/database/query" `
    -Method Post `
    -Body $body `
    -ContentType "application/json" `
    -Headers @{ Authorization = "Bearer $accessToken" } | Out-Null
  Write-Host "Management API: query executed."
}
elseif ($dbPassword -and $dbPassword -notmatch 'your_|paste|replace') {
  Write-Host "Applying via Supabase CLI (db execute)..."
  $tmp = [System.IO.Path]::GetTempFileName() + ".sql"
  Set-Content -Path $tmp -Value $sql -Encoding UTF8
  try {
    Push-Location $root
    npx --yes supabase db execute --file $tmp --linked 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) {
      npx --yes supabase link --project-ref $ref --password $dbPassword --yes 2>&1 | ForEach-Object { Write-Host $_ }
      npx --yes supabase db execute --file $tmp --linked 2>&1 | ForEach-Object { Write-Host $_ }
    }
  } finally {
    Pop-Location
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  }
}
else {
  Write-Host ""
  Write-Host "Cannot apply migration automatically."
  Write-Host "Add to .env ONE of:"
  Write-Host "  SUPABASE_ACCESS_TOKEN=sbp_...   (Dashboard -> Account -> Access Tokens)"
  Write-Host "  SUPABASE_DB_PASSWORD=...        (Dashboard -> Project Settings -> Database)"
  Write-Host "Then run: .\tools\apply_supabase_sql.ps1"
  Write-Host ""
  Write-Host "Or paste SQL manually:"
  Write-Host "  https://supabase.com/dashboard/project/$ref/sql/new"
  Write-Host "  File: supabase\APPLY_STORE_TERMS.sql"
  exit 1
}

if ($anon) {
  Start-Sleep -Seconds 1
  if (Test-StoreTermsColumn -BaseUrl $url -AnonKey $anon) {
    Write-Host "Verified: businesses.store_terms exists."
    exit 0
  }
  Write-Host "Warning: query ran but column still not visible via REST (wait a few seconds and retry)."
  exit 1
}

Write-Host "Done (no anon key to verify)."
exit 0
