@echo off
echo Starting Smart Waste Collection - Web Dashboard...
set FLUTTER_BIN=C:\Users\Adhyatmika\flutter\bin\flutter.bat

if not exist "%FLUTTER_BIN%" (
    echo ERROR: Flutter not found at %FLUTTER_BIN%
    pause
    exit /b 1
)

cd frontend
echo [1/2] Fetching dependencies...
call "%FLUTTER_BIN%" pub get

echo [2/2] Launching Web App on port 8082...
call "%FLUTTER_BIN%" run -d chrome --web-port 8082
pause
