#!/bin/bash
# Remove the installation directory
rm -rf "$HOME/.lollmsenv"
# Remove the PATH modifications from .bashrc and .zshrc
sed -i '/export PATH="\$PATH:\$HOME\/.lollmsenv\/bin"/d' "$HOME/.bashrc"
sed -i '/export PATH="\$PATH:\$HOME\/.lollmsenv\/bin"/d' "$HOME/.zshrc"
echo "LollmsEnv has been uninstalled."
