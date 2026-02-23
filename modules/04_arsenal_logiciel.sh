#!/bin/bash
# ==========================================
# MadOS ROG V2 - 04_arsenal_logiciel.sh
# ==========================================
# Phase: 4 - Arsenal Logiciel & IA (OpenClaw)
# Installe Chrome, Steam, Lutris, et les outils Gaming.
# ==========================================


export DEBIAN_FRONTEND=noninteractive

# ---- Couleurs & Styles ----
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "${RED}>>> ${WHITE}[Phase 4] ${BOLD}Installation de l'Arsenal Logiciel...${NC}"

install_pkg() {
    for pkg in "$@"; do
        if apt-cache show "$pkg" &>/dev/null 2>&1; then
            sudo apt install -y "$pkg" 2>/dev/null || true
        fi
    done
}

echo -e "    ${WHITE}├─ [WEB] Intégration Navigateur Chrome...${NC}"
install_pkg google-chrome-stable

echo -e "    ${WHITE}├─ [MULTIMÉDIA] Déploiement de Spotify...${NC}"
install_pkg spotify-client

echo -e "    ${WHITE}├─ [GAMING] Installation Steam & Lutris...${NC}"
install_pkg steam-installer steam-devices lutris

echo -e "    ${WHITE}├─ [Outils] Injection Utilitaires (VLC, OBS...)...${NC}"
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
install_pkg vlc obs-studio stacer mangohud goverlay ttf-mscorefonts-installer pipx

echo -e "    ${WHITE}├─ [PROTON] Déploiement Console ProtonUp-Qt...${NC}"
sudo -u "$REAL_USER" pipx install protonup-qt 2>/dev/null || true

# OpenClaw IA a été extrait vers son propre module (14_openclaw_ai.sh) pour l'automatisation.

echo -e "    ${WHITE}✅ Phase 4 Terminée.${NC}"
