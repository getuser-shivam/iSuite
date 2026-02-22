# Flutter Windows Build and Run Script for iSuite
param(
    [switch]$Setup,
    [switch]$Clean,
    [switch]$Release
)

$projectRoot = Split-Path $PSScriptRoot -Parent
$flutterPath = Join-Path $projectRoot "tools\flutter\bin\flutter.exe"

Write-Host "iSuite Flutter Windows Runner" -ForegroundColor Green
Write-Host "Project Root: $projectRoot" -ForegroundColor Cyan

# Setup Flutter if requested
if ($Setup) {
    Write-Host "Running Flutter setup..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot "setup_flutter.ps1")
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Flutter setup failed!" -ForegroundColor Red
        exit 1
    }
}

# Check if Flutter exists
if (-not (Test-Path $flutterPath)) {
    Write-Host "Flutter not found at $flutterPath" -ForegroundColor Red
    Write-Host "Please run with -Setup flag first, or install Flutter manually." -ForegroundColor Yellow
    exit 1
}

# Set Flutter to PATH for this session
$env:PATH += ";$(Split-Path $flutterPath -Parent)"

# Clean build if requested
if ($Clean) {
    Write-Host "Cleaning build files..." -ForegroundColor Yellow
    & $flutterPath clean
}

# Get dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Cyan
& $flutterPath pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to get dependencies!" -ForegroundColor Red
    exit 1
}

# Build configuration
$buildArgs = @("run", "-d", "windows")
if ($Release) {
    $buildArgs += "--release"
}

# Build and run
Write-Host "Building and running iSuite for Windows..." -ForegroundColor Cyan
Write-Host "Command: flutter $($buildArgs -join ' ')" -ForegroundColor Gray

& $flutterPath $buildArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "iSuite is running successfully!" -ForegroundColor Green
} else {
    Write-Host "Failed to run iSuite!" -ForegroundColor Red
    exit 1
}
