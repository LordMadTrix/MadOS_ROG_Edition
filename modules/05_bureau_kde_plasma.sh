#!/bin/bash
# ==========================================
# MadOS ROG V2 - 05_bureau_kde_plasma.sh
# ==========================================
# Phase: 5 - KDE Plasma Desktop & Élimination Bloatware
# ==========================================


export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# ---- Couleurs & Styles ----
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "${RED}>>> ${WHITE}[Phase 5] ${BOLD}Déploiement du Bureau KDE Plasma...${NC}"

# PPA Plasma 6
if ! grep -r "kubuntu-ppa/backports" /etc/apt/sources.list.d/ &>/dev/null; then
    sudo add-apt-repository ppa:kubuntu-ppa/backports -y > /dev/null 2>&1 || true
    sudo add-apt-repository ppa:kubuntu-ppa/backports-extra -y > /dev/null 2>&1 || true
    sudo apt update -q
fi

echo "sddm shared/default-x-display-manager select sddm" | sudo debconf-set-selections
echo "gdm3 shared/default-x-display-manager select sddm" | sudo debconf-set-selections

# Installation KDE
echo -e "    ${WHITE}├─ [BUREAU] Compilation KDE Plasma Desktop 6...${NC}"
sudo apt install -y kubuntu-desktop kde-plasma-desktop plasma-workspace plasma-nm plasma-pa plasma-systemmonitor kde-standard dolphin konsole kate ark gwenview spectacle kcalc partitionmanager >/dev/null 2>&1

echo -e "    ${WHITE}├─ [TRADUCTION] Conversion Locale vers Français...${NC}"
sudo apt install -y language-pack-fr language-pack-gnome-fr language-pack-kde-fr hunspell-fr >/dev/null 2>&1
sudo update-locale LANG=fr_FR.UTF-8 LC_MESSAGES=fr_FR.UTF-8 2>/dev/null || true

# Config SDDM
echo -e "    ${WHITE}├─ [CONNECT] Serveur de Connexion SDDM...${NC}"
sudo apt install -y sddm sddm-theme-breeze
sudo systemctl disable gdm3 lightdm xdm 2>/dev/null || true
sudo systemctl enable sddm 2>/dev/null || true

SDDM_CONF="/etc/sddm.conf.d/mados-sddm.conf"
sudo mkdir -p /etc/sddm.conf.d/
cat <<'SDDM_EOF' | sudo tee "$SDDM_CONF" >/dev/null
[Theme]
Current=breeze
[Autologin]
Relogin=false
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
[X11]
ServerPath=/usr/bin/X
ServerArguments=-nolisten tcp
EnableHiDPI=true
SDDM_EOF

# Wayland env pour root & user
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config"
cat <<'ENV_EOF' | sudo -u "$REAL_USER" tee -a "$USER_HOME/.profile" >/dev/null
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland
export MOZ_ENABLE_WAYLAND=1
ENV_EOF

# Nettoyage GNOME / FIrefox Snap
echo -e "\n    ${RED}>>> ${WHITE}[NETTOYAGE] ${BOLD}Désintégration de GNOME, Firefox (Snap) et du Démon Snapd...${NC}"
sudo apt purge -y ubuntu-desktop gnome-shell gnome-control-center gnome-software gdm3 2>/dev/null || true
sudo snap remove --purge firefox 2>/dev/null || true
sudo apt-get purge -y firefox snapd 2>/dev/null || true
sudo apt-get autoremove -y --purge > /dev/null 2>&1 || true
sudo apt-get clean > /dev/null 2>&1 || true

echo -e "    ${WHITE}✅ Phase 5 Terminée.${NC}"
