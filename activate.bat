@echo off
REM LollmsEnv - Lightweight environment management tool for Lollms projects
REM Copyright (c) 2024 ParisNeo
REM Licensed under the Apache License, Version 2.0
REM Built by ParisNeo using Lollms
SET SCRIPT_DIR=%~dp0
IF EXIST "%SCRIPT_DIR%.lollmsenv" (
    SET LOLLMSENV_DIR=%SCRIPT_DIR%.lollmsenv
) ELSE (
    SET LOLLMSENV_DIR=%USERPROFILE%\.lollmsenv
)
SET PATH=%LOLLMSENV_DIR%\bin;%PATH%
echo LollmsEnv activated. You can now use 'lollmsenv' commands.
