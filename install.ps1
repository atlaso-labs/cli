# Atlaso installer — Windows (PowerShell).
#   irm https://atlaso.ai/install.ps1 | iex
# From CMD:  powershell -ExecutionPolicy Bypass -c "irm https://atlaso.ai/install.ps1 | iex"
#
# Mirrors install.sh: download the standalone binary → %USERPROFILE%\.atlaso\bin
# → user PATH → hand off to `atlaso connect`. Idempotent — re-running updates in
# place. Env overrides: ATLASO_INSTALL_URL, ATLASO_NO_CONNECT.
$ErrorActionPreference = "Stop"

function Step($msg)  { Write-Host "o  $msg" -ForegroundColor Green }
function Fail($msg)  { Write-Host "x  $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "*  Atlaso" -ForegroundColor White
Write-Host "|"

# ── 1. platform ────────────────────────────────────────────────────────────────
$arch = $env:PROCESSOR_ARCHITECTURE
if ($arch -ne "AMD64" -and $arch -ne "ARM64") { Fail "Unsupported architecture: $arch" }
# bun ships windows x64; ARM64 Windows runs it via emulation
$target = "atlaso-windows-x64.exe"
Step "Detected Windows ($arch)"

# ── 2. download ────────────────────────────────────────────────────────────────
$base = if ($env:ATLASO_INSTALL_URL) { $env:ATLASO_INSTALL_URL } else {
  "https://github.com/atlaso-labs/cli/releases/latest/download"
}
$binDir = Join-Path $env:USERPROFILE ".atlaso\bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
$exe = Join-Path $binDir "atlaso.exe"
try {
  Invoke-WebRequest -Uri "$base/$target" -OutFile $exe -UseBasicParsing
} catch {
  Fail "Download failed - check your connection and retry"
}
$version = & $exe --version 2>$null
Step "Downloaded atlaso v$version"
Step "Installed to ~\.atlaso\bin"

# ── 3. PATH (user scope, idempotent) ───────────────────────────────────────────
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*\.atlaso\bin*") {
  [Environment]::SetEnvironmentVariable("Path", "$binDir;$userPath", "User")
}
$env:Path = "$binDir;$env:Path"
Step "Added to PATH (new terminals pick it up automatically)"
Write-Host "|"

# ── 4. hand off to the binary — connect opens the browser ─────────────────────
if ($env:ATLASO_NO_CONNECT) {
  Write-Host "+  Run 'atlaso connect' to link this device."
  exit 0
}
$env:ATLASO_FROM_INSTALLER = "1"
& $exe connect
