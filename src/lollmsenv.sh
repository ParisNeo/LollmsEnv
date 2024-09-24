#!/bin/bash
# lollmsenv.sh
# Determine the installation directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
LOLLMS_HOME="$(dirname "$SCRIPT_DIR")"
PYTHON_DIR="$LOLLMS_HOME/pythons"
ENVS_DIR="$LOLLMS_HOME/envs"
install_python() {
    VERSION=$1
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $OS in
        linux)
            URL="https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-${VERSION}+20230507-${ARCH}-unknown-linux-gnu-install_only.tar.gz"
            ;;
        darwin)
            if [ "$ARCH" == "arm64" ]; then
                URL="https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-${VERSION}+20230507-aarch64-apple-darwin-install_only.tar.gz"
            else
                URL="https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-${VERSION}+20230507-x86_64-apple-darwin-install_only.tar.gz"
            fi
            ;;
        *)
            echo "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    TARGET_DIR="$PYTHON_DIR/$VERSION"
    mkdir -p "$TARGET_DIR"
    curl -L -o "$TARGET_DIR/python.tar.gz" "$URL"
    tar -xzf "$TARGET_DIR/python.tar.gz" -C "$TARGET_DIR" --strip-components=1
    rm "$TARGET_DIR/python.tar.gz"
    echo "Python $VERSION installed successfully."
}
create_env() {
    ENV_NAME=$1
    PYTHON_VERSION=$2
    ENV_PATH="$ENVS_DIR/$ENV_NAME"
    PYTHON_PATH="$PYTHON_DIR/$PYTHON_VERSION/bin/python3"
    mkdir -p "$ENV_PATH"
    "$PYTHON_PATH" -m venv "$ENV_PATH"
    echo "Environment '$ENV_NAME' created with Python $PYTHON_VERSION"
}
activate_env() {
    ENV_NAME=$1
    ACTIVATE_SCRIPT="$ENVS_DIR/$ENV_NAME/bin/activate"
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
case $1 in
    install-python)
        install_python $2
        ;;
    create-env)
        create_env $2 $3
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
    *)
        echo "Unknown command. Available commands:"
        echo "install-python [version]"
        echo "create-env [name] [python-version]"
        echo "activate [name]"
        echo "deactivate"
        echo "install [package]"
        ;;
esac
