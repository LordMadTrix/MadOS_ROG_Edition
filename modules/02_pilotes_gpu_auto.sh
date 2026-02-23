#!/bin/bash
# ==========================================
# MadOS ROG V2 - 02_pilotes_gpu_auto.sh
# ==========================================
# Phase: 2 - Détection et Installation GPU
# Cherche la carte dédiée et installe les pilotes appropriés.
# ==========================================

set -u
export DEBIAN_FRONTEND=noninteractive

# ---- Couleurs & Styles ----
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}>>> ${WHITE}[Phase 2] ${BOLD}Scan & Déploiement des Pilotes Graphiques...${NC}"

# Identifier le GPU dédié
if command -v lspci >/dev/null; then
    GPU_INFO=$(lspci | grep -i 'vga\|3d\|2d')
else
    echo -e "    ${RED}⚠️  'lspci' introuvable, installation de bases recommandées...${NC}"
    sudo apt install pciutils -y >/dev/null 2>&1
    GPU_INFO=$(lspci | grep -i 'vga\|3d\|2d')
fi

echo -e "    ${GRAY}├─ Matériel(s) détecté(s) :${NC}"
echo "$GPU_INFO" | while read -r line; do
    echo -e "       ${GRAY}>> $line${NC}"
done

if echo "$GPU_INFO" | grep -iq "nvidia"; then
    echo -e "\n    ${WHITE}├─ [NVIDIA] Puce dédiée détectée. Engage du protocole Propriétaire DKMS...${NC}"
    
    # Ajout du PPA officiel NVIDIA pour les pilotes très récents
    if ! ls /etc/apt/sources.list.d/graphics-drivers-ubuntu-ppa-*.list &>/dev/null; then
        sudo add-apt-repository ppa:graphics-drivers/ppa -y --no-update >/dev/null 2>&1
        sudo apt update -q
    fi

    # Trouver le pilote recommandé via ubuntu-drivers
    echo -e "    ${GRAY}├─ Recherche du dernier profil stable...${NC}"
    if command -v ubuntu-drivers >/dev/null; then
        RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep recommended | awk '{print $3}')
        if [ -z "$RECOMMENDED_DRIVER" ]; then
            # Fallback for recent ROG models
            RECOMMENDED_DRIVER="nvidia-driver-550"
        fi
    else
        RECOMMENDED_DRIVER="nvidia-driver-550"
    fi

    echo -e "    ${WHITE}├─ [INSTALL] Cible acquise : $RECOMMENDED_DRIVER${NC}"
    # dkms est crucial pour s'assurer que le driver compile bien sur Xanmod
    if sudo apt install -y "$RECOMMENDED_DRIVER" dkms nvidia-utils-550 2>/dev/null || sudo apt install -y "$RECOMMENDED_DRIVER" dkms; then
        echo -e "    ${GRAY}✅ Pilotes NVIDIA installés et compilés (DKMS).${NC}"
        
        # Forcer le Modeset pour Wayland (KDE Plasma 6 exige Modeset)
        echo -e "    ${GRAY}├─ Activation de NVIDIA DRM Modeset pour interface Wayland...${NC}"
        echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-modeset.conf >/dev/null
        sudo update-initramfs -u >/dev/null 2>&1 || true
    else
        echo -e "    ${RED}❌ ALERTE: Échec sur l'installation du pilote $RECOMMENDED_DRIVER${NC}"
    fi

elif echo "$GPU_INFO" | grep -iq "amd\|radeon"; then
    echo -e "\n    ${WHITE}├─ [AMD] Architecture Radeon détectée. Engage des bibliothèques Mesa/Vulkan...${NC}"
    sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 libvulkan1 libvulkan1:i386 vulkan-tools xserver-xorg-video-amdgpu
    echo -e "    ${GRAY}✅ Noyau AMDGPU / RADV configuré.${NC}"

elif echo "$GPU_INFO" | grep -iq "intel"; then
    echo -e "\n    ${WHITE}├─ [INTEL] Architecture Intel ARC / Iris détectée...${NC}"
    sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 intel-media-va-driver-non-free vulkan-tools
    echo -e "    ${GRAY}✅ Pilotes Intel HD/ARC configurés.${NC}"
else
    echo -e "\n    ${RED}⚠️  Puce non reconnue. Application des moteurs graphiques génériques.${NC}"
fi

echo -e "    ${WHITE}✅ Phase 2 Terminée.${NC}"
