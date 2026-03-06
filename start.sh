#!/bin/bash
# ==============================================================================
# MadOS ROG Edition — Lanceur Clé USB (Ubuntu Server)
# start.sh
# ==============================================================================
# À utiliser sur Ubuntu Server après avoir inséré la clé USB "MADOS" :
#   bash /media/$USER/MADOS/start.sh
#
# Sur Windows : utilisez create_mados_usb.bat pour préparer la clé.
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
NC='\033[0m'

clear
echo ""
echo -e "${RED}  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗ ${NC}"
echo -e "${RED}  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝ ${NC}"
echo -e "${RED}  ██╔████╔██║███████║██║  ██║██║   ██║███████╗ ${NC}"
echo -e "${WHITE}  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║ ${NC}"
echo -e "${WHITE}  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║ ${NC}"
echo -e "${WHITE}  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝ ${NC}"
echo ""
echo -e "${RED}     ╔═══════════════════════════════════╗${NC}"
echo -e "${RED}     ║   🔴 MADOS USB LAUNCHER v3.2 🔴   ║${NC}"
echo -e "${RED}     ║        by LordMadTrix             ║${NC}"
echo -e "${RED}     ╚═══════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# Vérification : Linux / Ubuntu uniquement
# ==============================================================================
if ! command -v apt-get &>/dev/null; then
    echo -e "${RED}  [ERREUR] Ce script est réservé à Ubuntu/Debian Linux.${NC}"
    echo -e "${GRAY}  Sur Windows, utilisez : create_mados_usb.bat${NC}"
    exit 1
fi

# ==============================================================================
# Localisation de la clé USB MADOS
# ==============================================================================
USB_MOUNT=""
MOUNTED_BY_SCRIPT=false

# Méthode 1 : Chemin où start.sh est lui-même (racine de la clé)
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SELF_DIR/install_local.sh" ]; then
    USB_MOUNT="$SELF_DIR"
fi

# Méthode 2 : Chemins de montage automatiques standard
if [ -z "$USB_MOUNT" ]; then
    for MNTPOINT in /media/*/MADOS /media/root/MADOS /mnt/MADOS /run/media/*/MADOS; do
        if [ -d "$MNTPOINT" ] && [ -f "$MNTPOINT/install_local.sh" ]; then
            USB_MOUNT="$MNTPOINT"
            break
        fi
    done
fi

# Méthode 3 : Détection via label blkid
if [ -z "$USB_MOUNT" ]; then
    USB_DEV=$(blkid -L MADOS 2>/dev/null)
    if [ -n "$USB_DEV" ]; then
        echo -e "${YELLOW}  [USB] Clé MADOS sur $USB_DEV, montage...${NC}"
        USB_MOUNT="/mnt/mados_usb"
        sudo mkdir -p "$USB_MOUNT"
        if sudo mount "$USB_DEV" "$USB_MOUNT" 2>/dev/null; then
            echo -e "${GREEN}  [USB] Montée sur $USB_MOUNT${NC}"
            MOUNTED_BY_SCRIPT=true
        else
            USB_MOUNT=""
        fi
    fi
fi

# Méthode 4 : Saisie manuelle
if [ -z "$USB_MOUNT" ]; then
    echo -e "${YELLOW}  [USB] Clé MADOS non détectée automatiquement.${NC}"
    echo ""
    lsblk -o NAME,SIZE,LABEL,MOUNTPOINT 2>/dev/null | grep -v "^loop" || true
    echo ""
    echo -e "${CYAN}  Point de montage (ex: /media/user/MADOS) :${NC}"
    read -r USB_MOUNT
    if [ ! -f "$USB_MOUNT/install_local.sh" ]; then
        echo -e "${RED}  [ERREUR] install_local.sh introuvable dans $USB_MOUNT${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}  ✓ Clé USB MADOS : $USB_MOUNT${NC}"
echo ""

# ==============================================================================
# Chargement des modules en /tmp et lancement
# ==============================================================================

# Installation de whiptail si absent
if ! command -v whiptail &>/dev/null; then
    echo -e "${YELLOW}  [INFO] Installation de whiptail...${NC}"
    sudo apt-get install -y whiptail > /dev/null 2>&1
fi

BOOTSTRAP_DIR="/tmp/mados_install_bootstrap"
sudo rm -rf "$BOOTSTRAP_DIR" 2>/dev/null
sudo mkdir -p "$BOOTSTRAP_DIR/modules"

echo -e "${CYAN}  Chargement des modules depuis la clé USB...${NC}"
sudo cp "$USB_MOUNT/install_local.sh" "$BOOTSTRAP_DIR/install_local.sh"
sudo chmod +x "$BOOTSTRAP_DIR/install_local.sh"

if [ -d "$USB_MOUNT/modules" ]; then
    sudo cp "$USB_MOUNT/modules/"*.sh "$BOOTSTRAP_DIR/modules/" 2>/dev/null
    sudo chmod +x "$BOOTSTRAP_DIR/modules/"*.sh 2>/dev/null
    MODULE_COUNT=$(ls "$BOOTSTRAP_DIR/modules/"*.sh 2>/dev/null | wc -l)
    echo -e "${GREEN}  ✓ $MODULE_COUNT modules chargés${NC}"
else
    echo -e "${RED}  [ERREUR] Dossier modules/ manquant sur la clé.${NC}"
    exit 1
fi

echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Prêt ! Démarrage du menu MadOS...${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
sleep 1

export MODULES_DIR="$BOOTSTRAP_DIR/modules"
sudo bash "$BOOTSTRAP_DIR/install_local.sh" /dev/tty

# Démontage si monté par ce script
if [ "$MOUNTED_BY_SCRIPT" = "true" ]; then
    sudo umount "$USB_MOUNT" 2>/dev/null || true
fi
