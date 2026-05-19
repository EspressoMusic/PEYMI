# Example: run app on phone with Stripe keys (replace with your test keys and PC IP).
param(
  [Parameter(Mandatory = $true)][string]$PublishableKey,
  [Parameter(Mandatory = $true)][string]$BackendUrl
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

flutter run `
  --dart-define=STRIPE_PUBLISHABLE_KEY=$PublishableKey `
  --dart-define=STRIPE_BACKEND_URL=$BackendUrl
