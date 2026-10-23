[CmdletBinding()]
param(
    [string]$OutputName = "ChanIPTV.zip"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "ChanIPTV build" -ForegroundColor Cyan
Write-Host "Root: $root"

$required = @("manifest", "source", "components", "images")
foreach ($item in $required) {
    if (-not (Test-Path $item)) {
        throw "Missing required item: $item"
    }
}

$tempDir = Join-Path $env:TEMP ("ChanIPTV-build-" + [guid]::NewGuid().ToString())
$pkgDir = Join-Path $tempDir "pkg"
New-Item -ItemType Directory -Force -Path $pkgDir | Out-Null

$itemsToCopy = @("manifest", "source", "components", "images")
foreach ($item in $itemsToCopy) {
    Write-Host "Copying $item..." -ForegroundColor Gray
    Copy-Item -Path $item -Destination $pkgDir -Recurse -Force
}

$outPath = Join-Path $root $OutputName
if (Test-Path $outPath) {
    Remove-Item $outPath -Force
}

Write-Host "Zipping to $outPath..." -ForegroundColor Gray
Compress-Archive -Path (Join-Path $pkgDir "*") -DestinationPath $outPath -CompressionLevel Optimal

Remove-Item $tempDir -Recurse -Force

$size = (Get-Item $outPath).Length
Write-Host "Created $OutputName ($([math]::Round($size/1KB,1)) KB)" -ForegroundColor Green
Write-Host "Contents at zip root: manifest, source, components, images" -ForegroundColor Green
