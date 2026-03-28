#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 05_build_autoinstall_iso.sh
# ==============================================================================
# Génère une ISO MadOS "Zéro-Contact" en injectant les scripts
# de post-installation directement dans l'ISO officielle Ubuntu.
# ==============================================================================

set -euo pipefail

# ---- Configuration ----
ISO_VERSION="25.10"
ISO_URL="https://releases.ubuntu.com/${ISO_VERSION}/ubuntu-${ISO_VERSION}-live-server-amd64.iso"
SOURCE_ISO="/tmp/ubuntu-original.iso"
CUSTOM_ISO="/home/${USER}/MadOS_3.5_ROG_Edition.iso"
WORK_DIR="/tmp/mados_iso_work"

# ---- Couleurs ----
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${RED}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${RED}${BOLD}║${NC}   💿 ${WHITE}${BOLD}MADOS 3.5 — AUTOINSTALL ISO BUILDER${NC}       ${RED}${BOLD}║${NC}"
echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════╝${NC}\n"

# 1. Verification des dependances
for cmd in xorriso 7z wget; do
    if ! command -v "$cmd" >/dev/null; then
        echo -e "    ${RED}❌ Erreur: L'outil '$cmd' est requis.${NC}"
        sudo apt update && sudo apt install -y xorriso p7zip-full wget
    fi
done

# 2. Telechargement de l'ISO Originale
if [ ! -f "$SOURCE_ISO" ]; then
    echo -e "    ${WHITE}├─ [DOWNLOAD] Recuperation d'Ubuntu $ISO_VERSION...${NC}"
    wget -q --show-progress "$ISO_URL" -O "$SOURCE_ISO"
fi

# 3. Preparation de l'environnement
echo -e "    ${WHITE}├─ [MOUNT] Extraction des fichiers sources...${NC}"
rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"
7z x "$SOURCE_ISO" -o"$WORK_DIR" >/dev/null 2>&1

# 4. Injection du bundle MadOS
echo -e "    ${WHITE}├─ [INJECTION] Copie des scripts MadOS dans l'ISO...${NC}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$WORK_DIR/nocloud"
cp -r "$PROJECT_ROOT" "$WORK_DIR/nocloud/mados_bundle"

# 5. Creation du fichier user-data (Autoinstall)
echo -e "    ${WHITE}├─ [CONFIG] Generation de la recette 'Zéro-Contact'...${NC}"
cat <<'EOF' > "$WORK_DIR/nocloud/user-data"
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: mados-rog
    username: mados
    password: "$6$MadOS$9l4nZ6hVzF6v7yLp1" # Password: mados
    realname: MadOS User
  locale: fr_FR.UTF-8
  keyboard: {layout: fr, variant: oss}
  network:
    network:
      version: 2
      ethernets:
        all-en:
          match: {name: "en*"}
          dhcp4: true
  storage:
    layout: {name: direct}
  user-data:
    late-commands:
      - curtin in-target -- bash -c "mkdir -p /opt/mados-rog && cp -r /mnt/nocloud/mados_bundle/* /opt/mados-rog/"
      - curtin in-target -- bash -c "cd /opt/mados-rog && sudo bash MASTER_INSTALL.sh"
EOF
touch "$WORK_DIR/nocloud/meta-data"

# 6. Re-generation de l'ISO bootable
echo -e "    ${WHITE}├─ [MASTER] Re-generation de l'ISO via xorriso...${NC}"
cd "$WORK_DIR"
xorriso -as mkisofs -r -V "MadOS_3.5_ROG" \
  -J -b boot/grub/i386-pc/eltorito.img \
  -c boot.catalog -el-torito-noconv \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  --grub2-boot-info --grub2-mbr "$SOURCE_ISO" \
  -eltorito-alt-boot -e boot/grub/efi.img \
  -no-emul-boot -o "$CUSTOM_ISO" . >/dev/null 2>&1

echo -e "\n${RED}╭──────────────────────────────────────────────────────────────╮${NC}"
echo -e "${RED}│${NC} ✅ ${WHITE}${BOLD}L'ISO AUTO-PILOT EST PRÊTE !${NC}                             ${RED}│${NC}"
echo -e "${RED}│${NC} 🚀 ${GRAY}Chemin : $CUSTOM_ISO${NC}                     ${RED}│${NC}"
echo -e "${RED}│${NC} 🚀 ${GRAY}Note   : Brûlez-la via Rufus ou BalenaEtcher.${NC}        ${RED}│${NC}"
echo -e "${RED}╰──────────────────────────────────────────────────────────────╯${NC}\n"
