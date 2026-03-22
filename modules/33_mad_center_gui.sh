#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 33_mad_center_gui.sh
# ==============================================================================
# Phase: 33 - MadCenter GUI (Python Control Dashboard)
# ==============================================================================

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🎨 ${WHITE}${BOLD}Phase 33 Déploiement du MadCenter ROG Dashboard (Interface GUI)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation des dépendances Python/Qt
echo -e "    ${WHITE}├─ [SYSTEM] Préparation du moteur graphique (PyQt6)...${NC}"
sudo apt update -q
sudo apt install -y python3-pyqt6 python3-pip python3-full

# 2. Création du script Python MadCenter
echo -e "    ${WHITE}├─ [CODE] Génération de l'application MadCenter Dashboard...${NC}"
sudo mkdir -p /opt/mados/madcenter
cat <<'EOF' | sudo tee /opt/mados/madcenter/madcenter.py >/dev/null
import sys
import os
from PyQt6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLabel, QFrame
from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtGui import QFont, QPalette, QColor

class MadCenter(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("MadOS 3.5 - ROG Control Center")
        self.setFixedSize(600, 400)
        self.init_ui()

    def init_ui(self):
        container = QWidget()
        layout = QVBoxLayout()
        container.setStyleSheet("background-color: #0F0F0F; color: white;")
        
        header = QLabel("MADOS ULTIMATE DASHBOARD")
        header.setFont(QFont("Impact", 24))
        header.setAlignment(Qt.AlignmentFlag.AlignCenter)
        header.setStyleSheet("color: #FF0000; margin-bottom: 20px;")
        layout.addWidget(header)

        # Boutons de Profil Performance
        perf_layout = QHBoxLayout()
        btn_eco = QPushButton("ECO 25W")
        btn_std = QPushButton("STD 45W")
        btn_ext = QPushButton("ULTRA 65W")
        
        for btn in [btn_eco, btn_std, btn_ext]:
            btn.setStyleSheet("background-color: #222; border: 1px solid #FF0000; padding: 15px; font-weight: bold;")
            perf_layout.addWidget(btn)
        
        layout.addLayout(perf_layout)
        
        # Bouton de Switch de Thème
        theme_btn = QPushButton("♻️ SWITCH VISUAL THEME (ROG/CYBER/CARBON)")
        theme_btn.setStyleSheet("background-color: #333; margin-top: 10px; padding: 20px; font-weight: bold; border-left: 5px solid #00FFFF;")
        theme_btn.clicked.connect(lambda: os.system("bash /usr/local/bin/mados-theme-switch"))
        layout.addWidget(theme_btn)

        self.stats = QLabel("⚡ SYSTEM STATS: LOADING...")
        self.stats.setStyleSheet("font-family: monospace; font-size: 14px; margin-top: 30px; border-top: 1px solid #333; padding: 10px;")
        layout.addWidget(self.stats)

        self.setCentralWidget(container)
        container.setLayout(layout)

        # Timer pour les stats
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_stats)
        self.timer.start(2000)

    def update_stats(self):
        try:
            temp = os.popen("sensors | grep 'Package id 0' | awk '{print $4}'").read().strip()
            self.stats.setText(f"🔥 CPU TEMP: {temp} | 🚀 RTX STATUS: ACTIVE | 🧊 OPTI: GOD TIER")
        except:
            self.stats.setText("⚡ SYSTEM STATS: ERROR POLLING HARDWARE")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MadCenter()
    window.show()
    sys.exit(app.exec())
EOF

# 3. Création du switcher de thème CLI rapide
sudo mkdir -p /usr/local/bin
cat <<'EOF' | sudo tee /usr/local/bin/mados-theme-switch >/dev/null
#!/bin/bash
CHOIX=$(whiptail --title "MadOS Theme Switcher" --menu "Changer de look sans réinstaller :" 12 50 3 \
"ROG" "Rouge & Noir Classique" \
"CYBER" "Neon Rose & Bleu" \
"CARBON" "Stealth Gris & Noir" 3>&1 1>&2 2>&3)
if [ $? -eq 0 ]; then
    export MADOS_THEME=$CHOIX
    sudo bash /path/to/modules/06_thematique_mados.sh
fi
EOF
sudo chmod +x /usr/local/bin/mados-theme-switch 2>/dev/null || true

# 4. Raccourci Bureau
cat <<EOF | sudo -u "$REAL_USER" tee "$USER_HOME/Desktop/MadCenter_ROG.desktop" >/dev/null
[Desktop Entry]
Name=MadCenter ROG Control
Comment=Tableau de bord MadOS
Exec=python3 /opt/mados/madcenter/madcenter.py
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=Settings;System;
EOF
chmod +x "$USER_HOME/Desktop/MadCenter_ROG.desktop" 2>/dev/null || true

echo -e "    ${CYAN}✅ [SUCCÈS] MadCenter Dashboard est déployé sur votre bureau.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 33 Terminée.${NC}"
