[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
    [string] $Version
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$BuildRoot = Join-Path $RepoRoot "builds\$Version"
$WindowsOutput = Join-Path $BuildRoot 'windows-x86_64\TrashTrek.exe'
$MacOutput = Join-Path $BuildRoot 'macos-universal\TrashTrek.dmg'

if (Test-Path -LiteralPath $BuildRoot) {
    throw "Refusing to overwrite existing version directory: $BuildRoot"
}

if ($env:GODOT_BIN) {
    $GodotBin = $env:GODOT_BIN
} else {
    $GodotCommand = Get-Command godot.exe -ErrorAction SilentlyContinue
    if (-not $GodotCommand) {
        $GodotCommand = Get-Command godot -ErrorAction SilentlyContinue
    }
    if (-not $GodotCommand) {
        throw 'Godot 4.7.1 was not found. Set GODOT_BIN to the executable path.'
    }
    $GodotBin = $GodotCommand.Source
}

if (($GodotBin -match '[\\/]') -and -not (Test-Path -LiteralPath $GodotBin -PathType Leaf)) {
    throw "GODOT_BIN does not point to an executable: $GodotBin"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $WindowsOutput) | Out-Null

function Invoke-Godot {
    param([string[]] $Arguments)

    & $GodotBin @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Godot command failed with exit code $LASTEXITCODE"
    }
}

Invoke-Godot @('--headless', '--path', $RepoRoot, '--script', 'res://tools/verify_build.gd')
Invoke-Godot @('--headless', '--path', $RepoRoot, '--export-release', 'Windows Desktop', $WindowsOutput)

if ($IsMacOS) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $MacOutput) | Out-Null
    Invoke-Godot @('--headless', '--path', $RepoRoot, '--export-release', 'macOS', $MacOutput)
}

if (-not (Test-Path -LiteralPath $WindowsOutput -PathType Leaf)) {
    throw "Windows export did not produce $WindowsOutput"
}

if ($IsMacOS -and -not (Test-Path -LiteralPath $MacOutput -PathType Leaf)) {
    throw "macOS export did not produce $MacOutput"
}

Write-Host "Build complete: $BuildRoot"
