# LollmsEnv - Lightweight environment management tool for Lollms projects
# Copyright (c) 2024 ParisNeo
# Licensed under the Apache License, Version 2.0
# Built by ParisNeo using Lollms
# Adapted for PowerShell by LoLLMs

# Define the base path relative to lollmsenv
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$LOLLMS_HOME = Split-Path -Parent $SCRIPT_DIR
$PYTHON_DIR = Join-Path $LOLLMS_HOME "pythons"
$ENVS_DIR = Join-Path $LOLLMS_HOME "envs"
$BUNDLES_DIR = Join-Path $LOLLMS_HOME "bundles"
$TEMP_DIR = Join-Path $env:TEMP "lollmsenv"

if (-not (Test-Path $PYTHON_DIR)) { New-Item -ItemType Directory -Path $PYTHON_DIR | Out-Null }
if (-not (Test-Path $ENVS_DIR)) { New-Item -ItemType Directory -Path $ENVS_DIR | Out-Null }
if (-not (Test-Path $BUNDLES_DIR)) { New-Item -ItemType Directory -Path $BUNDLES_DIR | Out-Null }
if (-not (Test-Path $TEMP_DIR)) { New-Item -ItemType Directory -Path $TEMP_DIR | Out-Null }

# Check for installed_pythons.txt in PYTHON_DIR
if (-not (Test-Path (Join-Path $PYTHON_DIR "installed_pythons.txt"))) {
    New-Item -ItemType File -Path (Join-Path $PYTHON_DIR "installed_pythons.txt") | Out-Null
}

# Check for installed_envs.txt in ENVS_DIR
if (-not (Test-Path (Join-Path $ENVS_DIR "installed_envs.txt"))) {
    New-Item -ItemType File -Path (Join-Path $ENVS_DIR "installed_envs.txt") | Out-Null
}

function Log {
    param([string]$message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message"
}

function LogError {
    param([string]$message)
    Log "ERROR: $message"
    exit 1
}

function Cleanup {
    Log "Cleaning up temporary files..."
    if (Test-Path $TEMP_DIR) { Remove-Item -Recurse -Force $TEMP_DIR }
}

function Install-Python {
    param(
        [string]$VERSION,
        [string]$CUSTOM_DIR
    )

    Log "Installing Python $VERSION"

    # Check if Python is already installed
    if (Test-Path (Join-Path $PYTHON_DIR $VERSION "python.exe")) {
        Log "Python $VERSION is already installed."
        return
    }

    Log "Downloading Python $VERSION"
    $URL = "https://www.python.org/ftp/python/$VERSION/python-$VERSION-embed-amd64.zip"

    # Determine the target directory
    if ([string]::IsNullOrEmpty($CUSTOM_DIR)) {
        $TARGET_DIR = Join-Path $PYTHON_DIR $VERSION
    } else {
        if ([System.IO.Path]::IsPathRooted($CUSTOM_DIR)) {
            $TARGET_DIR = Join-Path $CUSTOM_DIR $VERSION
        } else {
            $TARGET_DIR = Join-Path $LOLLMS_HOME $CUSTOM_DIR $VERSION
        }
    }

    if (-not (Test-Path $TARGET_DIR)) { New-Item -ItemType Directory -Path $TARGET_DIR | Out-Null }

    $ARCHIVE = Join-Path $env:TEMP "python-$VERSION.zip"
    Log "Downloading from $URL"
    Invoke-WebRequest -Uri $URL -OutFile $ARCHIVE
    if (-not $?) { LogError "Failed to download Python $VERSION" }

    Log "Extracting Python $VERSION to $TARGET_DIR"
    Expand-Archive -Path $ARCHIVE -DestinationPath $TARGET_DIR -Force
    if (-not $?) { LogError "Failed to extract Python $VERSION" }

    # Remove the _pth file to allow pip installation
    Remove-Item "$TARGET_DIR\python*._pth" -ErrorAction SilentlyContinue

    $env:PATH = "$TARGET_DIR;$env:PATH"

    Write-Host "Target dir is $TARGET_DIR"
    & "$TARGET_DIR\python.exe" --version

    # Download get-pip.py
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "$TARGET_DIR\get-pip.py"
    if (-not $?) { LogError "Failed to download get-pip.py" }

    Log "Installing pip"
    & "$TARGET_DIR\python.exe" "$TARGET_DIR\get-pip.py" --no-warn-script-location
    if (-not $?) { LogError "Failed to install pip" }

    Log "Installing virtualenv"
    & "$TARGET_DIR\Scripts\pip.exe" install virtualenv --no-warn-script-location
    if (-not $?) { LogError "Failed to install virtualenv" }

    # Register the Python installation with a relative path
    $RELATIVE_PATH = Resolve-Path -Relative -Path $TARGET_DIR -BasePath $LOLLMS_HOME
    $RELATIVE_PATH = $RELATIVE_PATH -replace '^\.\\'

    # Display the result
    Log "Python $VERSION installed successfully with pip and virtualenv in $TARGET_DIR"
}

function Register-PythonInstallation {
    param(
        [string]$PYTHON_PATH,
        [string]$VERSION
    )

    if (-not (Test-Path (Join-Path $PYTHON_PATH "python.exe"))) {
        LogError "The specified Python path does not contain a valid Python installation."
    }
    Log "Registering Python $VERSION from $PYTHON_PATH"
    # Check if venv is installed
    & "$PYTHON_PATH\python.exe" -c "import venv" 2>$null
    if (-not $?) {
        Log "venv module not found. Installing venv..."
        & "$PYTHON_PATH\python.exe" -m pip install virtualenv
        if (-not $?) { LogError "Failed to install virtualenv" }
    }
    Add-Content -Path (Join-Path $PYTHON_DIR "installed_pythons.txt") -Value "$VERSION,$PYTHON_PATH"
    Log "Python $VERSION registered successfully"
}

function Create-Environment {
    param(
        [string]$ENV_NAME,
        [string]$PYTHON_VERSION,
        [string]$CUSTOM_DIR
    )

    Write-Host $LOLLMS_HOME
    Write-Host $PYTHON_DIR

    Write-Host "Creating environment: $ENV_NAME"
    Write-Host "Python version: $PYTHON_VERSION"
    Write-Host "Custom directory: $CUSTOM_DIR"

    if ([string]::IsNullOrEmpty($PYTHON_VERSION)) {
        Log "No Python version specified, checking for default..."
        $PYTHON_VERSION = Get-Content (Join-Path $PYTHON_DIR "installed_pythons.txt") | 
            ForEach-Object { $_.Split(',')[0] } | 
            Sort-Object -Descending | 
            Select-Object -First 1
    }
    Write-Host "Found a default python version: $PYTHON_VERSION"

    if ([string]::IsNullOrEmpty($PYTHON_VERSION)) {
        Log "No Python versions found."
        $INSTALL_PYTHON = Read-Host "Do you want to install Python 3.11.9? (Y/N)"
        if ($INSTALL_PYTHON -eq 'Y') {
            Install-Python -VERSION "3.11.9"
            $PYTHON_VERSION = "3.11.9"
        } else {
            LogError "Cannot create environment without Python. Please install Python first."
        }
    }

    $PYTHON_PATH = Join-Path $PYTHON_DIR $PYTHON_VERSION

    Write-Host $PYTHON_PATH

    # Check if PYTHON_PATH is an absolute path
    if ([System.IO.Path]::IsPathRooted($PYTHON_PATH)) {
        $FULL_PYTHON_PATH = $PYTHON_PATH
    } else {
        $FULL_PYTHON_PATH = Join-Path $LOLLMS_HOME $PYTHON_PATH
    }

    $PYTHON_EXE = Join-Path $FULL_PYTHON_PATH "python.exe"
    $VIRTUALENV_EXE = Join-Path $FULL_PYTHON_PATH "Scripts\virtualenv.exe"

    Write-Host $PYTHON_EXE
    Write-Host $VIRTUALENV_EXE

    if (-not (Test-Path $PYTHON_EXE)) {
        LogError "Python $PYTHON_VERSION is not installed or path is incorrect"
    }

    # Determine the environment path
    $ENV_PATH = Join-Path $ENVS_DIR $ENV_NAME

    Log "Creating virtual environment '$ENV_NAME' with Python $PYTHON_VERSION in $ENV_PATH"
    & $VIRTUALENV_EXE $ENV_PATH
    if (-not $?) { LogError "Failed to create virtual environment" }

    Log "Upgrading pip in the new environment"
    & "$ENV_PATH\Scripts\python.exe" -m pip install --upgrade pip
    if (-not $?) { LogError "Failed to upgrade pip in the new environment" }

    # Register the environment with a relative path
    $RELATIVE_ENV_PATH = $ENV_PATH.Replace("$LOLLMS_HOME\", "%LOLLMS_HOME%\")
    Add-Content -Path (Join-Path $ENVS_DIR "installed_envs.txt") -Value "$ENV_NAME,$RELATIVE_ENV_PATH,$PYTHON_VERSION"

    Log "Environment '$ENV_NAME' created successfully"
}

function Activate-Environment {
    param([string]$ENV_NAME)

    $INSTALLED_ENVS_FILE = Join-Path $ENVS_DIR "installed_envs.txt"

    # Find the environment entry in the installed environments file
    $ENV_ENTRY = Get-Content $INSTALLED_ENVS_FILE | Where-Object { $_ -match "^$ENV_NAME," }
    if (-not $ENV_ENTRY) {
        LogError "Environment '$ENV_NAME' not found"
    }

    $ENV_PATH = $ENV_ENTRY.Split(',')[1]

    # Check if ENV_PATH is relative and convert it to absolute if necessary
    if (-not [System.IO.Path]::IsPathRooted($ENV_PATH)) {
        $ENV_PATH = Join-Path $LOLLMS_HOME $ENV_PATH
    }

    $ACTIVATE_SCRIPT = Join-Path $ENV_PATH "Scripts\Activate.ps1"
    if (-not (Test-Path $ACTIVATE_SCRIPT)) {
        LogError "Activation script not found: $ACTIVATE_SCRIPT"
    }

    # Echo the activation command instead of executing it
    Write-Host ". '$ACTIVATE_SCRIPT'"
}

function Deactivate-Environment {
    Write-Host "To deactivate the current environment, run:"
    Write-Host "deactivate"
}

function Install-Package {
    param([string]$PACKAGE)
    pip install $PACKAGE
    if (-not $?) { LogError "Failed to install package '$PACKAGE'" }
    Log "Package '$PACKAGE' installed in the current environment"
}

function List-Pythons {
    Write-Host "Installed Python versions:"
    Get-Content (Join-Path $PYTHON_DIR "installed_pythons.txt")
}

function List-Environments {
    Write-Host "Installed environments:"
    Get-Content (Join-Path $ENVS_DIR "installed_envs.txt")
}

function Create-Bundle {
    param(
        [string]$BUNDLE_NAME,
        [string]$PYTHON_VERSION,
        [string]$ENV_NAME
    )
    $BUNDLE_DIR = Join-Path $BUNDLES_DIR $BUNDLE_NAME

    if (-not (Test-Path $BUNDLE_DIR)) { New-Item -ItemType Directory -Path $BUNDLE_DIR | Out-Null }
    Install-Python -VERSION $PYTHON_VERSION -CUSTOM_DIR $BUNDLE_DIR
    Create-Environment -ENV_NAME $ENV_NAME -PYTHON_VERSION $PYTHON_VERSION -CUSTOM_DIR $BUNDLE_DIR

    Log "Bundle '$BUNDLE_NAME' created with Python $PYTHON_VERSION and environment '$ENV_NAME' in $BUNDLE_DIR"
}

function Delete-Environment {
    param([string]$ENV_NAME)

    $ENV_PATH = $null
    Get-Content (Join-Path $ENVS_DIR "installed_envs.txt") | ForEach-Object {
        $parts = $_ -split ','
        if ($parts[0] -eq $ENV_NAME) {
            $ENV_PATH = $parts[1]
        }
    }

    if (-not $ENV_PATH) {
        LogError "Environment '$ENV_NAME' not found"
    }

    if (Test-Path $ENV_PATH) {
        Log "Deleting environment '$ENV_NAME' from $ENV_PATH"
        Remove-Item -Recurse -Force $ENV_PATH
        if (-not $?) { LogError "Failed to delete directory $ENV_PATH" }
    } else {
        LogError "Directory $ENV_PATH does not exist"
    }

    $newContent = Get-Content (Join-Path $ENVS_DIR "installed_envs.txt") | Where-Object { $_ -notmatch "^$ENV_NAME," }
    Set-Content -Path (Join-Path $ENVS_DIR "installed_envs.txt") -Value $newContent
    if (-not $?) { LogError "Failed to update installed_envs.txt" }

    Log "Environment '$ENV_NAME' deleted successfully"
}

function Delete-Python {
    param([string]$VERSION)

    $PYTHON_PATH = $null
    Get-Content (Join-Path $PYTHON_DIR "installed_pythons.txt") | ForEach-Object {
        $parts = $_ -split ','
        if ($parts[0] -eq $VERSION) {
            $PYTHON_PATH = $parts[1]
        }
    }

    if (-not $PYTHON_PATH) {
        LogError "Python $VERSION is not installed"
    }

    Log "Deleting Python $VERSION from $PYTHON_PATH"
    Remove-Item -Recurse -Force $PYTHON_PATH
    $newContent = Get-Content (Join-Path $PYTHON_DIR "installed_pythons.txt") | Where-Object { $_ -notmatch "^$VERSION," }
    Set-Content -Path (Join-Path $PYTHON_DIR "installed_pythons.txt") -Value $newContent
    Log "Python $VERSION deleted successfully"
}

function Show-Help {
    @"
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
  create-bundle [name] [python-version] [env-name]  Create a bundle with Python and environment
  delete-env [name]                      Delete a virtual environment
  delete-python [version]                Delete a Python installation
  register-python [path] [version]       Register an existing Python installation
  --help, -h                             Show this help message

Description:
  This tool helps manage Python installations and virtual environments.
  It can install multiple Python versions, create and manage
  virtual environments, and create bundles of Python with environments.
  You can also install Python and environments in custom directories,
  delete environments and Python installations, and register
  existing Python installations.
"@
}

# Main execution
if ($args.Count -eq 0 -or $args[0] -eq "--help" -or $args[0] -eq "-h") {
    Show-Help
} else {
    switch ($args[0]) {
        "install-python" {
            Install-Python -VERSION $args[1] -CUSTOM_DIR $args[2]
        }
        "register-python" {
            Register-PythonInstallation -PYTHON_PATH $args[1] -VERSION $args[2]
        }
        "create-env" {
            Create-Environment -ENV_NAME $args[1] -PYTHON_VERSION $args[2] -CUSTOM_DIR $args[3]
        }
        "activate" {
            Activate-Environment -ENV_NAME $args[1]
        }
        "deactivate" {
            Deactivate-Environment
        }
        "install" {
            Install-Package -PACKAGE $args[1]
        }
        "list-pythons" {
            List-Pythons
        }
        "list-envs" {
            List-Environments
        }
        "create-bundle" {
            Create-Bundle -BUNDLE_NAME $args[1] -PYTHON_VERSION $args[2] -ENV_NAME $args[3]
        }
        "delete-env" {
            Delete-Environment -ENV_NAME $args[1]
        }
        "delete-python" {
            Delete-Python -VERSION $args[1]
        }
        default {
            LogError "Unknown command. Use --help or -h for usage information."
        }
    }
}