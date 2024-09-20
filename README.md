# LollmsEnv

![GitHub license](https://img.shields.io/github/license/ParisNeo/LollmsEnv)
![GitHub stars](https://img.shields.io/github/stars/ParisNeo/LollmsEnv)
![GitHub forks](https://img.shields.io/github/forks/ParisNeo/LollmsEnv)
![GitHub issues](https://img.shields.io/github/issues/ParisNeo/LollmsEnv)

LollmsEnv is a lightweight environment management tool for Lollms projects. It allows you to install multiple Python versions, create and manage virtual environments, and install packages without requiring a pre-existing Python installation.
## Features
- Install and manage multiple Python versions
- Create and manage virtual environments
- Install and upgrade packages
- Export and import requirements
- Works without administrative privileges
## Installation

### Windows
1. Clone this repository:
   ```
   git clone https://github.com/ParisNeo/LollmsEnv.git
   ```
2. Navigate to the LollmsEnv directory and run:
   - For global installation: `install.bat`
   - For local installation: `install.bat --local`

### Unix-like systems (Linux, macOS)
1. Clone this repository:
   ```
   git clone https://github.com/ParisNeo/LollmsEnv.git
   ```
2. Navigate to the LollmsEnv directory.
3. Run `chmod +x install.sh` to make the install script executable.
4. Run:
   - For global installation: `./install.sh`
   - For local installation: `./install.sh --local`

## Usage

1. After installation:
   - For global installation: Restart your terminal or command prompt.
   - For local installation: Run `activate.bat` (Windows) or `source activate.sh` (Unix-like systems) in the installation directory.

2. Now you can use LollmsEnv commands. See [usage.md](docs/usage.md) for detailed usage instructions.

For detailed usage instructions, see docs/usage.md
## Commands
- install-python [version]: Install a specific Python version
- create-env [name] [python-version]: Create a new virtual environment
- activate [name]: Activate a virtual environment
- deactivate: Deactivate the current virtual environment
- install [package]: Install a package in the current environment
- list-packages: List installed packages
- upgrade-package [package]: Upgrade a package
- export-requirements [file]: Export environment requirements
- import-requirements [file]: Import environment requirements
- uninstall-python [version]: Uninstall a Python version
- remove-env [name]: Remove a virtual environment
- update-tool: Update LollmsEnv
- list-pythons: List installed Python versions
- list-envs: List available environments
## License

This project is licensed under the Apache License, Version 2.0 - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

If you encounter any problems or have any questions, please open an issue in the [GitHub repository](https://github.com/ParisNeo/LollmsEnv/issues).

## Credits
LollmsEnv is built by ParisNeo using Lollms.

![GitHub last commit](https://img.shields.io/github/last-commit/ParisNeo/LollmsEnv)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/ParisNeo/LollmsEnv)