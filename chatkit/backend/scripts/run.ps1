$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $ProjectRoot

if (-not (Test-Path ".venv")) {
  Write-Host "Creating virtual env in $ProjectRoot\.venv ..."
  python -m venv .venv
}

$activate = Join-Path $ProjectRoot ".venv\Scripts\Activate.ps1"
if (-not (Test-Path $activate)) {
  throw "Virtual env activation script not found at $activate"
}
. $activate

Write-Host "Installing backend deps (editable) ..."
python -m pip install -e . | Out-Null

# Load env vars from the repo's .env.local (if present) so OPENAI_API_KEY
# does not need to be exported manually.
$envFile = Resolve-Path (Join-Path $ProjectRoot "..\.env.local") -ErrorAction SilentlyContinue
if (-not $env:OPENAI_API_KEY -and $envFile) {
  Write-Host "Sourcing OPENAI_API_KEY from $envFile"
  Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith("#")) { return }
    $idx = $line.IndexOf("=")
    if ($idx -lt 1) { return }
    $key = $line.Substring(0, $idx).Trim()
    $val = $line.Substring($idx + 1)
    if ($key) { Set-Item -Path "Env:$key" -Value $val }
  }
}

if (-not $env:OPENAI_API_KEY) {
  throw "Set OPENAI_API_KEY in your environment or in .env.local before running this script."
}

$env:PYTHONPATH = "$ProjectRoot" + ($(if ($env:PYTHONPATH) { ";$($env:PYTHONPATH)" } else { "" }))

Write-Host "Starting ChatKit backend on http://127.0.0.1:8000 ..."
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

