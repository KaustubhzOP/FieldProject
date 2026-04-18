# Install Android SDK Command-line Tools
Write-Host "Installing Android SDK Command-line Tools..." -ForegroundColor Cyan
Write-Host ""

$toolsPath = "C:\Android\sdk\cmdline-tools"
$zipFile = "$env:TEMP\commandlinetools.zip"
$downloadUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"

# Create directory
if (-not (Test-Path $toolsPath)) {
    New-Item -ItemType Directory -Path $toolsPath -Force | Out-Null
}

# Download
Write-Host "[1/4] Downloading command-line tools..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile
    Write-Host "  Download complete!" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Download failed. Check internet connection." -ForegroundColor Red
    pause
    exit
}
Write-Host ""

# Extract
Write-Host "[2/4] Extracting tools..." -ForegroundColor Yellow
$extractPath = "$env:TEMP\cmdline-tools-extract"
if (Test-Path $extractPath) {
    Remove-Item $extractPath -Recurse -Force
}
Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
Write-Host "  Extracted!" -ForegroundColor Green
Write-Host ""

# Move to correct location
Write-Host "[3/4] Installing to SDK folder..." -ForegroundColor Yellow
$tempLatest = "$extractPath\cmdline-tools"
$finalPath = "$toolsPath\latest"

if (Test-Path $finalPath) {
    Remove-Item $finalPath -Recurse -Force
}

Move-Item -Path $tempLatest -Destination $finalPath -Force
Write-Host "  Installed to: $finalPath" -ForegroundColor Green
Write-Host ""

# Clean up
Write-Host "[4/4] Cleaning up..." -ForegroundColor Yellow
Remove-Item $zipFile -Force
Remove-Item $extractPath -Recurse -Force
Write-Host "  Cleaned!" -ForegroundColor Green
Write-Host ""

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Command-line Tools Installed!" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Now accepting Android licenses..." -ForegroundColor Yellow
Write-Host ""

# Accept licenses
& "$finalPath\bin\sdkmanager.bat" --licenses

Write-Host ""
Write-Host "Done! Close this window and run: flutter doctor" -ForegroundColor Green
Write-Host ""
pause
