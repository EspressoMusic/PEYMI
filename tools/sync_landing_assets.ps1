# Copy canonical landing page from docs/ to hosting/bizmi/public/
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Join-Path $root "docs"
$dest = Join-Path $root "hosting\bizmi\public"

foreach ($name in @("landing.js", "index.html", "styles.css", "404.html")) {
    $from = Join-Path $src $name
    if (-not (Test-Path $from)) { continue }
    Copy-Item -Path $from -Destination (Join-Path $dest $name) -Force
    Write-Host "Synced $name"
}
