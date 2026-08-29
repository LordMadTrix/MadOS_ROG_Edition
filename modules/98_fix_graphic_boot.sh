#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 98_fix_graphic_boot.sh
# ==============================================================================
# Phase: 98 - Réparation du Boot Graphique (outil de dépannage manuel)
#
# Ce script n'est PAS appelé par install.sh : c'est un utilitaire de secours,
# à lancer à la main depuis un TTY quand le bureau ne démarre plus.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Charge common.sh pour disposer de is_dry_run / run_action / log_*.
# Sans ça, --dry-run ne protégeait rien ici : le script redémarrait la machine
# pour de vrai, même en simulation.
[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"
if ! type is_dry_run >/dev/null 2>&1; then
    is_dry_run() { case "${DRY_RUN:-no}" in yes|true|1|oui) return 0 ;; *) return 1 ;; esac; }
    log_simu() { echo -e "\033[0;33m[SIMULATION]\033[0m $*"; }
fi

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
GRAY='\033[0;37m'
NC='\033[0m'

REAL_USER=${SUDO_USER:-$USER}

echo -e "${YELLOW}🛠️  MadOS - RÉPARATION DU DÉMARRAGE GRAPHIQUE...${NC}"
echo -e "${GRAY}    Utilisateur ciblé : ${REAL_USER}${NC}"

# 1. Installer X11 et forcer SDDM (KDE Login)
echo -e "    ├─ Mise à jour des dépôts et installation X11 (Plasma 6)..."
if is_dry_run; then
    log_simu "installerait sddm, xserver-xorg et plasma-session-x11"
else
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt install -y sddm xserver-xorg plasma-session-x11 --no-install-recommends
fi

echo -e "    ├─ Activation de SDDM comme gestionnaire par défaut..."
if is_dry_run; then
    log_simu "écrirait /etc/X11/default-display-manager et activerait sddm"
else
    echo "/usr/bin/sddm" | sudo tee /etc/X11/default-display-manager >/dev/null
    sudo systemctl enable sddm
fi

# 2. Forcer la configuration GLOBALE de SDDM pour X11
echo -e "    ├─ Force SDDM DisplayServer = x11..."
if is_dry_run; then
    log_simu "écrirait /etc/sddm.conf.d/mados.conf (DisplayServer=x11, autologin pour $REAL_USER)"
else
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/mados.conf > /dev/null <<CONF
[General]
DisplayServer=x11
InputMethod=

[Theme]
Current=breeze
CONF
    # L'utilisateur n'est plus code en dur : "User=mados" cassait l'autologin
    # sur toute machine dont le compte porte un autre nom.
    if id -u "$REAL_USER" >/dev/null 2>&1; then
        sudo tee -a /etc/sddm.conf.d/mados.conf > /dev/null <<CONF

[Autologin]
Session=plasma
User=$REAL_USER
CONF
    else
        echo -e "    ${YELLOW}⚠️  Utilisateur '$REAL_USER' introuvable : autologin non configuré.${NC}"
    fi
fi

# 3. Forcer la session X11 via AccountsService
echo -e "    ├─ Configuration de la session X11 via AccountsService..."
if is_dry_run; then
    log_simu "écrirait /var/lib/AccountsService/users/$REAL_USER (Session=plasma)"
elif id -u "$REAL_USER" >/dev/null 2>&1; then
    sudo mkdir -p /var/lib/AccountsService/users
    sudo tee "/var/lib/AccountsService/users/$REAL_USER" > /dev/null <<CONF
[User]
Session=plasma
SystemAccount=false
CONF
fi

# 4. Forcer le mode graphique
echo -e "    ├─ Configuration du boot en mode TARGET GRAPHICAL..."
if is_dry_run; then
    log_simu "passerait la cible systemd par défaut à graphical.target"
else
    sudo systemctl set-default graphical.target
fi

echo -e "\n${GREEN}🚀 RÉPARATION TERMINÉE !${NC}"

# 5. Redémarrage — jamais automatique.
# L'ancienne version faisait `read -n 1` puis `sudo reboot` sans condition :
# n'importe quelle touche redémarrait la machine, y compris en --dry-run.
if is_dry_run; then
    log_simu "proposerait un redémarrage (aucun redémarrage en simulation)"
    exit 0
fi

read -r -p "Redémarrer maintenant pour appliquer ? (o/N) : " reponse
if [[ "$reponse" =~ ^[oOyY]$ ]]; then
    echo -e "${GRAY}Redémarrage...${NC}"
    sudo reboot
else
    echo -e "${GRAY}Redémarrage annulé. Relancez-le vous-même avec : sudo reboot${NC}"
fi
