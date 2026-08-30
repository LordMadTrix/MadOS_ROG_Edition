#!/bin/bash
# ==============================================================================
# MadOS ROG Edition v4 - Test ISO via QEMU + VNC
# Accessible depuis Windows avec TightVNC/RealVNC/Windows VNC Viewer sur :5900
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

ISO_PATH="/mnt/d/DEV/MadOS_ROG_Edition/MadOS_ROG_Edition_v4.iso"
VNC_PORT=5900
VNC_DISPLAY=0

# 1. Vérification de l'ISO
if [ ! -f "$ISO_PATH" ]; then
    echo -e "${RED}✗ ISO introuvable : $ISO_PATH${NC}"
    exit 1
fi
ISO_SIZE=$(du -sh "$ISO_PATH" | cut -f1)
echo -e "${GREEN}✓ ISO trouvée : $ISO_PATH (${ISO_SIZE})${NC}"

# 2. Installation de QEMU si nécessaire
if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo -e "${CYAN}📦 Installation de QEMU...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y qemu-system-x86 qemu-utils -qq
fi

# 3. Détection KVM
QEMU_ACCEL=""
if [ -w /dev/kvm ]; then
    echo -e "${GREEN}✓ Accélération KVM disponible.${NC}"
    QEMU_ACCEL="-enable-kvm -cpu host"
else
    echo -e "${YELLOW}⚠ KVM non disponible — émulation logicielle (plus lent).${NC}"
    QEMU_ACCEL="-cpu qemu64"
fi

# 4. Tuer une instance QEMU précédente sur ce port
if pgrep -f "qemu.*vnc.*:${VNC_DISPLAY}" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Instance QEMU précédente détectée — arrêt...${NC}"
    pkill -f "qemu.*vnc.*:${VNC_DISPLAY}" || true
    sleep 2
fi

echo ""
echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  🚀 ${GREEN}DÉMARRAGE MADOS ROG EDITION v4${NC}                             ${RED}║${NC}"
echo -e "${RED}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${RED}║${NC}  Kernel   : XanMod 7.0.10-x64v3-xanmod1                         ${RED}║${NC}"
echo -e "${RED}║${NC}  Wayland  : Labwc compositor                                     ${RED}║${NC}"
echo -e "${RED}║${NC}  Desktop  : LXQt Panel (Razor-Qt)                                ${RED}║${NC}"
echo -e "${RED}║${NC}  RAM VM   : 4096 MB  │  CPU : 2 vCPUs                           ${RED}║${NC}"
echo -e "${RED}║${NC}  Affichage: VNC → localhost:5900                                 ${RED}║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📺 Connecte-toi avec un client VNC Windows sur :  localhost:5900${NC}"
echo -e "${CYAN}   (ex: TightVNC Viewer, RealVNC, ou Windows 11 VNC natif)${NC}"
echo ""
echo -e "${YELLOW}⏳ Démarrage de la VM en arrière-plan... (Ctrl+C pour arrêter)${NC}"
echo ""

# 5. Lancement QEMU en mode VNC (accessible Windows localhost:5900)
qemu-system-x86_64 \
    $QEMU_ACCEL \
    -m 4096 \
    -smp 2 \
    -cdrom "$ISO_PATH" \
    -vga virtio \
    -display vnc=0.0.0.0:${VNC_DISPLAY} \
    -device intel-hda \
    -device hda-duplex \
    -usb \
    -device usb-tablet \
    -boot d \
    -no-reboot

echo -e "\n${GREEN}✓ VM arrêtée.${NC}"
