#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - install.sh
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

# Usage: wget -qO install.sh https://raw.githubusercontent.com/LordMadTrix/MadOS_ROG_Edition/main/install.sh && sudo bash install.sh
# ==========================================

# Envelopper dans une fonction main permet d'éviter que wget | bash
# ne coupe le script en plein milieu si l'entrée standard est consommée.
main() {
    export DEBIAN_FRONTEND=noninteractive
    set -uo pipefail


    clear
    echo ""
    echo -e "${RED}  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗ ${NC}"
    echo -e "${RED}  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝ ${NC}"
    echo -e "${RED}  ██╔████╔██║███████║██║  ██║██║   ██║███████╗ ${NC}"
    echo -e "${WHITE}  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║ ${NC}"
    echo -e "${WHITE}  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║ ${NC}"
    echo -e "${WHITE}  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝ ${NC}"
    echo ""
    echo -e "${RED}     ╔══════════════════════════════╗${NC}"
    echo -e "${RED}     ║    INSTALLATEUR MadOS 3.0    ║${NC}"
    echo -e "${RED}     ║     by LordMadTrix           ║${NC}"
    echo -e "${RED}     ╚══════════════════════════════╝${NC}"
    echo ""

    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  [1/4] Vérification des privilèges...${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ "$EUID" -ne 0 ]; then
        echo -e "\n${RED}[!] ERREUR CRITIQUE : Privilèges Root manquants.${NC}"
        echo -e "${WHITE}La matrice refuse votre accès. Relancez avec SUDO :${NC}\n"
        echo -e "${GREEN}sudo bash install.sh${NC}\n"
        exit 1
    fi

    echo -e "      ${GREEN}✓ Privilèges confirmés.${NC}"

    echo ""
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  [2/4] Préparation de l'environnement matériel...${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if ! command -v git >/dev/null 2>&1; then
        echo -e "      ${WHITE}Git non détecté, installation silencieuse...${NC}"
        apt-get update -q >/dev/null 2>&1
        apt-get install -y git >/dev/null 2>&1
        echo -e "      ${GREEN}✓ Git installé avec succès.${NC}"
    else
        echo -e "      ${GREEN}✓ Git présent.${NC}"
    fi

    # whiptail sera géré par install_local.sh plus tard, mais on vérifie bash
    if ! command -v whiptail >/dev/null 2>&1; then
        apt-get install -y whiptail dialog >/dev/null 2>&1
    fi

    echo ""
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  [3/4] Clonage de la Matrice MadOS 3.0...${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    INSTALL_DIR="/tmp/mados_install_bootstrap"
    REPO_URL="https://github.com/LordMadTrix/MadOS_ROG_Edition.git"

    rm -rf "$INSTALL_DIR" 2>/dev/null || true

    if git clone --depth=1 "$REPO_URL" "$INSTALL_DIR" >/dev/null 2>&1; then
        echo -e "      ${GREEN}✓ Scripts téléchargés en mémoire volatile.${NC}"
    else
        echo -e "      ${RED}✗ Erreur : Impossible de contacter la forge matérielle (GitHub).${NC}"
        echo -e "      ${WHITE}Vérifiez votre connexion internet.${NC}"
        exit 1
    fi

    chmod +x "$INSTALL_DIR/install_local.sh"
    chmod +x "$INSTALL_DIR/modules"/*.sh 2>/dev/null || true

    echo ""
    echo -e "${RED}⚠️  Lancement automatique de l'assistant d'installation dans quelques secondes...${NC}"
    sleep 2
    
    # On s'assure que le script suivant a bien un terminal propre pour Whiptail
    exec /tmp/mados_install_bootstrap/install_local.sh < /dev/tty
}

main
