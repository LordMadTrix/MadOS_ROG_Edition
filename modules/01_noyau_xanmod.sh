#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 01_noyau_xanmod.sh
# ==============================================================================
# Phase: 1 - Installation Kernel XanMod MAIN (Stable Mainline - 6.19+)
# Priorité : MAIN (stable mainline) > EDGE (bleeding edge) > générique
# Cible la variance x64v3/v4 pour ROG (AVX2/AVX512).
# Optimisé pour Ubuntu 25.04 "Plucky Puffin" et NTSYNC natif.
# Ref: https://xanmod.org/ — MAIN = Stable Mainline (le plus à jour stable)
# ==============================================================================

# Variables de Couleurs
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

# Source common.sh pour retry APT et logging (fallback standalone)
_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
[ -f "$_LIB" ] && source "$_LIB" 2>/dev/null || [ -f "/opt/mados-rog/lib/common.sh" ] && source "/opt/mados-rog/lib/common.sh" 2>/dev/null || true

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}Phase 1 : Déploiement du Noyau XanMod MAIN v4.0 (6.19+ NTSYNC Native)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Détection VM — XanMod inutile en virtualisation (noyau hôte non remplaçable)
_VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
if [ "$_VIRT" != "none" ] && [ "$_VIRT" != "" ]; then
    echo -e "    ${YELLOW}⚠️  [VM DÉTECTÉE] Hyperviseur : ${CYAN}$_VIRT${NC}"
    echo -e "    ${YELLOW}    XanMod n'est pas installé en VM (kernel hôte non modifiable).${NC}"
    echo -e "    ${GRAY}    → Ce module sera ignoré automatiquement.${NC}"
    echo -e "\n    ${GREEN}✅ PHASE 1 : Skip VM — OK.${NC}\n"
    exit 0
fi

# 2. Vérification de la version d'Ubuntu
OS_VER=$(lsb_release -rs)
echo -e "    ${WHITE}├─ [OS] Détection Ubuntu $OS_VER...${NC}"

# 2. Détection du niveau d'architecture x86-64
detect_cpu_level() {
    local flags
    flags=$(grep -m1 '^flags' /proc/cpuinfo)
    if echo "$flags" | grep -q 'avx512f'; then echo "x64v4";
    elif echo "$flags" | grep -q 'avx2'; then echo "x64v3";
    elif echo "$flags" | grep -q 'sse4_2'; then echo "x64v2";
    else echo "x64v1"; fi
}

CPU_LEVEL=$(detect_cpu_level)
echo -e "    ${WHITE}├─ [HARDWARE] Architecture CPU identifiée : ${CYAN}$CPU_LEVEL${NC}"

# 3. Ajout du dépôt XanMod si manquant
if ! grep -q "xanmod" /etc/apt/sources.list.d/* 2>/dev/null; then
    echo -e "    ${GRAY}├─ [REPO] Ajout du dépôt officiel XanMod...${NC}"
    wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://dl.xanmod.org/repository xanmod main' | sudo tee /etc/apt/sources.list.d/xanmod-kernel.list > /dev/null
    apt_update_safe
fi

# 4. Installation du noyau — ordre de priorité :
#    MAIN (stable mainline) > EDGE (bleeding edge) > générique
#    Ref xanmod.org : MAIN 6.19 stable (2026-05-16), 7.x à venir
#    Le script cherche automatiquement la version la plus récente disponible dans le repo.
INSTALLED_PKG=""

# Afficher la version XanMod disponible dans le repo
_latest=$(apt-cache search "linux-xanmod" 2>/dev/null | grep -v "headers\|dbg\|devel" | grep "$CPU_LEVEL" | sort -V | tail -n1 | awk '{print $1}')
[ -n "$_latest" ] && echo -e "    ${CYAN}├─ [REPO] Dernière version détectée : ${WHITE}$_latest${NC}"

for variant in "" "-edge"; do
    PKG="linux-xanmod${variant}-${CPU_LEVEL}"
    echo -e "    ${GRAY}├─ Tentative : ${WHITE}$PKG${NC}"
    if apt-cache show "$PKG" &>/dev/null 2>&1; then
        _ver=$(apt-cache show "$PKG" 2>/dev/null | awk '/^Version:/{print $2; exit}')
        echo -e "    ${GRAY}    Version disponible : ${CYAN}$_ver${NC}"
        if apt_install_safe "$PKG" "Kernel XanMod${variant} $CPU_LEVEL"; then
            INSTALLED_PKG="$PKG"
            echo -e "    ${GREEN}✅ [SUCCÈS] $PKG ($_ver) installé.${NC}"
            break
        fi
    else
        echo -e "    ${GRAY}    (non disponible dans le repo)${NC}"
    fi
done

if [ -z "$INSTALLED_PKG" ]; then
    echo -e "    ${YELLOW}⚠️  Fallback : tentative version générique...${NC}"
    apt_install_safe "linux-xanmod" "Kernel XanMod (générique)" || \
    apt_install_safe "linux-xanmod-edge" "Kernel XanMod edge (générique)" || exit 1
fi

# 5. Headers pour drivers GPU (Crucial pour ROG)
echo -e "    ${WHITE}├─ [HEADERS] Installation des en-têtes (prérequis NVIDIA/DKMS)...${NC}"
for variant in "" "-edge"; do
    HDR="linux-headers-xanmod${variant}-${CPU_LEVEL}"
    if apt-cache show "$HDR" &>/dev/null 2>&1; then
        apt_install_safe "$HDR" "Headers XanMod${variant}" && break
    fi
done || apt_install_safe "linux-headers-xanmod-edge" "Headers XanMod (générique)" || true

# 6. Activation & Vérification NTSYNC
# NTSYNC est la clé du gaming en 2026.
echo -e "    ${WHITE}├─ [NTSYNC] Activation de la synchronisation noyau...${NC}"

# Création du fichier de chargement automatique
echo "ntsync" | sudo tee /etc/modules-load.d/ntsync.conf > /dev/null

# Tentative de chargement immédiat
if sudo modprobe ntsync 2>/dev/null; then
    echo -e "    ${GREEN}✅ [NTSYNC] Module chargé avec succès.${NC}"
else
    echo -e "    ${YELLOW}ℹ️  [NTSYNC] Sera actif après le redémarrage (Noyau actuel incompatible).${NC}"
fi

# Vérification du device
if [ -c /dev/ntsync ]; then
    echo -e "    ${CYAN}⚡ /dev/ntsync détecté et opérationnel.${NC}"
fi

# 7. Optimisation GRUB (Isolation CPU / Latence)
echo -e "    ${GRAY}├─ [BOOT] Optimisation des paramètres GRUB...${NC}"
# Ajoute des paramètres de performance si non présents
if ! grep -q "preempt=full" /etc/default/grub; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="preempt=full threadirqs mitigations=off /' /etc/default/grub
    sudo update-grub > /dev/null 2>&1 || true
fi

echo -e "\n${GREEN}✅ PHASE 1 TERMINÉE : Le moteur MadOS v4.0 est prêt.${NC}"
echo -e "${GRAY}Note: Redémarrez uniquement à la fin de l'installation complète.${NC}\n"
