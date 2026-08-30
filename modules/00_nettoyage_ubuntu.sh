#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 00_nettoyage_ubuntu.sh
# ==============================================================================
# Phase: 0 - Purification & Dépôts
# Nettoie les composants serveur et prépare l'environnement.
# Enlever 'set -e' pour éviter qu'une simple erreur réseau/apt update ne fasse crasher tout le script
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Kill process that could lock APT temporarily on fresh boot
if is_dry_run; then
    log_simu "tuerait les processus apt bloqués et purgerait les verrous dpkg/apt résiduels"
else
    if command -v pkill >/dev/null 2>&1; then
        sudo pkill -f apt 2>/dev/null || true
    else
        sudo killall apt apt-get 2>/dev/null || true
    fi
    sudo rm /var/lib/apt/lists/lock 2>/dev/null || true
    sudo rm /var/cache/apt/archives/lock 2>/dev/null || true
    sudo rm /var/lib/dpkg/lock* 2>/dev/null || true
    sudo dpkg --configure -a 2>/dev/null || true
fi

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 0 Purification du Système & Préparation${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 0. Installation des outils de base requis pour la suite
# Note: apt update centralisé déjà effectué dans install.sh avant le lancement des modules
echo -e "    ${WHITE}├─ [PREREQUIS] Installation des outils de dépôts...${NC}"
run_action "installerait software-properties-common, dirmngr, gpg, curl, wget, lsb-release" sudo apt install -y software-properties-common dirmngr gpg curl wget lsb-release 2>/dev/null || true

# 1. Neutralisation TOTALE et DÉFINITIVE de Snap (Bouclier MadOS)
echo -e "    ${WHITE}├─ [SÉCURITÉ] Érection d'un mur anti-Snap (APT Blockade)...${NC}"
# Bloquer toute réinstallation automatique de snapd par APT
if is_dry_run; then
    log_simu "écrirait /etc/apt/preferences.d/nosnap.pref pour bloquer snapd"
else
    sudo tee /etc/apt/preferences.d/nosnap.pref > /dev/null <<EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
fi

# Tuer les processus snapd s'ils tournent encore
run_action "arrêterait snapd.service, snapd.socket, snapd.seeded.service" sudo systemctl stop snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true
run_action "désactiverait snapd.service, snapd.socket, snapd.seeded.service" sudo systemctl disable snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true

# Purge radicale des composants et des montages snap
echo -e "    ${WHITE}├─ [NETTOYAGE] Purge atomique des composants Snap & Cloud-Init...${NC}"
run_action "purgerait cloud-init, multipath-tools, snapd" sudo apt purge -y cloud-init multipath-tools snapd 2>/dev/null || true
run_action "supprimerait /var/cache/snapd/, /var/lib/snapd/, /snap/" sudo rm -rf /var/cache/snapd/ /var/lib/snapd/ /snap/ 2>/dev/null || true
run_action "purgerait les paquets orphelins (apt autoremove --purge)" sudo apt autoremove -y --purge 2>/dev/null || true

# NetworkManager est installe ici (le bureau KDE en a besoin), mais la BASCULE
# du reseau vers lui a ete DEPLACEE dans le module 99, qui s'execute en dernier.
#
# Pourquoi : la bascule supprimait la configuration reseau fonctionnelle au tout
# DEBUT de l'installation, alors que les 38 modules suivants ont besoin du
# reseau pour telecharger. Mesure en VM QEMU Ubuntu 24.04 propre, meme charge
# apt des deux cotes :
#     avec la bascule ici : 2362 "Could not resolve", 6391 Ign:, ~4 paquets
#     sans la bascule     :    0 "Could not resolve",    0 Ign:,  95 paquets
# Le DNS survivait quelques secondes puis lachait, et comme chaque appel apt
# des modules finit par "|| true", AUCUN module ne signalait d'echec :
# l'installation allait au bout en n'installant presque rien.
#
# NetworkManager ne sert qu'au bureau, qui n'est meme pas encore installe a ce
# stade : rien ne justifiait de prendre ce risque avant les telechargements.
echo -e "    ${GRAY}├─ Installation de NetworkManager (bascule reportée en fin d'installation)...${NC}"
run_action "installerait network-manager" sudo apt install -y network-manager 2>/dev/null || true

# 2. Ajout de l'Architecture i386 (pour Steam/Wine)
run_action "ajouterait l'architecture i386 (dpkg --add-architecture)" sudo dpkg --add-architecture i386

# 3. Dépôts (XanMod, Google, Spotify, Lutris)
echo -e "    ${WHITE}├─ [DÉPÔTS] Ajout des clés GPG sécurisées en parallèle...${NC}"
run_action "créerait le répertoire /etc/apt/keyrings" sudo mkdir -p /etc/apt/keyrings

if is_dry_run; then
    log_simu "téléchargerait et importerait les clés GPG Google Chrome, Spotify, XanMod et WineHQ dans /etc/apt/keyrings"
else
    # Téléchargement asynchrone des clés pour gagner du temps
    (wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg) &
    (curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify-new.gpg) &
    (curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify-old.gpg) &
    (wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/xanmod-archive-keyring.gpg) &
    (wget -qO - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/winehq-archive-keyring.gpg) &

    # Attendre que tous les téléchargements soient finis
    wait
fi

if is_dry_run; then
    log_simu "écrirait les fichiers de dépôts APT google-chrome.list, spotify.list, xanmod-release.list et winehq.list"
else
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/spotify-new.gpg,/etc/apt/keyrings/spotify-old.gpg arch=amd64] https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null
    # XanMod a change la structure de son depot : la distribution "releases"
    # renvoie 404 (verifie : https://deb.xanmod.org/dists/releases/Release -> 404,
    # https://deb.xanmod.org/dists/noble/Release -> 200). Il faut le nom de code
    # de la distribution. Consequence de l'ancienne URL, mesuree en VM :
    #   E: The repository 'http://deb.xanmod.org releases Release' does not have a Release file.
    #   E: Unable to locate package linux-xanmod-edge-x64v3
    # ... et le module 01 annoncait quand meme un succes.
    # lsb_release peut renvoyer "n/a" (notamment si /etc/os-release a ete
    # rebrande sans VERSION_CODENAME) : on lit os-release en priorite.
    XANMOD_DIST="$(. /etc/os-release 2>/dev/null; echo "${VERSION_CODENAME:-}")"
    [ -z "$XANMOD_DIST" ] && XANMOD_DIST="$(lsb_release -sc 2>/dev/null)"
    case "$XANMOD_DIST" in ""|"n/a") XANMOD_DIST="noble" ;; esac
    echo "deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org ${XANMOD_DIST} main" | sudo tee /etc/apt/sources.list.d/xanmod-release.list > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/ubuntu/ ${XANMOD_DIST} main" | sudo tee /etc/apt/sources.list.d/winehq.list > /dev/null
fi

# Lutris & Divers
if ! ls /etc/apt/sources.list.d/lutris-team-ubuntu-lutris-*.list &>/dev/null; then
    run_action "ajouterait le PPA lutris-team/lutris" sudo add-apt-repository ppa:lutris-team/lutris -y --no-update
fi
run_action "activerait le dépôt universe" sudo add-apt-repository universe -y --no-update
run_action "activerait le dépôt multiverse" sudo add-apt-repository multiverse -y --no-update
run_action "activerait le dépôt restricted" sudo add-apt-repository restricted -y --no-update

# 4. Mise à jour globale
echo -e "    ${WHITE}├─ [MAJ] Rafraîchissement APT et mise à niveau...${NC}"
run_action "rafraîchirait les index APT (apt update)" sudo apt update -q
run_action "mettrait à niveau tous les paquets (apt upgrade)" sudo apt upgrade -y -q

# 5. Dépendances de base
echo -e "    ${WHITE}├─ [BASE] Utilitaires fondamentaux...${NC}"
run_action "installerait les utilitaires de base (build-essential, git, cmake, ...)" sudo apt install -y build-essential git cmake pkg-config unzip p7zip-full htop vim nano pipx zsh gamemode ca-certificates gcc g++ make file

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 0 Terminée.${NC}"
