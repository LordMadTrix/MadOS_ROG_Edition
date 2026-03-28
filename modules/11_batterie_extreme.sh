#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 11_batterie_extreme.sh
# ==============================================================================
# Phase: 11 - Batterie Extrême (auto-cpufreq)
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

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 11 Installation du gestionnaire Batterie Extrême${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Résolution des conflits système
# Sur Ubuntu 24/25, power-profiles-daemon empêche auto-cpufreq de fonctionner correctement.
echo -e "    ${GRAY}├─ Suppression des conflits (power-profiles-daemon)...${NC}"
sudo systemctl disable --now power-profiles-daemon 2>/dev/null || true
sudo apt purge -y power-profiles-daemon 2>/dev/null || true

# 2. Installation de auto-cpufreq (Moteur d'optimisation processeur)
if ! command -v auto-cpufreq >/dev/null 2>&1; then
    echo -e "    ${WHITE}├─ [DOWNLOAD] Recuperation du moteur auto-cpufreq...${NC}"
    TEMP_DIR=$(mktemp -d)
    if git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git "$TEMP_DIR" >/dev/null 2>&1; then
        cd "$TEMP_DIR" && sudo ./auto-cpufreq-installer --install >/dev/null 2>&1
        rm -rf "$TEMP_DIR"
    fi
fi

if command -v auto-cpufreq >/dev/null 2>&1; then
    # On force la configuration initiale
    sudo auto-cpufreq --install >/dev/null 2>&1 || true
    sudo systemctl enable --now auto-cpufreq >/dev/null 2>&1
    echo -e "    ${GREEN}✅ [SUCCÈS] auto-cpufreq est operationnel et le conflit power-profiles est regle.${NC}"
else
    echo -e "    ${RED}❌ [ERREUR] Impossible d'installer le moteur de batterie.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 11 Terminée.${NC}"
