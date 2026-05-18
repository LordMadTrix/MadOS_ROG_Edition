#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 00_nettoyage_ubuntu.sh
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
RED='\033[0;31m'
NC='\033[0m'
WHITE='\033[1;37m'

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Kill process that could lock APT temporarily on fresh boot
if command -v pkill >/dev/null 2>&1; then
    sudo pkill -f apt 2>/dev/null || true
else
    sudo killall apt apt-get 2>/dev/null || true
fi
sudo rm /var/lib/apt/lists/lock 2>/dev/null || true
sudo rm /var/cache/apt/archives/lock 2>/dev/null || true
sudo rm /var/lib/dpkg/lock* 2>/dev/null || true
sudo dpkg --configure -a 2>/dev/null || true

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 0 : Purification du Système & Préparation v4.0${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 0. Installation des outils de base requis pour la suite
echo -e "    ${WHITE}├─ [PREREQUIS] Installation des outils de dépôts...${NC}"
sudo apt install -y software-properties-common dirmngr gpg curl wget lsb-release 2>/dev/null || true

# 1. Neutralisation TOTALE et DÉFINITIVE de Snap (Bouclier MadOS)
echo -e "    ${WHITE}├─ [SÉCURITÉ] Érection d'un mur anti-Snap (APT Blockade)...${NC}"
sudo tee /etc/apt/preferences.d/nosnap.pref > /dev/null <<EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

sudo systemctl stop snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true
sudo systemctl disable snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true

echo -e "    ${WHITE}├─ [NETTOYAGE] Purge atomique des composants Snap & Cloud-Init...${NC}"
sudo apt purge -y cloud-init multipath-tools snapd 2>/dev/null || true
sudo rm -rf /var/cache/snapd/ /var/lib/snapd/ /snap/ 2>/dev/null || true
sudo apt autoremove -y --purge 2>/dev/null || true

echo -e "    ${GRAY}├─ Basculement réseau vers NetworkManager...${NC}"
sudo apt install -y network-manager 2>/dev/null || true

if [ -f /etc/netplan/50-cloud-init.yaml ]; then
    sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak 2>/dev/null || true
    sudo rm /etc/netplan/50-cloud-init.yaml 2>/dev/null || true
fi

sudo tee /etc/netplan/01-network-manager-all.yaml > /dev/null <<'EOF'
network:
  version: 2
  renderer: NetworkManager
EOF
sudo chmod 600 /etc/netplan/01-network-manager-all.yaml
sudo netplan generate 2>/dev/null || true
sudo netplan apply 2>/dev/null || true
sudo systemctl enable NetworkManager 2>/dev/null || true
sudo systemctl restart NetworkManager 2>/dev/null || true
sleep 5

# 2. Ajout de l'Architecture i386 (pour Steam/Wine)
sudo dpkg --add-architecture i386

# 3. Dépôts (XanMod, Google, Spotify, Lutris)
echo -e "    ${WHITE}├─ [DÉPÔTS] Ajout des clés GPG sécurisées en parallèle...${NC}"
sudo mkdir -p /etc/apt/keyrings

(wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg) &
(curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify-new.gpg) &
(curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify-old.gpg) &
(wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/xanmod-archive-keyring.gpg) &
(wget -qO - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/winehq-archive-keyring.gpg) &

wait

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/spotify-new.gpg,/etc/apt/keyrings/spotify-old.gpg arch=amd64] https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null
echo 'deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list > /dev/null
# WineHQ — utiliser "jammy" comme fallback si le codename courant n'est pas supporté
_WINE_SUITE=$(lsb_release -sc)
if ! curl -sf --max-time 5 "https://dl.winehq.org/wine-builds/ubuntu/dists/$_WINE_SUITE/" >/dev/null 2>&1; then
    _WINE_SUITE="jammy"  # Dernier LTS supporté par WineHQ
fi
echo "deb [signed-by=/etc/apt/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/ubuntu/ $_WINE_SUITE main" | sudo tee /etc/apt/sources.list.d/winehq.list > /dev/null

if ! ls /etc/apt/sources.list.d/lutris-team-ubuntu-lutris-*.list &>/dev/null; then
    sudo add-apt-repository ppa:lutris-team/lutris -y --no-update 2>/dev/null || true
fi
sudo add-apt-repository universe -y --no-update 2>/dev/null || true
sudo add-apt-repository multiverse -y --no-update 2>/dev/null || true
sudo add-apt-repository restricted -y --no-update 2>/dev/null || true

# 4. Mise à jour globale
echo -e "    ${WHITE}├─ [MAJ] Rafraîchissement APT et mise à niveau...${NC}"
sudo apt update -q 2>&1 | grep -E "^Err|^W:" | head -5 || true
sudo apt upgrade -y -q 2>/dev/null || true

# 5. Dépendances de base
echo -e "    ${WHITE}├─ [BASE] Utilitaires fondamentaux...${NC}"
sudo apt install -y build-essential git cmake pkg-config unzip p7zip-full htop vim nano pipx zsh gamemode ca-certificates gcc g++ make file 2>/dev/null || true

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 0 Terminée.${NC}"
