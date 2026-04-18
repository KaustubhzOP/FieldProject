@echo off
title Smart Waste Collection - Setup and Build
color 0A

echo.
echo ============================================================
echo    SMART WASTE COLLECTION MONITORING SYSTEM
echo    Automated Setup and Build Script
echo ============================================================
echo.

:: Check Flutter
if not exist "frontend\android\app\google-services.json" (
    echo.
    echo FIREBASE SETUP REQUIRED:
    echo 1. Go to https://console.firebase.google.com/
    echo 2. Create project and download google-services.json
    echo 3. Place it in: frontend\android\app\google-services.json
    echo.
    echo MAPS API KEY REQUIRED:
    echo 1. Get key from Google Cloud Console
    echo 2. Edit: android\app\src\main\AndroidManifest.xml
    echo 3. Replace: YOUR_GOOGLE_MAPS_API_KEY_HERE
    echo.
    pause
)
echo.

:: Enter frontend folder
cd frontend

:: Install dependencies
echo [3/6] Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies!
    cd ..
    pause
    exit /b 1
)
echo Dependencies installed!
echo.

:: Clean build
echo [4/6] Cleaning build...
flutter clean
echo.

:: Build APK
echo [5/6] Building APK (3-5 minutes)...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo ERROR: Build failed! Check configuration.
    cd ..
    pause
    exit /b 1
)
cd ..
echo.

:: Success
echo [6/6] BUILD COMPLETE!
echo.
echo ============================================================
echo    APK READY!
echo ============================================================
echo.
echo Location: frontend\build\app\outputs\flutter-apk\app-debug.apk
echo.
echo To install on connected device, run: cd frontend ^&^& flutter install
echo.
echo Demo Credentials:
echo   Admin 1: admin1@smartwaste.com / 123456
echo   Admin 2: admin2@smartwaste.com / 123456
echo   Driver: driver1@smartwaste.com / Demo@123
echo   Resident: resident1@smartwaste.com / Demo@123
echo ============================================================
echo.
pause
