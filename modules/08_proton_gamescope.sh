#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 08_proton_gamescope.sh
# ==============================================================================
# Phase: 8 - Ultra Gaming v4.0 (NTSYNC & HDR Ready)
# ==============================================================================

# Variables de Couleurs
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}Phase 8 : Optimisations Ultra Gaming v4.0 (NTSYNC & HDR)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. GAMESCOPE & GAMEMODE
echo -e "    ${WHITE}├─ [COMPOSITEUR] Installation de GameScope (HDR Support) et GameMode...${NC}"
# gamescope est dans universe (pas activé par défaut sur certaines installs)
sudo add-apt-repository universe -y >/dev/null 2>&1 || true
sudo apt-get update -qq >/dev/null 2>&1 || true
apt_install_safe "gamescope gamemode" "Installation GameScope & GameMode" || \
    echo -e "    ${YELLOW}⚠️  GameScope non disponible sur cette version — ignoré.${NC}"
# libgamemode i386 nécessite l'architecture i386 activée (optionnel, pour jeux 32-bit)
sudo dpkg --add-architecture i386 2>/dev/null || true
sudo apt-get update -qq >/dev/null 2>&1 || true
sudo apt-get install -y libgamemode0:i386 2>/dev/null || true

# 2. PROTON-GE (WINE 11 / NTSYNC)
echo -e "    ${WHITE}├─ [PROTON-GE] Déploiement de Proton 11+ via ProtonUp-CLI...${NC}"
if ! command -v pipx >/dev/null; then sudo apt install -y pipx && sudo -u "$REAL_USER" pipx ensurepath; fi
sudo -u "$REAL_USER" pipx install protonup-cli >/dev/null 2>&1 || true

# Création du dossier Steam Compatibility
STEAM_COMPAT_DIR="$USER_HOME/.steam/root/compatibilitytools.d"
sudo -u "$REAL_USER" mkdir -p "$STEAM_COMPAT_DIR"

# Installation de la dernière version GE
sudo -u "$REAL_USER" ~/.local/bin/protonup -d "$STEAM_COMPAT_DIR" -y >/dev/null 2>&1 || true

# 3. NTSYNC ENVIRONMENT FORCING
echo -e "    ${WHITE}├─ [NTSYNC] Injection des variables d'environnement globales...${NC}"
cat <<EOF | sudo tee /etc/environment.d/99-mados-gaming.conf >/dev/null
PROTON_NTSYNC=1
DXVK_ASYNC=1
PROTON_USE_SECCOMP=1
EOF

# 4. MANGOHUD CONFIG (ROG THEME)
echo -e "    ${WHITE}├─ [HUD] Configuration de MangoHud (Thème ROG)...${NC}"
sudo apt install -y mangohud 2>/dev/null || true
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/MangoHud"
cat <<EOF | sudo tee "$USER_HOME/.config/MangoHud/MangoHud.conf" >/dev/null
legacy_layout=0
horizontal
hud_no_margin
font_size=20
background_alpha=0.5
text_color=FF0000
cpu_text=CPU
gpu_text=GPU
fps
frame_timing
EOF

echo -e "\n${GREEN}✅ PHASE 8 TERMINÉE : Votre ROG est prêt pour l'E-Sport.${NC}\n"
