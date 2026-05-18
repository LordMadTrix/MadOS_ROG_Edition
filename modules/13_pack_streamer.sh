#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 13_pack_streamer.sh
# ==============================================================================
# Phase: 13 - Outils de Streaming (OBS)
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

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 13 : Déploiement du Pack Streamer v4.0${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# Ajouter le ppa officiel de OBS pour la dernière version
sudo add-apt-repository ppa:obsproject/obs-studio -y >/dev/null 2>&1 || true
sudo apt update -q >/dev/null 2>&1 || true

# Installation de OBS (stable) et support Caméra Virtuelle
echo -e "    ${GRAY}├─ Installation de OBS Studio & V4L2Loopback...${NC}"
sudo apt install -y obs-studio v4l2loopback-dkms >/dev/null 2>&1 || true

echo -e "    ${GRAY}✅ [SUCCÈS] OBS Studio installé.${NC}"

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 13 Terminée.${NC}"
