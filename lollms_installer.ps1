# Version number
$VERSION = "1.2.8"

# URL of the latest release
$RELEASE_URL = "https://github.com/ParisNeo/LollmsEnv/archive/refs/tags/V$VERSION.zip"

# Temporary directory for downloading and extraction
$TEMP_DIR = ".\lollmsenv_install"

# Create temporary directory
if (-not (Test-Path $TEMP_DIR)) {
    New-Item -ItemType Directory -Path $TEMP_DIR | Out-Null
}

# Download the latest release
Write-Host "Downloading LollmsEnv version $VERSION..."
try {
    Invoke-WebRequest -Uri $RELEASE_URL -OutFile "$TEMP_DIR\lollmsenv.zip"
}
catch {
    Write-Host "Error downloading LollmsEnv: $_"
    exit 1
}

# Extract the archive
Write-Host "Extracting files..."
Expand-Archive -Path "$TEMP_DIR\lollmsenv.zip" -DestinationPath $TEMP_DIR -Force

# Change to the extracted directory
Set-Location "$TEMP_DIR\LollmsEnv-$VERSION"

# Run the install script with forwarded parameters
Write-Host "Running installation..."
& .\install.ps1 $args

# Clean up
Write-Host "Cleaning up..."
Set-Location $env:USERPROFILE
Remove-Item -Path $TEMP_DIR -Recurse -Force

Write-Host "Installation of LollmsEnv version $VERSION complete."
