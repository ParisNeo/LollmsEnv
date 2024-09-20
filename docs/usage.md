# LollmsEnv Usage

LollmsEnv provides the following commands:
## Activating LollmsEnv

If you installed LollmsEnv globally, it should be available after restarting your terminal or command prompt.

If you installed LollmsEnv locally, you need to activate it:

- On Windows: Run `activate.bat` in the LollmsEnv directory.
- On Unix-like systems: Run `source activate.sh` in the LollmsEnv directory.

Once activated, you can use the following commands:

1. Install Python:
   ```
   lollmsenv install-python <version>
   ```
   Example: `lollmsenv install-python 3.8.12`

2. Create a new environment:
   ```
   lollmsenv create-env <name> <python-version>
   ```
   Example: `lollmsenv create-env lollms_dev 3.8.12`

3. Activate an environment:
   ```
   lollmsenv activate <name>
   ```
   Example: `lollmsenv activate lollms_dev`

4. Deactivate the current environment:
   ```
   lollmsenv deactivate
   ```

5. Install a package:
   ```
   lollmsenv install <package>
   ```
   Example: `lollmsenv install numpy`

Note: After activating an environment, you need to run the command provided to actually activate it in your current shell.

## Troubleshooting

If you encounter any issues while using LollmsEnv, please check the following:

1. Ensure that you have the necessary permissions to install software on your system.
2. Check that your system meets the minimum requirements for the Python version you're trying to install.
3. If you're having network issues, check your internet connection and firewall settings.

If you continue to experience problems, please open an issue in the [GitHub repository](https://github.com/ParisNeo/LollmsEnv/issues) with a detailed description of the issue and any error messages you received.

## Contributing

We welcome contributions to LollmsEnv! If you have ideas for improvements or have found a bug, please open an issue or submit a pull request on our [GitHub repository](https://github.com/ParisNeo/LollmsEnv).

## License

LollmsEnv is open-source software licensed under the Apache License, Version 2.0. For more details, see the [LICENSE](../LICENSE) file in the project repository.