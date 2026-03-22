#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 04_arsenal_logiciel.sh
# ==============================================================================
# Phase: 4 - Arsenal Logiciel & IA (OpenClaw)
# Installe Chrome, Steam, Lutris, et les outils Gaming.
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 4 Installation de l'Arsenal Logiciel${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

install_pkg() {
    for pkg in "$@"; do
        if apt-cache show "$pkg" &>/dev/null 2>&1; then
            sudo apt install -y "$pkg" || true
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

echo -e "    ${WHITE}├─ [EPIC/GOG] Déploiement Heroic Games Launcher & SGDBoop...${NC}"
install_pkg flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
sudo flatpak install -y flathub com.heroicgameslauncher.hgl >/dev/null 2>&1 || true
sudo flatpak install -y flathub com.steamgriddb.SGDBoop >/dev/null 2>&1 || true

# OpenClaw IA a été extrait vers son propre module (14_openclaw_ai.sh) pour l'automatisation.

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 4 Terminée.${NC}"
