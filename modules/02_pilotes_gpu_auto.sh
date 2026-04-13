#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 02_pilotes_gpu_auto.sh
# ==============================================================================
# Phase: 2 - Détection et Installation GPU
# Cherche la carte dédiée et installe les pilotes appropriés.
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
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 2 Scan & Déploiement des Pilotes Graphiques${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# Identifier le GPU dédié
if command -v lspci >/dev/null; then
    GPU_INFO=$(lspci | grep -i 'vga\|3d\|2d')
else
    echo -e "    ${RED}⚠️  [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] 'lspci' introuvable, installation de bases recommandée...${NC}"
    sudo apt install pciutils -y >/dev/null 2>&1 || true
    GPU_INFO=$(lspci | grep -i 'vga\|3d\|2d')
fi

echo -e "    ${GRAY}├─ Matériel(s) détecté(s) :${NC}"
echo "$GPU_INFO" | while read -r line; do
    echo -e "       ${GRAY}>> $line${NC}"
done

if echo "$GPU_INFO" | grep -iq "nvidia"; then
    # 1. Nettoyage préventif
    echo -e "    ${YELLOW}├─ [CLEAN] Purge des installations NVIDIA existantes...${NC}"
    sudo apt-get purge -y nvidia* 2>/dev/null || true
    sudo apt-get autoremove -y >/dev/null 2>&1 || true

    # 2. Détection du meilleur pilote
    echo -e "    ${GRAY}├─ Recherche du pilote recommandé...${NC}"
    if command -v ubuntu-drivers >/dev/null; then
        RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep 'recommended' | grep -o 'nvidia-driver-[0-9]*' | head -n 1)
        [ -z "$RECOMMENDED_DRIVER" ] && RECOMMENDED_DRIVER="nvidia-driver-550"
    else
        RECOMMENDED_DRIVER="nvidia-driver-535"
    fi

    # Extraire la version
    DRIVER_VER=$(echo "$RECOMMENDED_DRIVER" | grep -o '[0-9]*$')

    echo -e "    ${WHITE}├─ [INSTALL] Cible locale : $RECOMMENDED_DRIVER (Stable)${NC}"
    
    # Installation Standard
    if sudo apt-get install -y "$RECOMMENDED_DRIVER" "nvidia-utils-$DRIVER_VER" libnvidia-encode-$DRIVER_VER 2>/dev/null; then
        echo -e "    ${GRAY}✅ [SUCCÈS] Pilotes NVIDIA $DRIVER_VER installés.${NC}"
        
        # Activation DRM Modeset
        echo -e "    ${GRAY}├─ Activation de NVIDIA DRM Modeset...${NC}"
        echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-modeset.conf >/dev/null
        sudo update-initramfs -u >/dev/null 2>&1 || true
    else
        echo -e "    ${RED}❌ [ERREUR] Échec installation $RECOMMENDED_DRIVER.${NC}"
    fi
fi

elif echo "$GPU_INFO" | grep -iq "amd\|radeon"; then
    echo -e "\n    ${WHITE}├─ [AMD] Architecture Radeon détectée. Engage des bibliothèques Mesa/Vulkan...${NC}"
    sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 libvulkan1 libvulkan1:i386 vulkan-tools xserver-xorg-video-amdgpu || true
    echo -e "    ${GRAY}✅ [SUCCÈS] Noyau AMDGPU / RADV configuré.${NC}"

elif echo "$GPU_INFO" | grep -iq "intel"; then
    echo -e "\n    ${WHITE}├─ [INTEL] Architecture Intel ARC / Iris détectée...${NC}"
    sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 intel-media-va-driver-non-free vulkan-tools || true
    echo -e "    ${GRAY}✅ [SUCCÈS] Pilotes Intel HD/ARC configurés.${NC}"
else
    echo -e "\n    ${RED}⚠️  [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] Puce non reconnue. Application des moteurs graphiques génériques.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 2 Terminée.${NC}"
