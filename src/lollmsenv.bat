@echo off
setlocal enabledelayedexpansion

REM LollmsEnv - Lightweight environment management tool for Lollms projects
REM Copyright (c) 2024 ParisNeo
REM Licensed under the Apache License, Version 2.0
REM Built by ParisNeo using Lollms
REM Adapted for CMD by LoLLMs

set "SCRIPT_DIR=%~dp0"
set "LOLLMS_HOME=%SCRIPT_DIR%\.."
set "PYTHON_DIR=%LOLLMS_HOME%\pythons"
set "ENVS_DIR=%LOLLMS_HOME%\envs"
set "BUNDLES_DIR=%LOLLMS_HOME%\bundles"
set "TEMP_DIR=%TEMP%\lollmsenv"

if not exist "%PYTHON_DIR%" mkdir "%PYTHON_DIR%"
if not exist "%ENVS_DIR%" mkdir "%ENVS_DIR%"
if not exist "%BUNDLES_DIR%" mkdir "%BUNDLES_DIR%"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

goto :main

:log
echo [%date% %time%] %*
exit /b

:error
call :log ERROR: %*
exit /b 1

:cleanup
call :log Cleaning up temporary files...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
exit /b

:install_python
set "VERSION=%~1"
set "CUSTOM_DIR=%~2"

call :log Installing Python %VERSION%

REM Check if Python is already installed
if exist "%PYTHON_DIR%\%VERSION%\python.exe" (
    call :log Python %VERSION% is already installed.
    exit /b
)

call :log Downloading Python %VERSION%
set "URL=https://www.python.org/ftp/python/%VERSION%/python-%VERSION%-embed-amd64.zip"

if "%CUSTOM_DIR%"=="" (
    set "TARGET_DIR=%PYTHON_DIR%\%VERSION%"
) else (
    set "TARGET_DIR=%CUSTOM_DIR%\%VERSION%"
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

set "ARCHIVE=%TEMP_DIR%\python-%VERSION%.zip"
call :log Downloading from %URL%
curl -L "%URL%" -o "%ARCHIVE%"
if errorlevel 1 (
    call :error Failed to download Python %VERSION%
    exit /b 1
)

call :log Extracting Python %VERSION% to %TARGET_DIR%
powershell -Command "Expand-Archive -Path '%ARCHIVE%' -DestinationPath '%TARGET_DIR%' -Force"
if errorlevel 1 (
    call :error Failed to extract Python %VERSION%
    exit /b 1
)

REM Remove the _pth file to allow pip installation
del "%TARGET_DIR%\python*._pth"

REM Download get-pip.py
curl https://bootstrap.pypa.io/get-pip.py -o "%TARGET_DIR%\get-pip.py"
if errorlevel 1 (
    call :error Failed to download get-pip.py
    exit /b 1
)

call :log Installing pip
"%TARGET_DIR%\python.exe" "%TARGET_DIR%\get-pip.py" --no-warn-script-location
if errorlevel 1 (
    call :error Failed to install pip
    exit /b 1
)

call :log Installing virtualenv
"%TARGET_DIR%\Scripts\pip.exe" install virtualenv --no-warn-script-location
if errorlevel 1 (
    call :error Failed to install virtualenv
    exit /b 1
)

echo %VERSION%,%TARGET_DIR% >> "%PYTHON_DIR%\installed_pythons.txt"
call :log Python %VERSION% installed successfully with pip and virtualenv in %TARGET_DIR%
exit /b

:register_python
set "PYTHON_PATH=%~1"
set "VERSION=%~2"
if not exist "%PYTHON_PATH%\python.exe" (
    call :error The specified Python path does not contain a valid Python installation.
    exit /b 1
)
call :log Registering Python %VERSION% from %PYTHON_PATH%
REM Check if venv is installed
"%PYTHON_PATH%\python.exe" -c "import venv" 2>nul
if errorlevel 1 (
    call :log venv module not found. Installing venv...
    "%PYTHON_PATH%\python.exe" -m pip install virtualenv
    if errorlevel 1 (
        call :error Failed to install virtualenv
        exit /b 1
    )
)
echo %VERSION%,%PYTHON_PATH% >> "%PYTHON_DIR%\installed_pythons.txt"
call :log Python %VERSION% registered successfully
exit /b

:create_env
setlocal enabledelayedexpansion
set "ENV_NAME=%~1"
set "PYTHON_VERSION=%~2"
set "CUSTOM_DIR=%~3"

echo Creating environment: %ENV_NAME%
echo Python version: %PYTHON_VERSION%
echo Custom directory: %CUSTOM_DIR%

if "%PYTHON_VERSION%"=="" (
    call :log No Python version specified, checking for default...
    for /f "tokens=1,* delims=," %%a in ('type "%PYTHON_DIR%\installed_pythons.txt" ^| sort /r') do (
        set "PYTHON_VERSION=%%a"
        goto found_default
    )
)
:found_default

if "%PYTHON_VERSION%"=="" (
    call :log No Python versions found.
    set /p "INSTALL_PYTHON=Do you want to install Python 3.11.9? (Y/N): "
    if /i "!INSTALL_PYTHON!"=="Y" (
        call :install_python 3.11.9
        set "PYTHON_VERSION=3.11.9"
    ) else (
        call :error Cannot create environment without Python. Please install Python first.
        exit /b 1
    )
)

set "PYTHON_PATH="
for /f "tokens=1,2 delims=," %%a in ('findstr /b "%PYTHON_VERSION%," "%PYTHON_DIR%\installed_pythons.txt"') do (
    set "PYTHON_PATH=%%b"
    set "PYTHON_PATH=!PYTHON_PATH: =!"
)

if not defined PYTHON_PATH (
    call :error Python %PYTHON_VERSION% is not found in installed_pythons.txt
    exit /b 1
)

set "PYTHON_EXE=!PYTHON_PATH!\python.exe"
set "VIRTUALENV_EXE=!PYTHON_PATH!\Scripts\virtualenv.exe"

if not exist "!PYTHON_EXE!" (
    call :error Python %PYTHON_VERSION% is not installed or path is incorrect
    exit /b 1
)

if "%CUSTOM_DIR%"=="" (
    set "ENV_PATH=%ENVS_DIR%\%ENV_NAME%"
) else (
    set "ENV_PATH=%CUSTOM_DIR%\%ENV_NAME%"
)

call :log Creating virtual environment '%ENV_NAME%' with Python %PYTHON_VERSION% in !ENV_PATH!
"!VIRTUALENV_EXE!" "!ENV_PATH!"
if errorlevel 1 (
    call :error Failed to create virtual environment
    exit /b 1
)

call :log Upgrading pip in the new environment
"!ENV_PATH!\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 (
    call :error Failed to upgrade pip in the new environment
    exit /b 1
)

echo %ENV_NAME%,!ENV_PATH!,%PYTHON_VERSION% >> "%ENVS_DIR%\installed_envs.txt"
call :log Environment '%ENV_NAME%' created successfully
endlocal
exit /b

:activate_env

set "ENV_NAME=%~1"
set "INSTALLED_ENVS_FILE=%ENVS_DIR%\installed_envs.txt"
echo Debug: Searching for environment: %ENV_NAME%
echo Debug: INSTALLED_ENVS_FILE path: %INSTALLED_ENVS_FILE%

echo Debug: Searching for environment: %ENV_NAME%
echo Debug: INSTALLED_ENVS_FILE path: %INSTALLED_ENVS_FILE%

echo Debug: Content of INSTALLED_ENVS_FILE:
type "%INSTALLED_ENVS_FILE%"
echo.

echo Debug: Searching for environment: %ENV_NAME%
echo Debug: INSTALLED_ENVS_FILE path: %INSTALLED_ENVS_FILE%

echo Debug: Content of INSTALLED_ENVS_FILE:
type "%INSTALLED_ENVS_FILE%"
echo.

echo Debug: Searching for environment in file...
for /f "tokens=1,2,3 delims=," %%a in ('findstr /b "%ENV_NAME%," "%INSTALLED_ENVS_FILE%"') do (
    echo Debug: Match found - Name: %%a, Path: %%b, Version: %%c
    set "ENV_PATH=%%b"
    set "PYTHON_VERSION=%%c"
)

echo Debug: After search - ENV_PATH: !ENV_PATH!

if "!ENV_PATH!"=="" (
    call :error Environment '%ENV_NAME%' not found
    exit /b 1
)

set "ACTIVATE_SCRIPT=!ENV_PATH!\Scripts\activate.bat"
echo Debug: ACTIVATE_SCRIPT path: !ACTIVATE_SCRIPT!

if not exist "!ACTIVATE_SCRIPT!" (
    echo Debug: Activation script not found at: !ACTIVATE_SCRIPT!
    call :error Activation script not found: !ACTIVATE_SCRIPT!
    exit /b 1
)

echo Environment found: %ENV_NAME%
echo Path: !ENV_PATH!
echo Python version: !PYTHON_VERSION!
echo.
echo Activating environment...

call "!ACTIVATE_SCRIPT!"

if errorlevel 1 (
    call :error Failed to activate environment
    exit /b 1
)

set "PROMPT=(%ENV_NAME%) $P$G"

echo Environment activated. You are now using (%ENV_NAME%)
set LOLLMS_ENV_ACTIVATED=1

exit /b

:deactivate_env
echo To deactivate the current environment, run:
echo deactivate
exit /b

:install_package
set "PACKAGE=%~1"
pip install "%PACKAGE%"
if errorlevel 1 (
    call :error Failed to install package '%PACKAGE%'
    exit /b 1
)
call :log Package '%PACKAGE%' installed in the current environment
exit /b

:list_pythons
echo Installed Python versions:
type "%PYTHON_DIR%\installed_pythons.txt"
exit /b

:list_envs
echo Installed environments:
type "%ENVS_DIR%\installed_envs.txt"
exit /b

:create_bundle
set "BUNDLE_NAME=%~1"
set "PYTHON_VERSION=%~2"
set "ENV_NAME=%~3"
set "BUNDLE_DIR=%BUNDLES_DIR%\%BUNDLE_NAME%"

if not exist "%BUNDLE_DIR%" mkdir "%BUNDLE_DIR%"
call :install_python "%PYTHON_VERSION%" "%BUNDLE_DIR%"
call :create_env "%ENV_NAME%" "%PYTHON_VERSION%" "%BUNDLE_DIR%"

call :log Bundle '%BUNDLE_NAME%' created with Python %PYTHON_VERSION% and environment '%ENV_NAME%' in %BUNDLE_DIR%
exit /b

:delete_env
set "ENV_NAME=%~1"
set "ENV_PATH="

echo Debug: Searching for environment: %ENV_NAME%
echo Debug: Content of installed_envs.txt:
type "%ENVS_DIR%\installed_envs.txt"

for /f "tokens=1,2,3 delims=," %%a in ('type "%ENVS_DIR%\installed_envs.txt"') do (
    echo Debug: Checking %%a against %ENV_NAME%
    if "%%a"=="%ENV_NAME%" (
        set "ENV_PATH=%%b"
        echo Debug: Match found. ENV_PATH set to %%b
    )
)

if "%ENV_PATH%"=="" (
    call :error Environment '%ENV_NAME%' not found
    exit /b 1
)

echo Debug: Attempting to delete directory: %ENV_PATH%
if exist "%ENV_PATH%" (
    call :log Deleting environment '%ENV_NAME%' from %ENV_PATH%
    rmdir /s /q "%ENV_PATH%"
    if errorlevel 1 (
        call :error Failed to delete directory %ENV_PATH%
        exit /b 1
    )
) else (
    call :error Directory %ENV_PATH% does not exist
)

echo Debug: Updating installed_envs.txt
findstr /v /b "%ENV_NAME%," "%ENVS_DIR%\installed_envs.txt" > "%ENVS_DIR%\temp.txt"
move /y "%ENVS_DIR%\temp.txt" "%ENVS_DIR%\installed_envs.txt"
if errorlevel 1 (
    call :error Failed to update installed_envs.txt
    exit /b 1
)

call :log Environment '%ENV_NAME%' deleted successfully
exit /b

:delete_python
set "VERSION=%~1"
for /f "tokens=2 delims=," %%a in ('findstr /b "%VERSION%:" "%PYTHON_DIR%\installed_pythons.txt"') do set "PYTHON_PATH=%%a"

if "%PYTHON_PATH%"=="" (
    call :error Python %VERSION% is not installed
    exit /b 1
)

call :log Deleting Python %VERSION% from %PYTHON_PATH%
rmdir /s /q "%PYTHON_PATH%"
findstr /v /b "%VERSION%:" "%PYTHON_DIR%\installed_pythons.txt" > "%PYTHON_DIR%\temp.txt"
move /y "%PYTHON_DIR%\temp.txt" "%PYTHON_DIR%\installed_pythons.txt"
call :log Python %VERSION% deleted successfully
exit /b

:show_help
echo lollmsenv - Python and Virtual Environment Management Tool
echo.
echo Usage: lollmsenv.bat [command] [options]
echo.
echo Commands:
echo   install-python [version] [custom_dir]  Install a specific Python version
echo   create-env [name] [python-version] [custom_dir]  Create a new virtual environment
echo   activate [name]                        Show command to activate an environment
echo   deactivate                             Show command to deactivate the current environment
echo   install [package]                      Install a package in the current environment
echo   list-pythons                           List installed Python versions
echo   list-envs                              List installed virtual environments
echo   create-bundle [name] [python-version] [env-name]  Create a bundle with Python and environment
echo   delete-env [name]                      Delete a virtual environment
echo   delete-python [version]                Delete a Python installation
echo   register-python [path] [version]       Register an existing Python installation
echo   --help, -h                             Show this help message
echo.
echo Description:
echo   This tool helps manage Python installations and virtual environments.
echo   It can install multiple Python versions, create and manage
echo   virtual environments, and create bundles of Python with environments.
echo   You can also install Python and environments in custom directories,
echo   delete environments and Python installations, and register
echo   existing Python installations.
exit /b

:main
if "%1"=="" goto show_help
if "%1"=="--help" goto show_help
if "%1"=="-h" goto show_help

if "%1"=="install-python" (
    call :install_python "%2" "%3"
) else if "%1"=="register-python" (
    call :register_python "%2" "%3"
) else if "%1"=="create-env" (
    call :create_env "%2" "%3" "%4"
) else if "%1"=="activate" (
    call :activate_env "%2"
) else if "%1"=="deactivate" (
    call :deactivate_env
) else if "%1"=="install" (
    call :install_package "%2"
) else if "%1"=="list-pythons" (
    call :list_pythons
) else if "%1"=="list-envs" (
    call :list_envs
) else if "%1"=="create-bundle" (
    call :create_bundle "%2" "%3" "%4"
) else if "%1"=="delete-env" (
    call :delete_env "%2"
) else if "%1"=="delete-python" (
    call :delete_python "%2"
) else (
    call :error Unknown command. Use --help or -h for usage information.
)

endlocal
