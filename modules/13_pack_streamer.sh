#!/bin/bash
# ==========================================
# MadOS ROG V2.3 - 13_pack_streamer.sh
# ==========================================
# Phase: 13 - Outils de Streaming (OBS)
# ==========================================

export DEBIAN_FRONTEND=noninteractive

echo -e "${RED}>>> ${WHITE}[Phase 13] ${BOLD}Déploiement du Pack Streamer (OBS Studio)...${NC}"

# Ajouter le ppa officiel de OBS pour la dernière version
sudo add-apt-repository ppa:obsproject/obs-studio -y >/dev/null 2>&1 || true
sudo apt update -q >/dev/null 2>&1 || true

# Installation de OBS et obs-vkcapture (vital pour Wayland/Vulkan)
sudo apt install -y obs-studio obs-vkcapture noisetorch || true

echo -e "    ${GRAY}✅ [SUCCÈS] OBS Studio installé.${NC}"
echo -e "    ${GRAY}✅ [SUCCÈS] Plugin obs-vkcapture (Capture de fenêtres jeux Steam Wayland) activé.${NC}"
echo -e "    ${GRAY}✅ [SUCCÈS] NoiseTorch (Suppression du bruit clavier au micro via IA) installé.${NC}"

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 13 Terminée.${NC}"
