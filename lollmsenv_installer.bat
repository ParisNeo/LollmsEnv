@echo off
:: URL of the latest release
set RELEASE_URL=https://github.com/ParisNeo/LollmsEnv/archive/refs/tags/V1.0.zip

:: Temporary directory for downloading and extraction
set TEMP_DIR=%TEMP%\lollmsenv_install

:: Create temporary directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Download the latest release
echo Downloading LollmsEnv...
powershell -Command "Invoke-WebRequest -Uri '%RELEASE_URL%' -OutFile '%TEMP_DIR%\lollmsenv.zip'"

:: Extract the archive
echo Extracting files...
powershell -Command "Expand-Archive -Path '%TEMP_DIR%\lollmsenv.zip' -DestinationPath '%TEMP_DIR%' -Force"

:: Change to the extracted directory
cd /d "%TEMP_DIR%\LollmsEnv-1.0"

:: Run the install script with forwarded parameters
echo Running installation...
call install.bat %*

:: Clean up
echo Cleaning up...
cd /d "%USERPROFILE%"
rmdir /s /q "%TEMP_DIR%"

echo Installation complete.
