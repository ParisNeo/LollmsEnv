# URL of the latest release
$RELEASE_URL = "https://github.com/ParisNeo/LollmsEnv/archive/refs/tags/V1.0.zip"

# Temporary directory for downloading and extraction
$TEMP_DIR = Join-Path $env:TEMP "lollmsenv_install"

# Create temporary directory
New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null

# Download the latest release
Write-Host "Downloading LollmsEnv..."
Invoke-WebRequest -Uri $RELEASE_URL -OutFile (Join-Path $TEMP_DIR "lollmsenv.zip")

# Extract the archive
Write-Host "Extracting files..."
Expand-Archive -Path (Join-Path $TEMP_DIR "lollmsenv.zip") -DestinationPath $TEMP_DIR -Force

# Change to the extracted directory
Set-Location -Path (Join-Path $TEMP_DIR "LollmsEnv-1.0")

# Run the install script with forwarded parameters
Write-Host "Running installation..."
& .\install.ps1 @args

# Clean up
Write-Host "Cleaning up..."
Set-Location $env:USERPROFILE
Remove-Item -Path $TEMP_DIR -Recurse -Force

Write-Host "Installation complete."
