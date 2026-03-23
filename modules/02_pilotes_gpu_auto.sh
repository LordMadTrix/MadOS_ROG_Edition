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
    echo -e "    ${RED}⚠️  [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] 'lspci' introuvable, installation de bases recommandées...${NC}"
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
        # Capture strictly the driver name from lines containing 'recommended' and 'nvidia-driver'
        RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep 'recommended' | grep -o 'nvidia-driver-[0-9]*' | head -n 1)
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
        echo -e "    ${GRAY}✅ [SUCCÈS] Pilotes NVIDIA installés et compilés (DKMS).${NC}"
        
        # Forcer le Modeset pour Wayland (KDE Plasma 6 exige Modeset)
        echo -e "    ${GRAY}├─ Activation de NVIDIA DRM Modeset pour interface Wayland...${NC}"
        echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-modeset.conf >/dev/null
        sudo update-initramfs -u >/dev/null 2>&1 || true
    else
        echo -e "    ${RED}❌ [ERREUR] ALERTE: Échec sur l'installation du pilote $RECOMMENDED_DRIVER${NC}"
    fi

elif echo "$GPU_INFO" | grep -iq "amd\|radeon"; then
    echo -e "\n    ${WHITE}├─ [AMD] Architecture Radeon détectée. Engage des bibliothèques Mesa/Vulkan...${NC}"
    sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 libvulkan1 libvulkan1:i386 vulkan-tools xserver-xorg-video-amdgpu
    echo -e "    ${GRAY}✅ [SUCCÈS] Noyau AMDGPU / RADV configuré.${NC}"

elif echo "$GPU_INFO" | grep -iq "intel"; then
    echo -e "\n    ${WHITE}├─ [INTEL] Architecture Intel ARC / Iris détectée...${NC}"
    sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 intel-media-va-driver-non-free vulkan-tools
    echo -e "    ${GRAY}✅ [SUCCÈS] Pilotes Intel HD/ARC configurés.${NC}"
else
    echo -e "\n    ${RED}⚠️  [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] Puce non reconnue. Application des moteurs graphiques génériques.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 2 Terminée.${NC}"
