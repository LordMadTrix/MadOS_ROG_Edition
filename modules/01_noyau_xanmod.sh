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
# Repli par NIVEAU D'ARCHITECTURE decroissant. L'ancien repli visait
# "linux-xanmod-edge" sans suffixe : ce paquet N'EXISTE PAS dans le depot
# (verifie en VM : les paquets sont linux-xanmod-edge-x64v2/v3,
# linux-xanmod-lts-x64v1/v2/v3, linux-xanmod-x64v2/v3). Le repli echouait donc
# toujours, et le module annoncait un succes malgre tout.
XANMOD_POSE=0
for _pkg in "$XANMOD_PKG" "linux-xanmod-edge-x64v2" "linux-xanmod-lts-${CPU_LEVEL}" "linux-xanmod-lts-x64v1"; do
    if sudo apt install -y "$_pkg" 2>/dev/null; then
        echo -e "    ${GRAY}✅ [SUCCÈS] Noyau $_pkg installé.${NC}"
        XANMOD_PKG="$_pkg"
        XANMOD_POSE=1
        break
    fi
done
if [ "$XANMOD_POSE" -eq 0 ]; then
    echo -e "    ${RED}❌ [ERREUR] Aucun noyau XanMod n'a pu être installé.${NC}"
    echo -e "    ${YELLOW}    Le système restera sur son noyau actuel : $(uname -r)${NC}"
    echo -e "    ${GRAY}    Vérifiez le dépôt : ${GREEN}apt-cache search '^linux-xanmod'${NC}"
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
