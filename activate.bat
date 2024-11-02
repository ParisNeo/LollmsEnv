@echo off
REM LollmsEnv - Lightweight environment management tool for Lollms projects
REM Copyright (c) 2024 ParisNeo
REM Licensed under the Apache License, Version 2.0
REM Built by ParisNeo using Lollms

REM Enable delayed variable expansion
setlocal enabledelayedexpansion

REM Get the directory of the current batch file
set "current_dir=%~dp0"
echo !current_dir!

REM Remove the trailing backslash from the current directory path
set "current_dir=!current_dir:~0,-1!"

REM Add the bin folder to the PATH, prepending it to the existing PATH
set "bin_dir=!current_dir!\bin"
set "PATH=!bin_dir!;!PATH!"

REM Check if the pythons folder exists
set "pythons_dir=!current_dir!\pythons"
set "installed_pythons_file=!pythons_dir!\installed_pythons.txt"

if not exist "!pythons_dir!" (
    mkdir "!pythons_dir!"
    echo Created pythons directory: !pythons_dir!
)

if not exist "!installed_pythons_file!" (
    echo. > "!installed_pythons_file!"
    echo Created installed_pythons.txt file: !installed_pythons_file!
)

for /f "usebackq delims=" %%a in (`type "!installed_pythons_file!"`) do (
    set "line=%%a"
    if not "!line!"=="" (
        for /f "tokens=1 delims=," %%b in ("!line!") do (
            set "python_folder_name=%%b"
            goto :found
        )
    )
)
goto :notfound
:found
echo !python_folder_name!
echo Found python folder name: !python_folder_name!

REM Construct the python root directory path
set "python_root_dir=!current_dir!\pythons\!python_folder_name!"

REM Check if the variables are set correctly
if not defined python_folder_name (
    echo Error: python_folder_name is not set!
    goto :error
)
if not defined python_root_dir (
    echo Error: python_root_dir is not set!
    goto :error
)

REM Add the python root directory to the PATH
set "PATH=!python_root_dir!;!PATH!"

REM Break after processing the first line
goto :done
:notfound
echo No Python installations found in installed_pythons.txt
goto :done

:done
REM Capture the modified PATH variable before ending local environment
endlocal & set "PATH=%PATH%"

echo LollmsEnv activated. You can now use 'lollmsenv' commands.

REM Return control to the user in the same session
exit /b 0

:error
endlocal
echo LollmsEnv activation failed.
exit /b 1
