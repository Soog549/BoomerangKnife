@echo off
rem Сборка Web-версии для Яндекс Игр. Запускать из папки проекта (BoomerangKnife).
setlocal
set GODOT=..\tools\godot\Godot_v4.7.2-stable_win64_console.exe
if not exist "%GODOT%" set GODOT=..\tools\godot\Godot_v4.7.2-stable_win64.exe
"%GODOT%" --headless --path . --export-release "Web" build/web/index.html
if errorlevel 1 exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File web\sdk_inline.ps1 -Marker "<!--YSDK-->" -SdkSource "web\yandex_sdk.js" -IndexHtml "build\web\index.html"
if errorlevel 1 exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File web\gradient_patch.ps1
echo.
echo Готово: build\web\index.html
exit /b 0