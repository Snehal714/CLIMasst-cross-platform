#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "================================"
Write-Host "MASSTCLI Scan Started"
Write-Host "================================"

# Resolve root directory (repo root)
$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$ToolsDir = Join-Path $RootDir "tools"
$MasstDir = Join-Path $ToolsDir "MASSTCLI"
$ArtifactsDir = Join-Path $RootDir "artifacts"
$MasstZip = Join-Path $ToolsDir "MASSTCLI.zip"
$MasstUrl = "https://example.com/MASSTCLI.zip"

# OS detection
$IsWindows = $PSVersionTable.Platform -eq "Win32NT"
$MasstExe = if ($IsWindows) { "MASSTCLI.exe" } else { "MASSTCLI" }

# Ensure tools dir
New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null

# Download if missing
if (-not (Test-Path (Join-Path $MasstDir $MasstExe))) {
    Write-Host "MASSTCLI not found. Downloading..."

    Invoke-WebRequest -Uri $MasstUrl -OutFile $MasstZip

    Expand-Archive -Force $MasstZip $ToolsDir
    Remove-Item $MasstZip -Force

    # Normalize extracted folder name
    $Extracted = Get-ChildItem $ToolsDir -Directory |
                 Where-Object { $_.Name -like "MASSTCLI-*amd64*" } |
                 Select-Object -First 1

    if (-not $Extracted) {
        throw "Extracted MASSTCLI folder not found"
    }

    if (Test-Path $MasstDir) {
        Remove-Item $MasstDir -Recurse -Force
    }

    Rename-Item $Extracted.FullName "MASSTCLI"
}

# Validate
$MasstPath = Join-Path $MasstDir $MasstExe
if (-not (Test-Path $MasstPath)) {
    throw "MASSTCLI executable not found"
}

if (-not $IsWindows) {
    chmod +x $MasstPath
}

# Version check
Write-Host "MASSTCLI version:"
& $MasstPath --version

# Scan artifacts
$Files = @()
$Files += Get-ChildItem $ArtifactsDir -Filter "*.apk" -ErrorAction SilentlyContinue
$Files += Get-ChildItem $ArtifactsDir -Filter "*.aab" -ErrorAction SilentlyContinue

if ($Files.Count -eq 0) {
    Write-Host "No APK/AAB files found"
}

foreach ($file in $Files) {
    Write-Host "--------------------------------"
    Write-Host "Scanning $($file.Name)"
    & $MasstPath `
        -input="$($file.FullName)" `
        -config="$(Join-Path $MasstDir 'config.bm')" `
        -v=true
}

Write-Host "================================"
Write-Host "MASSTCLI Scan Completed Successfully"
Write-Host "================================"
