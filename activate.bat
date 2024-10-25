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

if exist "!pythons_dir!" (
    echo Checking if installed_pythons.txt exists at !pythons_dir!
    echo Pythons dir: !pythons_dir!
    echo Installed python file: !installed_pythons_file!
    
    if exist "!installed_pythons_file!" (
        echo Reading the first line of installed_pythons.txt
        for /f "tokens=1 delims=," %%a in ('type "!installed_pythons_file!"') do (
            set "python_folder_name=%%a"
            
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
        )
    ) else (
        echo Error: installed_pythons.txt not found!
        goto :error
    )
) else (
    echo Error: pythons directory not found!
    goto :error
)

:done
REM Capture the modified PATH variable before ending local environment
endlocal & set "PATH=%PATH%"

echo Updated PATH: %PATH%
echo LollmsEnv activated. You can now use 'lollmsenv' commands.

REM Return control to the user in the same session
exit /b 0

:error
endlocal
echo LollmsEnv activation failed.
exit /b 1
