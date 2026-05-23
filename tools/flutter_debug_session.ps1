# Long-running debug session: flutter run + hot reload/restart via .flutter_hot_cmd
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

$SupabaseArgs = @()
if ($env:PEYMI_DART_DEFINES) {
  $SupabaseArgs = $env:PEYMI_DART_DEFINES -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}
$PidFile = Join-Path $ProjectRoot ".flutter_run.pid"
$CmdFile = Join-Path $ProjectRoot ".flutter_hot_cmd"
$LogOut = Join-Path $ProjectRoot "tools\flutter_run.out.log"
$LogErr = Join-Path $ProjectRoot "tools\flutter_run.err.log"
$VmUrlFile = Join-Path $ProjectRoot ".flutter_vm_url"
$DeviceId = "RZCYA1S0LGL"

Set-Location $ProjectRoot
if (Test-Path $LogOut) { Remove-Item $LogOut -Force -ErrorAction SilentlyContinue }
if (Test-Path $LogErr) { Remove-Item $LogErr -Force -ErrorAction SilentlyContinue }
"" | Set-Content $CmdFile -Encoding utf8 -NoNewline

$flutterExe = (Get-Command flutter -ErrorAction Stop).Source
$runArgs = @("run", "-d", $DeviceId) + $SupabaseArgs
$argLine = ($runArgs | ForEach-Object {
  if ($_ -match '\s') { "`"$_`"" } else { $_ }
}) -join ' '

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $flutterExe
$psi.Arguments = $argLine
$psi.WorkingDirectory = $ProjectRoot
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true

$proc = [System.Diagnostics.Process]::Start($psi)
$proc.Id | Set-Content $PidFile

$ready = $false
$stdoutDone = $false
$stderrDone = $false

$outAction = {
  param($line)
  Add-Content -Path $LogOut -Value $line -Encoding utf8
  if ($line -match 'Dart VM Service on .+ is available at:\s*(http://127\.0\.0\.1:\d+/[A-Za-z0-9_=\-/]+)') {
    $Matches[1].Trim() | Set-Content $VmUrlFile -Encoding utf8 -NoNewline
  }
  if ($line -match 'Flutter run key commands') { $script:ready = $true }
}
$errAction = {
  param($line)
  Add-Content -Path $LogErr -Value $line -Encoding utf8
}

$proc.add_OutputDataReceived({ param($s, $e) if ($e.Data) { & $outAction $e.Data } })
$proc.add_ErrorDataReceived({ param($s, $e) if ($e.Data) { & $errAction $e.Data } })
$proc.BeginOutputReadLine()
$proc.BeginErrorReadLine()

while (-not $proc.HasExited) {
  Start-Sleep -Milliseconds 200
  if (Test-Path $CmdFile) {
    $raw = Get-Content $CmdFile -Raw -ErrorAction SilentlyContinue
    $cmd = if ($null -eq $raw) { '' } else { $raw.Trim() }
    if ($cmd -match '^[rRq]$') {
      try { $proc.StandardInput.WriteLine($cmd) } catch {}
      "" | Set-Content $CmdFile -Encoding utf8 -NoNewline
    }
  }
}

try { $proc.WaitForExit() } catch {}
Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
