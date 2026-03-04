#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 10_son_demarrage.sh
# ==============================================================================
# Phase: 10 - Son d'ouverture de session ROG
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

REAL_USER=${SUDO_USER:-$USER}

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 10 Installation du Son de Démarrage ROG${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"
sudo apt install -y sox libsox-fmt-all sound-theme-freedesktop >/dev/null 2>&1 || true

AUTOSTART_DIR="/home/$REAL_USER/.config/autostart"
sudo -u "$REAL_USER" mkdir -p "$AUTOSTART_DIR"

cat <<'EOF' | sudo -u "$REAL_USER" tee "$AUTOSTART_DIR/mados-login-sound.desktop" >/dev/null
[Desktop Entry]
Name=MadOS Boot Sound
Comment=Joue un son au lancement du plasma
Exec=sh -c "paplay /usr/share/sounds/freedesktop/stereo/desktop-login.oga"
Icon=audio-volume-high
Terminal=false
Type=Application
X-KDE-AutostartScript=true
EOF

echo -e "    ${GRAY}✅ [SUCCÈS] Effet audio d'ouverture de session ajouté.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 10 Terminée.${NC}"
