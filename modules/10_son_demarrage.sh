#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 10_son_demarrage.sh
# ==============================================================================
# Phase: 10 - Son d'ouverture de session ROG
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 10 Installation du Son de Démarrage ROG${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"
run_action "installer sox, libsox-fmt-all et sound-theme-freedesktop" sudo apt install -y sox libsox-fmt-all sound-theme-freedesktop >/dev/null 2>&1 || true

AUTOSTART_DIR="$USER_HOME/.config/autostart"
run_action "créer le dossier d'autostart $AUTOSTART_DIR" sudo -u "$REAL_USER" mkdir -p "$AUTOSTART_DIR"

if is_dry_run; then
    log_simu "écrirait le raccourci autostart $AUTOSTART_DIR/mados-login-sound.desktop"
else
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
fi

    # ---- NOUVEAU : Salut Vocal IA ----
    echo -e "    ${GRAY}├─ Injection de l'Accueil Vocal IA MadOS...${NC}"
    run_action "installer speech-dispatcher" sudo apt install -y speech-dispatcher 2>/dev/null || true

    # Script de bienvenue vocal
    if is_dry_run; then
        log_simu "écrirait et rendrait exécutable $USER_HOME/Documents/mados_welcome.sh"
    else
        cat <<EOF | sudo -u "$REAL_USER" tee "$USER_HOME/Documents/mados_welcome.sh" >/dev/null
#!/bin/bash
sleep 5
spd-say -v fr-fr -r -20 "MadOS 3.5 Engagé. Puissance au maximum. Bienvenue Maître \$(whoami)."
EOF
        sudo chmod +x "$USER_HOME/Documents/mados_welcome.sh" || true
    fi

    # Ajout au démarrage
    run_action "créer le dossier d'autostart $USER_HOME/.config/autostart" sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/autostart"
    if is_dry_run; then
        log_simu "écrirait et attribuerait la propriété du raccourci $USER_HOME/.config/autostart/mados-voice.desktop"
    else
        cat <<EOF | sudo -u "$REAL_USER" tee "$USER_HOME/.config/autostart/mados-voice.desktop" >/dev/null
[Desktop Entry]
Type=Application
Exec=bash $USER_HOME/Documents/mados_welcome.sh
Hidden=false
NoDisplay=false
Name=MadOS Voice Greeting
EOF
        sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/autostart/mados-voice.desktop" || true
    fi

    echo -e "    ${CYAN}✅ [SUCCÈS] Son de démarrage et Salut Vocal MadOS configurés.${NC}"
echo -e "    ${GRAY}✅ [SUCCÈS] Effet audio d'ouverture de session ajouté.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 10 Terminée.${NC}"
