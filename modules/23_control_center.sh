#!/bin/bash
# ==========================================
# Module 23 : Installation interface GUI - MadOS Control Center
# ==========================================

echo -e "\n${RED}========================================================================${NC}"
echo -e "${RED}║${NC} ${WHITE}${BOLD}[23/23] Déploiement du MadOS Control Center (GUI)${NC}"
echo -e "${RED}========================================================================${NC}"

echo -e "    ${GRAY}├─ Installation des dépendances Python (PyQt6)...${NC}"
sudo apt install -y python3-pyqt6 python3-psutil 2>/dev/null || true

APP_DIR="/opt/mados-control-center"
echo -e "    ${GRAY}├─ Création de l'arborescence $APP_DIR...${NC}"
sudo mkdir -p "$APP_DIR"

echo -e "    ${GRAY}├─ Copie de l'application graphique...${NC}"
if [ -f "$(dirname "$0")/../assets/mados_cc.py" ]; then
    sudo cp -f "$(dirname "$0")/../assets/mados_cc.py" "$APP_DIR/mados_cc.py"
    sudo chmod +x "$APP_DIR/mados_cc.py"
fi

if [ -f "$(dirname "$0")/../assets/logo.png" ]; then
    sudo cp "$(dirname "$0")/../assets/logo.png" "$APP_DIR/icon.png" 2>/dev/null || true
fi

REAL_USER=${SUDO_USER:-$(who am i | awk '{print $1}')}
if [ -n "$REAL_USER" ]; then
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/Bureau" "$USER_HOME/Desktop" 2>/dev/null || true

    # Raccourci unique : MadOS Control Center (tout centralisé)
    cat <<EOF | sudo tee "$USER_HOME/Desktop/MadOS_Control_Center.desktop" > /dev/null
[Desktop Entry]
Name=MadOS Control Center
Comment=Performance, IA OpenClaw, Diagnostic, Mises à jour
Exec=python3 /opt/mados-control-center/mados_cc.py
Icon=/opt/mados-control-center/icon.png
Terminal=false
Type=Application
Categories=System;Settings;
StartupNotify=true
EOF
    sudo chmod +x "$USER_HOME/Desktop/MadOS_Control_Center.desktop"
    sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/Desktop/MadOS_Control_Center.desktop"
    # Copie bureau français
    sudo cp "$USER_HOME/Desktop/MadOS_Control_Center.desktop" "$USER_HOME/Bureau/" 2>/dev/null || true

    # Supprimer l'ancien raccourci OpenClaw séparé s'il existe
    sudo rm -f "$USER_HOME/Desktop/OpenClaw_AI.desktop" "$USER_HOME/Bureau/OpenClaw_AI.desktop" 2>/dev/null || true
fi

echo -e "    ${WHITE}✅ [SUCCÈS] MadOS Control Center déployé — Tout est centralisé.${NC}"
