#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 02_pilotes_gpu_auto.sh
# ==============================================================================
# Phase: 2 - Détection et Installation GPU (Optimisé 2026)
# Priorise les drivers NVIDIA Open-Kernel et Mesa 26.x.
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

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}Phase 2 : Scan & Déploiement des Pilotes Graphiques v4.0${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Identifier le matériel
GPU_INFO=$(lspci | grep -i 'vga\|3d\|2d')
echo -e "    ${WHITE}├─ [SCAN] Matériel(s) détecté(s) :${NC}"
echo "$GPU_INFO" | while read -r line; do echo -e "       ${GRAY}>> $line${NC}"; done

# 2. Cas NVIDIA
if echo "$GPU_INFO" | grep -iq "nvidia"; then
    echo -e "    ${WHITE}├─ [NVIDIA] GPU GeForce identifié. Préparation de l'installation...${NC}"
    
    # Nettoyage
    sudo apt-get purge -y nvidia* 2>/dev/null || true
    
    # Choix du pilote (Priorité 565+ Open)
    echo -e "    ${GRAY}├─ Recherche du pilote recommandé (Open-Kernel)...${NC}"
    RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep 'recommended' | grep -o 'nvidia-driver-[0-9]*' | head -n 1)
    
    # Force 565 sur 25.04 si non trouvé
    if [ -z "$RECOMMENDED_DRIVER" ] || [[ "$RECOMMENDED_DRIVER" < "nvidia-driver-565" ]]; then
        RECOMMENDED_DRIVER="nvidia-driver-565-open"
    fi

    echo -e "    ${WHITE}├─ [INSTALL] Cible : ${CYAN}$RECOMMENDED_DRIVER${NC}"
    
    # Installation (inclut modules open si disponibles)
    sudo apt install -y "$RECOMMENDED_DRIVER" nvidia-settings "nvidia-utils-$(echo "$RECOMMENDED_DRIVER" | grep -o '[0-9]*' | head -n 1)" 2>/dev/null || \
        sudo apt install -y "$RECOMMENDED_DRIVER" 2>/dev/null || true
    
    # Activation Wayland & DRM
    echo -e "    ${GRAY}├─ [CONF] Optimisation NVIDIA DRM (Wayland Ready)...${NC}"
    sudo tee /etc/modprobe.d/nvidia-mados.conf > /dev/null <<EOF
options nvidia-drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var/tmp
EOF
    sudo update-initramfs -u > /dev/null 2>&1 || true

# 3. Cas AMD
elif echo "$GPU_INFO" | grep -iq "amd\|radeon"; then
    echo -e "    ${WHITE}├─ [AMD] Architecture Radeon détectée. Optimisation Mesa 26+...${NC}"
    
    # Ajout du PPA Kisantia pour les derniers Mesa si sur LTS, sinon natif sur 25.04
    if [[ $(lsb_release -rs) == "24.04" ]]; then
        sudo add-apt-repository ppa:kisak/kisak-mesa -y
    fi
    
    sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 libvulkan1 libvulkan1:i386 vulkan-tools xserver-xorg-video-amdgpu 2>/dev/null || true
    echo -e "    ${GREEN}✅ [AMD] Pilotes RADV/Vulkan configurés.${NC}"

# 4. Cas INTEL
elif echo "$GPU_INFO" | grep -iq "intel"; then
    echo -e "    ${WHITE}├─ [INTEL] Architecture Intel ARC / Iris détectée...${NC}"
    sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 intel-media-va-driver-non-free vulkan-tools 2>/dev/null || true
    echo -e "    ${GREEN}✅ [INTEL] Pilotes ANV configurés.${NC}"
fi

# 5. Outils de monitoring
echo -e "    ${GRAY}├─ [MONITORING] Installation de GVTU / NVTOP...${NC}"
sudo apt install -y nvtop >/dev/null 2>&1 || true

echo -e "\n${GREEN}✅ PHASE 2 TERMINÉE : Graphismes optimisés.${NC}\n"
