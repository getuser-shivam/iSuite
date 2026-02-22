# Flutter Setup Script for iSuite
Write-Host "Setting up Flutter for iSuite..." -ForegroundColor Green

# Check if Flutter is already installed
try {
    $flutterVersion = flutter --version 2>$null
    if ($flutterVersion) {
        Write-Host "Flutter is already installed:" -ForegroundColor Yellow
        Write-Host $flutterVersion
        exit 0
    }
} catch {
    Write-Host "Flutter not found in PATH, proceeding with installation..." -ForegroundColor Yellow
}

# Create tools directory
$toolsDir = Join-Path $PSScriptRoot "..\tools"
if (-not (Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
}

# Download Flutter SDK
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
$flutterZip = Join-Path $toolsDir "flutter_sdk.zip"
$flutterDir = Join-Path $toolsDir "flutter"

Write-Host "Downloading Flutter SDK..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -UseBasicParsing
    Write-Host "Download completed successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to download Flutter SDK. Please check your internet connection." -ForegroundColor Red
    exit 1
}

# Extract Flutter SDK
Write-Host "Extracting Flutter SDK..." -ForegroundColor Cyan
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($flutterZip, $toolsDir)
    Write-Host "Extraction completed successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to extract Flutter SDK. The downloaded file might be corrupted." -ForegroundColor Red
    exit 1
}

# Clean up zip file
Remove-Item $flutterZip -Force

# Add Flutter to PATH for current session
$env:PATH += ";$flutterDir\bin"

# Run Flutter doctor
Write-Host "Running Flutter doctor..." -ForegroundColor Cyan
flutter doctor

Write-Host "Flutter setup completed!" -ForegroundColor Green
Write-Host "Please add '$flutterDir\bin' to your system PATH environment variable for permanent access." -ForegroundColor Yellow
