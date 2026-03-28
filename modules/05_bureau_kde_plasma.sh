#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 05_bureau_kde_plasma.sh
# ==============================================================================
# Phase: 5 - KDE Plasma Desktop & Élimination Bloatware
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
export NEEDRESTART_MODE=a

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 5 Déploiement du Bureau KDE Plasma${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

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
sudo DEBIAN_FRONTEND=noninteractive apt install -y kubuntu-desktop kde-plasma-desktop plasma-workspace plasma-session-x11 plasma-nm plasma-pa plasma-systemmonitor kde-standard dolphin konsole kate ark gwenview kde-spectacle kcalc partitionmanager dbus-x11 xserver-xorg

echo -e "    ${WHITE}├─ [TRADUCTION] Conversion Locale vers Français...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt install -y language-pack-fr language-pack-gnome-fr language-pack-kde-fr hunspell-fr
sudo update-locale LANG=fr_FR.UTF-8 LC_MESSAGES=fr_FR.UTF-8 2>/dev/null || true

# Config SDDM
echo -e "    ${WHITE}├─ [CONNECT] Serveur de Connexion SDDM...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt install -y sddm sddm-theme-breeze
sudo systemctl disable gdm3 lightdm xdm 2>/dev/null || true
sudo systemctl enable sddm 2>/dev/null || true

# Détection VM pour forcer X11 (Stabilité VMware)
IS_VM=$(systemd-detect-virt)
SDDM_CONF="/etc/sddm.conf.d/mados-sddm.conf"
sudo mkdir -p /etc/sddm.conf.d/

if [[ "$IS_VM" == "vmware" || "$IS_VM" == "qemu" || "$IS_VM" == "oracle" ]]; then
    echo -e "    ${YELLOW}⚠️  VM Détectée : Forçage du DisplayServer X11 pour la stabilité...${NC}"
    cat <<'SDDM_EOF' | sudo tee "$SDDM_CONF" >/dev/null
[General]
DisplayServer=x11
InputMethod=

[Theme]
Current=breeze

[Autologin]
Relogin=false
Session=plasma
User=mados
SDDM_EOF
else
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
fi

# Wayland env (Optionnel : On laisse le système choisir pour éviter les écrans noirs NVIDIA)
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config"
# On commente les exports forcés pour la stabilité
# export QT_QPA_PLATFORM=wayland
# export GDK_BACKEND=wayland
# export MOZ_ENABLE_WAYLAND=1

# Nettoyage GNOME / FIrefox Snap
echo -e "\n    ${RED}>>> ${WHITE}[NETTOYAGE] ${BOLD}Désintégration de GNOME, Firefox (Snap) et du Démon Snapd...${NC}"
sudo apt purge -y ubuntu-desktop gnome-shell gnome-control-center gnome-software gdm3 2>/dev/null || true
sudo snap remove --purge firefox 2>/dev/null || true
sudo apt-get purge -y firefox snapd 2>/dev/null || true
sudo apt-get autoremove -y --purge > /dev/null 2>&1 || true
sudo apt-get clean > /dev/null 2>&1 || true

# ---- NOUVEAU : Macros-ROG (Raccourcis Clavier MadOS) ----
echo -e "    ${WHITE}├─ [HOTKEYS] Injection des raccourcis clavier MadOS (Macro-ROG)...${NC}"
sudo -u "$REAL_USER" kwriteconfig5 --file "$USER_HOME/.config/kglobalshortcutsrc" --group "khotkeys" --key "{mados_game}" "Meta+Shift+G,none,MadOS Game Mode" 2>/dev/null || true
sudo -u "$REAL_USER" kwriteconfig5 --file "$USER_HOME/.config/kglobalshortcutsrc" --group "khotkeys" --key "{mados_eco}" "Meta+Shift+E,none,MadOS Eco Mode" 2>/dev/null || true
sudo -u "$REAL_USER" kwriteconfig5 --file "$USER_HOME/.config/kglobalshortcutsrc" --group "khotkeys" --key "{mados_stealth}" "Meta+Shift+S,none,MadOS Stealth Mode" 2>/dev/null || true
# ---- NOUVEAU : Rage-Quit Force (Kill Game) ----
sudo -u "$REAL_USER" kwriteconfig5 --file "$USER_HOME/.config/kglobalshortcutsrc" --group "kglobalaccel" --key "Kill Window" "Ctrl+Alt+Backspace,none,Force Kill Current Window" 2>/dev/null || true

# Création du dossier khotkeys si manquant
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.local/share/khotkeys"

# Lancer la prise en compte (Optionnel: nécessite une session active, mais le config file est prêt pour le boot)
sudo -u "$REAL_USER" qdbus org.kde.kglobalaccel /kglobalaccel reconfigure >/dev/null 2>&1 || true

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 5 Terminée.${NC}"
