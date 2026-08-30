#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 07_snapshots_systeme.sh
# ==============================================================================
# Phase: 7 - Instantanés (Timeshift)
# Configure un point de sauvegarde système par sécurité
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

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 7 Déploiement du bouclier Timeshift${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# Installation
if ! command -v timeshift &>/dev/null; then
    run_action "installerait le paquet timeshift" sudo apt install -y timeshift || true
fi

# Basic check if root is btrfs
ROOT_FSTYPE=$(df -T / | awk 'NR==2 {print $2}')

if [ "$ROOT_FSTYPE" == "btrfs" ]; then
    echo -e "    ${WHITE}├─ [BTRFS] Mode snapshot ultra-rapide activé.${NC}"
    run_action "créerait un snapshot Timeshift BTRFS initial" sudo timeshift --btrfs --create --comments "Sauvegarde MadOS Initiale" > /dev/null 2>&1 || true
else
    echo -e "    ${GRAY}├─ [RSYNC] Mode standard RSYNC activé.${NC}"
    # On ne lance pas par défaut un rsync complet (trop long), on se contente de l'installer
    echo -e "    ${GRAY}├─ Veuillez ouvrir Timeshift graphiquement plus tard pour faire un backup.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 7 (Snapshots) Terminée.${NC}"
