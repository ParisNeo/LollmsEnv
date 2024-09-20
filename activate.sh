#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -d "$SCRIPT_DIR/.lollmsenv" ]; then
    export LOLLMSENV_DIR="$SCRIPT_DIR/.lollmsenv"
else
    export LOLLMSENV_DIR="$HOME/.lollmsenv"
fi
export PATH="$LOLLMSENV_DIR/bin:$PATH"

echo "LollmsEnv activated. You can now use 'lollmsenv' commands."
