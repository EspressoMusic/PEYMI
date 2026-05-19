# Starts the Stripe PaymentIntent server (requires server/.env with STRIPE_SECRET_KEY).
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ServerDir = Join-Path $ProjectRoot "server"

Set-Location $ServerDir
if (-not (Test-Path ".env")) {
  Write-Host "Create server/.env from server/.env.example and add your STRIPE_SECRET_KEY (sk_test_...)" -ForegroundColor Yellow
  exit 1
}

if (-not (Test-Path "node_modules")) {
  npm install
}

npm start
