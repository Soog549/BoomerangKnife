# Step 2: inject GamePush install-code into built index.html (right after <head>).
# Reads web\gamepush_install.html. Skip injection while the placeholder marker
# GP_INSTALL_CODE_PLACEHOLDER is present (honest demo mode). Writes UTF-8 no BOM.
$ErrorActionPreference = 'Stop'
$installFile = 'web\gamepush_install.html'
$target = 'build\web-gp\index.html'

if (-not (Test-Path -LiteralPath $installFile)) {
    Write-Host '  ! web\gamepush_install.html not found - build stays WITHOUT install-code (demo mode).'
    exit 0
}

$install = [System.IO.File]::ReadAllText($installFile, [System.Text.Encoding]::UTF8).Trim()
if ($install -match 'GP_INSTALL_CODE_PLACEHOLDER') {
    Write-Host '  ! install-code still has placeholder - injection skipped (demo mode). Remove GP_INSTALL_CODE_PLACEHOLDER to enable.'
    exit 0
}
if ($install -notmatch '<script') {
    Write-Host '  ! install-code has no <script> tag - injection skipped (demo mode).'
    exit 0
}

$html = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
$openMarker = '<!--GP_INSTALL_START-->'
$closeMarker = '<!--GP_INSTALL_END-->'
if ($html -notmatch '<head>') {
    Write-Host '  ! <head> not found in index.html - injection skipped.'
    exit 1
}
$block = $openMarker + "`r`n" + $install + "`r`n" + $closeMarker
# Idempotent: replace a previously injected block with the new one.
if ($html -match [System.Text.RegularExpressions.Regex]::Escape($openMarker)) {
    $pattern = [System.Text.RegularExpressions.Regex]::Escape($openMarker) + '[\s\S]*?' + [System.Text.RegularExpressions.Regex]::Escape($closeMarker)
    $html = [System.Text.RegularExpressions.Regex]::Replace($html, $pattern, $block, 1)
    Write-Host '  Previous install-block replaced (re-build).'
} else {
    $html = [System.Text.RegularExpressions.Regex]::Replace($html, '<head>', "<head>`r`n" + $block, 1)
    Write-Host '  New install-block injected.'
}
$html = [System.Text.RegularExpressions.Regex]::Replace($html, '<head>\r\n\r\n', '<head>' + "`r`n", 1)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($target, $html, $utf8NoBom)
Write-Host "  GamePush install-code injected into $target"
exit 0