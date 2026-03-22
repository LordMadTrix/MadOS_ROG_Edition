#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 09_montage_ntfs.sh
# ==============================================================================
# Phase: 9 - Montage Automatique des jeux NTFS
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

REAL_USER=${SUDO_USER:-$USER}
USER_UID=$(id -u "$REAL_USER")
USER_GID=$(id -g "$REAL_USER")

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 9 Recherche de disques Windows (NTFS)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# Trouver les disques NTFS
NTFS_DRIVES=$(sudo blkid | grep -i ntfs || true)

if [ -z "$NTFS_DRIVES" ]; then
    echo -e "    ${GRAY}├─ Aucun disque NTFS additionnel trouvé (ou déjà géré).${NC}"
    echo -e "    ${WHITE}✅ [SUCCÈS] Phase 9 Terminée.${NC}"
    exit 0
fi

# Réattacher stdin au terminal pour les commandes interactives (read)
exec < /dev/tty 2>/dev/null || true

echo -e "    ${CYAN}Disques NTFS détectés :${NC}"
echo "$NTFS_DRIVES" | awk -F: '{print "       - "$1}'

echo -e "\n    ${WHITE}Voulez-vous monter un de ces disques pour jouer sur Steam (Proton) ?${NC}"
read -p "    👉 (o/N) : " choix
if [[ ! "$choix" =~ ^[oO]$ ]]; then
    echo -e "    ${GRAY}├─ Montage NTFS ignoré.${NC}"
    exit 0
fi

read -p "    👉 Entrez le nom du périphérique (ex: /dev/sdb1) ou 'q' pour quitter : " TARGET_DRIVE

if [ "$TARGET_DRIVE" == "q" ]; then exit 0; fi

if sudo blkid | grep -q "$TARGET_DRIVE"; then
    UUID=$(sudo blkid -s UUID -o value "$TARGET_DRIVE")
    MOUNT_POINT="/mnt/Jeux_Windows"
    
    sudo mkdir -p "$MOUNT_POINT"
    
    # Check si déjà dans fstab
    if grep -q "$UUID" /etc/fstab; then
        echo -e "    ${RED}⚠️  [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] Le disque est déjà configuré dans /etc/fstab.${NC}"
    else
        echo -e "    ${GRAY}├─ Ajout de l'entrée fstab optimisée Steam...${NC}"
        sudo apt install -y ntfs-3g > /dev/null 2>&1 || true
        echo "UUID=$UUID $MOUNT_POINT ntfs-3g uid=$USER_UID,gid=$USER_GID,rw,user,exec,umask=000,utf8 0 0" | sudo tee -a /etc/fstab > /dev/null
        sudo mount -a || echo -e "    ${RED}⚠️  [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] [ATTENTION] Erreur lors du montage automatique.${NC}"
        echo -e "    ${GREEN}✅ [SUCCÈS] Disque monté avec succès dans $MOUNT_POINT !${NC}"
    fi
else
    echo -e "    ${RED}❌ [ERREUR] Périphérique invalide.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 9 Terminée.${NC}"
