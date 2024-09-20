@echo off
set SCRIPT_DIR=%~dp0
if exist %SCRIPT_DIR%\.lollmsenv (
    set LOLLMSENV_DIR=%SCRIPT_DIR%\.lollmsenv
) else (
    set LOLLMSENV_DIR=%USERPROFILE%\.lollmsenv
)
set PATH=%LOLLMSENV_DIR%\bin;%PATH%

echo LollmsEnv activated. You can now use 'lollmsenv' commands.
