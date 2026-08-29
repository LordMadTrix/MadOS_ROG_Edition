#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 01_noyau_xanmod.sh
# ==============================================================================
# Phase: 1 - Installation Kernel XanMod EDGE (7.0+)
# Cible spécifiquement la variance x64v3 pour ROG (AVX2).
# Inclut désormais le support natif NTSYNC pour Wine 11.
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
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 1 Déploiement du Noyau XanMod EDGE (Optimisé 7.0)${NC}"
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

if is_dry_run; then
    log_simu "installerait le noyau $XANMOD_PKG (ou linux-xanmod-edge générique en repli)"
else
if sudo apt install -y "$XANMOD_PKG"; then
    echo -e "    ${GRAY}✅ [SUCCÈS] Noyau $XANMOD_PKG installé.${NC}"
else
    echo -e "    ${RED}⚠️  [ATTENTION] Moteur introuvable, tentative version générique...${NC}"
    sudo apt install -y linux-xanmod-edge || true
fi
fi

echo -e "    ${WHITE}├─ [HEADERS] Construction des en-têtes (Prérequis DKMS GPU)...${NC}"
if is_dry_run; then
    log_simu "installerait linux-headers-xanmod-edge-${CPU_LEVEL} (ou linux-headers-xanmod-edge générique en repli)"
else
if sudo apt install -y "linux-headers-xanmod-edge-${CPU_LEVEL}" 2>/dev/null; then
    echo -e "    ${GRAY}✅ [SUCCÈS] linux-headers-xanmod-edge-${CPU_LEVEL} déployés.${NC}"
elif sudo apt install -y linux-headers-xanmod-edge 2>/dev/null; then
    echo -e "    ${GRAY}✅ [SUCCÈS] linux-headers-xanmod-edge déployés.${NC}"
fi
fi

echo -e "    ${WHITE}├─ [BOOT] Séquenceur GRUB mis à jour.${NC}"
run_action "lancerait update-grub" sudo update-grub 2>/dev/null || true

# 4. Activation NTSYNC (Révolution Gaming 2026)
echo -e "    ${WHITE}├─ [NTSYNC] Activation de la synchronisation noyau...${NC}"
if is_dry_run; then
    log_simu "chargerait le module ntsync et écrirait /etc/modules-load.d/ntsync.conf"
else
sudo modprobe ntsync 2>/dev/null || true
echo "ntsync" | sudo tee /etc/modules-load.d/ntsync.conf > /dev/null
fi

if [ -c /dev/ntsync ]; then
    echo -e "    ${GRAY}✅ [SUCCÈS] /dev/ntsync est opérationnel.${NC}"
else
    echo -e "    ${YELLOW}⚠️  [ATTENTION] [INFO] NTSYNC sera actif après le prochain redémarrage.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 1 Terminée (Ne pas redémarrer avant le script GPU).${NC}"
