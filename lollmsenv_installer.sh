#!/bin/bash

VERSION="1.3.0"
USE_MASTER=false

# Check for --use-master option
for arg in "$@"; do
    if [ "$arg" == "--use-master" ]; then
        USE_MASTER=true
        break
    fi
done

# Temporary directory for downloading and extraction
TEMP_DIR="/tmp/lollmsenv_install"

# Create temporary directory
mkdir -p "$TEMP_DIR"

if [ "$USE_MASTER" = true ]; then
    echo "Cloning LollmsEnv master branch..."
    git clone https://github.com/ParisNeo/LollmsEnv.git "$TEMP_DIR"
    cd "$TEMP_DIR"
else
    # URL of the latest release
    RELEASE_URL="https://github.com/ParisNeo/LollmsEnv/archive/refs/tags/V${VERSION}.tar.gz"

    # Download the latest release
    echo "Downloading LollmsEnv version ${VERSION}..."
    curl -L "$RELEASE_URL" -o "$TEMP_DIR/lollmsenv.tar.gz"

    # Extract the archive
    echo "Extracting files..."
    tar -xzf "$TEMP_DIR/lollmsenv.tar.gz" -C "$TEMP_DIR" --strip-components=1

    # Change to the extracted directory
    cd "$TEMP_DIR"
fi

# Remove --use-master from arguments
args=("$@")
for i in "${!args[@]}"; do
    if [[ ${args[i]} = "--use-master" ]]; then
        unset 'args[i]'
    fi
done

# Run the install script with forwarded parameters
echo "Running installation..."
chmod +x install.sh
./install.sh "${args[@]}"

# Clean up
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Installation complete."
