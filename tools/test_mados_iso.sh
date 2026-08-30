#!/bin/bash
# ==============================================================================
# MadOS 4.0 - Test de l'ISO personnalisée sous QEMU
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

ISO_PATH="MadOS_ROG_Edition_v4.iso"

if [ ! -f "$ISO_PATH" ]; then
    echo -e "${RED}✗ L'ISO $ISO_PATH n'existe pas. Veuillez lancer 'tools/build_mados_live_iso.sh' d'abord.${NC}"
    exit 1
fi

# Détection dynamique de l'accélération matérielle KVM
QEMU_ARGS=""
if [ -w /dev/kvm ]; then
    echo -e "${CYAN}ℹ Accélération matérielle KVM activée.${NC}"
    QEMU_ARGS="-enable-kvm -cpu host"
else
    echo -e "${YELLOW}⚠ Droits KVM manquants sur /dev/kvm. Utilisation de l'émulation logicielle (plus lente)...${NC}"
    QEMU_ARGS="-cpu qemu64"
fi

echo -e "${GREEN}🚀 Lancement de MadOS ROG Edition (ISO) sous QEMU...${NC}"
# shellcheck disable=SC2086
qemu-system-x86_64 \
    $QEMU_ARGS \
    -m 4096 \
    -smp 2 \
    -cdrom "$ISO_PATH" \
    -vga std \
    -display gtk \
    -device intel-hda \
    -device hda-duplex \
    -usb \
    -device usb-tablet
