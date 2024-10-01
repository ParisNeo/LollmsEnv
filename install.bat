@echo off
:: LollmsEnv - Lightweight environment management tool for Lollms projects
:: Copyright (c) 2024 ParisNeo
:: Licensed under the Apache License, Version 2.0
:: Built by ParisNeo using Lollms
setlocal enabledelayedexpansion

:: Parse command-line arguments
set "LOCAL_INSTALL=0"
set "NO_MODIFY_RC=0"
set "INSTALL_DIR="
set "DIR_OPTION_USED=0"

:parse_args
if "%~1"=="" goto :end_parse_args
if "%~1"=="--local" (
    set "LOCAL_INSTALL=1"
    shift
    goto :parse_args
)
if "%~1"=="--dir" (
    set "INSTALL_DIR=%~2"
    set "DIR_OPTION_USED=1"
    set "LOCAL_INSTALL=1"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--no-modify-rc" (
    set "NO_MODIFY_RC=1"
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
echo Unknown option: %~1
goto :show_help
:end_parse_args

:: Set default installation directory
if "%INSTALL_DIR%"=="" (
    echo Setting default installation directory...
    if "%LOCAL_INSTALL%"=="1" (
        set "INSTALL_DIR=%CD%\.lollmsenv"
        echo Installing locally in the current directory: %INSTALL_DIR%
    ) else (
        set "INSTALL_DIR=%USERPROFILE%\.lollmsenv"
        echo Installing in the user's profile directory: %INSTALL_DIR%
    )
)

:: Create directories and copy files
echo Creating installation directories...
set "SCRIPT_DIR=%INSTALL_DIR%\bin"
mkdir "%SCRIPT_DIR%" 2>nul
echo Copying necessary files...
copy "src\lollmsenv.bat" "%SCRIPT_DIR%\lollmsenv.bat" >nul
copy "activate.bat" "%INSTALL_DIR%" >nul

:: Modify environment variables or create activation script
if "%LOCAL_INSTALL%"=="0" if "%NO_MODIFY_RC%"=="0" (
    echo Modifying system PATH environment variable...
    setx PATH "%PATH%;%INSTALL_DIR%\bin"
    echo LollmsEnv has been installed globally. Please restart your command prompt to use it.
) else (
    echo Generating source.bat script...
    echo @echo off > "%INSTALL_DIR%\source.bat"
    echo set "PATH=%%PATH%%;%SCRIPT_DIR%" >> "%INSTALL_DIR%\source.bat"
    echo A source.bat script has been generated. Run '%INSTALL_DIR%\source.bat' to use LollmsEnv.
)
pause
goto :eof

:show_help
echo Usage: %~nx0 [--local] [--dir ^<directory^>] [--no-modify-rc] [-h^|--help]
echo Options:
echo   --local       Install LollmsEnv locally in the current directory.
echo   --dir ^<directory^> Install LollmsEnv in the specified directory (locally).
echo   --no-modify-rc Do not modify system PATH. Generate a source.bat script instead.
echo   -h, --help    Show this help message and exit.
pause
goto :eof
