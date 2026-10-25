@echo off
setlocal
pushd "%~dp0"

rem Build Web version via GamePush (multi-platform: VK/Yandex/OK/Telegram/own site).
rem Preset Web-GamePush (feature "gamepush"): YandexSDK facade delegates to GamePushSDK.
rem Step 1: export preset. Step 2: inject GamePush install-code from web\gamepush_install.html.

if not exist build\web-gp mkdir build\web-gp

set GODOT=..\tools\godot\Godot_v4.7.2-stable_win64_console.exe
if not exist "%GODOT%" set GODOT=..\tools\godot\Godot_v4.7.2-stable_win64.exe
"%GODOT%" --headless --path . --export-release "Web-GamePush" build/web-gp/index.html
if errorlevel 1 exit /b 1

powershell -NoProfile -ExecutionPolicy Bypass -File web\sdk_inline.ps1 -Marker "<!--GPSDK-->" -SdkSource "web\gamepush_sdk.js" -IndexHtml "build\web-gp\index.html"
if errorlevel 1 exit /b 1

echo.
echo [Step 2] GamePush install-code:
powershell -NoProfile -ExecutionPolicy Bypass -File build_web_gp_install.ps1
if errorlevel 1 exit /b 1

echo.
echo Done: build\web-gp\index.html
popd
exit /b 0
