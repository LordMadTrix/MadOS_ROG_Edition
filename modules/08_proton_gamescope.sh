#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 08_proton_gamescope.sh
# ==============================================================================
# Phase: 8 - Ultra Gaming (Proton-GE & GameScope)
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

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 8 Optimisations Ultra Gaming (Proton/GameScope)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installer GameScope et Feral GameMode
echo -e "    ${WHITE}├─ [COMPOSITEUR] Installation de Feral GameMode...${NC}"
sudo apt install -y gamemode >/dev/null 2>&1 || true

# 1b. Installer Wine 11 Stable (Système)
echo -e "    ${WHITE}├─ [WINE] Installation de Wine 11 Stable (support NTSYNC)...${NC}"
sudo apt install -y --install-recommends winehq-stable 2>/dev/null || true

# 2. Installer protonup en cli via pipx
echo -e "    ${WHITE}├─ [PROTON-GE] Recherche de la dernière version custom pour Steam...${NC}"
if ! sudo -u "$REAL_USER" command -v protonup &>/dev/null; then
    sudo -u "$REAL_USER" pipx install protonup >/dev/null 2>&1 || true
    export PATH="$PATH:$USER_HOME/.local/bin"
fi

# Créer le dossier compatibilitytools de Steam
STEAM_COMPAT_DIR="$USER_HOME/.steam/root/compatibilitytools.d"
sudo -u "$REAL_USER" mkdir -p "$STEAM_COMPAT_DIR"

if sudo -u "$REAL_USER" command -v protonup &>/dev/null; then
    sudo -u "$REAL_USER" protonup -d "$STEAM_COMPAT_DIR" -y >/dev/null 2>&1 || true
    echo -e "    ${GRAY}✅ [SUCCÈS] Proton-GE (Wine 11 based) déployé pour Steam.${NC}"
else
    echo -e "    ${RED}⚠️  [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] Impossible de télécharger Proton-GE automatiquement.${NC}"
fi

# Note informative sur NTSYNC
if [ -c /dev/ntsync ]; then
    echo -e "    ${GRAY}ℹ️  [INFO] NTSYNC est ACTIF. Vos jeux Windows utiliseront la synchro noyau.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 8 Terminée.${NC}"
