import sys
import os
import subprocess
from PyQt5.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QListWidget, QStackedWidget, QPushButton, QLabel, QLineEdit
from PyQt5.QtGui import QIcon
from PyQt5.QtCore import Qt

class LollmsEnvUI(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("LollmsEnv Manager")
        self.setGeometry(100, 100, 800, 600)
        self.setStyleSheet("""
                 
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
                border-radius: 4px;
            }
            QPushButton:hover {
                background-color: #45a049;
            }
        """)

        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.layout = QHBoxLayout(self.central_widget)

        self.sidebar = QListWidget()
        self.sidebar.addItems(["Pythons", "Environments", "Packages"])
        self.sidebar.setFixedWidth(150)
        self.layout.addWidget(self.sidebar)

        self.content_stack = QStackedWidget()
        self.layout.addWidget(self.content_stack)

        self.pythons_widget = self.create_pythons_widget()
        self.environments_widget = self.create_environments_widget()
        self.packages_widget = self.create_packages_widget()

        self.content_stack.addWidget(self.pythons_widget)
        self.content_stack.addWidget(self.environments_widget)
        self.content_stack.addWidget(self.packages_widget)

        self.sidebar.currentRowChanged.connect(self.content_stack.setCurrentIndex)

    def create_pythons_widget(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        
        pythons_list = QListWidget()
        layout.addWidget(pythons_list)

        install_button = QPushButton("Install Python")
        layout.addWidget(install_button)

        # Populate pythons_list and connect install_button
        return widget

    def create_environments_widget(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        
        envs_list = QListWidget()
        layout.addWidget(envs_list)

        create_button = QPushButton("Create Environment")
        layout.addWidget(create_button)

        # Populate envs_list and connect create_button
        return widget

    def create_packages_widget(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        
        packages_list = QListWidget()
        layout.addWidget(packages_list)

        package_input = QLineEdit()
        layout.addWidget(package_input)

        install_button = QPushButton("Install Package")
        layout.addWidget(install_button)

        # Populate packages_list and connect install_button
        return widget

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = LollmsEnvUI()
    window.show()
    sys.exit(app.exec_())
