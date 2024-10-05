#!/bin/bash

VERSION="1.2.9"

# URL of the latest release
RELEASE_URL="https://github.com/ParisNeo/LollmsEnv/archive/refs/tags/V${VERSION}.tar.gz"

# Temporary directory for downloading and extraction
TEMP_DIR="/tmp/lollmsenv_install"

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Download the latest release
echo "Downloading LollmsEnv version ${VERSION}..."
curl -L "$RELEASE_URL" -o "$TEMP_DIR/lollmsenv.tar.gz"

# Extract the archive
echo "Extracting files..."
tar -xzf "$TEMP_DIR/lollmsenv.tar.gz" -C "$TEMP_DIR" --strip-components=1

# Change to the extracted directory
cd "$TEMP_DIR"

# Run the install script with forwarded parameters
echo "Running installation..."
chmod +x install.sh
./install.sh "$@"

# Clean up
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Installation complete."
