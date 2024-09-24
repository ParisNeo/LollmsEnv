@echo off
REM LollmsEnv - Lightweight environment management tool for Lollms projects
REM Copyright (c) 2024 ParisNeo
REM Licensed under the Apache License, Version 2.0
REM Built by ParisNeo using Lollms
setlocal enabledelayedexpansion
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
:log
echo [%date% %time%] %~1
exit /b
:error
call :log "ERROR: %~1"
exit /b 1
:cleanup
call :log "Cleaning up temporary files..."
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
exit /b
:get_platform_info
set "OS=windows"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo "x86_64-pc-windows-msvc"
) else if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    echo "i686-pc-windows-msvc"
) else (
    call :error "Unsupported architecture: %PROCESSOR_ARCHITECTURE%"
)
exit /b
:list_available_pythons
call :log "Fetching available Python versions..."
powershell -Command "& {$releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/indygreg/python-build-standalone/releases'; $pattern = 'cpython-(\d+\.\d+\.\d+)\+\d+-(x86_64|i686)-pc-windows-msvc-.*\.tar\.gz'; $releases | ForEach-Object { $_.assets.name } | Where-Object { $_ -match $pattern } | ForEach-Object { $matches[1] } | Sort-Object -Unique}"
exit /b
:get_python_url
set "VERSION=%~1"
for /f "tokens=*" %%i in ('call :get_platform_info') do set "PLATFORM=%%i"
set "RELEASE_URL=https://api.github.com/repos/indygreg/python-build-standalone/releases"
set "ASSET_NAME=cpython-%VERSION%+-%PLATFORM%-.\.tar\.gz"
powershell -Command "& {$releases = Invoke-RestMethod -Uri '%RELEASE_URL%'; $asset = $releases.assets | Where-Object { $_.name -like '%ASSET_NAME%' } | Select-Object -First 1; if ($asset) { Write-Output $asset.browser_download_url } else { Write-Error 'Asset not found' }}"
exit /b
:scan_for_python
set "VERSION=%~1"
set "LOCATIONS=C:\Python%VERSION%\python.exe C:\Program Files\Python%VERSION%\python.exe C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python%VERSION%\python.exe"
for %%L in (%LOCATIONS%) do (
    if exist "%%L" (
        echo %%L
        exit /b 0
    )
)
exit /b 1
:install_python
set "VERSION=%~1"
set "CUSTOM_DIR=%~2"
for /f "tokens=*" %%i in ('call :scan_for_python %VERSION%') do set "EXISTING_PYTHON=%%i"
if not "%EXISTING_PYTHON%"=="" (
    call :log "Found existing Python %VERSION% installation at %EXISTING_PYTHON%"
    
    if "%CUSTOM_DIR%"=="" (
        set "TARGET_DIR=%PYTHON_DIR%\%VERSION%"
    ) else (
        set "TARGET_DIR=%CUSTOM_DIR%\%VERSION%"
    )
    
    if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
    mklink "%TARGET_DIR%\python.exe" "%EXISTING_PYTHON%"
    for %%F in ("%EXISTING_PYTHON%") do set "EXISTING_DIR=%%~dpF"
    if exist "%EXISTING_DIR%Scripts\pip.exe" mklink "%TARGET_DIR%\pip.exe" "%EXISTING_DIR%Scripts\pip.exe"
    
    call :log "Created symlinks to existing Python %VERSION% in %TARGET_DIR%"
    echo %VERSION%:%TARGET_DIR%>>"%PYTHON_DIR%\installed_pythons.txt"
    exit /b 0
)
for /f "tokens=*" %%i in ('call :get_python_url %VERSION%') do set "URL=%%i"
if "%URL%"=="" call :error "Failed to find Python %VERSION% download URL"
call :log "Downloading Python %VERSION% from %URL%"
if "%CUSTOM_DIR%"=="" (
    set "TARGET_DIR=%PYTHON_DIR%\%VERSION%"
) else (
    set "TARGET_DIR=%CUSTOM_DIR%\%VERSION%"
)
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
set "ARCHIVE=%TEMP_DIR%\python-%VERSION%.tar.gz"
powershell -Command "& { Invoke-WebRequest -Uri '%URL%' -OutFile '%ARCHIVE%' }" || call :error "Failed to download Python %VERSION%"
call :log "Extracting Python %VERSION% to %TARGET_DIR%"
tar -xzf "%ARCHIVE%" -C "%TARGET_DIR%" --strip-components=1 || call :error "Failed to extract Python %VERSION%"
call :log "Ensuring pip and venv are installed"
"%TARGET_DIR%\python.exe" -m ensurepip --upgrade || call :error "Failed to ensure pip is installed"
"%TARGET_DIR%\python.exe" -m pip install --upgrade pip || call :error "Failed to upgrade pip"
"%TARGET_DIR%\python.exe" -m pip install virtualenv || call :error "Failed to install virtualenv"
echo %VERSION%:%TARGET_DIR%>>"%PYTHON_DIR%\installed_pythons.txt"
call :log "Python %VERSION% installed successfully with pip and venv in %TARGET_DIR%"
exit /b
:create_env
set "ENV_NAME=%~1"
set "PYTHON_VERSION=%~2"
set "CUSTOM_DIR=%~3"
for /f "tokens=2 delims=:" %%i in ('findstr /b "%PYTHON_VERSION%:" "%PYTHON_DIR%\installed_pythons.txt"') do set "PYTHON_PATH=%%i\python.exe"
if not exist "%PYTHON_PATH%" call :error "Python %PYTHON_VERSION% is not installed"
if "%CUSTOM_DIR%"=="" (
    set "ENV_PATH=%ENVS_DIR%\%ENV_NAME%"
) else (
    set "ENV_PATH=%CUSTOM_DIR%\%ENV_NAME%"
)
call :log "Creating virtual environment '%ENV_NAME%' with Python %PYTHON_VERSION% in %ENV_PATH%"
"%PYTHON_PATH%" -m venv "%ENV_PATH%" || call :error "Failed to create virtual environment"
echo %ENV_NAME%:%ENV_PATH%:%PYTHON_VERSION%>>"%ENVS_DIR%\installed_envs.txt"
call :log "Environment '%ENV_NAME%' created successfully"
exit /b
:activate_env
set "ENV_NAME=%~1"
for /f "tokens=2 delims=:" %%i in ('findstr /b "%ENV_NAME%:" "%ENVS_DIR%\installed_envs.txt"') do set "ENV_PATH=%%i"
if "%ENV_PATH%"=="" call :error "Environment '%ENV_NAME%' not found"
set "ACTIVATE_SCRIPT=%ENV_PATH%\Scripts\activate.bat"
echo To activate the environment, run:
echo call "%ACTIVATE_SCRIPT%"
exit /b
:deactivate_env
echo To deactivate the current environment, run:
echo deactivate
exit /b
:install_package
set "PACKAGE=%~1"
pip install "%PACKAGE%" || call :error "Failed to install package '%PACKAGE%'"
call :log "Package '%PACKAGE%' installed in the current environment"
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
call :log "Bundle '%BUNDLE_NAME%' created with Python %PYTHON_VERSION% and environment '%ENV_NAME%' in %BUNDLE_DIR%"
exit /b
:delete_env
set "ENV_NAME=%~1"
for /f "tokens=2 delims=:" %%i in ('findstr /b "%ENV_NAME%:" "%ENVS_DIR%\installed_envs.txt"') do set "ENV_PATH=%%i"
if "%ENV_PATH%"=="" call :error "Environment '%ENV_NAME%' not found"
call :log "Deleting environment '%ENV_NAME%' from %ENV_PATH%"
rmdir /s /q "%ENV_PATH%"
findstr /v /b "%ENV_NAME%:" "%ENVS_DIR%\installed_envs.txt" > "%ENVS_DIR%\installed_envs_temp.txt"
move /y "%ENVS_DIR%\installed_envs_temp.txt" "%ENVS_DIR%\installed_envs.txt"
call :log "Environment '%ENV_NAME%' deleted successfully"
exit /b
:delete_python
set "VERSION=%~1"
for /f "tokens=2 delims=:" %%i in ('findstr /b "%VERSION%:" "%PYTHON_DIR%\installed_pythons.txt"') do set "PYTHON_PATH=%%i"
if "%PYTHON_PATH%"=="" call :error "Python %VERSION% is not installed"
call :log "Deleting Python %VERSION% from %PYTHON_PATH%"
rmdir /s /q "%PYTHON_PATH%"
findstr /v /b "%VERSION%:" "%PYTHON_DIR%\installed_pythons.txt" > "%PYTHON_DIR%\installed_pythons_temp.txt"
move /y "%PYTHON_DIR%\installed_pythons_temp.txt" "%PYTHON_DIR%\installed_pythons.txt"
call :log "Python %VERSION% deleted successfully"
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
echo   list-available-pythons                 List available Python versions for installation
echo   create-bundle [name] [python-version] [env-name]  Create a bundle with Python and environment
echo   delete-env [name]                      Delete a virtual environment
echo   delete-python [version]                Delete a Python installation
echo   --help, -h                             Show this help message
echo.
echo Description:
echo   This tool helps manage Python installations and virtual environments.
echo   It scans for existing Python installations before downloading.
echo   You can install multiple Python versions, create and manage
echo   virtual environments, and create bundles of Python with environments.
echo   You can also install Python and environments in custom directories.
echo   Now you can delete environments and Python installations as well.
exit /b
if "%1"=="install-python" (
    call :install_python %2 %3
) else if "%1"=="create-env" (
    call :create_env %2 %3 %4
) else if "%1"=="activate" (
    call :activate_env %2
) else if "%1"=="deactivate" (
    call :deactivate_env
) else if "%1"=="install" (
    call :install_package %2
) else if "%1"=="list-pythons" (
    call :list_pythons
) else if "%1"=="list-envs" (
    call :list_envs
) else if "%1"=="list-available-pythons" (
    call :list_available_pythons
) else if "%1"=="create-bundle" (
    call :create_bundle %2 %3 %4
) else if "%1"=="delete-env" (
    call :delete_env %2
) else if "%1"=="delete-python" (
    call :delete_python %2
) else if "%1"=="--help" (
    call :show_help
) else if "%1"=="-h" (
    call :show_help
) else (
    call :error "Unknown command. Use --help or -h for usage information."
)
call :cleanup
