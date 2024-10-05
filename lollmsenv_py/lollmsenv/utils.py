import subprocess
from .exceptions import LollmsEnvError
def run_command(cmd):
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        raise LollmsEnvError(f"Command failed: {e.cmd}\nError: {e.stderr}")