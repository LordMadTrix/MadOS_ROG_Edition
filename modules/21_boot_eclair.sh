#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 21_boot_eclair.sh
# ==============================================================================
# Phase: 21 - Boot Éclair (LZ4 & Silent GRUB)
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 21 : Extrémisation du Boot v4.0 (Démarrage Éclair)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Initramfs ZSTD (Modern & Safe)
echo -e "    ${GRAY}├─ Injection de l'outil de compression ZSTD (Standard Moderne)...${NC}"
sudo apt-get install -y zstd -qq >/dev/null 2>&1 || true

echo -e "    ${GRAY}├─ Optimisation du moteur Initramfs vers ZSTD (Équilibre Vitesse/Fiabilité)...${NC}"
INITRAMFS_CONF="/etc/initramfs-tools/initramfs.conf"
# 3. Mode Secours MadOS dans GRUB (entrée dynamique)
echo -e "    ${WHITE}├─ [RESCUE] Création de l'entrée de Secours ROG dans GRUB...${NC}"
ROOT_UUID=$(findmnt -n -o UUID / 2>/dev/null || blkid -s UUID -o value "$(df / | awk 'NR==2{print $1}')" 2>/dev/null)
XANMOD_VMLINUZ=$(ls /boot/vmlinuz-*xanmod* 2>/dev/null | sort -V | tail -n1)
XANMOD_INITRD=$(ls /boot/initrd.img-*xanmod* 2>/dev/null | sort -V | tail -n1)
if [ -n "$XANMOD_VMLINUZ" ] && [ -n "$ROOT_UUID" ]; then
    cat <<RESCUE_EOF | sudo tee /etc/grub.d/40_custom > /dev/null
#!/bin/sh
exec tail -n +3 \$0
menuentry 'MadOS ROG Edition - Mode Secours' --class red --class mados {
    search --no-floppy --fs-uuid --set=root $ROOT_UUID
    linux   $XANMOD_VMLINUZ root=UUID=$ROOT_UUID ro single mados_rescue=1 quiet
    initrd  $XANMOD_INITRD
}
RESCUE_EOF
    sudo chmod +x /etc/grub.d/40_custom || true
else
    echo -e "    ${YELLOW}⚠️  Kernel XanMod non encore installé — entrée GRUB rescue ignorée.${NC}"
fi

# 4. Activation du Timeout et Masquage partiel
echo -e "    ${WHITE}├─ [CONFIG] Optimisation du Timeout et Thème boot...${NC}"
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub || true
sudo update-grub 2>/dev/null || true
if [ -f "$INITRAMFS_CONF" ]; then
    sudo sed -i 's/^COMPRESS=.*/COMPRESS=zstd/' "$INITRAMFS_CONF" || true
fi

# 2. Silent GRUB
echo -e "    ${GRAY}├─ Masquage total des textes BIOS POST sous GRUB pour une esthétique console pure...${NC}"
GRUB_CONF="/etc/default/grub"
if [ -f "$GRUB_CONF" ]; then
    # Masquer le timeout en style Hidden mais garder 2 secondes de survie
    sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' "$GRUB_CONF" || true
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' "$GRUB_CONF" || true
    sudo sed -i '/GRUB_RECORDFAIL_TIMEOUT/d' "$GRUB_CONF" || true
    echo 'GRUB_RECORDFAIL_TIMEOUT=2' | sudo tee -a "$GRUB_CONF" >/dev/null || true

    # Paramètres de boot ultra discrets
    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" "$GRUB_CONF"; then
        sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_priority=3 vt.global_cursor_default=0"/' "$GRUB_CONF"
    else
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_priority=3 vt.global_cursor_default=0"' | sudo tee -a "$GRUB_CONF" >/dev/null
    fi
fi

# 3. Application massive avec protection LVM
echo -e "    ${GRAY}├─ Reconstruction brutale de l'initramfs et du grub (${CYAN}Ceci prendra 30s...${GRAY})${NC}"
if ! sudo update-initramfs -u -k all >/tmp/initramfs_update.log 2>&1; then
    echo -e "    ${RED}⚠ Échec du ZSTD. Tentative de repli vers GZIP (Standard)...${NC}"
    sudo sed -i 's/^COMPRESS=zstd/COMPRESS=gzip/' "$INITRAMFS_CONF" || true
    sudo update-initramfs -u -k all >/dev/null 2>&1 || true
fi
sudo update-grub >/dev/null 2>&1 || true

echo -e "    ${CYAN}✅ [SUCCÈS] Boot sublimé. Au redémarrage, la seule chose que vous verrez sera le Splash Plymouth ROG instantané.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 21 Terminée.${NC}"
