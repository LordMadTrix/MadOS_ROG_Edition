#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 04_arsenal_logiciel.sh
# ==============================================================================
# Phase: 4 - Arsenal Logiciel & IA v4.0 (NTSYNC Edition)
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
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Source common.sh pour retry APT et logging (fallback standalone)
_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
[ -f "$_LIB" ] && source "$_LIB" 2>/dev/null || [ -f "/opt/mados-rog/lib/common.sh" ] && source "/opt/mados-rog/lib/common.sh" 2>/dev/null || true

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 4 : Installation de l'Arsenal Logiciel v4.0${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# Détection VM/headless — skip les apps GUI lourdes inutiles sans bureau
_VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
_HAS_DISPLAY=false
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then _HAS_DISPLAY=true; fi

if [ "$_VIRT" != "none" ] && ! $_HAS_DISPLAY; then
    echo -e "    ${YELLOW}⚠️  [VM SANS GUI détectée : $_VIRT]${NC}"
    echo -e "    ${GRAY}    Chrome, Spotify, VLC, OBS, Steam skippés (inutiles sans bureau).${NC}"
    echo -e "    ${GRAY}    Seuls flatpak et mangohud (CLI) seront installés.${NC}"
    install_pkg() { :; }  # Neutralise install_pkg pour ce module
    _VM_HEADLESS=true
else
    _VM_HEADLESS=false
    install_pkg() {
        for pkg in "$@"; do
            if apt-cache show "$pkg" &>/dev/null 2>&1; then
                if declare -f apt_install_safe &>/dev/null; then
                    apt_install_safe "$pkg" "$pkg" || true
                else
                    sudo apt-get install -y "$pkg" || true
                fi
            fi
        done
    }
fi

if ! $_VM_HEADLESS; then
    echo -e "    ${WHITE}├─ [WEB] Intégration Navigateur Chrome...${NC}"
    # Ajout du dépôt Google Chrome si absent
    if ! apt-cache show google-chrome-stable &>/dev/null; then
        wget -qO- https://dl.google.com/linux/linux_signing_key.pub \
            | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg 2>/dev/null || true
        echo 'deb [signed-by=/usr/share/keyrings/google-chrome.gpg arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' \
            | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
        apt_update_safe 2>/dev/null || true
    fi
    install_pkg google-chrome-stable

    echo -e "    ${WHITE}├─ [MULTIMÉDIA] Déploiement de Spotify...${NC}"
    if ! apt-cache show spotify-client &>/dev/null; then
        # Importer toutes les clés Spotify connues (le keyID change selon les versions du repo)
        for _spkey in 6224F9941A8AA6D1 C85668DF69375001 5384CE82BA52C83A; do
            curl -sS "https://download.spotify.com/debian/pubkey_${_spkey}.gpg" \
                | sudo gpg --dearmor --yes -o "/etc/apt/trusted.gpg.d/spotify-${_spkey}.gpg" 2>/dev/null || true
        done
        echo "deb http://repository.spotify.com stable non-free" \
            | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null
        apt_update_safe 2>/dev/null || true
    fi
    install_pkg spotify-client

    echo -e "    ${WHITE}├─ [GAMING] Installation Steam & Lutris...${NC}"
    install_pkg steam-installer steam-devices lutris

    echo -e "    ${WHITE}├─ [Outils] Injection Utilitaires (VLC, OBS...)...${NC}"
    echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
    install_pkg vlc obs-studio stacer mangohud goverlay ttf-mscorefonts-installer pipx

    echo -e "    ${WHITE}├─ [PROTON] Déploiement Console ProtonUp-Qt...${NC}"
    sudo -u "$REAL_USER" pipx install protonup-qt 2>/dev/null || true
fi

echo -e "    ${WHITE}├─ [EPIC/GOG] Configuration Flatpak & Flathub...${NC}"
sudo apt-get install -y flatpak >/dev/null 2>&1 || true
if command -v flatpak &>/dev/null; then
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
    if ! $_VM_HEADLESS; then
        echo -e "    ${GRAY}├─ Injection de Heroic Games Launcher...${NC}"
        flatpak install -y flathub com.heroicgameslauncher.hgl --noninteractive >/dev/null 2>&1 || true
        echo -e "    ${GRAY}├─ Injection de SGDBoop (Steam Artwork)...${NC}"
        flatpak install -y flathub com.steamgriddb.SGDBoop --noninteractive >/dev/null 2>&1 || true
    fi
fi

# OpenClaw IA a été extrait vers son propre module (14_openclaw_ai.sh) pour l'automatisation.

echo -e "\n    ${GREEN}✅ [SUCCÈS] Phase 4 (Arsenal Logiciel) injectée.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 4 Terminée.${NC}"
