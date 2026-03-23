#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 05_bureau_gnome.sh
# ==============================================================================
# Phase: 5 - GNOME Desktop (Next / 50 Edition) & E-Sport Tuning
# ==============================================================================

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 5 Déploiement du Bureau GNOME (E-Sport Edition)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation GNOME
echo -e "    ${WHITE}├─ [BUREAU] Injection de GNOME Desktop & Shell...${NC}"
sudo apt update -q
sudo DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-desktop gnome-shell gnome-control-center gnome-terminal gnome-software gdm3 nautilus eog gnome-system-monitor

echo -e "    ${WHITE}├─ [TRADUCTION] Conversion Locale vers Français...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt install -y language-pack-fr language-pack-gnome-fr hunspell-fr
sudo update-locale LANG=fr_FR.UTF-8 LC_MESSAGES=fr_FR.UTF-8 2>/dev/null || true

# 2. OPTIMISATIONS E-SPORT & RTX (0% LATENCE)
echo -e "    ${WHITE}├─ [TWEAK] Désactivation des animations GNOME (Input Lag minimal)...${NC}"
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.desktop.interface enable-animations false
echo -e "    ${WHITE}├─ [TWEAK] Activation Variable Refresh Rate (VRR) pour RTX...${NC}"
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.mutter experimental-features "['variable-refresh-rate', 'scale-monitor-framebuffer']"
echo -e "    ${WHITE}├─ [TWEAK] Forcer le profil Energie sur PERFORMANCE...${NC}"
sudo apt install -y power-profiles-daemon 2>/dev/null || true
sudo powerprofilesctl set performance 2>/dev/null || true

# 3. CONFIGURATION ESTHÉTIQUE "WINDOWS-STYLE" ROG
echo -e "    ${WHITE}├─ [TWEAK] Sculpture du Bureau GNOME (Windows-Style)...${NC}"
# Basculer la barre (Dock) vers le BAS et en faire un panneau horizontal
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.8

# Appliquer le Thème Sombre & l'Accent Rouge (Ubuntu Modern)
echo -e "    ${WHITE}├─ [TWEAK] Injection de l'ADN Rouge MadOS...${NC}"
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.desktop.interface accent-color 'red' 2>/dev/null || true

# Désactivation des services lourds (Background Indexing)
echo -e "    ${WHITE}├─ [TWEAK] Mise en sommeil des services Tracker3 (CPU Save)...${NC}"
sudo -u "$REAL_USER" dbus-launch gsettings set org.gnome.desktop.search-providers disabled "['org.gnome.Nautilus.desktop', 'org.gnome.Contacts.desktop', 'org.gnome.Documents.desktop']"
sudo -u "$REAL_USER" systemctl --user mask tracker-miner-fs-3.service tracker-extract-3.service 2>/dev/null || true

# 3. CONFIGURATION SERVEUR D'AFFICHAGE
echo -e "    ${WHITE}├─ [CONNECT] Serveur de Connexion GDM3 (Wayland par défaut)...${NC}"
sudo systemctl disable sddm lightdm xdm 2>/dev/null || true
echo "gdm3 shared/default-x-display-manager select gdm3" | sudo debconf-set-selections
sudo systemctl enable gdm3 2>/dev/null || true

# 4. OPTIMISATIONS NVIDIA WAYLAND POUR GNOME
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config"
cat <<'ENV_EOF' | sudo -u "$REAL_USER" tee -a "$USER_HOME/.profile" >/dev/null
export MOZ_ENABLE_WAYLAND=1
export GDK_BACKEND=wayland
export CLUTTER_BACKEND=wayland
export __GL_GSYNC_ALLOWED=1
export __GL_VRR_ALLOWED=1
export MUTTER_DEBUG_ENABLE_ATOMIC_KMS=1
ENV_EOF

# 5. NETTOYAGE KDE
echo -e "\n    ${RED}>>> ${WHITE}[NETTOYAGE] ${BOLD}Désinstallation des résidus KDE Plasma...${NC}"
sudo apt purge -y kubuntu-desktop kde-plasma-desktop sddm 2>/dev/null || true
sudo apt-get autoremove -y --purge > /dev/null 2>&1 || true

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 5 (GNOME E-SPORT) Terminée.${NC}"
