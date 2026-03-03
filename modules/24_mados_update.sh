#!/bin/bash
# ==========================================
# MadOS ROG V2 - 24_mados_update.sh
# ==========================================
# Phase: 24 - Mise à jour automatique MadOS
# ==========================================

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}
INSTALL_DIR="/tmp/mados_update_$(date +%s)"
REPO_URL="https://github.com/LordMadTrix/MadOS_ROG_Edition.git"

echo -e "${RED}>>> ${WHITE}[Phase 24] ${BOLD}Mise à jour de MadOS ROG Edition...${NC}"

echo -e "    ${GRAY}├─ Vérification de la connexion internet...${NC}"
if ! ping -c 1 github.com &>/dev/null; then
    echo -e "    ${RED}✗ Pas de connexion internet. Mise à jour impossible.${NC}"
    exit 1
fi
echo -e "    ${GREEN}✓ Connexion OK.${NC}"

echo -e "    ${GRAY}├─ Clonage de la dernière version depuis GitHub...${NC}"
sudo rm -rf "$INSTALL_DIR" 2>/dev/null || true
if ! sudo git clone --depth=1 "$REPO_URL" "$INSTALL_DIR" >/dev/null 2>&1; then
    echo -e "    ${RED}✗ Impossible de récupérer la mise à jour depuis GitHub.${NC}"
    exit 1
fi

CURRENT_SCRIPT="/tmp/mados_install_bootstrap"
NEW_VERSION_FILE="$INSTALL_DIR/VERSION"
CURRENT_VERSION_FILE="/opt/mados/VERSION"

# Comparer les versions si le fichier existe
if [ -f "$NEW_VERSION_FILE" ] && [ -f "$CURRENT_VERSION_FILE" ]; then
    NEW_VER=$(cat "$NEW_VERSION_FILE")
    CUR_VER=$(cat "$CURRENT_VERSION_FILE")
    if [ "$NEW_VER" = "$CUR_VER" ]; then
        echo -e "    ${CYAN}ℹ️  MadOS est déjà à jour (version $CUR_VER).${NC}"
        sudo rm -rf "$INSTALL_DIR"
        exit 0
    fi
    echo -e "    ${GRAY}├─ Mise à jour : ${RED}$CUR_VER${NC} → ${GREEN}$NEW_VER${NC}"
fi

echo -e "    ${GRAY}├─ Application des permissions...${NC}"
sudo chmod +x "$INSTALL_DIR/Menu_Installation_ROG.sh" "$INSTALL_DIR/modules/"*.sh

# Demander quels modules relancer
CHOICE=$(whiptail --title "MadOS 3.0 - 🔄 Update Launcher" --menu \
    "Quelle mise à jour souhaitez-vous appliquer ?" 18 65 5 \
    "1" "Mise à jour Totale (tous les modules)" \
    "2" "Mise à jour Sélective (choisir les modules)" \
    "3" "Mise à jour Logiciels uniquement (apt upgrade)" \
    "4" "Annuler" 3>&1 1>&2 2>&3) || true

case "$CHOICE" in
    1)
        echo -e "    ${WHITE}▶ Lancement de la mise à jour totale...${NC}"
        cd "$INSTALL_DIR" && sudo bash Menu_Installation_ROG.sh
        ;;
    2)
        echo -e "    ${WHITE}▶ Lancement du menu sélectif...${NC}"
        cd "$INSTALL_DIR" && sudo bash Menu_Installation_ROG.sh
        ;;
    3)
        echo -e "    ${GRAY}├─ Mise à jour des paquets système...${NC}"
        sudo apt update -q && sudo apt upgrade -y
        sudo npm update -g pnpm 2>/dev/null || true
        echo -e "    ${GREEN}✓ Paquets mis à jour.${NC}"
        ;;
    *)
        echo -e "    ${CYAN}ℹ️  Mise à jour annulée.${NC}"
        ;;
esac

# Sauvegarder la version installée
sudo mkdir -p /opt/mados
[ -f "$NEW_VERSION_FILE" ] && sudo cp "$NEW_VERSION_FILE" /opt/mados/VERSION

sudo rm -rf "$INSTALL_DIR" 2>/dev/null || true
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 24 Terminée.${NC}"
