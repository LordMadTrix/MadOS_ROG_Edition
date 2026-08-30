#!/bin/bash
# ==============================================================================
# MadOS 4.0 - Test interactif du système chroot (sans générer d'ISO)
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# ÉLÉVATION — le mot de passe n'est JAMAIS stocké dans ce script.
#
# Avant, on trouvait ici « SUDO_PWD="<mot de passe>" » en clair. Comme
# build_mados_live_iso.sh recopie tout le dépôt vers /opt/mados-rog dans le
# chroot, ce mot de passe partait DANS CHAQUE ISO produite. Vérifié en
# l'extrayant d'une image déjà construite : il y était.
#
# « sudo -v » le demande une fois puis rafraîchit le ticket. La boucle de fond
# le maintient vivant : une construction dure bien plus que les 15 minutes du
# délai sudo par défaut, et sans elle le script s'arrêterait au milieu.
# ------------------------------------------------------------------------------
demander_sudo() {
    [ "$(id -u)" -eq 0 ] && return 0
    if ! sudo -n true 2>/dev/null; then
        echo -e "${CYAN:-}Privilèges administrateur requis pour cette étape.${NC:-}"
        sudo -v || { echo -e "${RED:-}Élévation refusée : arrêt.${NC:-}"; exit 1; }
    fi
    # Maintien du ticket tant que ce script vit.
    ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
}
run_sudo() { sudo "$@"; }
demander_sudo

CHROOT_DIR="/tmp/mados_iso_workspace/chroot"

if [ ! -d "$CHROOT_DIR/usr" ]; then
    echo -e "${YELLOW}Le système de base chroot n'est pas encore installé ou est incomplet.${NC}"
    echo -e "${CYAN}Initialisation rapide du système de base...${NC}"
    
    # Lance uniquement la phase d'initialisation rapide (étapes 1 et 2 du script de build)
    run_sudo apt-get update -qq
    run_sudo apt-get install -y debootstrap squashfs-tools binutils systemd-container -qq
    run_sudo rm -rf "/tmp/mados_iso_workspace"
    run_sudo mkdir -p "$CHROOT_DIR"
    # Meme base que le constructeur, et signatures verifiees (le --no-check-gpg
# desactivait la verification d'authenticite du depot).
SUITE_UBUNTU="${SUITE_UBUNTU:-resolute}"
run_sudo debootstrap --arch=amd64 "$SUITE_UBUNTU" "$CHROOT_DIR" http://archive.ubuntu.com/ubuntu/
fi

echo -e "${GREEN}Entering MadOS System Chroot (Tapez 'exit' pour quitter)...${NC}"
echo -e "${GRAY}Note: Vous êtes connecté en tant que root dans votre futur système d'exploitation.${NC}\n"

# Lancement interactif de chroot avec montage automatique des systèmes de fichiers virtuels
run_sudo systemd-nspawn -D "$CHROOT_DIR" /bin/bash
