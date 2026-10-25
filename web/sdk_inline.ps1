param(
  [string]$Marker,
  [string]$SdkSource,
  [string]$IndexHtml
)

$ErrorActionPreference = "Stop"
# Inline-embed SDK snippet into <head> of exported index.html.
# Godot injects head_include as external <script src>, but yandex_sdk.js is an
# HTML snippet (<style> + <script src="/sdk.js"> + <script>), not plain JS.
# So instead of <script src> the cfg holds a marker <!--YSDK--> / <!--GPSDK-->,
# and here the marker is replaced with the FULL SDK file content.

if (-not (Test-Path $SdkSource)) { Write-Error "SDK file not found: $SdkSource"; exit 1 }
if (-not (Test-Path $IndexHtml)) { Write-Error "index.html not found: $IndexHtml"; exit 1 }

$enc = New-Object System.Text.UTF8Encoding($false)
$x = [System.IO.File]::ReadAllText($IndexHtml, $enc)
$sdk = [System.IO.File]::ReadAllText($SdkSource, $enc)

if (-not $x.Contains($Marker)) {
  Write-Error "marker $Marker not found in $IndexHtml"; exit 1
}

# Idempotency: if the marker was already replaced by SDK content, skip.
if ($x -like "*$($sdk.Substring(0, [Math]::Min(40, $sdk.Length)))*") {
  Write-Output "SDK already inlined, skip"
  exit 0
}

$x = $x.Replace($Marker, $sdk)
[System.IO.File]::WriteAllText($IndexHtml, $x, $enc)
Write-Output "sdk inline applied ($Marker)"
