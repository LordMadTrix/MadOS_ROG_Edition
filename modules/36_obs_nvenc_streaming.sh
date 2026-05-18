#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 36_obs_nvenc_streaming.sh
# ==============================================================================
# Phase: 36 - OBS Streamer-Ready (Pack Performance RTX NVENC)
# ==============================================================================

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'


export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🎥 ${WHITE}${BOLD}Phase 36 : Déploiement du Pack Streaming MadOS v4.0 (Pack OBS RTX)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation de OBS Studio
echo -e "    ${WHITE}├─ [SYSTEM] Injection de OBS Studio (Version Récente)...${NC}"
sudo add-apt-repository ppa:obsproject/obs-studio -y 2>/dev/null || true
sudo apt update -q || true
# Installation des headers requis pour la compilation du module v4l2loopback (Virtual Cam)
sudo apt install -y linux-headers-$(uname -r) 2>/dev/null || true
sudo apt install -y obs-studio ffmpeg v4l2loopback-dkms || true

# 2. Injection du profil de performance RTX
echo -e "    ${WHITE}├─ [CONFIG] Calibration des profils d'encodage NVENC (Max Quality)...${NC}"
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/obs-studio/basic/profiles/MadOS_Stream" || true

# Création du fichier de config MadOS_Stream profil
cat <<'EOF' | sudo -u "$REAL_USER" tee "$USER_HOME/.config/obs-studio/basic/profiles/MadOS_Stream/basic.ini" >/dev/null
[General]
Name=MadOS_Stream

[Video]
BaseCX=1920
BaseCY=1080
OutputCX=1920
OutputCY=1080
FPSType=0
FPSCommon=60

[Output]
Mode=Advanced

[AdvOut]
TrackIndex=1
RecType=Standard
RecFormat=mkv
RecEncoder=ffmpeg_nvenc
RecRescale=false
RecTracks=1
Encoder=ffmpeg_nvenc

[NVENC]
RateControl=CBR
Bitrate=6000
Quality=p7
Tuning=lowlatency
Multipass=fullres
Profile=high
Lookahead=true
PsychoVisualTuning=true
EOF

# 3. Création du raccourci Bureau MadStream
echo -e "    ${WHITE}├─ [UI] Création de l'icône 'MadStream' sur le Bureau...${NC}"
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.local/share/applications"
    cat << EOF | sudo -u "$REAL_USER" tee "$USER_HOME/.local/share/applications/MadStream_OBS.desktop" > /dev/null
[Desktop Entry]
Name=MadStream (OBS RTX)
Comment=Lancer OBS avec les presets MadOS RTX
Exec=obs
Icon=obs
Terminal=false
Type=Application
Categories=AudioVideo;Recorder;
EOF
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/Desktop" "$USER_HOME/Bureau" 2>/dev/null || true
    cp "$USER_HOME/.local/share/applications/MadStream_OBS.desktop" "$USER_HOME/Desktop/" 2>/dev/null || true
    cp "$USER_HOME/.local/share/applications/MadStream_OBS.desktop" "$USER_HOME/Bureau/" 2>/dev/null || true
    chmod +x "$USER_HOME/Desktop/MadStream_OBS.desktop" "$USER_HOME/Bureau/MadStream_OBS.desktop" 2>/dev/null || true

if command -v gio &>/dev/null; then
    sudo -u "$REAL_USER" gio set "$USER_HOME/Desktop/MadStream_OBS.desktop" metadata::trusted true 2>/dev/null || true
    sudo -u "$REAL_USER" gio set "$USER_HOME/Bureau/MadStream_OBS.desktop" metadata::trusted true 2>/dev/null || true
fi

echo -e "    ${CYAN}✅ [SUCCÈS] OBS Studio est configuré en mode 'E-Sport Stream'. Votre RTX est prête à diffuser !${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 36 Terminée.${NC}"
