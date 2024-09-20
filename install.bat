@echo off
:: LollmsEnv - Lightweight environment management tool for Lollms projects
:: Copyright (c) 2024 ParisNeo
:: Licensed under the Apache License, Version 2.0
:: Built by ParisNeo using Lollms
setlocal enabledelayedexpansion
if "%1"=="--local" (
    set INSTALL_DIR=%CD%\.lollmsenv
    set LOCAL_INSTALL=1
) else (
    set INSTALL_DIR=%USERPROFILE%\.lollmsenv
    set LOCAL_INSTALL=0
)
set SCRIPT_DIR=%INSTALL_DIR%\bin
set CONFIG_FILE=%INSTALL_DIR%\lollmsenv.config
if not exist %INSTALL_DIR% mkdir %INSTALL_DIR%
if not exist %SCRIPT_DIR% mkdir %SCRIPT_DIR%
:: Copy scripts
copy /Y src\lollmsenv.bat %SCRIPT_DIR%
copy /Y src\activate.bat %INSTALL_DIR%
:: Create default config file if it doesn't exist
if not exist %CONFIG_FILE% (
    echo {> %CONFIG_FILE%
    echo   "default_python": "3.11.4",>> %CONFIG_FILE%
    echo   "default_env": "default">> %CONFIG_FILE%
    echo }>> %CONFIG_FILE%
)
if %LOCAL_INSTALL%==0 (
    setx PATH "%PATH%;%SCRIPT_DIR%"
    echo LollmsEnv has been installed globally. Please restart your command prompt to use it.
) else (
    echo LollmsEnv has been installed locally in the current directory.
    echo To use LollmsEnv, run 'activate.bat' in this directory.
)
endlocal