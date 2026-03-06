#!/bin/bash
# ==============================================================================
# MadOS ROG Edition — Lanceur Universel (Windows & Linux)
# start.sh
# ==============================================================================
# Sur WINDOWS (Git Bash / WSL) : redirige vers create_mados_usb.bat
# Sur LINUX   (Ubuntu Server)  : lance l'installateur MadOS depuis la clé USB
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
echo -e "${RED}     ║   🔴 MADOS USB LAUNCHER v3.2 🔴   ║${NC}"
echo -e "${RED}     ║        by LordMadTrix             ║${NC}"
echo -e "${RED}     ╚═══════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# 1. DÉTECTION OS : Windows (Git Bash / WSL) ou Linux natif
# ==============================================================================

detect_os() {
    local OS_TYPE="linux"

    # Méthode 1 : uname (retourne MINGW*, CYGWIN*, MSYS* sur Windows Git Bash)
    local UNAME
    UNAME=$(uname -s 2>/dev/null || echo "unknown")
    case "$UNAME" in
        MINGW*|CYGWIN*|MSYS*)
            OS_TYPE="windows_gitbash"
            ;;
        Linux)
            # Méthode 2 : Détection WSL (Windows Subsystem for Linux)
            if grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
                OS_TYPE="windows_wsl"
            elif [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSLENV:-}" ]; then
                OS_TYPE="windows_wsl"
            fi
            ;;
    esac

    # Méthode 3 : Variable d'environnement OSTYPE
    case "${OSTYPE:-}" in
        cygwin*|msys*|win32*)
            OS_TYPE="windows_gitbash"
            ;;
    esac

    echo "$OS_TYPE"
}

OS=$(detect_os)

# ==============================================================================
# 2. BRANCHE WINDOWS
# ==============================================================================

if [[ "$OS" == windows_* ]]; then

    if [[ "$OS" == "windows_wsl" ]]; then
        echo -e "${CYAN}  Environnement détecté : ${WHITE}Windows WSL${NC}"
    else
        echo -e "${CYAN}  Environnement détecté : ${WHITE}Windows Git Bash / MSYS${NC}"
    fi

    echo ""
    echo -e "${YELLOW}  ⚠️  Ce script est destiné à Ubuntu Server (Linux).${NC}"
    echo -e "${GRAY}  Sur Windows, utilisez le créateur de clé USB MadOS.${NC}"
    echo ""
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  Pour préparer votre clé USB MadOS depuis Windows :${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Cherche le .bat dans le même dossier que ce script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Convertit le chemin POSIX en chemin Windows si nécessaire
    if command -v cygpath &>/dev/null; then
        WIN_SCRIPT_DIR=$(cygpath -w "$SCRIPT_DIR")
    else
        WIN_SCRIPT_DIR=$(echo "$SCRIPT_DIR" | sed 's|/mnt/\([a-z]\)/|\1:/|' | sed 's|/|\\|g')
    fi

    BAT_PATH="$SCRIPT_DIR/create_mados_usb.bat"
    PS1_PATH="$SCRIPT_DIR/create_mados_usb.ps1"

    if [ -f "$BAT_PATH" ]; then
        echo -e "${GREEN}  ✓ Trouvé : create_mados_usb.bat${NC}"
        echo ""
        echo -e "${WHITE}  Double-cliquez sur :${NC}"
        echo -e "${CYAN}  $WIN_SCRIPT_DIR\\create_mados_usb.bat${NC}"
        echo ""
        echo -e "${GRAY}  Ce fichier .bat demande automatiquement les droits Admin${NC}"
        echo -e "${GRAY}  et prépare votre clé USB en quelques secondes.${NC}"
        echo ""

        # Tenter de l'ouvrir automatiquement si possible
        if [[ "$OS" == "windows_gitbash" ]]; then
            echo -e "${YELLOW}  Lancement automatique du .bat...${NC}"
            sleep 1
            cmd.exe //c start "" "$WIN_SCRIPT_DIR\\create_mados_usb.bat" 2>/dev/null || \
            cmd //c "$WIN_SCRIPT_DIR\\create_mados_usb.bat" 2>/dev/null || \
            echo -e "${GRAY}  Ouvrez-le manuellement depuis l'Explorateur Windows.${NC}"
        elif [[ "$OS" == "windows_wsl" ]]; then
            echo -e "${YELLOW}  Lancement automatique depuis WSL...${NC}"
            sleep 1
            WIN_BAT=$(wslpath -w "$BAT_PATH" 2>/dev/null)
            cmd.exe /c start "" "$WIN_BAT" 2>/dev/null || \
            powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w "$PS1_PATH" 2>/dev/null)" 2>/dev/null || \
            echo -e "${GRAY}  Ouvrez-le manuellement depuis l'Explorateur Windows.${NC}"
        fi

    elif [ -f "$PS1_PATH" ]; then
        echo -e "${GREEN}  ✓ Trouvé : create_mados_usb.ps1${NC}"
        echo ""
        echo -e "${WHITE}  Clic droit → Exécuter avec PowerShell (Admin) sur :${NC}"
        echo -e "${CYAN}  $WIN_SCRIPT_DIR\\create_mados_usb.ps1${NC}"
    else
        echo -e "${RED}  [ERREUR] create_mados_usb.bat introuvable dans : $WIN_SCRIPT_DIR${NC}"
        echo -e "${GRAY}  Téléchargez MadOS depuis GitHub :${NC}"
        echo -e "${CYAN}  https://github.com/LordMadTrix/MadOS_ROG_Edition${NC}"
    fi

    echo ""
    read -rp "  Appuyez sur Entrée pour fermer..."
    exit 0
fi

# ==============================================================================
# 3. BRANCHE LINUX NATIF (Ubuntu Server)
# ==============================================================================

echo -e "${CYAN}  Environnement détecté : ${GREEN}Linux natif ✓${NC}"
echo ""

# Vérification Ubuntu/Debian
if ! command -v apt-get &>/dev/null; then
    echo -e "${RED}  [ERREUR] Système non compatible (pas Ubuntu/Debian).${NC}"
    echo -e "${GRAY}  MadOS ROG Edition nécessite Ubuntu Server 25.10.${NC}"
    exit 1
fi

# --- Auto-détection du point de montage de la clé USB "MADOS" ---
USB_MOUNT=""
MOUNTED_BY_SCRIPT=false

for MNTPOINT in /media/*/MADOS /media/root/MADOS /mnt/MADOS /run/media/*/MADOS; do
    if [ -d "$MNTPOINT" ] && [ -f "$MNTPOINT/install_local.sh" ]; then
        USB_MOUNT="$MNTPOINT"
        break
    fi
done

# Méthode 2 : blkid par label
if [ -z "$USB_MOUNT" ]; then
    USB_DEV=$(blkid -L MADOS 2>/dev/null)
    if [ -n "$USB_DEV" ]; then
        echo -e "${YELLOW}  [USB] Clé MADOS détectée sur $USB_DEV, montage...${NC}"
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

# Méthode 3 : Chemin relatif au script (start.sh est à la racine de la clé)
if [ -z "$USB_MOUNT" ]; then
    SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SELF_DIR/install_local.sh" ]; then
        USB_MOUNT="$SELF_DIR"
        echo -e "${GREEN}  [USB] Modules trouvés dans le répertoire courant.${NC}"
    fi
fi

# Méthode 4 : Saisie manuelle
if [ -z "$USB_MOUNT" ]; then
    echo -e "${YELLOW}  [USB] Clé USB MADOS non détectée automatiquement.${NC}"
    echo ""
    lsblk -o NAME,SIZE,LABEL,MOUNTPOINT 2>/dev/null | grep -v "^loop" || true
    echo ""
    echo -e "${CYAN}  Point de montage de la clé (ex: /mnt ou /media/user/MADOS) :${NC}"
    read -r USB_MOUNT
    if [ ! -f "$USB_MOUNT/install_local.sh" ]; then
        echo -e "${RED}  [ERREUR] install_local.sh introuvable dans $USB_MOUNT${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}  ✓ Clé USB MADOS : $USB_MOUNT${NC}"
echo ""

# --- Vérification et installation de whiptail si absent ---
if ! command -v whiptail &>/dev/null; then
    echo -e "${YELLOW}  [INFO] Installation de whiptail...${NC}"
    sudo apt-get install -y whiptail > /dev/null 2>&1
fi

# --- Copie des modules en /tmp ---
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

# Nettoyage si montage automatique
if [ "$MOUNTED_BY_SCRIPT" = "true" ]; then
    sudo umount "$USB_MOUNT" 2>/dev/null || true
fi
