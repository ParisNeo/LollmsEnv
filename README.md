# LollmsEnv

![GitHub license](https://img.shields.io/github/license/ParisNeo/LollmsEnv)
![GitHub stars](https://img.shields.io/github/stars/ParisNeo/LollmsEnv)
![GitHub forks](https://img.shields.io/github/forks/ParisNeo/LollmsEnv)
![GitHub issues](https://img.shields.io/github/issues/ParisNeo/LollmsEnv)

LollmsEnv is a lightweight and simple tool for managing Python environments and versions. It provides an easy-to-use interface for installing multiple Python versions, creating and managing virtual environments, and bundling Python installations with environments.

## Table of Contents

1. [Features](#features)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Commands](#commands)
5. [Examples](#examples)
6. [License](#license)
7. [Acknowledgments](#acknowledgments)

## Features

- Install and manage multiple Python versions
- Create and manage virtual environments
- Create bundles of Python installations with environments
- Cross-platform support (Windows and Unix-based systems)
- Lightweight and easy to use
- Supports custom installation directories

## Installation

### Windows

1. Download the installer:
   [lollmsenv_installer.bat](https://github.com/ParisNeo/LollmsEnv/releases/download/V1.2.5/lollmsenv_installer.bat)

2. Run the installer:
   ```
   lollmsenv_installer.bat [options]
   ```

### Unix-based systems (Linux, macOS)

1. Download the installer:
   [lollmsenv_installer.sh](https://github.com/ParisNeo/LollmsEnv/releases/download/V1.2.5/lollmsenv_installer.sh)
   Or in the console, type:
   ```
   wget https://github.com/ParisNeo/LollmsEnv/releases/download/V1.2.5/lollmsenv_installer.sh
   ```

3. Make the installer executable:
   ```
   chmod +x lollmsenv_installer.sh
   ```

4. Run the installer:
   ```
   ./lollmsenv_installer.sh [options]
   ```

### Installation Options

- `--local`: Install LollmsEnv locally in the current directory.
- `--dir <directory>`: Install LollmsEnv in the specified directory.
- `--no-modify-rc`: Do not modify .bashrc or .zshrc (Unix) or system PATH (Windows). Generate a source script instead.
- `-h, --help`: Show help message and exit.

## Usage

After installation, you can use the `lollmsenv` command to manage Python versions and environments.

For Windows:
```
lollmsenv.bat [command] [options]
```

For Unix-based systems:
```
[source] lollmsenv [command] [options]
```

If you did not accept adding lollmsenv to your Path (`--no-modify-rc`), make sure you start by activating the tool before usage:
Windows
```
path/to/your/lollmsenv activate
```

Linux
```
source path/to/your/lollmsenv activate 
```

## Commands

- `install-python [version] [custom_dir]`: Install a specific Python version
- `create-env [name] [python-version] [custom_dir]`: Create a new virtual environment
- `activate [name]`: Activate an environment
- `deactivate`: Deactivate the current environment
- `install [package]`: Install a package in the current environment
- `list-pythons`: List installed Python versions
- `list-envs`: List installed virtual environments
- `list-available-pythons`: List available Python versions for installation
- `create-bundle [name] [python-version] [env-name]`: Create a bundle with Python and environment
- `delete-env [name]`: Delete a virtual environment
- `delete-python [version]`: Delete a Python installation
- `--help, -h`: Show help message

## Examples

1. Install Python 3.9.5:
   ```
   lollmsenv install-python 3.9.5
   ```

2. Create a new environment named "myproject" with Python 3.9.5:
   ```
   lollmsenv create-env myproject 3.9.5
   ```

3. Activate the "myproject" environment:
   Windowe:
   ```
   lollmsenv activate myproject
   ```
   Linux:
   ```
   source lollmsenv activate myproject
   ```

5. Install a package in the current environment:
   ```
   lollmsenv install numpy
   ```

6. Create a bundle with Python 3.9.5 and an environment named "mybundle":
   ```
   lollmsenv create-bundle mybundle 3.9.5 myenv
   ```

## License

This project is open source and available under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Acknowledgments

LollmsEnv was created by ParisNeo and is hosted on GitHub at [https://github.com/ParisNeo/LollmsEnv](https://github.com/ParisNeo/LollmsEnv).
