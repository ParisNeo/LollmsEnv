# LollmsEnv - Lightweight environment management tool for Lollms projects
# Copyright (c) 2024 ParisNeo
# Licensed under the Apache License, Version 2.0
# Built by ParisNeo using Lollms
$ErrorActionPreference = "Stop"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$LOLLMS_HOME = Split-Path -Parent $SCRIPT_DIR
$PYTHON_DIR = Join-Path $LOLLMS_HOME "pythons"
$ENVS_DIR = Join-Path $LOLLMS_HOME "envs"
$BUNDLES_DIR = Join-Path $LOLLMS_HOME "bundles"
$TEMP_DIR = Join-Path $env:TEMP "lollmsenv"
New-Item -ItemType Directory -Force -Path $PYTHON_DIR, $ENVS_DIR, $BUNDLES_DIR, $TEMP_DIR | Out-Null
function Log($message) {
    Write-Host "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] $message"
}
function Error($message) {
    Log "ERROR: $message"
    exit 1
}
function Cleanup {
    Log "Cleaning up temporary files..."
    Remove-Item -Recurse -Force $TEMP_DIR -ErrorAction SilentlyContinue
}
trap {
    Cleanup
    exit 1
}
function Get-PlatformInfo {
    $arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "win32" }
    return $arch
}
function List-AvailablePythons {
    $releaseUrl = "https://api.github.com/repos/indygreg/python-build-standalone/releases"
    $platform = Get-PlatformInfo
    Log "Fetching available Python versions for $platform..."
    $versions = (Invoke-RestMethod -Uri $releaseUrl) | 
        Select-Object -ExpandProperty assets | 
        Where-Object { $_.name -match "cpython-\d+\.\d+\.\d+\+\d+.$platform.\.tar\.gz" } |
        ForEach-Object { $_.name -replace 'cpython-(.+?)\+.+', '$1' } |
        Sort-Object -Unique
    return $versions
}
function Get-PythonUrl($version) {
    $releaseUrl = "https://api.github.com/repos/indygreg/python-build-standalone/releases"
    $platform = Get-PlatformInfo
    $assetName = "cpython-${version}+.${platform}.\.tar\.gz"
    $release = (Invoke-RestMethod -Uri $releaseUrl) | 
        Where-Object { $_.assets | Where-Object { $_.name -match $assetName } } |
        Select-Object -First 1
    $asset = $release.assets | Where-Object { $_.name -match $assetName } | Select-Object -First 1
    return $asset.browser_download_url
}
function Scan-ForPython($version) {
    $locations = @(
        "C:\Python$($version -replace '\.', '')\python.exe",
        "C:\Program Files\Python$($version -replace '\.', '')\python.exe",
        "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python$($version -replace '\.', '')\python.exe"
    )
    foreach ($loc in $locations) {
        if (Test-Path $loc) {
            return $loc
        }
    }
    return $null
}
function Install-Python($version, $customDir) {
    $existingPython = Scan-ForPython $version
    if ($existingPython) {
        Log "Found existing Python $version installation at $existingPython"
        
        if (-not $customDir) {
            $targetDir = Join-Path $PYTHON_DIR $version
        } else {
            $targetDir = Join-Path $customDir $version
        }
        
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
        New-Item -ItemType SymbolicLink -Path "$targetDir\python.exe" -Target $existingPython | Out-Null
        $pipPath = Join-Path (Split-Path $existingPython) "Scripts\pip.exe"
        if (Test-Path $pipPath) {
            New-Item -ItemType SymbolicLink -Path "$targetDir\pip.exe" -Target $pipPath | Out-Null
        }
        
        Log "Created symlinks to existing Python $version in $targetDir"
        Add-Content -Path "$PYTHON_DIR\installed_pythons.txt" -Value "$version:$targetDir"
        return
    }
    $url = Get-PythonUrl $version
    if (-not $url) {
        Error "Failed to find Python $version download URL"
    }
    Log "Downloading Python $version from $url"
    if (-not $customDir) {
        $targetDir = Join-Path $PYTHON_DIR $version
    } else {
        $targetDir = Join-Path $customDir $version
    }
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    $archive = Join-Path $TEMP_DIR "python-$version.tar.gz"
    Invoke-WebRequest -Uri $url -OutFile $archive
    Log "Extracting Python $version to $targetDir"
    tar -xzf $archive -C $targetDir --strip-components=1
    Log "Ensuring pip and venv are installed"
    & "$targetDir\python.exe" -m ensurepip --upgrade
    & "$targetDir\python.exe" -m pip install --upgrade pip
    & "$targetDir\python.exe" -m pip install virtualenv
    Add-Content -Path "$PYTHON_DIR\installed_pythons.txt" -Value "$version:$targetDir"
    Log "Python $version installed successfully with pip and venv in $targetDir"
}
function Create-Env($envName, $pythonVersion, $customDir) {
    $pythonPath = (Get-Content "$PYTHON_DIR\installed_pythons.txt" | Where-Object { $_ -match "^$pythonVersion:" } | ForEach-Object { ($_ -split ':')[1] }) + "\python.exe"
    if (-not (Test-Path $pythonPath)) {
        Error "Python $pythonVersion is not installed"
    }
    if (-not $customDir) {
        $envPath = Join-Path $ENVS_DIR $envName
    } else {
        $envPath = Join-Path $customDir $envName
    }
    Log "Creating virtual environment '$envName' with Python $pythonVersion in $envPath"
    & $pythonPath -m venv $envPath
    Add-Content -Path "$ENVS_DIR\installed_envs.txt" -Value "$envName:$envPath:$pythonVersion"
    Log "Environment '$envName' created successfully"
}
function Activate-Env($envName) {
    $envPath = (Get-Content "$ENVS_DIR\installed_envs.txt" | Where-Object { $_ -match "^$envName:" } | ForEach-Object { ($_ -split ':')[1] })
    if (-not $envPath) {
        Error "Environment '$envName' not found"
    }
    $activateScript = Join-Path $envPath "Scripts\Activate.ps1"
    Write-Host "To activate the environment, run:"
    Write-Host ". $activateScript"
}
function Deactivate-Env {
    Write-Host "To deactivate the current environment, run:"
    Write-Host "deactivate"
}
function Install-Package($package) {
    & pip install $package
    Log "Package '$package' installed in the current environment"
}
function List-Pythons {
    Write-Host "Installed Python versions:"
    Get-Content "$PYTHON_DIR\installed_pythons.txt"
}
function List-Envs {
    Write-Host "Installed environments:"
    Get-Content "$ENVS_DIR\installed_envs.txt"
}
function Create-Bundle($bundleName, $pythonVersion, $envName) {
    $bundleDir = Join-Path $BUNDLES_DIR $bundleName
    New-Item -ItemType Directory -Force -Path $bundleDir | Out-Null
    Install-Python $pythonVersion $bundleDir
    Create-Env $envName $pythonVersion $bundleDir
    Log "Bundle '$bundleName' created with Python $pythonVersion and environment '$envName' in $bundleDir"
}
function Show-Help {
    Write-Host @"
lollmsenv - Python and Virtual Environment Management Tool
Usage: .\lollmsenv.ps1 [command] [options]
Commands:
  install-python [version] [custom_dir]  Install a specific Python version
  create-env [name] [python-version] [custom_dir]  Create a new virtual environment
  activate [name]                        Show command to activate an environment
  deactivate                             Show command to deactivate the current environment
  install [package]                      Install a package in the current environment
  list-pythons                           List installed Python versions
  list-envs                              List installed virtual environments
  list-available-pythons                 List available Python versions for installation
  create-bundle [name] [python-version] [env-name]  Create a bundle with Python and environment
  -help, -h                              Show this help message
Description:
  This tool helps manage Python installations and virtual environments.
  It scans for existing Python installations before downloading.
  You can install multiple Python versions, create and manage
  virtual environments, and create bundles of Python with environments.
  You can also install Python and environments in custom directories.
"@
}
switch ($args[0]) {
    "install-python" { Install-Python $args[1] $args[2] }
    "create-env" { Create-Env $args[1] $args[2] $args[3] }
    "activate" { Activate-Env $args[1] }
    "deactivate" { Deactivate-Env }
    "install" { Install-Package $args[1] }
    "list-pythons" { List-Pythons }
    "list-envs" { List-Envs }
    "list-available-pythons" { List-AvailablePythons }
    "create-bundle" { Create-Bundle $args[1] $args[2] $args[3] }
    "-help" { Show-Help }
    "-h" { Show-Help }
    default { Error "Unknown command. Use -help or -h for usage information." }
}
Cleanup
