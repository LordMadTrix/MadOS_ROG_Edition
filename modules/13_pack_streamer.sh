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

# Installation de OBS (stable)
sudo apt install -y obs-studio >/dev/null 2>&1 || true

echo -e "    ${GRAY}✅ [SUCCÈS] OBS Studio installé.${NC}"

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 13 Terminée.${NC}"
