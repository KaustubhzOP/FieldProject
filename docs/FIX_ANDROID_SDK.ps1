# Smart Waste Collection - Android SDK Path Fix Script
# This script automatically moves Android SDK to a space-free path

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Android SDK Path Fix - Automated Script" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create C:\Android folder
Write-Host "[1/5] Creating C:\Android folder..." -ForegroundColor Yellow
if (Test-Path "C:\Android") {
    Write-Host "  Folder already exists: C:\Android" -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Path "C:\Android" -Force | Out-Null
    Write-Host "  Created: C:\Android" -ForegroundColor Green
}
Write-Host ""

# Step 2: Find current SDK location
Write-Host "[2/5] Finding current Android SDK..." -ForegroundColor Yellow
$oldSdkPath = "$env:LOCALAPPDATA\Android\sdk"
$newSdkPath = "C:\Android\sdk"

if (Test-Path $oldSdkPath) {
    Write-Host "  Found SDK at: $oldSdkPath" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Cannot find Android SDK at $oldSdkPath" -ForegroundColor Red
    Write-Host "  Please install Android Studio first!" -ForegroundColor Red
    pause
    exit
}
Write-Host ""

# Step 3: Move SDK files
Write-Host "[3/5] Moving SDK to C:\Android\sdk..." -ForegroundColor Yellow
Write-Host "  This may take 2-3 minutes..." -ForegroundColor Yellow

if (Test-Path $newSdkPath) {
    Write-Host "  SDK already exists at new location, skipping copy..." -ForegroundColor Green
} else {
    try {
        Copy-Item -Path $oldSdkPath -Destination "C:\Android" -Recurse -Force
        Write-Host "  SDK moved successfully!" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to copy SDK files" -ForegroundColor Red
        Write-Host "  Try running this script as Administrator" -ForegroundColor Red
        pause
        exit
    }
}
Write-Host ""

# Step 4: Set environment variable
Write-Host "[4/5] Setting ANDROID_HOME environment variable..." -ForegroundColor Yellow

# Set user environment variable
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $newSdkPath, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $newSdkPath, "User")

Write-Host "  Set ANDROID_HOME = $newSdkPath" -ForegroundColor Green
Write-Host "  Set ANDROID_SDK_ROOT = $newSdkPath" -ForegroundColor Green
Write-Host ""
Write-Host "  NOTE: You may need to restart your terminal for this to take effect!" -ForegroundColor Yellow
Write-Host ""

# Step 5: Configure Flutter
Write-Host "[5/5] Configuring Flutter to use new SDK path..." -ForegroundColor Yellow

$env:ANDROID_HOME = $newSdkPath
$env:ANDROID_SDK_ROOT = $newSdkPath

& flutter config --android-sdk $newSdkPath

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE!" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. CLOSE this Command Prompt window" -ForegroundColor White
Write-Host "2. Open a NEW Command Prompt" -ForegroundColor White
Write-Host "3. Run: flutter doctor" -ForegroundColor White
Write-Host "4. Run: flutter doctor --android-licenses" -ForegroundColor White
Write-Host "5. Type 'y' to accept all licenses" -ForegroundColor White
Write-Host ""
Write-Host "Then you can proceed to Firebase setup!" -ForegroundColor Green
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan

pause
