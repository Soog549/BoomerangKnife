@echo off
setlocal
chcp 65001 >nul

echo.
echo  ========================================================
echo   Generate Android Debug Keystore
echo  ========================================================
echo.

if not exist "build\keystore" mkdir "build\keystore"

if exist "build\keystore\debug.keystore" (
    echo   Debug keystore already exists: build\keystore\debug.keystore
    echo   Delete it to regenerate, or use existing.
    echo.
    pause
    exit /b 0
)

echo  Creating debug keystore (10 year validity)...
echo  NOTE: Use -genkeypair for a production/release keystore instead.
echo.

keytool -genkeypair ^
  -alias androiddebugkey ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 3650 ^
  -keystore "build\keystore\debug.keystore" ^
  -storepass android ^
  -keypass android ^
  -dname "CN=Debug, OU=Debug, O=Debug, L=Debug, ST=Debug, C=US"

if errorlevel 1 (
    echo   ERROR: keytool not found. Ensure JDK 17 is installed
    echo   and 'keytool' is in your PATH.
    exit /b 1
)

echo.
echo  ========================================================
echo   OK: build\keystore\debug.keystore
echo  ========================================================
echo.
echo  Next: copy this path into export_presets.cfg:
echo    keystore/debug = "build/keystore/debug.keystore"
echo    keystore/debug_user = "androiddebugkey"
echo    keystore/debug_password = "android"
echo.
pause
endlocal
