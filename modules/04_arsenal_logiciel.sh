#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 04_arsenal_logiciel.sh
# ==============================================================================
# Phase: 4 - Arsenal Logiciel & IA (OpenClaw)
# Installe Chrome, Steam, Lutris, et les outils Gaming.
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

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
            run_action "installer le paquet $pkg" sudo apt install -y "$pkg" || true
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
if is_dry_run; then
    log_simu "configurerait debconf pour accepter l'EULA ttf-mscorefonts-installer"
else
    echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
fi
install_pkg vlc obs-studio stacer mangohud goverlay ttf-mscorefonts-installer pipx

echo -e "    ${WHITE}├─ [PROTON] Déploiement Console ProtonUp-Qt...${NC}"
run_action "installer protonup-qt via pipx" sudo -u "$REAL_USER" pipx install protonup-qt 2>/dev/null || true

echo -e "    ${WHITE}├─ [EPIC/GOG] Configuration Flatpak & Flathub...${NC}"
install_pkg flatpak 2>/dev/null || true
if command -v flatpak &>/dev/null; then
    run_action "ajouter le dépôt Flathub" sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
    echo -e "    ${GRAY}├─ Injection de Heroic Games Launcher...${NC}"
    run_action "installer Heroic Games Launcher (flatpak)" sudo flatpak install -y flathub com.heroicgameslauncher.hgl --noninteractive >/dev/null 2>&1 || true
    echo -e "    ${GRAY}├─ Injection de SGDBoop (Steam Artwork)...${NC}"
    run_action "installer SGDBoop (flatpak)" sudo flatpak install -y flathub com.steamgriddb.SGDBoop --noninteractive >/dev/null 2>&1 || true
fi

# OpenClaw IA a été extrait vers son propre module (14_openclaw_ai.sh) pour l'automatisation.

echo -e "\n    ${GREEN}✅ [SUCCÈS] Phase 4 (Arsenal Logiciel) injectée.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 4 Terminée.${NC}"
