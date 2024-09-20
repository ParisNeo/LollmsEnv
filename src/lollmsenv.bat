@echo off
:: LollmsEnv - Lightweight environment management tool for Lollms projects
:: Copyright (c) 2024 ParisNeo
:: Licensed under the Apache License, Version 2.0
:: Built by ParisNeo using Lollms
setlocal enabledelayedexpansion
:: Check for local installation
if exist %~dp0..\.lollmsenv (
    set LOLLMS_HOME=%~dp0..\.lollmsenv
) else (
    set LOLLMS_HOME=%USERPROFILE%\.lollmsenv
)
set PYTHON_DIR=%LOLLMS_HOME%\pythons
set ENVS_DIR=%LOLLMS_HOME%\envs
set CONFIG_FILE=%LOLLMS_HOME%\lollmsenv.config
set VERSIONS_FILE=%LOLLMS_HOME%\versions.json
:: Read default Python version from config
for /f "tokens=2 delims=:," %%a in ('type %CONFIG_FILE% ^| findstr "default_python"') do (
    set DEFAULT_PYTHON=%%~a
    set DEFAULT_PYTHON=!DEFAULT_PYTHON:"=!
    set DEFAULT_PYTHON=!DEFAULT_PYTHON: =!
)
if "%1"=="install-python" (
    call :install_python %2
) else if "%1"=="create-env" (
    call :create_env %2 %3
) else if "%1"=="activate" (
    call :activate_env %2
) else if "%1"=="deactivate" (
    call :deactivate_env
) else if "%1"=="install" (
    call :install_package %2
) else if "%1"=="list-packages" (
    call :list_packages
) else if "%1"=="upgrade-package" (
    call :upgrade_package %2
) else if "%1"=="export-requirements" (
    call :export_requirements %2
) else if "%1"=="import-requirements" (
    call :import_requirements %2
) else if "%1"=="uninstall-python" (
    call :uninstall_python %2
) else if "%1"=="remove-env" (
    call :remove_env %2
) else if "%1"=="update-tool" (
    call :update_tool
) else if "%1"=="list-pythons" (
    call :list_pythons
) else if "%1"=="list-envs" (
    call :list_envs
) else (
    call :show_help
)
exit /b
:install_python
if "%1"=="" set VERSION=%DEFAULT_PYTHON%
if not "%1"=="" set VERSION=%1
set PYTHON_URL=https://www.python.org/ftp/python/%VERSION%/python-%VERSION%-embed-amd64.zip
set TARGET_DIR=%PYTHON_DIR%\%VERSION%
if exist %TARGET_DIR% (
    echo Python %VERSION% is already installed.
    exit /b 1
)
if not exist %TARGET_DIR% mkdir %TARGET_DIR%
powershell -Command "Invoke-WebRequest %PYTHON_URL% -OutFile %TARGET_DIR%\python.zip"
if %errorlevel% neq 0 (
    echo Failed to download Python %VERSION%.
    exit /b 1
)
powershell -Command "Expand-Archive %TARGET_DIR%\python.zip -DestinationPath %TARGET_DIR%"
if %errorlevel% neq 0 (
    echo Failed to extract Python %VERSION%.
    exit /b 1
)
:: Update versions.json
if not exist %VERSIONS_FILE% echo {}> %VERSIONS_FILE%
powershell -Command "(Get-Content %VERSIONS_FILE% | ConvertFrom-Json) | Add-Member -Type NoteProperty -Name '%VERSION%' -Value (Get-Date -Format 'yyyy-MM-dd') -Force | ConvertTo-Json | Set-Content %VERSIONS_FILE%"
echo Python %VERSION% installed successfully.
exit /b
:create_env
if "%1"=="" (
    echo Please specify an environment name.
    exit /b 1
)
set ENV_NAME=%1
if "%2"=="" set PYTHON_VERSION=%DEFAULT_PYTHON%
if not "%2"=="" set PYTHON_VERSION=%2
set ENV_PATH=%ENVS_DIR%\%ENV_NAME%
set PYTHON_PATH=%PYTHON_DIR%\%PYTHON_VERSION%\python.exe
if not exist %PYTHON_PATH% (
    echo Python %PYTHON_VERSION% is not installed. Please install it first.
    exit /b 1
)
if exist %ENV_PATH% (
    echo Environment '%ENV_NAME%' already exists.
    exit /b 1
)
%PYTHON_PATH% -m venv %ENV_PATH%
if %errorlevel% neq 0 (
    echo Failed to create environment '%ENV_NAME%'.
    exit /b 1
)
echo Environment '%ENV_NAME%' created with Python %PYTHON_VERSION%
exit /b
:activate_env
if "%1"=="" (
    echo Please specify an environment name.
    exit /b 1
)
set ENV_NAME=%1
set ACTIVATE_SCRIPT=%ENVS_DIR%\%ENV_NAME%\Scripts\activate.bat
if not exist %ACTIVATE_SCRIPT% (
    echo Environment '%ENV_NAME%' not found.
    exit /b 1
)
call %ACTIVATE_SCRIPT%
echo Environment '%ENV_NAME%' activated.
exit /b
:deactivate_env
if defined VIRTUAL_ENV (
    call deactivate
    echo Environment deactivated.
) else (
    echo No active virtual environment.
)
exit /b
:install_package
if "%1"=="" (
    echo Please specify a package name.
    exit /b 1
)
set PACKAGE=%1
pip install %PACKAGE%
if %errorlevel% neq 0 (
    echo Failed to install package '%PACKAGE%'.
    exit /b 1
)
echo Package '%PACKAGE%' installed in the current environment
exit /b
:list_packages
pip list
exit /b
:upgrade_package
if "%1"=="" (
    echo Please specify a package name.
    exit /b 1
)
set PACKAGE=%1
pip install --upgrade %PACKAGE%
if %errorlevel% neq 0 (
    echo Failed to upgrade package '%PACKAGE%'.
    exit /b 1
)
echo Package '%PACKAGE%' upgraded in the current environment
exit /b
:export_requirements
if "%1"=="" set REQUIREMENTS_FILE=requirements.txt
if not "%1"=="" set REQUIREMENTS_FILE=%1
pip freeze > %REQUIREMENTS_FILE%
if %errorlevel% neq 0 (
    echo Failed to export requirements to '%REQUIREMENTS_FILE%'.
    exit /b 1
)
echo Requirements exported to '%REQUIREMENTS_FILE%'
exit /b
:import_requirements
if "%1"=="" (
    echo Please specify a requirements file.
    exit /b 1
)
set REQUIREMENTS_FILE=%1
if not exist %REQUIREMENTS_FILE% (
    echo Requirements file '%REQUIREMENTS_FILE%' not found.
    exit /b 1
)
pip install -r %REQUIREMENTS_FILE%
if %errorlevel% neq 0 (
    echo Failed to import requirements from '%REQUIREMENTS_FILE%'.
    exit /b 1
)
echo Requirements imported from '%REQUIREMENTS_FILE%'
exit /b
:uninstall_python
if "%1"=="" (
    echo Please specify a Python version to uninstall.
    exit /b 1
)
set VERSION=%1
set TARGET_DIR=%PYTHON_DIR%\%VERSION%
if not exist %TARGET_DIR% (
    echo Python %VERSION% is not installed.
    exit /b 1
)
rmdir /s /q %TARGET_DIR%
if %errorlevel% neq 0 (
    echo Failed to uninstall Python %VERSION%.
    exit /b 1
)
:: Update versions.json
powershell -Command "$json = Get-Content %VERSIONS_FILE% | ConvertFrom-Json; $json.PSObject.Properties.Remove('%VERSION%'); $json | ConvertTo-Json | Set-Content %VERSIONS_FILE%"
echo Python %VERSION% uninstalled successfully.
exit /b
:remove_env
if "%1"=="" (
    echo Please specify an environment name to remove.
    exit /b 1
)
set ENV_NAME=%1
set ENV_PATH=%ENVS_DIR%\%ENV_NAME%
if not exist %ENV_PATH% (
    echo Environment '%ENV_NAME%' does not exist.
    exit /b 1
)
rmdir /s /q %ENV_PATH%
if %errorlevel% neq 0 (
    echo Failed to remove environment '%ENV_NAME%'.
    exit /b 1
)
echo Environment '%ENV_NAME%' removed successfully.
exit /b
:update_tool
echo Updating LollmsEnv...
git pull
if %errorlevel% neq 0 (
    echo Failed to update LollmsEnv.
    exit /b 1
)
echo LollmsEnv updated successfully.
exit /b
:list_pythons
echo Installed Python versions:
powershell -Command "Get-Content %VERSIONS_FILE% | ConvertFrom-Json | Format-Table @{L='Version';E={$_.PSObject.Properties.Name}}, @{L='Installed On';E={$_.PSObject.Properties.Value}} -AutoSize"
exit /b
:list_envs
echo Available environments:
dir /b /ad %ENVS_DIR%
exit /b
:show_help
echo Available commands:
echo install-python [version]
echo create-env [name] [python-version]
echo activate [name]
echo deactivate
echo install [package]
echo list-packages
echo upgrade-package [package]
echo export-requirements [file]
echo import-requirements [file]
echo uninstall-python [version]
echo remove-env [name]
echo update-tool
echo list-pythons
echo list-envs
exit /b