#!/bin/bash
# LollmsEnv - Lightweight environment management tool for Lollms projects
# Copyright (c) 2024 ParisNeo
# Licensed under the Apache License, Version 2.0
# Built by ParisNeo using Lollms
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
get_platform_info() {
    local OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local ARCH=$(uname -m)
    
    case $OS in
        linux)
            echo "${ARCH}-.*linux-gnu"
            ;;
        darwin)
            if [ "$ARCH" == "arm64" ]; then
                echo "aarch64-apple-darwin"
            else
                echo "x86_64-apple-darwin"
            fi
            ;;
        *)
            error "Unsupported operating system: $OS"
            ;;
    esac
}
list_available_pythons() {
    local RELEASE_URL="https://api.github.com/repos/indygreg/python-build-standalone/releases"
    local PLATFORM=$(get_platform_info)
    log "Fetching available Python versions for $PLATFORM..."
    
    curl -s "$RELEASE_URL" | 
    grep -oP "cpython-\d+\.\d+\.\d+" | 
    sed 's/cpython-//' | 
    sort -u -V
}
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}
get_python_url() {
    local VERSION=$1
    local PLATFORM=$(get_platform_info)
    local RELEASE_URL="https://api.github.com/repos/indygreg/python-build-standalone/releases"
    
    # Split the version into major, minor, and patch
    IFS='.' read -r MAJOR_VERSION MINOR_VERSION PATCH_VERSION <<< "$VERSION"
   
    local VERSION_PATTERN="cpython-$MAJOR_VERSION\.$MINOR_VERSION"
    if [ -n "$PATCH_VERSION" ]; then
        VERSION_PATTERN="$VERSION_PATTERN\.$PATCH_VERSION"
    else
        VERSION_PATTERN="$VERSION_PATTERN\.[0-9]+"
    fi
    
    local ASSET_INFO=$(curl -s "$RELEASE_URL" | 
                       grep -oP "\"browser_download_url\": \"https://github.com/indygreg/python-build-standalone/releases/download/[^\"]+/$VERSION_PATTERN[^\"]+${PLATFORM}[^\"]*\.tar\.gz\"" | 
                       sort -V | 
                       tail -n 1 | 
                       sed 's/"browser_download_url": "//' | 
                       sed 's/"//')
    
    if [ -z "$ASSET_INFO" ]; then
        log "No compatible Python version found for $MAJOR_VERSION.$MINOR_VERSION${PATCH_VERSION:+.$PATCH_VERSION} on $PLATFORM"
        return 1
    fi
    
    # URL encode the asset info
    ENCODED_URL=$(urlencode "$ASSET_INFO")
    
    echo "$ENCODED_URL"
}






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

urldecode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

install_python() {
    local VERSION=$1
    local CUSTOM_DIR=$2
    
    # Additional debugging information
    log "Python Dir: $PYTHON_DIR"
    log "Temp Dir: $TEMP_DIR"
    log "Current user: $(whoami)"
    log "Current directory: $(pwd)"
    
    # Ensure required variables are set
    [ -z "$PYTHON_DIR" ] && error "PYTHON_DIR is not set"
    [ -z "$TEMP_DIR" ] && error "TEMP_DIR is not set"
    
    # Check if TEMP_DIR is writable
    if [ ! -w "$TEMP_DIR" ]; then
        error "TEMP_DIR ($TEMP_DIR) is not writable. Please check permissions."
    fi
    
    local ENCODED_URL=$(get_python_url "$VERSION")

    echo "$ENCODED_URL"
    
    if [ -z "$ENCODED_URL" ]; then
        error "Failed to find Python $VERSION download URL"
    fi
    
    local URL=$(urldecode "$ENCODED_URL")
    log "Downloading Python $VERSION from $URL"
    
    # Extract the actual version from the URL
    local ACTUAL_VERSION=$(echo "$URL" | grep -oP "cpython-\K[0-9]+\.[0-9]+\.[0-9]+")
    log "Actual version available: $ACTUAL_VERSION"
    
    TARGET_DIR="${CUSTOM_DIR:-$PYTHON_DIR}/$ACTUAL_VERSION"
    
    if [ -d "$TARGET_DIR" ]; then
        log "Target directory $TARGET_DIR already exists. Skipping installation."
        return 0
    fi
    
    mkdir -p "$TARGET_DIR" || error "Failed to create directory $TARGET_DIR"
    
    local ARCHIVE="$TEMP_DIR/python-$ACTUAL_VERSION.tar.gz"
    log "Attempting to download to: $ARCHIVE"
    
    wget --no-check-certificate -q --show-progress --progress=bar:force:noscroll "$URL" -O "$ARCHIVE" || {
        log "Wget failed. Trying curl..."
        curl -L "$URL" -o "$ARCHIVE" || error "Both wget and curl failed to download Python $ACTUAL_VERSION"
    }
    
    log "Extracting Python $ACTUAL_VERSION to $TARGET_DIR"
    tar -xzf "$ARCHIVE" -C "$TARGET_DIR" --strip-components=1 || error "Failed to extract Python $ACTUAL_VERSION"
    
    if [ ! -f "$TARGET_DIR/bin/python3" ]; then
        error "Python binary not found after extraction. Installation failed."
    fi
    
    log "Ensuring pip and venv are installed"
    "$TARGET_DIR/bin/python3" -m ensurepip --upgrade || error "Failed to ensure pip is installed"
    "$TARGET_DIR/bin/python3" -m pip install --upgrade pip || error "Failed to upgrade pip"
    "$TARGET_DIR/bin/python3" -m pip install virtualenv || error "Failed to install virtualenv"
    
    echo "$ACTUAL_VERSION:$TARGET_DIR" >> "$PYTHON_DIR/installed_pythons.txt"
    log "Python $ACTUAL_VERSION installed successfully with pip and venv in $TARGET_DIR"
}


create_env() {
    local ENV_NAME=$1
    local PYTHON_VERSION=$2
    local CUSTOM_DIR=$3
    
    local PYTHON_PATH=$(grep "^$PYTHON_VERSION:" "$PYTHON_DIR/installed_pythons.txt" | cut -d':' -f2)/bin/python3

    echo "Using Python: $PYTHON_PATH"
    
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
    
    # Activate the new environment and install basic packages
    source "$ENV_PATH/bin/activate"
    pip install --upgrade pip
    pip install wheel setuptools
    deactivate
}
activate_env() {
    env_name=$1
    envs_file="$LOLLMS_HOME/envs/installed_envs.txt"
    env_path=""
    python_path=""

    # Check if the environment exists in the installed_envs.txt file
    if [ -f "$envs_file" ]; then
        while IFS=: read -r name path python_info; do
            if [ "$name" == "$env_name" ]; then
                env_path="$path"
                # Determine if python_info is a full path or a version
                if [[ "$python_info" == /* ]]; then
                    # Full path
                    python_path="$python_info"
                else
                    # Version, construct the full path
                    python_path="$LOLLMS_HOME/python/$python_info"
                fi
                break
            fi
        done < "$envs_file"
    fi

    # If the environment path is not found, return an error
    if [ -z "$env_path" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Error: Environment '$env_name' does not exist in $envs_file"
        return 1
    fi

    # Check if the environment directory exists
    if [ -d "$env_path" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Activating environment '$env_name'"

        # Add Python path to the PATH variable if it exists
        if [ -n "$python_path" ] && [ -d "$python_path/bin" ]; then
            export PATH="$python_path/bin:$PATH"
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Added Python path '$python_path/bin' to PATH"
        else
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Warning: Python path '$python_path/bin' does not exist or is invalid"
        fi

        # Activate the environment
        source "$env_path/bin/activate"
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Environment '$env_name' activated"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Error: Environment directory '$env_path' does not exist"
        return 1
    fi
}

deactivate_env() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Deactivating current environment"
        deactivate
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Environment deactivated"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] No active virtual environment to deactivate"
    fi
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
delete_env() {
    local ENV_NAME=$1
    local ENV_PATH=$(grep "^$ENV_NAME:" "$ENVS_DIR/installed_envs.txt" | cut -d':' -f2)
    
    if [ -z "$ENV_PATH" ]; then
        error "Environment '$ENV_NAME' not found"
    fi
    
    log "Deleting environment '$ENV_NAME' from $ENV_PATH"
    rm -rf "$ENV_PATH"
    sed -i "/^$ENV_NAME:/d" "$ENVS_DIR/installed_envs.txt"
    log "Environment '$ENV_NAME' deleted successfully"
}
delete_python() {
    local VERSION=$1
    local PYTHON_PATH=$(grep "^$VERSION:" "$PYTHON_DIR/installed_pythons.txt" | cut -d':' -f2)
    
    if [ -z "$PYTHON_PATH" ]; then
        error "Python $VERSION is not installed"
    fi
    
    log "Deleting Python $VERSION from $PYTHON_PATH"
    rm -rf "$PYTHON_PATH"
    sed -i "/^$VERSION:/d" "$PYTHON_DIR/installed_pythons.txt"
    log "Python $VERSION deleted successfully"
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
    echo "  list-available-pythons                 List available Python versions for installation"
    echo "  create-bundle [name] [python-version] [env-name]  Create a bundle with Python and environment"
    echo "  delete-env [name]                      Delete a virtual environment"
    echo "  delete-python [version]                Delete a Python installation"
    echo "  --help, -h                             Show this help message"
    echo
    echo "Description:"
    echo "  This tool helps manage Python installations and virtual environments."
    echo "  It scans for existing Python installations before downloading."
    echo "  You can install multiple Python versions, create and manage"
    echo "  virtual environments, and create bundles of Python with environments."
    echo "  You can also install Python and environments in custom directories."
    echo "  Now you can delete environments and Python installations as well."
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
    list-available-pythons)
        list_available_pythons
        ;;
    create-bundle)
        create_bundle "$2" "$3" "$4"
        ;;
    delete-env)
        delete_env "$2"
        ;;
    delete-python)
        delete_python "$2"
        ;;
    --help|-h)
        show_help
        ;;
    *)
        error "Unknown command. Use --help or -h for usage information."
        ;;
esac
