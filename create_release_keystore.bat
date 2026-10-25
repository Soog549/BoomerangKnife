@echo off
setlocal
chcp 65001 >nul

echo.
echo  ========================================================
echo   Generate Release Keystore for Android
echo  ========================================================
echo.
echo  This will prompt for a password (remember it!) and details.
echo  The keystore is stored in build\keystore\release.keystore
echo.

if exist "build\keystore\release.keystore" (
    echo  WARNING: build\keystore\release.keystore already exists.
    echo  Delete it manually to regenerate.
    pause
    exit /b 0
)

if not exist "build\keystore" mkdir "build\keystore"

echo  Enter your details when prompted (common name = your name/company):
echo.

keytool -genkeypair ^
  -alias boomerangknife ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -keystore "build\keystore\release.keystore"

if errorlevel 1 (
    echo   ERROR: keytool not found. Install JDK 17 first.
    exit /b 1
)

echo.
echo  ========================================================
echo   OK: build\keystore\release.keystore
echo  ========================================================
echo.
echo  Configure in export_presets.cfg ^[preset.0.options^]:
echo    keystore/release = "build/keystore/release.keystore"
echo    keystore/release_user = "your_alias"
echo    keystore/release_password = "your_password"
echo.
echo  IMPORTANT: never commit release.keystore or its password to git!
pause
endlocal
