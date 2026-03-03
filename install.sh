#!/bin/bash
# ==========================================
# MadOS 3.0 - Bootstrap (Phase 1)
# Usage: sudo wget -qO- https://raw.githubusercontent.com/LordMadTrix/MadOS_ROG_Edition/main/install.sh | sudo bash
# ==========================================

# Envelopper dans une fonction main permet d'éviter que wget | bash
# ne coupe le script en plein milieu si l'entrée standard est consommée.
main() {
    export DEBIAN_FRONTEND=noninteractive
    set -uo pipefail

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    GRAY='\033[0;37m'
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
        echo -e "${WHITE}La matrice refuse votre accès. Veuillez lancer le script avec SUDO :${NC}\n"
        echo -e "${GREEN}sudo wget -qO- https://raw.githubusercontent.com/LordMadTrix/MadOS_ROG_Edition/main/install.sh | sudo bash${NC}\n"
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
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  [4/4] Transition vers le terminal local interactif...${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 2

    # ==========================================
    # LA RUSTINE MAGIQUE TTY
    # ==========================================
    # Étant donné que wget | bash pompe le flux STDIN, le menu Whiptail ne capte pas le clavier.
    # Ici, nous basculons toute l'exécution sur le VRAI terminal attaché au processus (/dev/tty).
    # La commande 'exec' remplace le script actuel par la suite, tout étant isolé du wget.
    export TERM=xterm-256color
    
    # On garantit que sudo ne flingue pas le TTY interactif en le relançant sous la console tty locale
    exec bash -c "exec < /dev/tty > /dev/tty 2>&1; bash '$INSTALL_DIR/install_local.sh'"
}

main
