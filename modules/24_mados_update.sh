#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 24_mados_update.sh
# ==============================================================================
# Phase: 24 - Mise à jour automatique MadOS
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

export DEBIAN_FRONTEND=noninteractive

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

REAL_USER=${SUDO_USER:-$USER}
INSTALL_DIR="/tmp/mados_update_$(date +%s)"
REPO_URL="https://github.com/LordMadTrix/MadOS_ROG_Edition.git"

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 24 Mise à jour de MadOS ROG Edition${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "    ${GRAY}├─ Vérification de la connexion internet...${NC}"
# `ping -c 1 github.com` sans -W pouvait bloquer longtemps, et echouait sur tout
# reseau filtrant l'ICMP -- le module sortait alors en erreur alors qu'Internet
# fonctionnait parfaitement. On teste donc aussi en HTTPS, ce qui est ce dont on
# a reellement besoin pour cloner.
RESEAU_OK=0
ping -c 1 -W 3 github.com >/dev/null 2>&1 && RESEAU_OK=1
if [ "$RESEAU_OK" -eq 0 ] && command -v curl >/dev/null 2>&1; then
    curl -fsS --max-time 10 -o /dev/null https://github.com && RESEAU_OK=1
fi
if [ "$RESEAU_OK" -eq 0 ] && command -v wget >/dev/null 2>&1; then
    wget -q --timeout=10 --spider https://github.com && RESEAU_OK=1
fi
if [ "$RESEAU_OK" -eq 0 ]; then
    echo -e "    ${RED}✗ Pas de connexion à GitHub. Mise à jour impossible.${NC}"
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
        sudo rm -rf "$INSTALL_DIR" || true
        exit 0
    fi
    echo -e "    ${GRAY}├─ Mise à jour : ${RED}$CUR_VER${NC} → ${GREEN}$NEW_VER${NC}"
fi

echo -e "    ${GRAY}├─ Application des permissions...${NC}"
# Chmod sur des fichiers fraîchement clonés dans /tmp (pas un emplacement système
# persistant) : nécessaire même en simulation pour pouvoir relancer install.sh
# ci-dessous, qui gérera lui-même le mode --dry-run.
sudo chmod +x "$INSTALL_DIR/install.sh" "$INSTALL_DIR/modules/"*.sh || true

# Demander quels modules relancer
CHOICE=$(whiptail --title "MadOS 3.5 - 🔄 Update Launcher" --menu \
    "Quelle mise à jour souhaitez-vous appliquer ?" 18 65 5 \
    "1" "Mise à jour Totale (tous les modules)" \
    "2" "Mise à jour Sélective (choisir les modules)" \
    "3" "Mise à jour Logiciels uniquement (apt upgrade)" \
    "4" "Annuler" 3>&1 1>&2 2>&3) || true

case "$CHOICE" in
    1)
        echo -e "    ${WHITE}▶ Lancement de la mise à jour totale...${NC}"
        # On transmet DRY_RUN au sous-processus : install.sh (fraîchement cloné,
        # donc déjà doté du même support --dry-run) se chargera lui-même de simuler
        # au lieu d'exécuter réellement, exactement comme install.sh le fait.
        if is_dry_run; then
            log_simu "relancerait install.sh en mode simulation (mise à jour totale, tous les modules)"
        fi
        cd "$INSTALL_DIR" && sudo DRY_RUN="${DRY_RUN:-no}" bash install.sh
        ;;
    2)
        echo -e "    ${WHITE}▶ Lancement du menu sélectif...${NC}"
        if is_dry_run; then
            log_simu "relancerait install.sh en mode simulation (menu sélectif)"
        fi
        cd "$INSTALL_DIR" && sudo DRY_RUN="${DRY_RUN:-no}" bash install.sh
        ;;
    3)
        echo -e "    ${GRAY}├─ Mise à jour des paquets système...${NC}"
        if is_dry_run; then
            log_simu "lancerait apt update && apt upgrade -y"
        else
            sudo apt update -q || true && sudo apt upgrade -y || true
        fi
        run_action "mettrait à jour pnpm globalement (npm)" sudo npm update -g pnpm 2>/dev/null || true
        echo -e "    ${GREEN}✓ Paquets mis à jour.${NC}"
        ;;
    *)
        echo -e "    ${CYAN}ℹ️  Mise à jour annulée.${NC}"
        ;;
esac

# Sauvegarder la version installée
if is_dry_run; then
    log_simu "mettrait à jour /opt/mados/VERSION"
else
    sudo mkdir -p /opt/mados
    [ -f "$NEW_VERSION_FILE" ] && sudo cp "$NEW_VERSION_FILE" /opt/mados/VERSION
fi

sudo rm -rf "$INSTALL_DIR" 2>/dev/null || true
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 24 Terminée.${NC}"
