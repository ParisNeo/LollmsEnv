import sys, os
import subprocess
import logging
from pathlib import Path
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, 
                             QListWidget, QPushButton, QStackedWidget, QInputDialog, 
                             QMessageBox, QLabel, QLineEdit, QProgressBar)
from PyQt5.QtGui import QIcon
from PyQt5.QtCore import Qt, QThread, pyqtSignal, QTimer

# Set up logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

class Worker(QThread):
    finished = pyqtSignal(object)
    error = pyqtSignal(str)

    def __init__(self, function, *args, **kwargs):
        super().__init__()
        self.function = function
        self.args = args
        self.kwargs = kwargs

    def run(self):
        try:
            result = self.function(*self.args, **self.kwargs)
            self.finished.emit(result)
        except Exception as e:
            logging.error(f"Error in worker thread: {str(e)}")
            self.error.emit(str(e))

class Spinner(QProgressBar):
    def __init__(self):
        super().__init__()
        self.setRange(0, 0)
        self.setTextVisible(False)
        self.setFixedSize(50, 50)
        self.hide()

class LollmsEnvManager:
    SCRIPT_DIR = Path(__file__).resolve().parent
    PYTHONS_FILE = SCRIPT_DIR.parent / "pythons" / "installed_pythons.txt"
    ENVS_FILE = SCRIPT_DIR.parent / "envs" / "installed_envs.txt"

    @staticmethod
    def run_lollmsenv_command(command):
        try:
            full_command = f"lollmsenv.bat {' '.join(command)}"
            logging.debug(f"Running command: {full_command}")
            
            process = subprocess.Popen(full_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, text=True, cwd=os.getcwd())
            
            stdout, stderr = process.communicate(timeout=30)
            
            if process.returncode != 0:
                logging.error(f"Command failed with return code {process.returncode}")
                logging.error(f"Error output: {stderr}")
                return None

            logging.debug(f"Command output: {stdout}")
            return stdout.strip()
        except subprocess.TimeoutExpired:
            logging.error("Command timed out")
            return None
        except Exception as e:
            logging.error(f"Error running command: {str(e)}")
            return None

    @staticmethod
    def is_env_active(env_name):
        # Get the path of the Python interpreter
        executable_path = Path(sys.executable)

        # Check if we're in a virtual environment
        if 'venv' in executable_path.parts or 'virtualenv' in executable_path.parts:
            # We're in a virtual environment
            venv_path = executable_path.parent.parent
            active_venv_name = venv_path.name

            # Check if the active venv matches the given env_name
            return active_venv_name.lower() == env_name.lower()
        else:
            # We're not in a virtual environment
            return False


    @staticmethod
    def get_installed_pythons():
        if LollmsEnvManager.PYTHONS_FILE.exists():
            with LollmsEnvManager.PYTHONS_FILE.open("r") as f:
                return [f"{line.split(',')[0]}: {line.split(',')[1]}" for line in f]
        return []

    @staticmethod
    def get_installed_envs():
        if LollmsEnvManager.ENVS_FILE.exists():
            with LollmsEnvManager.ENVS_FILE.open("r") as f:
                return [f"{line.split(',')[0]}: {line.split(',')[2]}" for line in f]
        return []

    @staticmethod
    def install_python(version):
        result = LollmsEnvManager.run_lollmsenv_command(['install-python', version])
        if result:
            LollmsEnvManager.update_pythons_file(version, result)
        return result is not None

    @staticmethod
    def remove_python(version):
        result = LollmsEnvManager.run_lollmsenv_command(['delete-python', version])
        if result:
            LollmsEnvManager.remove_from_pythons_file(version)
        return result is not None

    @staticmethod
    def create_env(name, python_version):
        result = LollmsEnvManager.run_lollmsenv_command(['create-env', name, python_version])
        if result:
            LollmsEnvManager.update_envs_file(name, result, python_version)
        return result is not None

    @staticmethod
    def remove_env(name):
        result = LollmsEnvManager.run_lollmsenv_command(['delete-env', name])
        if result:
            LollmsEnvManager.remove_from_envs_file(name)
        return result is not None

    @staticmethod
    def update_pythons_file(version, path):
        with LollmsEnvManager.PYTHONS_FILE.open("a") as f:
            f.write(f"{version},{path}\n")

    @staticmethod
    def remove_from_pythons_file(version):
        lines = LollmsEnvManager.PYTHONS_FILE.read_text().splitlines()
        LollmsEnvManager.PYTHONS_FILE.write_text("\n".join(line for line in lines if not line.startswith(f"{version},")))

    @staticmethod
    def update_envs_file(name, path, python_version):
        with LollmsEnvManager.ENVS_FILE.open("a") as f:
            f.write(f"{name},{path},{python_version}\n")

    @staticmethod
    def remove_from_envs_file(name):
        lines = LollmsEnvManager.ENVS_FILE.read_text().splitlines()
        LollmsEnvManager.ENVS_FILE.write_text("\n".join(line for line in lines if not line.startswith(f"{name},")))

    @staticmethod
    def install_package(env_name, package_name):
        return LollmsEnvManager.run_lollmsenv_command(['activate', env_name, '&&', 'install', package_name]) is not None

    @staticmethod
    def remove_package(env_name, package_name):
        return LollmsEnvManager.run_lollmsenv_command(['activate', env_name, '&&', 'pip', 'uninstall', '-y', package_name]) is not None

    @staticmethod
    def update_package(env_name, package_name):
        return LollmsEnvManager.run_lollmsenv_command(['activate', env_name, '&&', 'pip', 'install', '--upgrade', package_name]) is not None

class PythonsView(QWidget):
    def __init__(self):
        super().__init__()
        self.layout = QVBoxLayout()
        self.pythons_list = QListWidget()
        self.refresh_button = QPushButton("Refresh")
        self.install_button = QPushButton("Install Python")
        self.remove_button = QPushButton("Remove Python")

        self.layout.addWidget(self.pythons_list)
        self.layout.addWidget(self.refresh_button)
        self.layout.addWidget(self.install_button)
        self.layout.addWidget(self.remove_button)

        self.setLayout(self.layout)

        self.refresh_button.clicked.connect(self.refresh_pythons)
        self.install_button.clicked.connect(self.install_python)
        self.remove_button.clicked.connect(self.remove_python)

        self.refresh_pythons()

    def refresh_pythons(self):
        self.pythons_list.clear()
        pythons = LollmsEnvManager.get_installed_pythons()
        self.pythons_list.addItems(pythons)

    def install_python(self):
        version, ok = QInputDialog.getText(self, "Install Python", "Enter Python version:")
        if ok and version:
            success = LollmsEnvManager.install_python(version)
            if success:
                self.refresh_pythons()
            else:
                QMessageBox.warning(self, "Installation Failed", "Failed to install Python " + version)

    def remove_python(self):
        current_item = self.pythons_list.currentItem()
        if current_item:
            version = current_item.text().split(':')[0]
            reply = QMessageBox.question(self, "Remove Python", f"Are you sure you want to remove Python {version}?",
                                         QMessageBox.Yes | QMessageBox.No)
            if reply == QMessageBox.Yes:
                success = LollmsEnvManager.remove_python(version)
                if success:
                    self.refresh_pythons()
                else:
                    QMessageBox.warning(self, "Removal Failed", f"Failed to remove Python {version}")
        else:
            QMessageBox.warning(self, "No Selection", "Please select a Python version to remove")

class EnvironmentsView(QWidget):
    def __init__(self):
        super().__init__()
        self.layout = QVBoxLayout()
        self.envs_list = QListWidget()
        self.refresh_button = QPushButton("Refresh")
        self.create_button = QPushButton("Create Environment")
        self.remove_button = QPushButton("Remove Environment")

        self.layout.addWidget(self.envs_list)
        self.layout.addWidget(self.refresh_button)
        self.layout.addWidget(self.create_button)
        self.layout.addWidget(self.remove_button)

        self.setLayout(self.layout)

        self.refresh_button.clicked.connect(self.refresh_envs)
        self.create_button.clicked.connect(self.create_env)
        self.remove_button.clicked.connect(self.remove_env)

        self.refresh_envs()

    def refresh_envs(self):
        self.envs_list.clear()
        envs = LollmsEnvManager.get_installed_envs()
        self.envs_list.addItems(envs)

    def create_env(self):
        name, ok1 = QInputDialog.getText(self, "Create Environment", "Enter environment name:")
        if ok1 and name:
            version, ok2 = QInputDialog.getText(self, "Create Environment", "Enter Python version:")
            if ok2 and version:
                success = LollmsEnvManager.create_env(name, version)
                if success:
                    self.refresh_envs()
                else:
                    QMessageBox.warning(self, "Creation Failed", f"Failed to create environment {name}")

    def remove_env(self):
        current_item = self.envs_list.currentItem()
        if current_item:
            name = current_item.text().split(':')[0]
            reply = QMessageBox.question(self, "Remove Environment", f"Are you sure you want to remove environment {name}?",
                                         QMessageBox.Yes | QMessageBox.No)
            if reply == QMessageBox.Yes:
                success = LollmsEnvManager.remove_env(name)
                if success:
                    self.refresh_envs()
                else:
                    QMessageBox.warning(self, "Removal Failed", f"Failed to remove environment {name}")
        else:
            QMessageBox.warning(self, "No Selection", "Please select an environment to remove")

class PackagesView(QWidget):
    def __init__(self):
        super().__init__()
        self.layout = QVBoxLayout()
        self.env_selector = QListWidget()
        self.packages_list = QListWidget()
        self.package_input = QLineEdit()
        self.install_button = QPushButton("Install Package")
        self.remove_button = QPushButton("Remove Package")
        self.update_button = QPushButton("Update Package")
        self.spinner = Spinner()

        self.layout.addWidget(QLabel("Select Environment:"))
        self.layout.addWidget(self.env_selector)
        self.layout.addWidget(QLabel("Packages:"))
        self.layout.addWidget(self.packages_list)
        self.layout.addWidget(self.package_input)
        self.layout.addWidget(self.install_button)
        self.layout.addWidget(self.remove_button)
        self.layout.addWidget(self.update_button)
        self.layout.addWidget(self.spinner)

        self.setLayout(self.layout)

        self.env_selector.currentItemChanged.connect(self.refresh_packages)
        self.install_button.clicked.connect(self.install_package)
        self.remove_button.clicked.connect(self.remove_package)
        self.update_button.clicked.connect(self.update_package)

        self.refresh_envs()

    def refresh_envs(self):
        self.env_selector.clear()
        envs = LollmsEnvManager.get_installed_envs()
        self.env_selector.addItems(envs)

    def refresh_packages(self):
        self.packages_list.clear()
        current_env = self.env_selector.currentItem()
        if current_env:
            env_name = current_env.text().split(':')[0]
            self.spinner.show()
            self.worker = Worker(self.get_packages, env_name)
            self.worker.finished.connect(self.on_packages_loaded)
            self.worker.error.connect(self.on_error)
            self.worker.start()

    def get_packages(self, env_name):
        # Check if the environment is already active
        if not LollmsEnvManager.is_env_active(env_name):
            # Activate the environment only if it's not already active
            activate_result = LollmsEnvManager.run_lollmsenv_command(['activate', env_name])
            logging.debug(f"Activate result: {activate_result}")
            if activate_result is None:
                raise Exception(f"Failed to activate environment {env_name}")

        # List the packages
        packages_result = LollmsEnvManager.run_lollmsenv_command(['pip', 'list'])
        logging.debug(f"Packages result: {packages_result}")
        if packages_result is None:
            raise Exception("Failed to list packages")

        return packages_result  

    def on_packages_loaded(self, packages):
        self.spinner.hide()
        if packages:
            self.packages_list.addItems(packages.split('\n')[2:])  # Skip the header rows
        else:
            QMessageBox.warning(self, "Error", "Failed to load packages")

    def on_error(self, error_message):
        self.spinner.hide()
        QMessageBox.warning(self, "Error", f"An error occurred: {error_message}")
      
    def install_package(self):
        current_env = self.env_selector.currentItem()
        package_name = self.package_input.text()
        if current_env and package_name:
            env_name = current_env.text().split(':')[0]
            self.spinner.show()
            self.worker = Worker(LollmsEnvManager.install_package, env_name, package_name)
            self.worker.finished.connect(self.on_package_installed)
            self.worker.error.connect(self.on_error)
            self.worker.start()
        else:
            QMessageBox.warning(self, "Invalid Input", "Please select an environment and enter a package name")

    def on_package_installed(self, success):
        self.spinner.hide()
        if success:
            self.refresh_packages()
            self.package_input.clear()
        else:
            QMessageBox.warning(self, "Installation Failed", f"Failed to install package {self.package_input.text()}")

    def remove_package(self):
        current_env = self.env_selector.currentItem()
        current_package = self.packages_list.currentItem()
        if current_env and current_package:
            env_name = current_env.text().split(':')[0]
            package_name = current_package.text().split()[0]
            reply = QMessageBox.question(self, "Remove Package", f"Are you sure you want to remove package {package_name}?",
                                         QMessageBox.Yes | QMessageBox.No)
            if reply == QMessageBox.Yes:
                self.spinner.show()
                self.worker = Worker(LollmsEnvManager.remove_package, env_name, package_name)
                self.worker.finished.connect(self.on_package_removed)
                self.worker.error.connect(self.on_error)
                self.worker.start()
        else:
            QMessageBox.warning(self, "No Selection", "Please select an environment and a package to remove")

    def on_package_removed(self, success):
        self.spinner.hide()
        if success:
            self.refresh_packages()
        else:
            QMessageBox.warning(self, "Removal Failed", f"Failed to remove package")

    def update_package(self):
        current_env = self.env_selector.currentItem()
        current_package = self.packages_list.currentItem()
        if current_env and current_package:
            env_name = current_env.text().split(':')[0]
            package_name = current_package.text().split()[0]
            self.spinner.show()
            self.worker = Worker(LollmsEnvManager.update_package, env_name, package_name)
            self.worker.finished.connect(self.on_package_updated)
            self.worker.error.connect(self.on_error)
            self.worker.start()
        else:
            QMessageBox.warning(self, "No Selection", "Please select an environment and a package to update")

    def on_package_updated(self, success):
        self.spinner.hide()
        if success:
            self.refresh_packages()
        else:
            QMessageBox.warning(self, "Update Failed", "Failed to update package")


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("LollmsEnv Manager")
        self.setGeometry(100, 100, 800, 600)

        # Create main layout
        main_layout = QHBoxLayout()

        # Create and setup sidebar
        self.sidebar = QListWidget()
        self.sidebar.addItems(["Pythons", "Environments", "Packages"])
        self.sidebar.setFixedWidth(150)
        self.sidebar.currentRowChanged.connect(self.change_view)

        # Create stacked widget for content area
        self.content_area = QStackedWidget()

        # Create and add views
        self.pythons_view = PythonsView()
        self.environments_view = EnvironmentsView()
        self.packages_view = PackagesView()

        self.content_area.addWidget(self.pythons_view)
        self.content_area.addWidget(self.environments_view)
        self.content_area.addWidget(self.packages_view)

        # Add widgets to main layout
        main_layout.addWidget(self.sidebar)
        main_layout.addWidget(self.content_area)

        # Set central widget
        central_widget = QWidget()
        central_widget.setLayout(main_layout)
        self.setCentralWidget(central_widget)

    def change_view(self, index):
        self.content_area.setCurrentIndex(index)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    
    # Apply custom styling
    app.setStyleSheet("""
        QMainWindow {
            background-color: #f0f0f0;
        }
        QListWidget {
            background-color: #ffffff;
            border: 1px solid #cccccc;
            border-radius: 5px;
        }
        QPushButton {
            background-color: #4CAF50;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 5px;
        }
        QPushButton:hover {
            background-color: #45a049;
        }
        QLineEdit {
            padding: 5px;
            border: 1px solid #cccccc;
            border-radius: 3px;
        }
        QProgressBar {
            border: 2px solid grey;
            border-radius: 5px;
            text-align: center;
        }
        QProgressBar::chunk {
            background-color: #4CAF50;
            width: 10px;
            margin: 0.5px;
        }
    """)
    
    window = MainWindow()
    window.show()
    sys.exit(app.exec_())
