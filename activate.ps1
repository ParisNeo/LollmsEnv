# LollmsEnv - Lightweight environment management tool for Lollms projects
# Copyright (c) 2024 ParisNeo
# Licensed under the Apache License, Version 2.0
# Built by ParisNeo using Lollms
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (Test-Path "$SCRIPT_DIR\.lollmsenv") {
    $env:LOLLMSENV_DIR = "$SCRIPT_DIR\.lollmsenv"
} else {
    $env:LOLLMSENV_DIR = "$env:USERPROFILE\.lollmsenv"
}
$env:PATH = "$env:LOLLMSENV_DIR\bin;" + $env:PATH
Write-Host "LollmsEnv activated. You can now use 'lollmsenv' commands."
