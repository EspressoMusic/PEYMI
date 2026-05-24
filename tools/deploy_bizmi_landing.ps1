# Build config.js, sync landing assets, deploy hosting/bizmi to Vercel (bizmi.app).
# Prereq: npm / npx, .env with Supabase keys, Vercel CLI logged in.
# Usage: .\tools\deploy_bizmi_landing.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

& (Join-Path $root "tools\sync_landing_assets.ps1")
& (Join-Path $root "tools\generate_bizmi_config.ps1")

$hosting = Join-Path $root "hosting\bizmi"
Push-Location $hosting
try {
    Write-Host "Deploying bizmi.app from $hosting ..."
    npx --yes vercel deploy --prod
}
finally {
    Pop-Location
}
