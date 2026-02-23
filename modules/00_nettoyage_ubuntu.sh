#!/bin/bash
# ==========================================
# MadOS ROG V2 - 00_nettoyage_ubuntu.sh
# ==========================================
# Phase: 0 - Purification & Dépôts
# Nettoie les composants serveur et prépare l'environnement.
# ==========================================

# Enlever 'set -e' pour éviter qu'une simple erreur réseau/apt update ne fasse crasher tout le script
set -u

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Kill process that could lock APT temporarily on fresh boot
sudo killall apt apt-get 2>/dev/null || true
sudo rm /var/lib/apt/lists/lock 2>/dev/null || true
sudo rm /var/cache/apt/archives/lock 2>/dev/null || true
sudo rm /var/lib/dpkg/lock* 2>/dev/null || true
sudo dpkg --configure -a 2>/dev/null || true

# ---- Couleurs & Styles ----
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}>>> ${WHITE}[Phase 0] ${BOLD}Purification du Système & Préparation...${NC}"

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
cat <<EOF | sudo tee /etc/netplan/01-network-manager-all.yaml > /dev/null
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
curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify-new.gpg
curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify-old.gpg
echo "deb [arch=amd64] https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null

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
sudo apt install -y build-essential git curl wget cmake pkg-config unzip p7zip-full htop vim nano pipx zsh gamemode software-properties-common ca-certificates gcc g++ make file

echo -e "    ${WHITE}✅ Phase 0 Terminée.${NC}"
