#!/bin/bash
# ==============================================================================
# MadOS ROG Edition - Lanceur Cle USB (Ubuntu Server)
# usb/start.sh
# ==============================================================================
# Apres avoir installe Ubuntu Server et insere la cle USB MADOS, tapez :
#   bash /media/$USER/MADOS/start.sh
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
echo -e "${RED}     ║   MADOS USB LAUNCHER v3.2         ║${NC}"
echo -e "${RED}     ║   by LordMadTrix                  ║${NC}"
echo -e "${RED}     ╚═══════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# Verification : Ubuntu/Linux uniquement
# ==============================================================================
if ! command -v apt-get &>/dev/null; then
    echo -e "${RED}  [ERREUR] Ce script est reserve a Ubuntu/Debian Linux.${NC}"
    echo -e "${GRAY}  Sur Windows : lancez usb/create_mados_usb.bat${NC}"
    exit 1
fi

# ==============================================================================
# Localisation de la cle USB MADOS et du dossier mados/
# ==============================================================================
USB_MOUNT=""
MOUNTED_BY_SCRIPT=false

# Methode 1 : Environnement de developpement (QEMU avec dossier Windows partage)
# start.sh est dans usb/, install_local.sh est juste au-dessus
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SELF_DIR/../install_local.sh" ] && [ -d "$SELF_DIR/../modules" ]; then
    USB_MOUNT="$(dirname "$SELF_DIR")"
    MADOS_DIR="$USB_MOUNT"
fi

# Methode 2 : start.sh est a la racine de la cle -> cherche mados/ a cote de lui
if [ -z "$USB_MOUNT" ]; then
    if [ -d "$SELF_DIR/mados" ] && [ -f "$SELF_DIR/mados/install_local.sh" ]; then
        USB_MOUNT="$SELF_DIR"
        MADOS_DIR="$USB_MOUNT/mados"
    fi
fi

# Methode 3 : Chemins de montage standard (Ubuntu Desktop/Serveur)
if [ -z "$USB_MOUNT" ]; then
    for MNTPOINT in /media/*/MADOS /media/root/MADOS /mnt/MADOS /run/media/*/MADOS; do
        if [ -d "$MNTPOINT/mados" ] && [ -f "$MNTPOINT/mados/install_local.sh" ]; then
            USB_MOUNT="$MNTPOINT"
            MADOS_DIR="$USB_MOUNT/mados"
            break
        fi
    done
fi

# Methode 3 : Detection via label blkid
if [ -z "$USB_MOUNT" ]; then
    USB_DEV=$(blkid -L MADOS 2>/dev/null)
    if [ -n "$USB_DEV" ]; then
        echo -e "${YELLOW}  [USB] Cle MADOS sur $USB_DEV, montage...${NC}"
        USB_MOUNT="/mnt/mados_usb"
        sudo mkdir -p "$USB_MOUNT"
        if sudo mount "$USB_DEV" "$USB_MOUNT" 2>/dev/null; then
            echo -e "${GREEN}  [USB] Montee sur $USB_MOUNT${NC}"
            MOUNTED_BY_SCRIPT=true
        else
            USB_MOUNT=""
        fi
    fi
fi

# Methode 5 : Saisie manuelle
if [ -z "$USB_MOUNT" ]; then
    echo -e "${YELLOW}  [USB] Cle MADOS non detectee automatiquement.${NC}"
    echo ""
    lsblk -o NAME,SIZE,LABEL,MOUNTPOINT 2>/dev/null | grep -v "^loop" || true
    echo ""
    echo -e "${CYAN}  Point de montage de la cle USB (ex: /media/user/MADOS) :${NC}"
    read -r USB_MOUNT
    if [ -f "$USB_MOUNT/install_local.sh" ]; then
        MADOS_DIR="$USB_MOUNT"
    elif [ -f "$USB_MOUNT/mados/install_local.sh" ]; then
        MADOS_DIR="$USB_MOUNT/mados"
    else
        echo -e "${RED}  [ERREUR] install_local.sh introuvable dans $USB_MOUNT ou $USB_MOUNT/mados${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}  OK Cle USB MADOS : $USB_MOUNT${NC}"
echo -e "${GRAY}     Scripts dans  : $MADOS_DIR${NC}"
echo ""

# ==============================================================================
# Installation de whiptail si absent
# ==============================================================================
if ! command -v whiptail &>/dev/null; then
    echo -e "${YELLOW}  [INFO] Installation de whiptail...${NC}"
    sudo apt-get install -y whiptail > /dev/null 2>&1
fi

# ==============================================================================
# Chargement des modules depuis mados/ vers /tmp
# ==============================================================================
BOOTSTRAP_DIR="/tmp/mados_install_bootstrap"
sudo rm -rf "$BOOTSTRAP_DIR" 2>/dev/null
sudo mkdir -p "$BOOTSTRAP_DIR/modules"

echo -e "${CYAN}  Chargement des modules depuis la cle USB...${NC}"
sudo cp "$MADOS_DIR/install_local.sh" "$BOOTSTRAP_DIR/install_local.sh"
sudo chmod +x "$BOOTSTRAP_DIR/install_local.sh"

if [ -d "$MADOS_DIR/modules" ]; then
    sudo cp "$MADOS_DIR/modules/"*.sh "$BOOTSTRAP_DIR/modules/" 2>/dev/null
    sudo chmod +x "$BOOTSTRAP_DIR/modules/"*.sh 2>/dev/null
    MODULE_COUNT=$(ls "$BOOTSTRAP_DIR/modules/"*.sh 2>/dev/null | wc -l)
    echo -e "${GREEN}  OK $MODULE_COUNT modules charges${NC}"
else
    echo -e "${RED}  [ERREUR] mados/modules/ manquant sur la cle.${NC}"
    exit 1
fi

echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  OK Pret ! Demarrage du menu MadOS...${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
sleep 1

export MODULES_DIR="$BOOTSTRAP_DIR/modules"
sudo bash "$BOOTSTRAP_DIR/install_local.sh" /dev/tty

# Demontage si monte par ce script
if [ "$MOUNTED_BY_SCRIPT" = "true" ]; then
    sudo umount "$USB_MOUNT" 2>/dev/null || true
fi
