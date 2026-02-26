#!/bin/bash
# ==========================================
# MadOS ROG V2.1 - 10_son_demarrage.sh
# ==========================================
# Phase: 10 - Son d'ouverture de session ROG
# ==========================================

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}

echo -e "${RED}>>> ${WHITE}[Phase 10] ${BOLD}Installation du Son de Démarrage ROG...${NC}"
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
