#!/bin/bash
# LollmsEnv - Lightweight environment management tool for Lollms projects
# Copyright (c) 2024 ParisNeo
# Licensed under the Apache License, Version 2.0
# Built by ParisNeo using Lollms

# Function to display help message
show_help() {
    echo "Usage: $0 [--local] [--dir <directory>] [--no-modify-rc] [-h|--help]"
    echo "Options:"
    echo "  --local       Install LollmsEnv locally in the current directory."
    echo "  --dir <directory> Install LollmsEnv in the specified directory."
    echo "  --no-modify-rc Do not modify .bashrc or .zshrc. Generate a source.sh script instead."
    echo "  -h, --help    Show this help message and exit."
}
# Parse command-line arguments
LOCAL_INSTALL=0
NO_MODIFY_RC=0
INSTALL_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            LOCAL_INSTALL=1
            shift
            ;;
        --dir)
            LOCAL_INSTALL=1
            INSTALL_DIR="$2"
            shift 2
            ;;
        --no-modify-rc)
            NO_MODIFY_RC=1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done
# Set default installation directory if not specified
if [ -z "$INSTALL_DIR" ]; then
    if [ "$LOCAL_INSTALL" -eq 1 ]; then
        INSTALL_DIR="$PWD/.lollmsenv"
    else
        INSTALL_DIR="$HOME/.lollmsenv"
    fi
fi
SCRIPT_DIR="$INSTALL_DIR/bin"
mkdir -p "$SCRIPT_DIR"
cp src/lollmsenv.sh "$SCRIPT_DIR/lollmsenv"
chmod +x "$SCRIPT_DIR/lollmsenv"
cp activate.sh "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/activate.sh"
# Define the delimiter
DELIMITER="# BEGIN LOLLMS ENV"
END_DELIMITER="# END LOLLMS ENV"
# Function to add the source line to RC files
add_to_rc_file() {
    local rc_file="$1"
    if ! grep -q "$DELIMITER" "$rc_file"; then
        echo "" >> "$rc_file"
        echo "$DELIMITER" >> "$rc_file"
        echo 'source $HOME/.lollmsenv/activate.sh' >> "$rc_file"
        echo "$END_DELIMITER" >> "$rc_file"
        echo "Added LollmsEnv to $rc_file"
    else
        echo "LollmsEnv already exists in $rc_file"
    fi
}

if [ "$LOCAL_INSTALL" -eq 0 ] && [ "$NO_MODIFY_RC" -eq 0 ]; then
    # Add to .bashrc
    add_to_rc_file "$HOME/.bashrc"
    # Add to .zshrc
    add_to_rc_file "$HOME/.zshrc"
    echo "LollmsEnv has been installed globally. Please restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc) to use it."
else
    echo "LollmsEnv has been installed in: $INSTALL_DIR"
    echo "To use LollmsEnv, run 'source $INSTALL_DIR/activate.sh'"
    if [ "$NO_MODIFY_RC" -eq 1 ]; then
        echo '#!/bin/bash' > "$INSTALL_DIR/source.sh"
        echo 'export PATH="$PATH:'"$SCRIPT_DIR"'"' >> "$INSTALL_DIR/source.sh"
        chmod +x "$INSTALL_DIR/source.sh"
        echo "A source.sh script has been generated. Run 'source $INSTALL_DIR/source.sh' to use LollmsEnv."
    else
        # Function to add the source line to RC files
        add_1_to_rc_file() {
            local rc_file="$1"
            if ! grep -q "$DELIMITER" "$rc_file"; then
                echo "" >> "$rc_file"
                echo "$DELIMITER" >> "$rc_file"
                echo "source $INSTALL_DIR/activate.sh" >> "$rc_file"
                echo "$END_DELIMITER" >> "$rc_file"
                echo "Added LollmsEnv to $rc_file"
            else
                echo "LollmsEnv already exists in $rc_file"
            fi
        }
    
        # Add to .bashrc
        add_1_to_rc_file "$HOME/.bashrc"
    
        # Add to .zshrc if it exists
        if [ -f "$HOME/.zshrc" ]; then
            add_1_to_rc_file "$HOME/.zshrc"
        fi
    fi
fi
echo "Installation done"
