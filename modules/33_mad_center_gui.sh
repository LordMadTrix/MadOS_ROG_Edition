#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 33_mad_center_gui.sh
# ==============================================================================
# Phase: 33 - MadCenter GUI (Python Control Dashboard)
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🎨 ${WHITE}${BOLD}Phase 33 Déploiement du MadCenter ROG Dashboard (Interface GUI)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation des dépendances Python/Qt (Moteur Premium)
echo -e "    ${WHITE}├─ [SYSTEM] Préparation du moteur graphique (Qt6 & XCB)...${NC}"
run_action "mettrait à jour les index apt" sudo apt update -q || true
run_action "installerait python3-pyqt6, python3-pip, python3-full et les libs libxcb/libxkbcommon" \
    sudo DEBIAN_FRONTEND=noninteractive apt install -y python3-pyqt6 python3-pip python3-full \
    libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxcb-xinerama0 \
    libxcb-xkb1 libxkbcommon-x11-0 --no-install-recommends || true

# Correctif pour les liens symboliques Qt6 sur Ubuntu 25.10
run_action "créerait le lien symbolique libxcb-cursor.so -> libxcb-cursor.so.0" sudo ln -sf /usr/lib/x86_64-linux-gnu/libxcb-cursor.so.0 /usr/lib/x86_64-linux-gnu/libxcb-cursor.so 2>/dev/null || true

# 2. Déploiement du script Premium MadOS Control Center
echo -e "    ${WHITE}├─ [CODE] Déploiement du MadOS Control Center Premium...${NC}"
run_action "créerait /opt/mados-control-center" sudo mkdir -p /opt/mados-control-center
# On essaie de copier depuis les assets si disponibles, sinon on créé un placeholder fonctionnel
# Chemin de developpement VMware (/mnt/hgfs/...) laisse en dur : toujours faux
# sur une machine reelle, donc le module ne deployait jamais rien. On repart
# des assets du depot, comme le fait le module 23.
MADOS_ASSETS="${PROJECT_ROOT:-$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")}/assets"
if [ -f "$MADOS_ASSETS/mados_cc.py" ]; then
    if is_dry_run; then
        log_simu "copierait mados_cc.py et logo.png depuis $MADOS_ASSETS vers /opt/mados-control-center"
    else
        sudo cp "$MADOS_ASSETS/mados_cc.py" /opt/mados-control-center/mados_cc.py
        [ -f "$MADOS_ASSETS/logo.png" ] && sudo cp "$MADOS_ASSETS/logo.png" /opt/mados-control-center/icon.png
    fi
else
    # Si les assets sont absents pendant cette phase, on s'assure que le dossier existe pour plus tard
    run_action "créerait /opt/mados-control-center/README.txt (placeholder)" sudo touch /opt/mados-control-center/README.txt
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
        if is_dry_run; then
            log_simu "installerait le raccourci MadOS.desktop dans $USER_HOME/$d (copie, propriétaire, exécutable, marqué fiable)"
        else
            sudo cp /tmp/MadOS.desktop "$USER_HOME/$d/MadOS.desktop"
            sudo chown "$REAL_USER":"$REAL_USER" "$USER_HOME/$d/MadOS.desktop"
            chmod +x "$USER_HOME/$d/MadOS.desktop"
            sudo -u "$REAL_USER" gio set "$USER_HOME/$d/MadOS.desktop" metadata::trusted true 2>/dev/null || true
        fi
    fi
done

echo -e "    ${CYAN}✅ [SUCCÈS] MadCenter Dashboard Premium est déployé.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 33 Terminée.${NC}"
