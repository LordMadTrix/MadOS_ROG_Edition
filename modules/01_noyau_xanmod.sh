#!/bin/bash
# ==========================================
# MadOS ROG V2 - 01_noyau_xanmod.sh
# ==========================================
# Phase: 1 - Installation Kernel XanMod EDGE
# Cible spécifiquement la variance x64v3 pour ROG (AVX2).
# ==========================================

export DEBIAN_FRONTEND=noninteractive

echo -e "${RED}>>> ${WHITE}[Phase 1] ${BOLD}Déploiement du Noyau XanMod EDGE...${NC}"

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
if sudo apt install -y "linux-headers-${CPU_LEVEL}" 2>/dev/null; then
    echo -e "    ${GRAY}✅ [SUCCÈS] linux-headers-${CPU_LEVEL} déployés.${NC}"
elif sudo apt install -y linux-headers-xanmod-edge 2>/dev/null; then
    echo -e "    ${GRAY}✅ [SUCCÈS] linux-headers-xanmod-edge déployés.${NC}"
fi

echo -e "    ${WHITE}├─ [BOOT] Séquenceur GRUB mis à jour.${NC}"
sudo update-grub 2>/dev/null || true

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 1 Terminée (Ne pas redémarrer avant le script GPU).${NC}"
