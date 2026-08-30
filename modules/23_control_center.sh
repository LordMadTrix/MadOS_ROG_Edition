#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 23_control_center.sh
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

# Module 23 : Installation interface GUI - MadOS Control Center
# ==========================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

echo -e "\n${RED}========================================================================${NC}"
echo -e "${RED}║${NC} ${WHITE}${BOLD}[23/23] Déploiement du MadOS Control Center (GUI)${NC}"
echo -e "${RED}========================================================================${NC}"

echo -e "    ${GRAY}├─ Installation des dépendances Python (PyQt6)...${NC}"
run_action "installerait python3-pyqt6 python3-psutil" sudo apt install -y python3-pyqt6 python3-psutil 2>/dev/null || true

APP_DIR="/opt/mados-control-center"
echo -e "    ${GRAY}├─ Création de l'arborescence $APP_DIR...${NC}"
run_action "créerait $APP_DIR" sudo mkdir -p "$APP_DIR" || true

echo -e "    ${GRAY}├─ Copie de l'application graphique...${NC}"
if [ -f "$(dirname "$0")/../assets/mados_cc.py" ]; then
    run_action "copierait mados_cc.py vers $APP_DIR" sudo cp -f "$(dirname "$0")/../assets/mados_cc.py" "$APP_DIR/mados_cc.py" || true
    run_action "rendrait $APP_DIR/mados_cc.py exécutable" sudo chmod +x "$APP_DIR/mados_cc.py" || true
fi

if [ -f "$(dirname "$0")/../assets/logo.png" ]; then
    run_action "copierait logo.png vers $APP_DIR/icon.png" sudo cp "$(dirname "$0")/../assets/logo.png" "$APP_DIR/icon.png" 2>/dev/null || true
fi

REAL_USER=${SUDO_USER:-$(who am i | awk '{print $1}')}
if [ -n "$REAL_USER" ]; then
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    run_action "créerait $USER_HOME/Bureau et $USER_HOME/Desktop" sudo -u "$REAL_USER" mkdir -p "$USER_HOME/Bureau" "$USER_HOME/Desktop" 2>/dev/null || true

    # Raccourci unique : MadOS Control Center (tout centralisé)
    if is_dry_run; then
        log_simu "créerait le raccourci $USER_HOME/Desktop/MadOS_Control_Center.desktop"
    else
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
    fi
    run_action "rendrait le raccourci exécutable" sudo chmod +x "$USER_HOME/Desktop/MadOS_Control_Center.desktop" || true
    run_action "changerait le propriétaire du raccourci pour $REAL_USER" sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/Desktop/MadOS_Control_Center.desktop" || true
    # Copie bureau français
    run_action "copierait le raccourci vers $USER_HOME/Bureau" sudo cp "$USER_HOME/Desktop/MadOS_Control_Center.desktop" "$USER_HOME/Bureau/" 2>/dev/null || true

    # Supprimer l'ancien raccourci OpenClaw séparé s'il existe
    run_action "supprimerait les anciens raccourcis OpenClaw_AI.desktop" sudo rm -f "$USER_HOME/Desktop/OpenClaw_AI.desktop" "$USER_HOME/Bureau/OpenClaw_AI.desktop" 2>/dev/null || true
fi

echo -e "    ${WHITE}✅ [SUCCÈS] MadOS Control Center déployé — Tout est centralisé.${NC}"
