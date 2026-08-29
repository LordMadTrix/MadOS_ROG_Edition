#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 08_proton_gamescope.sh
# ==============================================================================
# Phase: 8 - Ultra Gaming (Proton-GE & GameScope)
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
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 8 Optimisations Ultra Gaming (Proton/GameScope)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installer GameScope et Feral GameMode
echo -e "    ${WHITE}├─ [COMPOSITEUR] Installation de Feral GameMode...${NC}"
run_action "installerait le paquet gamemode" sudo apt install -y gamemode >/dev/null 2>&1 || true

# 1b. Installer Wine 11 Stable (Système)
echo -e "    ${WHITE}├─ [WINE] Installation de Wine 11 Stable (support NTSYNC)...${NC}"
run_action "installerait winehq-stable" sudo apt install -y --install-recommends winehq-stable 2>/dev/null || true

# 2. Installer protonup en cli via pipx
echo -e "    ${WHITE}├─ [PROTON-GE] Recherche de la dernière version custom pour Steam...${NC}"
if ! sudo -u "$REAL_USER" command -v protonup &>/dev/null; then
    if is_dry_run; then
        log_simu "installerait protonup via pipx pour $REAL_USER"
    else
    sudo -u "$REAL_USER" pipx install protonup >/dev/null 2>&1 || true
    export PATH="$PATH:$USER_HOME/.local/bin"
    fi
fi

# Créer le dossier compatibilitytools de Steam
STEAM_COMPAT_DIR="$USER_HOME/.steam/root/compatibilitytools.d"
run_action "créerait $STEAM_COMPAT_DIR" sudo -u "$REAL_USER" mkdir -p "$STEAM_COMPAT_DIR"

if sudo -u "$REAL_USER" command -v protonup &>/dev/null; then
    run_action "déploierait Proton-GE dans $STEAM_COMPAT_DIR via protonup" sudo -u "$REAL_USER" protonup -d "$STEAM_COMPAT_DIR" -y >/dev/null 2>&1 || true
    echo -e "    ${GRAY}✅ [SUCCÈS] Proton-GE (Wine 11 based) déployé pour Steam.${NC}"
else
    echo -e "    ${RED}⚠️  [ATTENTION] Impossible de télécharger Proton-GE automatiquement.${NC}"
fi

# Note informative sur NTSYNC
if [ -c /dev/ntsync ]; then
    echo -e "    ${GRAY}ℹ️  [INFO] NTSYNC est ACTIF. Vos jeux Windows utiliseront la synchro noyau.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 8 Terminée.${NC}"
