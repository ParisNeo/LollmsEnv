# lollmsenv-py
A Python wrapper for lollmsenv, allowing you to manage Python versions and virtual environments directly from Python.
## Installation
```bash
pip install lollmsenv-py
```
## Usage

```python
from lollmsenv import LollmsEnv

env = LollmsEnv()


# Install Python
env.install_python("3.9.5")

# Create a virtual environment
env.create_env("myenv", "3.9.5")

# Activate an environment
env.activate_env("myenv")

# Install a package
env.install_package("requests")

# List installed Python versions
print(env.list_pythons())

# List virtual environments
print(env.list_envs())
```

## License
This project is licensed under the Apache 2.0 License - see the LICENSE file for details.