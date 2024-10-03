import sys
from PyQt5.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QListWidget, QStackedWidget, QLabel, QLineEdit
from PyQt5.QtGui import QIcon
from PyQt5.QtCore import Qt
import subprocess

class LollmsEnvUI(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("LollmsEnv Manager")
        self.setGeometry(100, 100, 800, 600)
        self.setStyleSheet("""
            QMainWindow {
                background-color: #f0f0f0;
            }
            QPushButton {
                background-color: #4CAF50;
                color: white;
                border: none;
                padding: 8px 16px;
                text-align: center;
                text-decoration: none;
                font-size: 14px;
                margin: 4px 2px;
                border-radius: 4px;
            }
            QPushButton:hover {
                background-color: #45a049;
            }
            QListWidget {
                background-color: white;
                border: 1px solid #ddd;
                border-radius: 4px;
            }
            QLabel {
                font-size: 16px;
                font-weight: bold;
            }
        """)

        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.main_layout = QHBoxLayout(self.central_widget)

        self.setup_sidebar()
        self.setup_main_content()

    def setup_sidebar(self):
        sidebar = QWidget()
        sidebar.setStyleSheet("background-color: #333; color: white;")
        sidebar_layout = QVBoxLayout(sidebar)

        buttons = ["Pythons", "Environments", "Packages"]
        for button_text in buttons:
            button = QPushButton(button_text)
            button.clicked.connect(lambda checked, text=button_text: self.change_view(text))
            sidebar_layout.addWidget(button)

        sidebar_layout.addStretch()
        self.main_layout.addWidget(sidebar, 1)

    def setup_main_content(self):
        self.main_content = QStackedWidget()
        self.main_layout.addWidget(self.main_content, 4)

        self.pythons_view = self.create_list_view("Pythons")
        self.envs_view = self.create_list_view("Environments")
        self.packages_view = self.create_list_view("Packages")

        self.main_content.addWidget(self.pythons_view)
        self.main_content.addWidget(self.envs_view)
        self.main_content.addWidget(self.packages_view)

    def create_list_view(self, title):
        view = QWidget()
        layout = QVBoxLayout(view)
        layout.addWidget(QLabel(title))
        list_widget = QListWidget()
        layout.addWidget(list_widget)

        if title == "Packages":
            search_box = QLineEdit()
            search_box.setPlaceholderText("Search packages...")
            layout.insertWidget(1, search_box)

            action_layout = QHBoxLayout()
            install_btn = QPushButton("Install")
            remove_btn = QPushButton("Remove")
            update_btn = QPushButton("Update")
            action_layout.addWidget(install_btn)
            action_layout.addWidget(remove_btn)
            action_layout.addWidget(update_btn)
            layout.addLayout(action_layout)

        return view

    def change_view(self, view_name):
        if view_name == "Pythons":
            self.main_content.setCurrentWidget(self.pythons_view)
            self.load_pythons()
        elif view_name == "Environments":
            self.main_content.setCurrentWidget(self.envs_view)
            self.load_environments()
        elif view_name == "Packages":
            self.main_content.setCurrentWidget(self.packages_view)
            self.load_packages()

    def load_pythons(self):
        pythons = self.run_lollmsenv_command("list-pythons")
        self.update_list_widget(self.pythons_view, pythons)

    def load_environments(self):
        environments = self.run_lollmsenv_command("list-envs")
        self.update_list_widget(self.envs_view, environments)

    def load_packages(self):
        packages = self.run_lollmsenv_command("pip list")
        self.update_list_widget(self.packages_view, packages)

    def update_list_widget(self, view, items):
        list_widget = view.findChild(QListWidget)
        list_widget.clear()
        list_widget.addItems(items)

    def run_lollmsenv_command(self, command):
        result = subprocess.run(["lollmsenv", command], capture_output=True, text=True)
        return result.stdout.strip().split("\n")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = LollmsEnvUI()
    window.show()
    sys.exit(app.exec_())
