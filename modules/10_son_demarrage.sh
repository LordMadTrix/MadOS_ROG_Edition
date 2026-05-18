#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 10_son_demarrage.sh
# ==============================================================================
# Phase: 10 - Son d'ouverture de session ROG
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
WHITE='\033[1;37m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 10 : Installation du Son de Démarrage ROG v4.0${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"
sudo apt install -y sox libsox-fmt-all sound-theme-freedesktop >/dev/null 2>&1 || true

AUTOSTART_DIR="$USER_HOME/.config/autostart"
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

    # ---- NOUVEAU : Salut Vocal IA ----
    echo -e "    ${GRAY}├─ Injection de l'Accueil Vocal IA MadOS...${NC}"
    sudo apt install -y speech-dispatcher 2>/dev/null || true
    
    # Script de bienvenue vocal
    cat <<EOF | sudo -u "$REAL_USER" tee "$USER_HOME/Documents/mados_welcome.sh" >/dev/null
#!/bin/bash
sleep 5
spd-say -v fr-fr -r -20 "MadOS 4.0 Engagé. Synchronisation N-T-Sync active. Bienvenue Maître $(whoami)."
EOF
    sudo chmod +x "$USER_HOME/Documents/mados_welcome.sh" || true
    
    # Ajout au démarrage
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/autostart"
    cat <<EOF | sudo -u "$REAL_USER" tee "$USER_HOME/.config/autostart/mados-voice.desktop" >/dev/null
[Desktop Entry]
Type=Application
Exec=bash $USER_HOME/Documents/mados_welcome.sh
Hidden=false
NoDisplay=false
Name=MadOS Voice Greeting
EOF
    sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/autostart/mados-voice.desktop" || true

    echo -e "    ${CYAN}✅ [SUCCÈS] Son de démarrage et Salut Vocal MadOS configurés.${NC}"
echo -e "    ${GRAY}✅ [SUCCÈS] Effet audio d'ouverture de session ajouté.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 10 Terminée.${NC}"
