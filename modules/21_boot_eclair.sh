#!/bin/bash
# ==========================================
# MadOS ROG V2.6 - 21_boot_eclair.sh
# ==========================================
# Phase: 21 - Boot Éclair (LZ4 & Silent GRUB)
# ==========================================

CYAN='\033[0;36m'

echo -e "${RED}>>> ${WHITE}[Phase 21] ${BOLD}Extrémisation du Boot (Démarrage Éclair)...${NC}"

# 1. Initramfs LZ4
echo -e "    ${GRAY}├─ Modification de l'algorithme de décompression Kernel vers LZ4 (Le plus rapide)...${NC}"
INITRAMFS_CONF="/etc/initramfs-tools/initramfs.conf"
if [ -f "$INITRAMFS_CONF" ]; then
    sudo sed -i 's/^COMPRESS=.*/COMPRESS=lz4/' "$INITRAMFS_CONF"
fi

# 2. Silent GRUB
echo -e "    ${GRAY}├─ Masquage total des textes BIOS POST sous GRUB pour une esthétique console pure...${NC}"
GRUB_CONF="/etc/default/grub"
if [ -f "$GRUB_CONF" ]; then
    # Masquer le timeout en style Hidden
    sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' "$GRUB_CONF"
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "$GRUB_CONF"
    sudo sed -i '/GRUB_RECORDFAIL_TIMEOUT/d' "$GRUB_CONF"
    echo 'GRUB_RECORDFAIL_TIMEOUT=0' | sudo tee -a "$GRUB_CONF" >/dev/null

    # Paramètres de boot ultra discrets
    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" "$GRUB_CONF"; then
        sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_priority=3 vt.global_cursor_default=0"/' "$GRUB_CONF"
    else
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_priority=3 vt.global_cursor_default=0"' | sudo tee -a "$GRUB_CONF" >/dev/null
    fi
fi

# 3. Application massive
echo -e "    ${GRAY}├─ Reconstruction brutale de l'initramfs et du grub (${CYAN}Ceci prendra 30s...${GRAY})${NC}"
sudo update-initramfs -u -k all >/dev/null 2>&1 || true
sudo update-grub >/dev/null 2>&1 || true

echo -e "    ${CYAN}✅ [SUCCÈS] Boot sublimé. Au redémarrage, la seule chose que vous verrez sera le Splash Plymouth ROG instantané.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 21 Terminée.${NC}"
