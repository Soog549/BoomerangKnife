$root = Split-Path $PSScriptRoot -Parent
$f = Join-Path $root "build\web\index.html"
$enc = New-Object System.Text.UTF8Encoding($false)
$x = [System.IO.File]::ReadAllText($f, $enc)
$before = "background-color: black;"
$after = "background: linear-gradient(180deg, #17242e 0%, #0c1320 60%, #070b12 100%);"
if ($x -like "*$after*") { exit 0 }
if (-not $x.Contains($before)) { Write-Error "marker not found"; exit 1 }
$x = $x.Replace($before, $after)
[System.IO.File]::WriteAllText($f, $x, $enc)
Write-Output "gradient applied"