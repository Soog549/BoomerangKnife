@echo off
setlocal
chcp 65001 >nul

set "GODOT=godot"
set "BUILD=release"

if not "%~1"=="" set "GODOT=%~1"
if not "%~2"=="" set "BUILD=%~2"

echo.
echo  ========================================================
echo   BoomerangKnife — Android APK Builder
echo  ========================================================
echo.

REM --- [1] Godot ---
echo  [1/5] Checking Godot...
"%GODOT%" --version >nul 2>nul
if errorlevel 1 (
    echo   ERROR: '%GODOT%' not found.
    echo   Add godot.exe folder to PATH, or run:
    echo     build_android.bat "C:\Godot\godot.exe" release
    exit /b 1
)
echo   OK

REM --- [2] Java ---
echo  [2/5] Checking Java (JDK 17)...
java -version >nul 2>nul
if errorlevel 1 (
    echo   WARNING: Java not found.
    echo   Install: https://adoptium.net/temurin/releases/?version=17
) else (
    echo   OK
)

REM --- [3] Android SDK ---
echo  [3/5] Checking Android SDK...
if defined ANDROID_HOME (
    echo   OK: %ANDROID_HOME%
) else if defined ANDROID_SDK_ROOT (
    echo   OK: %ANDROID_SDK_ROOT%
) else (
    echo   WARNING: ANDROID_HOME not set.
    echo   Set in Godot ^> Editor ^> Editor Settings ^> Export ^> Android
)

REM --- [4] Export templates ---
echo  [4/5] Checking export templates...
if exist "%APPDATA%\Godot\export_templates" (
    echo   OK
) else (
    echo   WARNING: Export templates not found.
    echo   Install: Godot ^> Editor ^> Manage Export Templates
)

REM --- [5] Build ---
echo  [5/5] Building APK (%BUILD%)...
if not exist "build\android" mkdir "build\android"

"%GODOT%" --headless --path . --export-%BUILD% "Android" "build\android\boomerangknife.apk"

if errorlevel 1 (
    echo.
    echo   ERROR: Build failed. Check:
    echo    1. Project ^> Export ^> Android preset exists
    echo    2. Keystore debug/release are set
    echo    3. Export templates installed
    echo    4. Gradle build templates installed
    exit /b 1
)

echo.
echo  ========================================================
echo   OK: build\android\boomerangknife.apk
echo  ========================================================
echo.
if /i "%BUILD%"=="debug" (
    echo   Install: adb install build\android\boomerangknife.apk
) else (
    echo   For RuStore: upload APK directly
    echo   For Google Play: use AAB (choose in Export ^> Android ^> Export AAB)
    echo   For ads: configure AdMob in scripts\ads.gd
)
echo.
endlocal
pause
