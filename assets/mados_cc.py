import sys
import subprocess
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QPushButton, QLabel, QTabWidget, QMessageBox)
from PyQt6.QtGui import QFont, QIcon, QColor, QPalette
from PyQt6.QtCore import Qt

class MadOSControlCenter(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("MadOS ROG Edition - Control Center")
        self.setFixedSize(600, 450)
        
        # Thème sombre / Rouge "MadOS"
        self.apply_theme()
        
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)
        
        # En-tête
        header_label = QLabel("MAD OS ROG - CENTRE DE CONTRÔLE")
        header_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        header_label.setStyleSheet("color: #ff0000; font-size: 20px; font-weight: bold; margin-bottom: 15px;")
        self.layout.addWidget(header_label)
        
        # Système d'onglets
        self.tabs = QTabWidget()
        self.tabs.setStyleSheet("QTabBar::tab { background: #1a1a1a; color: white; padding: 10px; } QTabBar::tab:selected { background: #ff0000; font-weight: bold;}")
        
        self.tab_perf = QWidget()
        self.tab_ai = QWidget()
        self.tab_sys = QWidget()
        
        self.tabs.addTab(self.tab_perf, "⚡ Performances ROG")
        self.tabs.addTab(self.tab_ai, "🤖 IA OpenClaw")
        self.tabs.addTab(self.tab_sys, "🧹 Système & RAM")
        
        self.setup_perf_tab()
        self.setup_ai_tab()
        self.setup_sys_tab()
        
        self.layout.addWidget(self.tabs)
        
    def apply_theme(self):
        palette = QPalette()
        palette.setColor(QPalette.ColorRole.Window, QColor(20, 20, 20))
        palette.setColor(QPalette.ColorRole.WindowText, Qt.GlobalColor.white)
        palette.setColor(QPalette.ColorRole.Base, QColor(30, 30, 30))
        palette.setColor(QPalette.ColorRole.AlternateBase, QColor(40, 40, 40))
        palette.setColor(QPalette.ColorRole.ToolTipBase, Qt.GlobalColor.white)
        palette.setColor(QPalette.ColorRole.ToolTipText, Qt.GlobalColor.white)
        palette.setColor(QPalette.ColorRole.Text, Qt.GlobalColor.white)
        palette.setColor(QPalette.ColorRole.Button, QColor(40, 40, 40))
        palette.setColor(QPalette.ColorRole.ButtonText, Qt.GlobalColor.white)
        palette.setColor(QPalette.ColorRole.Highlight, QColor(255, 0, 0))
        palette.setColor(QPalette.ColorRole.HighlightedText, Qt.GlobalColor.white)
        self.setPalette(palette)
        
    def create_btn(self, text, command, color="#cc0000"):
        btn = QPushButton(text)
        btn.setFixedHeight(50)
        btn.setStyleSheet(f"QPushButton {{ background-color: {color}; color: white; font-weight: bold; border-radius: 5px; }} QPushButton:hover {{ background-color: #ff3333; }}")
        btn.clicked.connect(lambda: self.run_command(command))
        return btn
        
    def run_command(self, cmd):
        try:
            subprocess.run(cmd, shell=True, check=True)
            QMessageBox.information(self, "Succès", f"Commande exécutée avec succès :\n{cmd}")
        except subprocess.CalledProcessError as e:
            QMessageBox.critical(self, "Erreur", f"L'exécution a échoué :\n{e}")
            
    def setup_perf_tab(self):
        layout = QVBoxLayout(self.tab_perf)
        layout.addWidget(QLabel("Modes de Performance (asusctl) :"))
        layout.addWidget(self.create_btn("Mode Silencieux (Batterie)", "asusctl profile -P Quiet", "#2e8b57"))
        layout.addWidget(self.create_btn("Mode Équilibré", "asusctl profile -P Balanced", "#d2691e"))
        layout.addWidget(self.create_btn("Mode Turbo / Performance", "asusctl profile -P Performance", "#ff0000"))
        layout.addWidget(QLabel("Gestion Carte Graphique (supergfxctl) :"))
        layout.addWidget(self.create_btn("GPU Intégré uniquement (Eco)", "supergfxctl -m Integrated", "#2e8b57"))
        layout.addWidget(self.create_btn("GPU Dédié NVIDIA/AMD (Gaming)", "supergfxctl -m Dedicated", "#ff0000"))
        
    def setup_ai_tab(self):
        layout = QVBoxLayout(self.tab_ai)
        layout.addWidget(QLabel("Gestion de l'assistant IA Local (OpenClaw) :"))
        layout.addWidget(self.create_btn("Démarrer le moteur IA", "systemctl --user start openclaw.service", "#2e8b57"))
        layout.addWidget(self.create_btn("Ouvrir l'interface Web (Chat)", "python3 -c \"import webbrowser; webbrowser.open('http://localhost:3000')\"", "#0055ff"))
        layout.addWidget(self.create_btn("Arrêter le moteur IA", "systemctl --user stop openclaw.service", "#ff0000"))
        
    def setup_sys_tab(self):
        layout = QVBoxLayout(self.tab_sys)
        layout.addWidget(QLabel("Optimisation Système :"))
        layout.addWidget(self.create_btn("Purger le Cache RAM (Drop Caches)", "pkexec bash -c 'sync; echo 3 > /proc/sys/vm/drop_caches'", "#555555"))
        layout.addWidget(self.create_btn("Forcer le TRIM des SSD/NVMe", "pkexec fstrim -av", "#555555"))
        layout.addWidget(self.create_btn("Lancer System Update (APT)", "x-terminal-emulator -e 'sudo apt update && sudo apt upgrade -y; read -p \"Appuyez sur Entrée pour quitter...\"'", "#0055ff"))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MadOSControlCenter()
    window.show()
    sys.exit(app.exec())
