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
function Log {
    param([string]$message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message"
}
function Error {
    param([string]$message)
    Log "ERROR: $message"
    exit 1
}
function Cleanup {
    Log "Cleaning up temporary files..."
    Remove-Item -Recurse -Force $TEMP_DIR -ErrorAction SilentlyContinue
}
# Register cleanup function to run on script exit
Register-EngineEvent PowerShell.Exiting -Action { Cleanup } | Out-Null
function Get-PlatformInfo {
    $arch = if ([Environment]::Is64BitOperatingSystem) { "win64" } else { "win32" }
    return $arch
}
function List-AvailablePythons {
    $RELEASE_URL = "https://api.github.com/repos/indygreg/python-build-standalone/releases"
    $PLATFORM = Get-PlatformInfo
    Log "Fetching available Python versions for $PLATFORM..."
    $releases = Invoke-RestMethod -Uri $RELEASE_URL
    $versions = $releases.assets | 
                Where-Object { $_.name -match "cpython-\d+\.\d+\.\d+\+\d+.$PLATFORM\.tar\.gz" } |
                ForEach-Object { $_.name -replace "cpython-", "" -replace "\+.*$", "" } |
                Sort-Object -Unique
    return $versions
}
function Get-PythonUrl {
    param([string]$VERSION)
    $PLATFORM = Get-PlatformInfo
    $RELEASE_URL = "https://api.github.com/repos/indygreg/python-build-standalone/releases"
    $ASSET_NAME = "cpython-${VERSION}+.*$PLATFORM\.tar\.gz"
    $releases = Invoke-RestMethod -Uri $RELEASE_URL
    $asset = $releases.assets | Where-Object { $_.name -match $ASSET_NAME } | Select-Object -First 1
    return $asset.browser_download_url
}
function Scan-ForPython {
    param([string]$VERSION)
    $LOCATIONS = @(
        "C:\Python$($VERSION -replace '\.')",
        "${env:LOCALAPPDATA}\Programs\Python\Python$($VERSION -replace '\.')",
        "${env:ProgramFiles}\Python$($VERSION -replace '\.')",
        "${env:ProgramFiles(x86)}\Python$($VERSION -replace '\.')"
    )
    foreach ($loc in $LOCATIONS) {
        if (Test-Path "$loc\python.exe") {
            return "$loc\python.exe"
        }
    }
    return $null
}
function Install-Python {
    param(
        [string]$VERSION,
        [string]$CUSTOM_DIR
    )
    
    # First, scan for existing Python installation
    $EXISTING_PYTHON = Scan-ForPython $VERSION
    
    if ($EXISTING_PYTHON) {
        Log "Found existing Python $VERSION installation at $EXISTING_PYTHON"
        
        if (-not $CUSTOM_DIR) {
            $TARGET_DIR = Join-Path $PYTHON_DIR $VERSION
        } else {
            $TARGET_DIR = Join-Path $CUSTOM_DIR $VERSION
        }
        
        New-Item -ItemType Directory -Force -Path $TARGET_DIR | Out-Null
        New-Item -ItemType SymbolicLink -Path "$TARGET_DIR\python.exe" -Target $EXISTING_PYTHON | Out-Null
        $PIP_PATH = Join-Path (Split-Path $EXISTING_PYTHON) "Scripts\pip.exe"
        if (Test-Path $PIP_PATH) {
            New-Item -ItemType SymbolicLink -Path "$TARGET_DIR\pip.exe" -Target $PIP_PATH | Out-Null
        }
        
        Log "Created symlinks to existing Python $VERSION in $TARGET_DIR"
        Add-Content -Path "$PYTHON_DIR\installed_pythons.txt" -Value "$VERSION:$TARGET_DIR"
        return
    }
    
    $URL = Get-PythonUrl $VERSION
    
    if (-not $URL) {
        Error "Failed to find Python $VERSION download URL"
    }
    
    Log "Downloading Python $VERSION from $URL"
    
    if (-not $CUSTOM_DIR) {
        $TARGET_DIR = Join-Path $PYTHON_DIR $VERSION
    } else {
        $TARGET_DIR = Join-Path $CUSTOM_DIR $VERSION
    }
    
    New-Item -ItemType Directory -Force -Path $TARGET_DIR | Out-Null
    
    $ARCHIVE = Join-Path $TEMP_DIR "python-$VERSION.tar.gz"
    Invoke-WebRequest -Uri $URL -OutFile $ARCHIVE
    
    Log "Extracting Python $VERSION to $TARGET_DIR"
    tar -xzf $ARCHIVE -C $TARGET_DIR --strip-components=1
    
    Log "Ensuring pip and venv are installed"
    & "$TARGET_DIR\python.exe" -m ensurepip --upgrade
    & "$TARGET_DIR\python.exe" -m pip install --upgrade pip
    & "$TARGET_DIR\python.exe" -m pip install virtualenv
    
    Add-Content -Path "$PYTHON_DIR\installed_pythons.txt" -Value "$VERSION:$TARGET_DIR"
    Log "Python $VERSION installed successfully with pip and venv in $TARGET_DIR"
}
function Create-Env {
    param(
        [string]$ENV_NAME,
        [string]$PYTHON_VERSION,
        [string]$CUSTOM_DIR
    )
    
    $PYTHON_PATH = (Get-Content "$PYTHON_DIR\installed_pythons.txt" | Where-Object { $_ -match "^$PYTHON_VERSION:" } | ForEach-Object { ($_ -split ':')[1] }) + "\python.exe"
    
    if (-not (Test-Path $PYTHON_PATH)) {
        Error "Python $PYTHON_VERSION is not installed"
    }
    
    if (-not $CUSTOM_DIR) {
        $ENV_PATH = Join-Path $ENVS_DIR $ENV_NAME
    } else {
        $ENV_PATH = Join-Path $CUSTOM_DIR $ENV_NAME
    }
    
    Log "Creating virtual environment '$ENV_NAME' with Python $PYTHON_VERSION in $ENV_PATH"
    & $PYTHON_PATH -m venv $ENV_PATH
    
    Add-Content -Path "$ENVS_DIR\installed_envs.txt" -Value "$ENV_NAME:$ENV_PATH:$PYTHON_VERSION"
    Log "Environment '$ENV_NAME' created successfully"
}
function Activate-Env {
    param([string]$ENV_NAME)
    $ENV_PATH = (Get-Content "$ENVS_DIR\installed_envs.txt" | Where-Object { $_ -match "^$ENV_NAME:" } | ForEach-Object { ($_ -split ':')[1] })
    
    if (-not $ENV_PATH) {
        Error "Environment '$ENV_NAME' not found"
    }
    
    $ACTIVATE_SCRIPT = Join-Path $ENV_PATH "Scripts\Activate.ps1"
    Write-Host "To activate the environment, run:"
    Write-Host ". $ACTIVATE_SCRIPT"
}
function Deactivate-Env {
    Write-Host "To deactivate the current environment, run:"
    Write-Host "deactivate"
}
function Install-Package {
    param([string]$PACKAGE)
    pip install $PACKAGE
    Log "Package '$PACKAGE' installed in the current environment"
}
function List-Pythons {
    Write-Host "Installed Python versions:"
    Get-Content "$PYTHON_DIR\installed_pythons.txt"
}
function List-Envs {
    Write-Host "Installed environments:"
    Get-Content "$ENVS_DIR\installed_envs.txt"
}
function Create-Bundle {
    param(
        [string]$BUNDLE_NAME,
        [string]$PYTHON_VERSION,
        [string]$ENV_NAME
    )
    $BUNDLE_DIR = Join-Path $BUNDLES_DIR $BUNDLE_NAME
    
    New-Item -ItemType Directory -Force -Path $BUNDLE_DIR | Out-Null
    Install-Python $PYTHON_VERSION $BUNDLE_DIR
    Create-Env $ENV_NAME $PYTHON_VERSION $BUNDLE_DIR
    
    Log "Bundle '$BUNDLE_NAME' created with Python $PYTHON_VERSION and environment '$ENV_NAME' in $BUNDLE_DIR"
}
function Delete-Env {
    param([string]$ENV_NAME)
    $ENV_PATH = (Get-Content "$ENVS_DIR\installed_envs.txt" | Where-Object { $_ -match "^$ENV_NAME:" } | ForEach-Object { ($_ -split ':')[1] })
    
    if (-not $ENV_PATH) {
        Error "Environment '$ENV_NAME' not found"
    }
    
    Log "Deleting environment '$ENV_NAME' from $ENV_PATH"
    Remove-Item -Recurse -Force $ENV_PATH
    (Get-Content "$ENVS_DIR\installed_envs.txt") | Where-Object { $_ -notmatch "^$ENV_NAME:" } | Set-Content "$ENVS_DIR\installed_envs.txt"
    Log "Environment '$ENV_NAME' deleted successfully"
}
function Delete-Python {
    param([string]$VERSION)
    $PYTHON_PATH = (Get-Content "$PYTHON_DIR\installed_pythons.txt" | Where-Object { $_ -match "^$VERSION:" } | ForEach-Object { ($_ -split ':')[1] })
    
    if (-not $PYTHON_PATH) {
        Error "Python $VERSION is not installed"
    }
    
    Log "Deleting Python $VERSION from $PYTHON_PATH"
    Remove-Item -Recurse -Force $PYTHON_PATH
    (Get-Content "$PYTHON_DIR\installed_pythons.txt") | Where-Object { $_ -notmatch "^$VERSION:" } | Set-Content "$PYTHON_DIR\installed_pythons.txt"
    Log "Python $VERSION deleted successfully"
}
function Show-Help {
    Write-Host "lollmsenv - Python and Virtual Environment Management Tool"
    Write-Host
    Write-Host "Usage: .\lollmsenv.ps1 [command] [options]"
    Write-Host
    Write-Host "Commands:"
    Write-Host "  install-python [version] [custom_dir]  Install a specific Python version"
    Write-Host "  create-env [name] [python-version] [custom_dir]  Create a new virtual environment"
    Write-Host "  activate [name]                        Show command to activate an environment"
    Write-Host "  deactivate                             Show command to deactivate the current environment"
    Write-Host "  install [package]                      Install a package in the current environment"
    Write-Host "  list-pythons                           List installed Python versions"
    Write-Host "  list-envs                              List installed virtual environments"
    Write-Host "  list-available-pythons                 List available Python versions for installation"
    Write-Host "  create-bundle [name] [python-version] [env-name]  Create a bundle with Python and environment"
    Write-Host "  delete-env [name]                      Delete a virtual environment"
    Write-Host "  delete-python [version]                Delete a Python installation"
    Write-Host "  --help, -h                             Show this help message"
    Write-Host
    Write-Host "Description:"
    Write-Host "  This tool helps manage Python installations and virtual environments."
    Write-Host "  It scans for existing Python installations before downloading."
    Write-Host "  You can install multiple Python versions, create and manage"
    Write-Host "  virtual environments, and create bundles of Python with environments."
    Write-Host "  You can also install Python and environments in custom directories."
    Write-Host "  Now you can delete environments and Python installations as well."
}
# Main script logic
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
    "delete-env" { Delete-Env $args[1] }
    "delete-python" { Delete-Python $args[1] }
    { $_ -in "--help", "-h" } { Show-Help }
    default { Error "Unknown command. Use --help or -h for usage information." }
}
