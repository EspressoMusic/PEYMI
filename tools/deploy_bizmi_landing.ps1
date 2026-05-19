# Build config.js and deploy hosting/bizmi to Vercel (bizmi.app).
# Prereq: npm i -g vercel  (or npx vercel), and .env with Supabase keys.
# Usage: .\tools\deploy_bizmi_landing.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

& (Join-Path $root "tools\generate_peymii_config.ps1")

# Legacy script — landing now lives in docs/ for GitHub Pages.
$hosting = Join-Path $root "docs"
Push-Location $hosting
try {
    Write-Host "Deploying from $hosting ..."
    npx --yes vercel deploy --prod
}
finally {
    Pop-Location
}
