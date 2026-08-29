#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 99_integration_systeme.sh
# ==============================================================================
# Phase: 99 - Finalisation & Intégration Permanente
# Rend l'installateur disponible via commande globale et nettoie l'OOBE.
# ==============================================================================

# ==============================================================================
# Variables de Couleurs
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC} 🔧 ${WHITE}${BOLD}Phase 99 Intégration Permanente au Système${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# 1. Création d'une commande globale 'mados-install'
# Note : le raccourci ci-dessous utilisait "gnome-terminal", absent sur KDE --
# c'est-a-dire sur le bureau que MadOS installe lui-meme. x-terminal-emulator
# est l'alternative Debian/Ubuntu qui pointe vers le terminal reellement present.
echo -e "    ${WHITE}├─ [CLI] Création de la commande 'mados-install'...${NC}"
if is_dry_run; then
    log_simu "écrirait le lanceur /usr/local/bin/mados-install et le rendrait exécutable"
else
    cat <<EOF | sudo tee /usr/local/bin/mados-install > /dev/null
#!/bin/bash
# Lanceur universel MadOS
curl -sL https://raw.githubusercontent.com/LordMadTrix/MadOS_ROG_Edition/main/install.sh | sudo bash
EOF
    sudo chmod +x /usr/local/bin/mados-install
fi

# 2. Création d'un raccourci sur le Bureau
echo -e "    ${WHITE}├─ [GUI] Création du raccourci sur le Bureau...${NC}"
if is_dry_run; then
    log_simu "créerait le raccourci MadOS-Installer.desktop dans $USER_HOME/Desktop et $USER_HOME/Bureau"
else
    mkdir -p "$USER_HOME/Bureau" "$USER_HOME/Desktop" 2>/dev/null || true

    cat <<EOF > "$USER_HOME/Desktop/MadOS-Installer.desktop"
[Desktop Entry]
Type=Application
Name=MadOS Installer
Comment=Relancer l'installateur MadOS
Exec=x-terminal-emulator -e mados-install
Icon=utilities-terminal
Terminal=false
Categories=System;
EOF

    cp "$USER_HOME/Desktop/MadOS-Installer.desktop" "$USER_HOME/Bureau/MadOS-Installer.desktop" 2>/dev/null || true
    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/Desktop" "$USER_HOME/Bureau" 2>/dev/null || true
    chmod +x "$USER_HOME/Desktop/MadOS-Installer.desktop" "$USER_HOME/Bureau/MadOS-Installer.desktop" 2>/dev/null || true
fi

# 3. Nettoyage de l'OOBE (Autostart & Terminal)
echo -e "    ${WHITE}├─ [SYSTEM] Nettoyage des mécanismes d'auto-run post-install...${NC}"
if is_dry_run; then
    log_simu "supprimerait /etc/xdg/autostart/mados.desktop et /usr/local/bin/mados-oobe"
else
    sudo rm -f /etc/xdg/autostart/mados.desktop 2>/dev/null || true
    sudo rm -f /usr/local/bin/mados-oobe 2>/dev/null || true
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 99 Terminée.${NC}"
