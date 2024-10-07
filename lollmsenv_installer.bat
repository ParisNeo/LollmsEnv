@echo off
set VERSION=1.2.10
set REPO_URL=https://github.com/ParisNeo/LollmsEnv.git
set RELEASE_URL=https://github.com/ParisNeo/LollmsEnv/archive/refs/tags/V%VERSION%.zip
set TEMP_DIR=.\lollmsenv_install

set USE_MASTER=false
for %%a in (%*) do (
    if "%%a"=="--use-master" set USE_MASTER=true
)

if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

if %USE_MASTER%==true (
    echo Cloning master branch...
    git clone %REPO_URL% %TEMP_DIR%
    cd /d "%TEMP_DIR%"
) else (
    echo Downloading LollmsEnv version %VERSION%...
    powershell -Command "Invoke-WebRequest -Uri '%RELEASE_URL%' -OutFile '%TEMP_DIR%\lollmsenv.zip'"
    if %errorlevel% neq 0 (
        echo Error downloading LollmsEnv: %errorlevel%
        exit /b 1
    )
    powershell -Command "Expand-Archive -Path '%TEMP_DIR%\lollmsenv.zip' -DestinationPath '%TEMP_DIR%' -Force"
    cd /d "%TEMP_DIR%\LollmsEnv-%VERSION%"
)

echo Running installation...
call install.bat %*

echo Cleaning up...
cd /d ..
rmdir /s /q "%TEMP_DIR%"

echo Installation of LollmsEnv complete.
