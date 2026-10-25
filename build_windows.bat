@echo off
setlocal
chcp 65001 >nul

set "GODOT=godot"
set "BUILD=release"

if not "%~1"=="" set "GODOT=%~1"
if not "%~2"=="" set "BUILD=%~2"

echo.
echo  ========================================================
echo   BoomerangKnife — Windows Desktop Builder
echo  ========================================================
echo.

REM --- [1] Godot ---
echo  [1/3] Checking Godot...
"%GODOT%" --version >nul 2>nul
if errorlevel 1 (
    echo   ERROR: '%GODOT%' not found.
    echo   Run: build_windows.bat "C:\Godot\godot.exe"
    exit /b 1
)
echo   OK

REM --- [2] Export templates ---
echo  [2/3] Checking templates...
if exist "%APPDATA%\Godot\export_templates" (
    echo   OK
) else (
    echo   WARNING: not found. Install via Manage Export Templates.
)

REM --- [3] Build ---
echo  [3/3] Building .exe (%BUILD%)...
if not exist "build\windows" mkdir "build\windows"

"%GODOT%" --headless --path . --export-%BUILD% "Windows Desktop" "build\windows\boomerangknife.exe"

if errorlevel 1 (
    echo.
    echo   ERROR: Build failed.
    echo    1. Ensure Windows Desktop preset is active in Project ^> Export
    echo    2. Export templates installed
    exit /b 1
)

echo.
echo  ========================================================
echo   OK: build\windows\boomerangknife.exe
echo  ========================================================
echo.
echo   .pck is embedded (single-file exe).
echo   Steam/VK Play: see README.md for distribution.
echo.
endlocal
pause
