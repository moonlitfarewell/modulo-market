$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$capturesRoot = Join-Path $root 'captures'
$script = Join-Path $root 'tools\foreverdb_importer\market_data_importer.py'

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host 'Python 3.10 or newer was not found. Install Python from https://www.python.org/downloads/windows/.' -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 2
}
$versionText = (& python --version 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $versionText -notmatch 'Python\s+(\d+)\.(\d+)') {
    Write-Host 'Could not determine the Python version.' -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 2
}
if ([int]$Matches[1] -lt 3 -or ([int]$Matches[1] -eq 3 -and [int]$Matches[2] -lt 10)) {
    Write-Host "Found $versionText. Python 3.10 or newer is required." -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 2
}
if (-not (Test-Path $capturesRoot)) {
    Write-Host 'No captures folder exists yet. Run Start-Capture.cmd first.' -ForegroundColor Yellow
    Read-Host 'Press Enter to close'
    exit 1
}
$capture = Get-ChildItem -LiteralPath $capturesRoot -Directory -Filter 'capture-*' |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $capture) {
    Write-Host 'No capture folder exists yet. Run Start-Capture.cmd first.' -ForegroundColor Yellow
    Read-Host 'Press Enter to close'
    exit 1
}
$outputRoot = Join-Path $root 'normalized'
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
$output = Join-Path $outputRoot ($capture.Name + '-canonical.json')
Write-Host "Normalizing $($capture.FullName)" -ForegroundColor Cyan
Write-Host 'This verifies hashes and maps only the reviewed ForeverDB response shape.'
Push-Location $root
try {
    & python $script normalize-capture $capture.FullName --output $output
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}
Write-Host ''
if ($exitCode -eq 0) {
    Write-Host "Canonical data written to: $output" -ForegroundColor Green
    Write-Host 'Next developer step: validate and compile-runtime after source review.'
}
else {
    Write-Host 'Normalization failed. The capture was not changed.' -ForegroundColor Red
}
Read-Host 'Press Enter to close'
exit $exitCode
