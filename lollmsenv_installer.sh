#!/bin/bash

VERSION="1.2.10"
REPO_URL="https://github.com/ParisNeo/LollmsEnv.git"
RELEASE_URL="https://github.com/ParisNeo/LollmsEnv/archive/refs/tags/V${VERSION}.tar.gz"
TEMP_DIR="/tmp/lollmsenv_install"

# Check for --use-master option
USE_MASTER=false
for arg in "$@"; do
    if [ "$arg" == "--use-master" ]; then
        USE_MASTER=true
        break
    fi
done

mkdir -p "$TEMP_DIR"

if [ "$USE_MASTER" = true ]; then
    echo "Cloning master branch..."
    git clone "$REPO_URL" "$TEMP_DIR"
    cd "$TEMP_DIR"
else
    echo "Downloading LollmsEnv version ${VERSION}..."
    curl -L "$RELEASE_URL" -o "$TEMP_DIR/lollmsenv.tar.gz"
    tar -xzf "$TEMP_DIR/lollmsenv.tar.gz" -C "$TEMP_DIR" --strip-components=1
    cd "$TEMP_DIR"
fi

echo "Running installation..."
chmod +x install.sh
./install.sh "$@"

echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Installation complete."
