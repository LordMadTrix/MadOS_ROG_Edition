#!/bin/bash
# ==========================================
# MadOS ROG Edition V2.4 - Bootstrap Installer
# Usage: wget -qO- lordmadtrix.github.io/MadOS_ROG_Edition | bash
# ==========================================

export DEBIAN_FRONTEND=noninteractive

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

clear
echo ""
echo -e "${RED} ██████╗  ██████╗  ██████╗     ███████${NC}"
echo -e "${RED}██╔══██╗██╔═══██╗██╔════╝     ██╔════${NC}"
echo -e "${RED}██████╔╝██║   ██║██║  ███╗     █████╗ ${NC}"
echo -e "${RED}██╔══██╗██║   ██║██║   ██║     ██╔══╝ ${NC}"
echo -e "${WHITE}██║  ██║╚██████╔╝╚██████╔╝     ███████${NC}"
echo -e "${WHITE}╚═╝  ╚═╝ ╚═════╝  ╚═════╝     ╚══════${NC}"
echo ""
echo -e "${RED}     ╔══════════════════════════════╗${NC}"
echo -e "${RED}     ║    MadOS ROG EDITION V2.4    ║${NC}"
echo -e "${RED}     ║     by LordMadTrix            ║${NC}"
echo -e "${RED}     ╚══════════════════════════════╝${NC}"
echo ""

echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  [1/4] Vérification des prérequis...${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if ! command -v git >/dev/null 2>&1; then
    echo -e "      ${WHITE}Git non détecté, installation automatique...${NC}"
    sudo apt-get update -q >/dev/null 2>&1
    sudo apt-get install -y git >/dev/null 2>&1
    echo -e "      ${GREEN}✓ Git installé avec succès.${NC}"
else
    echo -e "      ${GREEN}✓ Git présent.${NC}"
fi

if ! command -v wget >/dev/null 2>&1; then
    sudo apt-get install -y wget >/dev/null 2>&1
fi

echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  [2/4] Clonage de la Matrice MadOS ROG...${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

INSTALL_DIR="/tmp/mados_install_bootstrap"
REPO_URL="https://github.com/LordMadTrix/MadOS_ROG_Edition.git"

sudo rm -rf "$INSTALL_DIR" 2>/dev/null || true

if sudo git clone "$REPO_URL" "$INSTALL_DIR" 2>&1 | grep -v '^$'; then
    echo -e "      ${GREEN}✓ Dépôt cloné avec succès.${NC}"
else
    echo -e "      ${RED}✗ Erreur : Impossible de cloner le dépôt GitHub.${NC}"
    echo -e "      ${WHITE}Vérifiez votre connexion internet et réessayez.${NC}"
    exit 1
fi

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "      ${RED}✗ Erreur critique : répertoire introuvable après clonage.${NC}"
    exit 1
fi

cd "$INSTALL_DIR" || exit 1

echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  [3/4] Application des permissions...${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
sudo chmod +x Menu_Installation_ROG.sh modules/*.sh 2>/dev/null || true
echo -e "      ${GREEN}✓ Permissions appliquées.${NC}"

echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  [4/4] Lancement de l'installateur principal...${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${WHITE}  Préparez-vous à entrer dans la Matrice. 🔴${NC}"
echo ""
sleep 2

sudo bash Menu_Installation_ROG.sh
