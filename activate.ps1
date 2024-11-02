# LollmsEnv - Lightweight environment management tool for Lollms projects
# Copyright (c) 2024 ParisNeo
# Licensed under the Apache License, Version 2.0
# Built by ParisNeo using Lollms

# Get the directory of the current script
$current_dir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host $current_dir

# Remove the trailing backslash from the current directory path if present
$current_dir = $current_dir.TrimEnd('\')

# Add the bin folder to the PATH, prepending it to the existing PATH
$bin_dir = Join-Path $current_dir "bin"
$env:PATH = "$bin_dir;$env:PATH"

# Check if the pythons folder exists
$pythons_dir = Join-Path $current_dir "pythons"
$installed_pythons_file = Join-Path $pythons_dir "installed_pythons.txt"

if (-not (Test-Path $pythons_dir)) {
    New-Item -ItemType Directory -Path $pythons_dir | Out-Null
    Write-Host "Created pythons directory: $pythons_dir"
}

if (-not (Test-Path $installed_pythons_file)) {
    New-Item -ItemType File -Path $installed_pythons_file | Out-Null
    Write-Host "Created installed_pythons.txt file: $installed_pythons_file"
}

$python_folder_name = $null
foreach ($line in Get-Content $installed_pythons_file) {
    if ($line -ne "") {
        $python_folder_name = $line.Split(',')[0]
        break
    }
}

if ($python_folder_name) {
    Write-Host "Found python folder name: $python_folder_name"

    # Construct the python root directory path
    $python_root_dir = Join-Path $pythons_dir $python_folder_name

    # Check if the variables are set correctly
    if (-not $python_folder_name) {
        Write-Host "Error: python_folder_name is not set!"
        exit 1
    }
    if (-not $python_root_dir) {
        Write-Host "Error: python_root_dir is not set!"
        exit 1
    }

    # Add the python root directory to the PATH
    $env:PATH = "$python_root_dir;$env:PATH"

    Write-Host "LollmsEnv activated. You can now use 'lollmsenv' commands."
} else {
    Write-Host "No Python installations found in installed_pythons.txt"
}

# The modified PATH is automatically available in the current session in PowerShell