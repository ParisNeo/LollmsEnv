@echo off
setlocal

if "%1"=="--local" (
    set INSTALL_DIR=%CD%\.lollmsenv
    set LOCAL_INSTALL=1
) else (
    set INSTALL_DIR=%USERPROFILE%\.lollmsenv
    set LOCAL_INSTALL=0
)

set SCRIPT_DIR=%INSTALL_DIR%\bin

if not exist %INSTALL_DIR% mkdir %INSTALL_DIR%
if not exist %SCRIPT_DIR% mkdir %SCRIPT_DIR%

copy src\lollmsenv.bat %SCRIPT_DIR%
copy activate.bat %INSTALL_DIR%

if %LOCAL_INSTALL%==0 (
    setx PATH "%PATH%;%SCRIPT_DIR%"
    echo LollmsEnv has been installed globally. Please restart your command prompt to use it.
) else (
    echo LollmsEnv has been installed locally in the current directory.
    echo To use LollmsEnv, run 'activate.bat' in this directory.
)

endlocal
