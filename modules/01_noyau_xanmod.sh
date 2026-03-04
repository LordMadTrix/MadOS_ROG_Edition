#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 01_noyau_xanmod.sh
# ==============================================================================
# Phase: 1 - Installation Kernel XanMod EDGE
# Cible spécifiquement la variance x64v3 pour ROG (AVX2).
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 1 Déploiement du Noyau XanMod EDGE${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

detect_cpu_level() {
    local flags
    flags=$(grep -m1 '^flags' /proc/cpuinfo)
    if echo "$flags" | grep -q 'avx512f'; then echo "x64v4";
    elif echo "$flags" | grep -q 'avx2'; then echo "x64v3";
    elif echo "$flags" | grep -q 'sse4_2'; then echo "x64v2";
    else echo "x64v1"; fi
}

CPU_LEVEL=$(detect_cpu_level)
echo -e "    ${WHITE}├─ [HARDWARE] Architecture CPU identifiée : $CPU_LEVEL${NC}"

XANMOD_PKG="linux-xanmod-edge-${CPU_LEVEL}"
echo -e "    ${GRAY}├─ Injection du paquet : $XANMOD_PKG...${NC}"

if sudo apt install -y "$XANMOD_PKG"; then
    echo -e "    ${GRAY}✅ [SUCCÈS] Noyau $XANMOD_PKG installé.${NC}"
else
    echo -e "    ${RED}⚠️  [ATTENTION] Moteur introuvable, tentative version générique...${NC}"
    sudo apt install -y linux-xanmod-edge
fi

echo -e "    ${WHITE}├─ [HEADERS] Construction des en-têtes (Prérequis DKMS GPU)...${NC}"
if sudo apt install -y "linux-headers-xanmod-edge-${CPU_LEVEL}" 2>/dev/null; then
    echo -e "    ${GRAY}✅ [SUCCÈS] linux-headers-xanmod-edge-${CPU_LEVEL} déployés.${NC}"
elif sudo apt install -y linux-headers-xanmod-edge 2>/dev/null; then
    echo -e "    ${GRAY}✅ [SUCCÈS] linux-headers-xanmod-edge déployés.${NC}"
fi

echo -e "    ${WHITE}├─ [BOOT] Séquenceur GRUB mis à jour.${NC}"
sudo update-grub 2>/dev/null || true

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 1 Terminée (Ne pas redémarrer avant le script GPU).${NC}"
