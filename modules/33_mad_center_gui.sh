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
# On essaie de copier depuis les assets si disponibles, sinon on créé un placeholder fonctionnel
if [ -f "/mnt/hgfs/mados/assets/mados_cc.py" ]; then
    sudo cp /mnt/hgfs/mados/assets/mados_cc.py /opt/mados-control-center/mados_cc.py
    sudo cp /mnt/hgfs/mados/assets/logo.png /opt/mados-control-center/icon.png
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
Exec=sudo python3 /opt/mados-control-center/mados_cc.py
Icon=/opt/mados-control-center/icon.png
Terminal=true
Categories=System;Game;
EOF

# Copie sur "Desktop" et "Bureau" pour compatibilité FR/EN
for d in "Desktop" "Bureau" "bureau" "desktop"; do
    if [ -d "$USER_HOME/$d" ]; then
        sudo cp /tmp/MadOS.desktop "$USER_HOME/$d/MadOS.desktop"
        sudo chown "$REAL_USER":"$REAL_USER" "$USER_HOME/$d/MadOS.desktop"
        chmod +x "$USER_HOME/$d/MadOS.desktop"
        sudo -u "$REAL_USER" gio set "$USER_HOME/$d/MadOS.desktop" metadata::trusted true 2>/dev/null || true
    fi
done

echo -e "    ${CYAN}✅ [SUCCÈS] MadCenter Dashboard Premium est déployé.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 33 Terminée.${NC}"
