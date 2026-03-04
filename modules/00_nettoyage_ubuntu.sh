#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 00_nettoyage_ubuntu.sh
# ==============================================================================
# Phase: 0 - Purification & Dépôts
# Nettoie les composants serveur et prépare l'environnement.
# Enlever 'set -e' pour éviter qu'une simple erreur réseau/apt update ne fasse crasher tout le script
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
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 0 Purification du Système & Préparation${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 0. Installation des outils de base requis pour la suite
echo -e "    ${WHITE}├─ [PREREQUIS] Installation des outils de dépôts...${NC}"
sudo apt update -qq >/dev/null 2>&1
sudo apt install -y software-properties-common dirmngr gpg curl wget 2>/dev/null || true

# 1. Nettoyage des Bloatwares Serveur (Cloud-Init, Multipathd)
echo -e "    ${WHITE}├─ [NETTOYAGE] Suppression des services serveur inutiles...${NC}"
sudo apt purge -y cloud-init multipath-tools snapd 2>/dev/null || true
sudo apt autoremove -y --purge 2>/dev/null || true

# Suppression propre des dossiers cloud-init
sudo rm -rf /etc/cloud/ /var/lib/cloud/ 2>/dev/null || true

# Assurer que NetworkManager prend le relais du réseau
echo -e "    ${GRAY}├─ Basculement réseau vers NetworkManager...${NC}"
sudo apt install -y network-manager 2>/dev/null || true
if [ -f /etc/netplan/50-cloud-init.yaml ]; then
    sudo rm /etc/netplan/50-cloud-init.yaml 2>/dev/null || true
fi
# Créer un fichier netplan simple géré par NM
sudo tee /etc/netplan/01-network-manager-all.yaml > /dev/null <<'EOF'
network:
  version: 2
  renderer: NetworkManager
EOF
sudo netplan generate 2>/dev/null || true
sudo systemctl enable NetworkManager 2>/dev/null || true

# 2. Ajout de l'Architecture i386 (pour Steam/Wine)
sudo dpkg --add-architecture i386

# 3. Dépôts (XanMod, Google, Spotify, Lutris)
echo -e "    ${WHITE}├─ [DÉPÔTS] Ajout des clés GPG sécurisées...${NC}"
sudo mkdir -p /etc/apt/keyrings

# Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

# Spotify
curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify-new.gpg
curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify-old.gpg
echo "deb [signed-by=/etc/apt/keyrings/spotify-new.gpg,/etc/apt/keyrings/spotify-old.gpg arch=amd64] https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null

# XanMod
wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list > /dev/null

# Lutris & Divers
if ! ls /etc/apt/sources.list.d/lutris-team-ubuntu-lutris-*.list &>/dev/null; then
    sudo add-apt-repository ppa:lutris-team/lutris -y --no-update
fi
sudo add-apt-repository universe -y --no-update
sudo add-apt-repository multiverse -y --no-update
sudo add-apt-repository restricted -y --no-update

# 4. Mise à jour globale
echo -e "    ${WHITE}├─ [MAJ] Rafraîchissement APT et mise à niveau...${NC}"
sudo apt update -q
sudo apt upgrade -y -q

# 5. Dépendances de base
echo -e "    ${WHITE}├─ [BASE] Utilitaires fondamentaux...${NC}"
sudo apt install -y build-essential git cmake pkg-config unzip p7zip-full htop vim nano pipx zsh gamemode ca-certificates gcc g++ make file

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 0 Terminée.${NC}"
