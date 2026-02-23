#!/bin/bash
# ==========================================
# MadOS ROG V2.1 - 07_snapshots_systeme.sh
# ==========================================
# Phase: 7 - Instantanés (Timeshift)
# Configure un point de sauvegarde système par sécurité
# ==========================================


export DEBIAN_FRONTEND=noninteractive

# ---- Couleurs & Styles ----
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}>>> ${WHITE}[Phase 7] ${BOLD}Déploiement du bouclier Timeshift...${NC}"

# Installation
if ! command -v timeshift &>/dev/null; then
    sudo apt install -y timeshift > /dev/null 2>&1
fi

# Basic check if root is btrfs
ROOT_FSTYPE=$(df -T / | awk 'NR==2 {print $2}')

if [ "$ROOT_FSTYPE" == "btrfs" ]; then
    echo -e "    ${WHITE}├─ [BTRFS] Mode snapshot ultra-rapide activé.${NC}"
    sudo timeshift --btrfs --create --comments "Sauvegarde MadOS Initiale" > /dev/null 2>&1 || true
else
    echo -e "    ${GRAY}├─ [RSYNC] Mode standard RSYNC activé.${NC}"
    # On ne lance pas par défaut un rsync complet (trop long), on se contente de l'installer
    echo -e "    ${GRAY}├─ Veuillez ouvrir Timeshift graphiquement plus tard pour faire un backup.${NC}"
fi

echo -e "    ${WHITE}✅ Phase 7 (Snapshots) Terminée.${NC}"
