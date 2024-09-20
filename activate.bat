@echo off
:: LollmsEnv - Lightweight environment management tool for Lollms projects
:: Copyright (c) 2024 ParisNeo
:: Licensed under the Apache License, Version 2.0
:: Built by ParisNeo using Lollms
setlocal enabledelayedexpansion
set SCRIPT_DIR=%~dp0
if exist %SCRIPT_DIR%\.lollmsenv (
    set LOLLMSENV_DIR=%SCRIPT_DIR%\.lollmsenv
) else (
    set LOLLMSENV_DIR=%USERPROFILE%\.lollmsenv
)
set PATH=%LOLLMSENV_DIR%\bin;%PATH%
:: Read default environment from config
for /f "tokens=2 delims=:," %%a in ('type %LOLLMSENV_DIR%\lollmsenv.config ^| findstr "default_env"') do (
    set DEFAULT_ENV=%%~a
    set DEFAULT_ENV=!DEFAULT_ENV:"=!
    set DEFAULT_ENV=!DEFAULT_ENV: =!
)
if "%1"=="" (
    set ENV_NAME=!DEFAULT_ENV!
) else (
    set ENV_NAME=%1
)
set ACTIVATE_SCRIPT=%LOLLMSENV_DIR%\envs\%ENV_NAME%\Scripts\activate.bat
if exist %ACTIVATE_SCRIPT% (
    call %ACTIVATE_SCRIPT%
    echo LollmsEnv activated. Environment: %ENV_NAME%
) else (
    echo Environment '%ENV_NAME%' not found.
    exit /b 1
)
endlocal & set PATH=%PATH%