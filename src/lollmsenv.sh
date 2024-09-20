#!/bin/bash
# lollmsenv.sh

LOLLMS_HOME="$HOME/.lollmsenv"
PYTHON_DIR="$LOLLMS_HOME/pythons"
ENVS_DIR="$LOLLMS_HOME/envs"

install_python() {
    VERSION=$1
    PYTHON_URL="https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz"
    TARGET_DIR="$PYTHON_DIR/$VERSION"

    mkdir -p "$TARGET_DIR"
    curl -o "$TARGET_DIR/python.tgz" "$PYTHON_URL"
    tar -xzf "$TARGET_DIR/python.tgz" -C "$TARGET_DIR"
    cd "$TARGET_DIR/Python-$VERSION"
    ./configure --prefix="$TARGET_DIR"
    make install
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
