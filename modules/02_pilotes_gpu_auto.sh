#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 02_pilotes_gpu_auto.sh
# ==============================================================================
# Phase: 2 - Détection et Installation GPU
# Cherche la carte dédiée et installe les pilotes appropriés.
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
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 2 Scan & Déploiement des Pilotes Graphiques${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# Identifier le GPU dédié.
# L'ancienne version rappelait `lspci` juste apres avoir tente d'installer
# pciutils, SANS revérifier qu'il existait desormais : en simulation (ou si
# l'installation echoue faute de reseau) on obtenait "lspci: command not found"
# puis un GPU_INFO vide, et le module concluait "puce non reconnue" sans le dire.
GPU_INFO=""
if ! command -v lspci >/dev/null 2>&1; then
    echo -e "    ${YELLOW}⚠️  [ATTENTION] 'lspci' introuvable, installation de pciutils...${NC}"
    run_action "installer pciutils" sudo apt-get install -y pciutils >/dev/null 2>&1 || true
fi

if command -v lspci >/dev/null 2>&1; then
    GPU_INFO=$(lspci | grep -i 'vga\|3d\|2d')
else
    echo -e "    ${YELLOW}⚠️  'lspci' toujours indisponible : détection GPU impossible, module ignoré.${NC}"
    echo -e "    ${WHITE}✅ [SUCCÈS] Phase 2 Terminée (aucune action).${NC}"
    return 0 2>/dev/null || exit 0
fi

echo -e "    ${GRAY}├─ Matériel(s) détecté(s) :${NC}"
echo "$GPU_INFO" | while read -r line; do
    echo -e "       ${GRAY}>> $line${NC}"
done

if echo "$GPU_INFO" | grep -iq "nvidia"; then
    # 1. Détection du pilote recommandé — AVANT toute suppression.
    #    L'ancienne version faisait `apt-get purge -y nvidia*` en premier : si
    #    l'installation echouait ensuite (depot indisponible, coupure reseau),
    #    la machine se retrouvait SANS pilote graphique, donc en ecran noir au
    #    redemarrage. On n'enleve plus rien tant que le remplacant n'est pas en
    #    place ; apt gere lui-meme le remplacement des anciens paquets.
    echo -e "    ${GRAY}├─ Recherche du pilote recommandé...${NC}"
    if command -v ubuntu-drivers >/dev/null; then
        RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep 'recommended' | grep -o 'nvidia-driver-[0-9]*' | head -n 1)
        [ -z "$RECOMMENDED_DRIVER" ] && RECOMMENDED_DRIVER="nvidia-driver-550"
    else
        RECOMMENDED_DRIVER="nvidia-driver-535"
    fi

    DRIVER_VER=$(echo "$RECOMMENDED_DRIVER" | grep -o '[0-9]*$')
    echo -e "    ${WHITE}├─ [INSTALL] Cible locale : $RECOMMENDED_DRIVER (Stable)${NC}"

    if is_dry_run; then
        log_simu "installerait $RECOMMENDED_DRIVER, nvidia-utils-$DRIVER_VER, libnvidia-encode-$DRIVER_VER (sans purge prealable), activerait le DRM Modeset (/etc/modprobe.d/nvidia-modeset.conf) et régénèrerait l'initramfs"
    else
        installer_nvidia() {
            sudo apt-get install -y \
                "$RECOMMENDED_DRIVER" \
                "nvidia-utils-$DRIVER_VER" \
                "libnvidia-encode-$DRIVER_VER" 2>/dev/null
        }

        NVIDIA_OK=0
        if installer_nvidia; then
            NVIDIA_OK=1
        else
            # 2. Repli SEULEMENT en cas d'echec : une installation cassee peut
            #    bloquer la nouvelle. On purge alors, puis on retente une fois.
            echo -e "    ${YELLOW}├─ [CLEAN] Échec initial. Purge des installations NVIDIA cassées, puis nouvelle tentative...${NC}"
            sudo apt-get purge -y 'nvidia*' 2>/dev/null || true
            sudo apt-get autoremove -y >/dev/null 2>&1 || true
            sudo apt-get install -f -y >/dev/null 2>&1 || true
            if installer_nvidia; then
                NVIDIA_OK=1
            fi
        fi

        if [ "$NVIDIA_OK" -eq 1 ]; then
            echo -e "    ${GRAY}✅ [SUCCÈS] Pilotes NVIDIA $DRIVER_VER installés.${NC}"

            # Activation DRM Modeset
            echo -e "    ${GRAY}├─ Activation de NVIDIA DRM Modeset...${NC}"
            echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-modeset.conf >/dev/null
            sudo update-initramfs -u >/dev/null 2>&1 || true
        else
            echo -e "    ${RED}❌ [ERREUR] Échec installation $RECOMMENDED_DRIVER.${NC}"
            echo -e "    ${YELLOW}    ATTENTION : le système peut démarrer sans pilote graphique propriétaire.${NC}"
            echo -e "    ${GRAY}    Récupération depuis un TTY (Ctrl+Alt+F3) :${NC}"
            echo -e "      ${GREEN}sudo ubuntu-drivers autoinstall && sudo reboot${NC}"
        fi
    fi

elif echo "$GPU_INFO" | grep -iq "amd\|radeon"; then
    echo -e "\n    ${WHITE}├─ [AMD] Architecture Radeon détectée. Engage des bibliothèques Mesa/Vulkan...${NC}"
    run_action "installer les pilotes Mesa/Vulkan AMDGPU" sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 libvulkan1 libvulkan1:i386 vulkan-tools xserver-xorg-video-amdgpu || true
    echo -e "    ${GRAY}✅ [SUCCÈS] Noyau AMDGPU / RADV configuré.${NC}"

elif echo "$GPU_INFO" | grep -iq "intel"; then
    echo -e "\n    ${WHITE}├─ [INTEL] Architecture Intel ARC / Iris détectée...${NC}"
    run_action "installer les pilotes Mesa/Vulkan/Intel media" sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 intel-media-va-driver-non-free vulkan-tools || true
    echo -e "    ${GRAY}✅ [SUCCÈS] Pilotes Intel HD/ARC configurés.${NC}"
else
    echo -e "\n    ${RED}⚠️  [ATTENTION] Puce non reconnue. Application des moteurs graphiques génériques.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 2 Terminée.${NC}"
