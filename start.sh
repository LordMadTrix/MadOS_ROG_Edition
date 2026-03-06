#!/bin/bash
# ==============================================================================
# MadOS ROG Edition — Lanceur Clé USB Offline
# start.sh
# ==============================================================================
# Placez ce fichier à la RACINE de la clé USB "MADOS"
# Usage : bash /media/$USER/MADOS/start.sh
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
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
echo -e "${RED}     ║   🔴 MADOS USB OFFLINE v3.1 🔴   ║${NC}"
echo -e "${RED}     ║        by LordMadTrix             ║${NC}"
echo -e "${RED}     ╚═══════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# 1. Auto-détection du point de montage de la clé USB "MADOS"
# ==============================================================================

USB_MOUNT=""

# Méthode 1 : Cherche la clé montée avec le label MADOS
for MNTPOINT in /media/*/MADOS /media/root/MADOS /mnt/MADOS /run/media/*/MADOS; do
    if [ -d "$MNTPOINT" ] && [ -f "$MNTPOINT/install_local.sh" ]; then
        USB_MOUNT="$MNTPOINT"
        break
    fi
done

# Méthode 2 : Cherche via blkid si non trouvé
if [ -z "$USB_MOUNT" ]; then
    USB_DEV=$(blkid -L MADOS 2>/dev/null)
    if [ -n "$USB_DEV" ]; then
        echo -e "${YELLOW}  [USB] Clé MADOS détectée sur $USB_DEV, montage en cours...${NC}"
        USB_MOUNT="/mnt/mados_usb"
        sudo mkdir -p "$USB_MOUNT"
        if sudo mount "$USB_DEV" "$USB_MOUNT" 2>/dev/null; then
            echo -e "${GREEN}  [USB] Montée avec succès sur $USB_MOUNT${NC}"
            MOUNTED_BY_SCRIPT=true
        else
            USB_MOUNT=""
        fi
    fi
fi

# Méthode 3 : Demander manuellement à l'utilisateur
if [ -z "$USB_MOUNT" ]; then
    echo -e "${YELLOW}  [USB] Clé USB MADOS non détectée automatiquement.${NC}"
    echo -e "${GRAY}  Listage des partitions disponibles :${NC}"
    echo ""
    lsblk -o NAME,SIZE,LABEL,MOUNTPOINT 2>/dev/null | grep -v "^loop" || fdisk -l 2>/dev/null | grep "^/dev"
    echo ""
    echo -e "${CYAN}  Entrez le point de montage de votre clé USB (ex: /mnt ou /media/user/MADOS) :${NC}"
    read -r USB_MOUNT
    if [ ! -f "$USB_MOUNT/install_local.sh" ]; then
        echo -e "${RED}  [ERREUR] install_local.sh introuvable dans $USB_MOUNT${NC}"
        echo -e "${GRAY}  Assurez-vous que la clé est montée et que les scripts MadOS sont présents.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}  ✓ Clé USB MADOS trouvée : $USB_MOUNT${NC}"
echo ""

# ==============================================================================
# 2. Vérification de l'environnement (Ubuntu Server)
# ==============================================================================

echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Vérification de l'environnement système...${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifie qu'on est bien sur Ubuntu/Debian
if ! command -v apt-get &>/dev/null; then
    echo -e "${RED}  [ERREUR] Système non compatible (pas Ubuntu/Debian).${NC}"
    echo -e "${GRAY}  MadOS ROG Edition nécessite Ubuntu Server 25.10.${NC}"
    exit 1
fi

# Vérifie que whiptail est disponible, l'installe sinon
if ! command -v whiptail &>/dev/null; then
    echo -e "${YELLOW}  [INFO] Installation de whiptail (interface menu)...${NC}"
    sudo apt-get install -y whiptail > /dev/null 2>&1
fi

# Vérifie sudo
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}  [SUDO] Mot de passe requis pour l'installation :${NC}"
fi

echo -e "${GREEN}  ✓ Environnement OK${NC}"
echo ""

# ==============================================================================
# 3. Copie des modules en /tmp pour les rendre disponibles
# ==============================================================================

BOOTSTRAP_DIR="/tmp/mados_install_bootstrap"
sudo rm -rf "$BOOTSTRAP_DIR" 2>/dev/null
sudo mkdir -p "$BOOTSTRAP_DIR/modules"

echo -e "${CYAN}  Chargement des modules MadOS depuis la clé USB...${NC}"

# Copie install_local.sh
sudo cp "$USB_MOUNT/install_local.sh" "$BOOTSTRAP_DIR/install_local.sh"
sudo chmod +x "$BOOTSTRAP_DIR/install_local.sh"

# Copie les modules
if [ -d "$USB_MOUNT/modules" ]; then
    sudo cp "$USB_MOUNT/modules/"*.sh "$BOOTSTRAP_DIR/modules/" 2>/dev/null
    sudo chmod +x "$BOOTSTRAP_DIR/modules/"*.sh 2>/dev/null
    MODULE_COUNT=$(ls "$BOOTSTRAP_DIR/modules/"*.sh 2>/dev/null | wc -l)
    echo -e "${GREEN}  ✓ $MODULE_COUNT modules chargés en mémoire${NC}"
else
    echo -e "${RED}  [ERREUR] Dossier modules/ introuvable sur la clé USB.${NC}"
    echo -e "${GRAY}  La clé USB semble incomplète. Recreez-la avec create_mados_usb.ps1${NC}"
    exit 1
fi

echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ MadOS USB Offline prêt ! Démarrage du menu...${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
sleep 1

# ==============================================================================
# 4. Lancement de l'installateur
# ==============================================================================

# On force MODULES_DIR vers /tmp pour que install_local.sh fonctionne
export MODULES_DIR="$BOOTSTRAP_DIR/modules"

# Override : on patch la variable dans install_local.sh si nécessaire
# (certaines versions utilisent /tmp/mados_install_bootstrap/modules directement)
sudo bash "$BOOTSTRAP_DIR/install_local.sh" /dev/tty

# Nettoyage si la clé a été montée par ce script
if [ "${MOUNTED_BY_SCRIPT:-false}" = "true" ]; then
    echo -e "${GRAY}  Démontage de la clé USB...${NC}"
    sudo umount "$USB_MOUNT" 2>/dev/null || true
fi
