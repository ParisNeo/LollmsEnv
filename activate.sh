#!/bin/bash
# LollmsEnv - Lightweight environment management tool for Lollms projects
# Copyright (c) 2024 ParisNeo
# Licensed under the Apache License, Version 2.0
# Built by ParisNeo using Lollms
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "$SCRIPT_DIR"
if [ -d "$SCRIPT_DIR" ]; then
    export LOLLMSENV_DIR="$SCRIPT_DIR"
else
    export LOLLMSENV_DIR="$HOME/.lollmsenv"
fi
export PATH="$LOLLMSENV_DIR/bin:$PATH"

echo "LollmsEnv activated. You can now use 'lollmsenv' commands."
