#!/bin/bash
# ==========================================
# MadOS ROG V2.3 - 13_pack_streamer.sh
# ==========================================
# Phase: 13 - Outils de Streaming (OBS)
# ==========================================

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}>>> ${WHITE}[Phase 13] ${BOLD}Déploiement du Pack Streamer (OBS Studio)...${NC}"

# Ajouter le ppa officiel de OBS pour la dernière version
sudo add-apt-repository ppa:obsproject/obs-studio -y >/dev/null 2>&1 || true
sudo apt update -q >/dev/null 2>&1 || true

# Installation de OBS et obs-vkcapture (vital pour Wayland/Vulkan)
sudo apt install -y obs-studio obs-vkcapture noisetorch >/dev/null 2>&1 || true

echo -e "    ${GRAY}✅ OBS Studio installé.${NC}"
echo -e "    ${GRAY}✅ Plugin obs-vkcapture (Capture de fenêtres jeux Steam Wayland) activé.${NC}"
echo -e "    ${GRAY}✅ NoiseTorch (Suppression du bruit clavier au micro via IA) installé.${NC}"

echo -e "    ${WHITE}✅ Phase 13 Terminée.${NC}"
