#!/bin/bash

if [ "$1" == "--local" ]; then
    INSTALL_DIR="$PWD/.lollmsenv"
    LOCAL_INSTALL=1
else
    INSTALL_DIR="$HOME/.lollmsenv"
    LOCAL_INSTALL=0
fi

SCRIPT_DIR="$INSTALL_DIR/bin"

mkdir -p "$SCRIPT_DIR"

cp src/lollmsenv.sh "$SCRIPT_DIR/lollmsenv"
chmod +x "$SCRIPT_DIR/lollmsenv"
cp activate.sh "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/activate.sh"

if [ $LOCAL_INSTALL -eq 0 ]; then
    echo 'export PATH="$PATH:$HOME/.lollmsenv/bin"' >> "$HOME/.bashrc"
    echo 'export PATH="$PATH:$HOME/.lollmsenv/bin"' >> "$HOME/.zshrc"
    echo "LollmsEnv has been installed globally. Please restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc) to use it."
else
    echo "LollmsEnv has been installed locally in the current directory."
    echo "To use LollmsEnv, run 'source activate.sh' in this directory."
fi
