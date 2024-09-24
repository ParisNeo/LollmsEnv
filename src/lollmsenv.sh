#!/bin/bash
# lollmsenv.sh
# Determine the installation directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
LOLLMS_HOME="$(dirname "$SCRIPT_DIR")"
PYTHON_DIR="$LOLLMS_HOME/pythons"
ENVS_DIR="$LOLLMS_HOME/envs"
BUNDLES_DIR="$LOLLMS_HOME/bundles"
install_python() {
    VERSION=$1
    CUSTOM_DIR=$2
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $OS in
        linux)
            URL="https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-${VERSION}+20230507-${ARCH}-unknown-linux-gnu-pgo+lto.tar.gz"
            ;;
        darwin)
            if [ "$ARCH" == "arm64" ]; then
                URL="https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-${VERSION}+20230507-aarch64-apple-darwin-pgo+lto.tar.gz"
            else
                URL="https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-${VERSION}+20230507-x86_64-apple-darwin-pgo+lto.tar.gz"
            fi
            ;;
        *)
            echo "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    if [ -z "$CUSTOM_DIR" ]; then
        TARGET_DIR="$PYTHON_DIR/$VERSION"
    else
        TARGET_DIR="$CUSTOM_DIR/$VERSION"
    fi
    mkdir -p "$TARGET_DIR"
    curl -L -o "$TARGET_DIR/python.tar.gz" "$URL"
    tar -xzf "$TARGET_DIR/python.tar.gz" -C "$TARGET_DIR" --strip-components=1
    rm "$TARGET_DIR/python.tar.gz"
    # Ensure pip and venv are installed
    "$TARGET_DIR/bin/python3" -m ensurepip --upgrade
    "$TARGET_DIR/bin/python3" -m pip install --upgrade pip
    "$TARGET_DIR/bin/python3" -m pip install virtualenv
    # Add to tracking file
    echo "$VERSION:$TARGET_DIR" >> "$PYTHON_DIR/installed_pythons.txt"
    echo "Python $VERSION installed successfully with pip and venv in $TARGET_DIR."
}
create_env() {
    ENV_NAME=$1
    PYTHON_VERSION=$2
    CUSTOM_DIR=$3
    PYTHON_PATH=$(grep "^$PYTHON_VERSION:" "$PYTHON_DIR/installed_pythons.txt" | cut -d':' -f2)/bin/python3
    if [ -z "$CUSTOM_DIR" ]; then
        ENV_PATH="$ENVS_DIR/$ENV_NAME"
    else
        ENV_PATH="$CUSTOM_DIR/$ENV_NAME"
    fi
    "$PYTHON_PATH" -m venv "$ENV_PATH"
    
    # Add to tracking file
    echo "$ENV_NAME:$ENV_PATH:$PYTHON_VERSION" >> "$ENVS_DIR/installed_envs.txt"
    echo "Environment '$ENV_NAME' created with Python $PYTHON_VERSION in $ENV_PATH"
}
activate_env() {
    ENV_NAME=$1
    ENV_PATH=$(grep "^$ENV_NAME:" "$ENVS_DIR/installed_envs.txt" | cut -d':' -f2)
    ACTIVATE_SCRIPT="$ENV_PATH/bin/activate"
    echo "To activate the environment, run:"
    echo "source $ACTIVATE_SCRIPT"
}
deactivate_env() {
    echo "To deactivate the current environment, run:"
    echo "deactivate"
}
install_package() {
    PACKAGE=$1
    pip install "$PACKAGE"
    echo "Package '$PACKAGE' installed in the current environment"
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
    BUNDLE_NAME=$1
    PYTHON_VERSION=$2
    ENV_NAME=$3
    BUNDLE_DIR="$BUNDLES_DIR/$BUNDLE_NAME"
    mkdir -p "$BUNDLE_DIR"
    install_python "$PYTHON_VERSION" "$BUNDLE_DIR"
    create_env "$ENV_NAME" "$PYTHON_VERSION" "$BUNDLE_DIR"
    echo "Bundle '$BUNDLE_NAME' created with Python $PYTHON_VERSION and environment '$ENV_NAME' in $BUNDLE_DIR"
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
    echo "  It allows you to install multiple Python versions, create and manage"
    echo "  virtual environments, and create bundles of Python with environments."
    echo "  You can also install Python and environments in custom directories."
}
case $1 in
    install-python)
        install_python $2 $3
        ;;
    create-env)
        create_env $2 $3 $4
        ;;
    activate)
        activate_env $2
        ;;
    deactivate)
        deactivate_env
        ;;
    install)
        install_package $2
        ;;
    list-pythons)
        list_pythons
        ;;
    list-envs)
        list_envs
        ;;
    create-bundle)
        create_bundle $2 $3 $4
        ;;
    --help|-h)
        show_help
        ;;
    *)
        echo "Unknown command. Use --help or -h for usage information."
        ;;
esac
