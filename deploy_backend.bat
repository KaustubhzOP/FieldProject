@echo off
setlocal
echo ==================================================
echo   Smart Waste - Real Email Deployment Helper
echo ==================================================
echo.
echo PREREQUISITE:
echo You MUST run [npx -p firebase-tools firebase login] 
echo manually in your terminal before running this script.
echo.
echo SMTP REQUIREMENT:
echo You MUST use a 16-character 'App Password'.
echo Your regular Gmail password will NOT work.
echo.

set /p EMAIL="Enter Sender Email (e.g. user@gmail.com): "
set /p PASS="Enter 16-character App Password (no spaces): "

echo.
echo [1/3] Configuring Firebase Environment...
call npx -p firebase-tools firebase functions:config:set email.user="%EMAIL%" email.pass="%PASS%" --non-interactive

echo.
echo [2/3] Installing Backend Dependencies...
cd backend\functions
call npm install --no-audit --no-fund

echo.
echo [3/3] Deploying Cloud Functions...
cd ..
call npx -p firebase-tools firebase deploy --only "functions" --non-interactive

echo.
echo ==================================================
echo   Deployment Triggered!
echo   If you see 'Deploy complete!', test it in the app.
echo ==================================================
pause
