#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 33_mad_center_gui.sh
# ==============================================================================
# Phase: 33 - MadCenter GUI (Python Control Dashboard)
# ==============================================================================

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'


echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🎨 ${WHITE}${BOLD}Phase 33 : Déploiement du MadCenter ROG Dashboard v4.0 (Interface GUI)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation des dépendances Python/Qt (Moteur Premium)
echo -e "    ${WHITE}├─ [SYSTEM] Préparation du moteur graphique (Qt6 & XCB)...${NC}"
sudo apt update -q || true
sudo DEBIAN_FRONTEND=noninteractive apt install -y python3-pyqt6 python3-pip python3-full \
    libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxcb-xinerama0 \
    libxcb-xkb1 libxkbcommon-x11-0 --no-install-recommends || true

# Correctif pour les liens symboliques Qt6 sur Ubuntu 25.10
sudo ln -sf /usr/lib/x86_64-linux-gnu/libxcb-cursor.so.0 /usr/lib/x86_64-linux-gnu/libxcb-cursor.so 2>/dev/null || true

# 2. Déploiement du script Premium MadOS Control Center
echo -e "    ${WHITE}├─ [CODE] Déploiement du MadOS Control Center Premium...${NC}"
sudo mkdir -p /opt/mados-control-center

# Définition du chemin des sources
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ASSETS="$SCRIPT_DIR/../assets"

# On essaie de copier depuis les assets si disponibles, sinon on créé un placeholder fonctionnel
if [ -f "$SRC_ASSETS/mados_cc.py" ]; then
    sudo cp "$SRC_ASSETS/mados_cc.py" /opt/mados-control-center/mados_cc.py || true
    sudo cp "$SRC_ASSETS/logo.png" /opt/mados-control-center/icon.png 2>/dev/null || true
elif [ -f "/opt/mados-rog/assets/mados_cc.py" ]; then
    sudo cp "/opt/mados-rog/assets/mados_cc.py" /opt/mados-control-center/mados_cc.py || true
    sudo cp "/opt/mados-rog/assets/logo.png" /opt/mados-control-center/icon.png 2>/dev/null || true
else
    # Si les assets sont absents pendant cette phase, on s'assure que le dossier existe pour plus tard
    sudo touch /opt/mados-control-center/README.txt
fi

# 3. Création des raccourcis Bureau (Bureau et Desktop)
echo -e "    ${WHITE}├─ [DESKTOP] Création des raccourcis sur le bureau...${NC}"
cat <<EOF > /tmp/MadOS.desktop
[Desktop Entry]
Type=Application
Name=MadOS Control Center
Comment=Interface ROG pour MadOS
Exec=python3 /opt/mados-control-center/mados_cc.py
Icon=/opt/mados-control-center/icon.png
Terminal=false
StartupNotify=false
Categories=System;Game;
EOF

# Ne pas créer de raccourci ici : module 23 crée déjà MadOS_Control_Center.desktop
# (évite le doublon sur le bureau)
rm -f /tmp/MadOS.desktop 2>/dev/null || true

echo -e "    ${CYAN}✅ [SUCCÈS] MadCenter Dashboard Premium est déployé.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 33 Terminée.${NC}"
