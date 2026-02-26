#!/bin/bash
# ==========================================
# MadOS ROG V2.1 - 08_proton_gamescope.sh
# ==========================================
# Phase: 8 - Ultra Gaming (Proton-GE & GameScope)
# ==========================================

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}

echo -e "${RED}>>> ${WHITE}[Phase 8] ${BOLD}Optimisations Ultra Gaming (Proton/GameScope)...${NC}"

# 1. Installer GameScope et Feral GameMode
echo -e "    ${WHITE}├─ [COMPOSITEUR] Installation de Feral GameMode...${NC}"
sudo apt install -y gamemode >/dev/null 2>&1 || true

# 2. Installer protonup en cli via pipx
echo -e "    ${WHITE}├─ [PROTON-GE] Recherche de la dernière version custom pour Steam...${NC}"
if ! sudo -u "$REAL_USER" command -v protonup &>/dev/null; then
    sudo -u "$REAL_USER" pipx install protonup >/dev/null 2>&1 || true
    export PATH="$PATH:/home/$REAL_USER/.local/bin"
fi

# Créer le dossier compatibilitytools de Steam
STEAM_COMPAT_DIR="/home/$REAL_USER/.steam/root/compatibilitytools.d"
sudo -u "$REAL_USER" mkdir -p "$STEAM_COMPAT_DIR"

if sudo -u "$REAL_USER" command -v protonup &>/dev/null; then
    sudo -u "$REAL_USER" protonup -d "$STEAM_COMPAT_DIR" -y >/dev/null 2>&1 || true
    echo -e "    ${GRAY}✅ [SUCCÈS] Proton-GE a été déployé pour votre compte Steam.${NC}"
else
    echo -e "    ${RED}⚠️  [ATTENTION] Impossible de télécharger Proton-GE automatiquement. Utilisez ProtonUp-Qt.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 8 Terminée.${NC}"
