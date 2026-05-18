#!/bin/bash
# ==============================================================================
# MadOS 4.0 - VM Test Bench (QEMU/KVM)
# "NTSYNC Edition" - Validation Environment
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# --keep : conserve le disque existant (reprendre une install interrompue)
KEEP_DISK=false
for _arg in "$@"; do [[ "$_arg" == "--keep" ]] && KEEP_DISK=true; done

VM_DIR="$HOME/MadOS_VM_Test"
# Ubuntu 25.04 Desktop (5.8GB) — environnement graphique complet pour tester MadOS
# Ubuntu 25.04 est EOL (janv. 2026) → ISO sur old-releases.ubuntu.com
ISO_URL="https://old-releases.ubuntu.com/releases/25.04/ubuntu-25.04-desktop-amd64.iso"
ISO_PATH="$VM_DIR/ubuntu-25.04-desktop.iso"
DISK_PATH="$VM_DIR/mados_test_disk.qcow2"
DISK_SIZE=40  # Go

echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🖥️  ${WHITE}BANC DE TEST VIRTUEL - MADOS 4.0 NTSYNC EDITION${NC}                ${RED}║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Vérification des prérequis
if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo -e "    ${YELLOW}⚠  QEMU non installé. Installation...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y qemu-system-x86 qemu-utils libvirt-daemon-system virt-manager
fi

if [ ! -w /dev/kvm ]; then
    echo -e "    ${YELLOW}⚠  Droits KVM manquants.${NC}"
    echo -e "    ${GRAY}Correction : sudo usermod -aG kvm $USER  (puis redémarrer la session)${NC}"
fi

# 2. Vérification espace disque disponible
_available_gb=$(df -BG "$HOME" 2>/dev/null | awk 'NR==2{gsub("G",""); print $4}')
if [ -n "$_available_gb" ] && [ "$_available_gb" -lt "$DISK_SIZE" ]; then
    echo -e "    ${RED}✗ Espace insuffisant : ${_available_gb}G disponible, ${DISK_SIZE}G requis.${NC}"
    exit 1
fi

# 3. Vérification RAM disponible (VM demande 8 Go)
_avail_ram_mb=$(awk '/^MemAvailable:/{print int($2/1024)}' /proc/meminfo 2>/dev/null)
if [ -n "$_avail_ram_mb" ] && [ "$_avail_ram_mb" -lt 6144 ]; then
    echo -e "    ${YELLOW}⚠  RAM disponible : ${_avail_ram_mb}Mo — la VM demande 8192Mo, risque de gel système.${NC}"
    read -r -p "    Continuer quand même ? [o/N] " _yn
    [[ "$_yn" =~ ^[oO]$ ]] || exit 1
fi

mkdir -p "$VM_DIR"

# 4. Suppression de l'ancienne VM et recréation propre (sauf --keep)
if [ -f "$DISK_PATH" ]; then
    if $KEEP_DISK; then
        echo -e "    ${CYAN}♻  Mode --keep : disque existant conservé (reprise d'install).${NC}"
    else
        echo -e "    ${YELLOW}🗑  Suppression de l'ancienne VM...${NC}"
        rm -f "$DISK_PATH"
    fi
fi

# 5. Téléchargement de l'ISO Ubuntu 25.04 Server (conservé entre les runs)
if [ ! -f "$ISO_PATH" ]; then
    echo -e "    ${CYAN}📥 Téléchargement de l'ISO Ubuntu 25.04 Desktop (~5.8GB)...${NC}"
    wget -c --timeout=30 --tries=3 "$ISO_URL" -O "$ISO_PATH" || {
        echo -e "    ${RED}✗ Échec du téléchargement de l'ISO.${NC}"
        rm -f "$ISO_PATH"
        exit 1
    }
fi

# 6. Création d'un disque vierge (sauf si --keep et disque existant)
if ! $KEEP_DISK || [ ! -f "$DISK_PATH" ]; then
    echo -e "    ${CYAN}💾 Création d'un nouveau disque virtuel (${DISK_SIZE}G)...${NC}"
    qemu-img create -f qcow2 "$DISK_PATH" "${DISK_SIZE}G" || {
        echo -e "    ${RED}✗ Échec de la création du disque virtuel.${NC}"
        exit 1
    }
fi

# 7. Chemins du projet
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Calcul dynamique des vCPUs (moitié des cœurs physiques, min 2)
_host_cores=$(nproc 2>/dev/null || echo 4)
_vm_cores=$(( _host_cores / 2 ))
[ "$_vm_cores" -lt 2 ] && _vm_cores=2

# 8. Lancement de la VM
# En mode --keep, on retire le CDROM pour éviter que Ubuntu veuille se réinstaller
# au reboot (QEMU garde l'ISO attachée sinon)
if $KEEP_DISK; then
    _CDROM_ARGS=""
    _BOOT_ORDER="order=c"
    echo -e "    ${CYAN}ℹ  Mode --keep : ISO détachée, boot sur disque uniquement.${NC}"
else
    _CDROM_ARGS="-cdrom $ISO_PATH"
    _BOOT_ORDER="order=dc,menu=on"
    echo -e "    ${YELLOW}ℹ  CONSEIL : Appuie sur F12 au démarrage pour sélectionner le périphérique de boot.${NC}"
fi

echo -e "    ${WHITE}├─ [NETWORK] SSH: localhost:2222 | OpenClaw: localhost:18790${NC}"
echo -e "    ${WHITE}├─ [SHARE]   Dossier source monté en tag 'mados_share'${NC}"
echo -e "    ${WHITE}├─ [CPU]     ${_vm_cores} vCPUs alloués (${_host_cores} cœurs détectés sur l'hôte)${NC}"
echo -e "    ${GREEN}🚀 Lancement de la VM MadOS...${NC}\n"

# shellcheck disable=SC2086
qemu-system-x86_64 \
    -enable-kvm \
    -machine q35 \
    -m 8192 \
    -cpu host \
    -smp "$_vm_cores" \
    -drive file="$DISK_PATH",if=virtio,format=qcow2 \
    ${_CDROM_ARGS} \
    -vga virtio \
    -display gtk,gl=on \
    -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::18790-:18789 \
    -device virtio-net-pci,netdev=net0 \
    -virtfs local,path="$PROJECT_ROOT",mount_tag=mados_share,security_model=none,id=mados_share \
    -device intel-hda \
    -device hda-duplex \
    -usb \
    -device usb-tablet \
    -boot "$_BOOT_ORDER"

echo -e "\n${CYAN}💡 SE CONNECTER EN SSH À LA VM :${NC}"
echo -e "   ssh -p 2222 user@localhost"

echo -e "\n${CYAN}💡 POUR ACCÉDER À L'IA DE LA VM DEPUIS TON NAVIGATEUR :${NC}"
echo -e "   URL : http://localhost:18790"

echo -e "\n${CYAN}💡 POUR MONTER LE DOSSIER PARTAGÉ DANS LA VM :${NC}"
echo -e "   sudo mkdir -p /mnt/mados"
echo -e "   sudo mount -t 9p -o trans=virtio,version=9p2000.L mados_share /mnt/mados"
echo -e "   cd /mnt/mados && sudo bash install.sh"

echo -e "\n${CYAN}💡 RELANCER LA VM APRÈS INSTALLATION (sans ISO) :${NC}"
echo -e "   bash tools/test_vm_mados.sh --keep"

echo -e "\n${GREEN}✓ Session VM terminée.${NC}"
