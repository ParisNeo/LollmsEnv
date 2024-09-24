#!/bin/bash

# LollmsEnv - Lightweight environment management tool for Lollms projects
# Copyright (c) 2024 ParisNeo
# Licensed under the Apache License, Version 2.0
# Built by ParisNeo using Lollms

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
LOLLMS_HOME="$(dirname "$SCRIPT_DIR")"
PYTHON_DIR="$LOLLMS_HOME/pythons"
ENVS_DIR="$LOLLMS_HOME/envs"
BUNDLES_DIR="$LOLLMS_HOME/bundles"
TEMP_DIR="/tmp/lollmsenv"
mkdir -p "$PYTHON_DIR" "$ENVS_DIR" "$BUNDLES_DIR" "$TEMP_DIR"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    log "ERROR: $1" >&2
    exit 1
}

cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

scan_for_python() {
    local VERSION=$1
    local LOCATIONS=(
        "/usr/bin/python$VERSION"
        "/usr/local/bin/python$VERSION"
        "$HOME/.pyenv/versions/$VERSION/bin/python"
        "$HOME/anaconda3/envs/py$VERSION/bin/python"
        "$HOME/miniconda3/envs/py$VERSION/bin/python"
    )

    for loc in "${LOCATIONS[@]}"; do
        if [ -x "$loc" ]; then
            echo "$loc"
            return 0
        fi
    done

    return 1
}

get_python_url() {
    local VERSION=$1
    local OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local ARCH=$(uname -m)
    local RELEASE_URL="https://api.github.com/repos/indygreg/python-build-standalone/releases"
    
    local ASSET_NAME
    case $OS in
        linux)
            ASSET_NAME="cpython-${VERSION}+*-${ARCH}-unknown-linux-gnu-pgo+lto.tar.gz"
            ;;
        darwin)
            if [ "$ARCH" == "arm64" ]; then
                ASSET_NAME="cpython-${VERSION}+*-aarch64-apple-darwin-pgo+lto.tar.gz"
            else
                ASSET_NAME="cpython-${VERSION}+*-x86_64-apple-darwin-pgo+lto.tar.gz"
            fi
            ;;
        *)
            error "Unsupported operating system: $OS"
            ;;
    esac
    
    # Try to find the exact version first
    local URL=$(curl -s "$RELEASE_URL" | grep -o "https://github.com.*${ASSET_NAME}" | head -n 1)
    
    # If exact version is not found, try with a more flexible pattern
    if [ -z "$URL" ]; then
        local MAJOR_MINOR=$(echo $VERSION | cut -d. -f1-2)
        ASSET_NAME="cpython-${MAJOR_MINOR}.*-${ARCH}-unknown-linux-gnu-pgo+lto.tar.gz"
        URL=$(curl -s "$RELEASE_URL" | grep -o "https://github.com.*${ASSET_NAME}" | head -n 1)
    fi
    
    echo "$URL"
}

install_python() {
    local VERSION=$1
    local CUSTOM_DIR=$2
    
    # First, scan for existing Python installation
    local EXISTING_PYTHON=$(scan_for_python "$VERSION")
    
    if [ -n "$EXISTING_PYTHON" ]; then
        log "Found existing Python $VERSION installation at $EXISTING_PYTHON"
        
        if [ -z "$CUSTOM_DIR" ]; then
            TARGET_DIR="$PYTHON_DIR/$VERSION"
        else
            TARGET_DIR="$CUSTOM_DIR/$VERSION"
        fi
        
        mkdir -p "$TARGET_DIR"
        ln -s "$EXISTING_PYTHON" "$TARGET_DIR/bin/python3"
        ln -s "$(dirname "$EXISTING_PYTHON")/pip$VERSION" "$TARGET_DIR/bin/pip" 2>/dev/null || true
        
        log "Created symlinks to existing Python $VERSION in $TARGET_DIR"
        echo "$VERSION:$TARGET_DIR" >> "$PYTHON_DIR/installed_pythons.txt"
        return 0
    fi
    
    local URL=$(get_python_url "$VERSION")
    
    if [ -z "$URL" ]; then
        log "WARNING: Failed to find Python $VERSION download URL. Trying to find a compatible version..."
        local MAJOR_MINOR=$(echo $VERSION | cut -d. -f1-2)
        URL=$(get_python_url "$MAJOR_MINOR")
        if [ -z "$URL" ]; then
            error "Failed to find a compatible Python version for $VERSION"
        else
            log "Found a compatible version. Using $URL"
        fi
    fi
    
    log "Downloading Python $VERSION from $URL"
    
    if [ -z "$CUSTOM_DIR" ]; then
        TARGET_DIR="$PYTHON_DIR/$VERSION"
    else
        TARGET_DIR="$CUSTOM_DIR/$VERSION"
    fi
    
    mkdir -p "$TARGET_DIR"
    
    local ARCHIVE="$TEMP_DIR/python-$VERSION.tar.gz"
    curl -L -o "$ARCHIVE" "$URL" || error "Failed to download Python $VERSION"
    
    log "Extracting Python $VERSION to $TARGET_DIR"
    tar -xzf "$ARCHIVE" -C "$TARGET_DIR" --strip-components=1 || error "Failed to extract Python $VERSION"
    
    log "Ensuring pip and venv are installed"
    "$TARGET_DIR/bin/python3" -m ensurepip --upgrade || error "Failed to ensure pip is installed"
    "$TARGET_DIR/bin/python3" -m pip install --upgrade pip || error "Failed to upgrade pip"
    "$TARGET_DIR/bin/python3" -m pip install virtualenv || error "Failed to install virtualenv"
    
    echo "$VERSION:$TARGET_DIR" >> "$PYTHON_DIR/installed_pythons.txt"
    log "Python $VERSION installed successfully with pip and venv in $TARGET_DIR"
}

create_env() {
    local ENV_NAME=$1
    local PYTHON_VERSION=$2
    local CUSTOM_DIR=$3
    
    local PYTHON_PATH=$(grep "^$PYTHON_VERSION:" "$PYTHON_DIR/installed_pythons.txt" | cut -d':' -f2)/bin/python3
    
    if [ ! -f "$PYTHON_PATH" ]; then
        error "Python $PYTHON_VERSION is not installed"
    fi
    
    if [ -z "$CUSTOM_DIR" ]; then
        ENV_PATH="$ENVS_DIR/$ENV_NAME"
    else
        ENV_PATH="$CUSTOM_DIR/$ENV_NAME"
    fi
    
    log "Creating virtual environment '$ENV_NAME' with Python $PYTHON_VERSION in $ENV_PATH"
    "$PYTHON_PATH" -m venv "$ENV_PATH" || error "Failed to create virtual environment"
    
    echo "$ENV_NAME:$ENV_PATH:$PYTHON_VERSION" >> "$ENVS_DIR/installed_envs.txt"
    log "Environment '$ENV_NAME' created successfully"
}

activate_env() {
    local ENV_NAME=$1
    local ENV_PATH=$(grep "^$ENV_NAME:" "$ENVS_DIR/installed_envs.txt" | cut -d':' -f2)
    
    if [ -z "$ENV_PATH" ]; then
        error "Environment '$ENV_NAME' not found"
    fi
    
    local ACTIVATE_SCRIPT="$ENV_PATH/bin/activate"
    echo "To activate the environment, run:"
    echo "source $ACTIVATE_SCRIPT"
}

deactivate_env() {
    echo "To deactivate the current environment, run:"
    echo "deactivate"
}

install_package() {
    local PACKAGE=$1
    pip install "$PACKAGE" || error "Failed to install package '$PACKAGE'"
    log "Package '$PACKAGE' installed in the current environment"
}

list_pythons() {
    echo "Installed Python versions:"
    cat "$PYTHON_DIR/installed_pythons.txt"
}

list_envs() {
    echo "Installed environments:"
    cat "$ENVS_DIR/installed_envs.txt"
}

create_bundle() {
    local BUNDLE_NAME=$1
    local PYTHON_VERSION=$2
    local ENV_NAME=$3
    local BUNDLE_DIR="$BUNDLES_DIR/$BUNDLE_NAME"
    
    mkdir -p "$BUNDLE_DIR"
    install_python "$PYTHON_VERSION" "$BUNDLE_DIR"
    create_env "$ENV_NAME" "$PYTHON_VERSION" "$BUNDLE_DIR"
    
    log "Bundle '$BUNDLE_NAME' created with Python $PYTHON_VERSION and environment '$ENV_NAME' in $BUNDLE_DIR"
}

show_help() {
    echo "lollmsenv - Python and Virtual Environment Management Tool"
    echo
    echo "Usage: ./lollmsenv.sh [command] [options]"
    echo
    echo "Commands:"
    echo "  install-python [version] [custom_dir]  Install a specific Python version"
    echo "  create-env [name] [python-version] [custom_dir]  Create a new virtual environment"
    echo "  activate [name]                        Show command to activate an environment"
    echo "  deactivate                             Show command to deactivate the current environment"
    echo "  install [package]                      Install a package in the current environment"
    echo "  list-pythons                           List installed Python versions"
    echo "  list-envs                              List installed virtual environments"
    echo "  create-bundle [name] [python-version] [env-name]  Create a bundle with Python and environment"
    echo "  --help, -h                             Show this help message"
    echo
    echo "Description:"
    echo "  This tool helps manage Python installations and virtual environments."
    echo "  It scans for existing Python installations before downloading."
    echo "  You can install multiple Python versions, create and manage"
    echo "  virtual environments, and create bundles of Python with environments."
    echo "  You can also install Python and environments in custom directories."
}

case $1 in
    install-python)
        install_python "$2" "$3"
        ;;
    create-env)
        create_env "$2" "$3" "$4"
        ;;
    activate)
        activate_env "$2"
        ;;
    deactivate)
        deactivate_env
        ;;
    install)
        install_package "$2"
        ;;
    list-pythons)
        list_pythons
        ;;
    list-envs)
        list_envs
        ;;
    create-bundle)
        create_bundle "$2" "$3" "$4"
        ;;
    --help|-h)
        show_help
        ;;
    *)
        error "Unknown command. Use --help or -h for usage information."
        ;;
esac
