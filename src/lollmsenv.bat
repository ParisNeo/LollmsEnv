@echo off
:: lollmsenv.bat

set LOLLMS_HOME=%USERPROFILE%\.lollmsenv
set PYTHON_DIR=%LOLLMS_HOME%\pythons
set ENVS_DIR=%LOLLMS_HOME%\envs

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
) else (
    echo Unknown command. Available commands:
    echo install-python [version]
    echo create-env [name] [python-version]
    echo activate [name]
    echo deactivate
    echo install [package]
)
exit /b

:install_python
set VERSION=%1
set PYTHON_URL=https://www.python.org/ftp/python/%VERSION%/python-%VERSION%-embed-amd64.zip
set TARGET_DIR=%PYTHON_DIR%\%VERSION%

if not exist %TARGET_DIR% mkdir %TARGET_DIR%
powershell -Command "Invoke-WebRequest %PYTHON_URL% -OutFile %TARGET_DIR%\python.zip"
powershell -Command "Expand-Archive %TARGET_DIR%\python.zip -DestinationPath %TARGET_DIR%"
echo Python %VERSION% installed successfully.
exit /b

:create_env
set ENV_NAME=%1
set PYTHON_VERSION=%2
set ENV_PATH=%ENVS_DIR%\%ENV_NAME%
set PYTHON_PATH=%PYTHON_DIR%\%PYTHON_VERSION%\python.exe

if not exist %ENV_PATH% mkdir %ENV_PATH%
%PYTHON_PATH% -m venv %ENV_PATH%
echo Environment '%ENV_NAME%' created with Python %PYTHON_VERSION%
exit /b

:activate_env
set ENV_NAME=%1
set ACTIVATE_SCRIPT=%ENVS_DIR%\%ENV_NAME%\Scripts\activate.bat
echo To activate the environment, run:
echo call %ACTIVATE_SCRIPT%
exit /b

:deactivate_env
echo To deactivate the current environment, run:
echo deactivate
exit /b

:install_package
set PACKAGE=%1
pip install %PACKAGE%
echo Package '%PACKAGE%' installed in the current environment
exit /b
