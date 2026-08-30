#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 36_obs_nvenc_streaming.sh
# ==============================================================================
# Phase: 36 - OBS Streamer-Ready (Pack Performance RTX NVENC)
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🎥 ${WHITE}${BOLD}Phase 36 Déploiement du Pack Streaming MadOS (Pack OBS RTX)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation de OBS Studio
echo -e "    ${WHITE}├─ [SYSTEM] Injection de OBS Studio (Version Récente)...${NC}"
if is_dry_run; then
    log_simu "ajouterait le PPA obsproject/obs-studio, ferait apt update et installerait obs-studio, ffmpeg, v4l2loopback-dkms et les headers du noyau"
else
    sudo add-apt-repository ppa:obsproject/obs-studio -y 2>/dev/null || true
    sudo apt update -q || true
    # Installation des headers requis pour la compilation du module v4l2loopback (Virtual Cam)
    sudo apt install -y "linux-headers-$(uname -r)" 2>/dev/null || true
    sudo apt install -y obs-studio ffmpeg || true

    # v4l2loopback (camera virtuelle) est un module DKMS : il doit se compiler
    # contre CHAQUE noyau installe. Or MadOS pose un noyau XanMod de pointe, et
    # la version du depot Ubuntu peut ne pas encore le supporter. Mesure en VM
    # avec XanMod 7.2 et v4l2loopback 0.15.0 :
    #     v4l2loopback.c:2337: error: too few arguments to function call
    #     v4l2loopback.c:2904: call to undeclared function 'setup_timer'
    # Le paquet restait alors en etat "iF" (installe, configuration echouee),
    # ce qui fait echouer TOUTES les operations apt suivantes. On verifie donc,
    # et on nettoie franchement plutot que de laisser le systeme casse.
    if sudo apt install -y v4l2loopback-dkms 2>/dev/null; then
        echo -e "    ${GRAY}├─ Caméra virtuelle (v4l2loopback) installée.${NC}"
    else
        ETAT=$(dpkg-query -W -f='${db:Status-Abbrev}' v4l2loopback-dkms 2>/dev/null | tr -d ' ')
        if [ -n "$ETAT" ] && [ "$ETAT" != "ii" ]; then
            echo -e "    ${YELLOW}⚠️  v4l2loopback ne compile pas contre le noyau installé.${NC}"
            echo -e "    ${GRAY}    Cause probable : le noyau XanMod est plus récent que la version${NC}"
            echo -e "    ${GRAY}    du module dans les dépôts. Le paquet est retiré pour ne pas${NC}"
            echo -e "    ${GRAY}    laisser APT dans un état cassé.${NC}"
            echo -e "    ${GRAY}    Conséquence : pas de caméra virtuelle OBS pour l'instant.${NC}"
            sudo apt-get purge -y v4l2loopback-dkms >/dev/null 2>&1 || true
            sudo dpkg --configure -a >/dev/null 2>&1 || true
        fi
    fi
fi

# 2. Injection du profil de performance RTX
echo -e "    ${WHITE}├─ [CONFIG] Calibration des profils d'encodage NVENC (Max Quality)...${NC}"
run_action "créerait le dossier de profil OBS MadOS_Stream" sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/obs-studio/basic/profiles/MadOS_Stream" || true

# Création du fichier de config MadOS_Stream profil
if is_dry_run; then
    log_simu "écrirait le profil OBS MadOS_Stream (NVENC) dans $USER_HOME/.config/obs-studio/basic/profiles/MadOS_Stream/basic.ini"
else
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
fi

# 3. Création du raccourci Bureau MadStream
echo -e "    ${WHITE}├─ [UI] Création de l'icône 'MadStream' sur le Bureau...${NC}"
if is_dry_run; then
    log_simu "créerait le raccourci MadStream_OBS.desktop dans $USER_HOME/.local/share/applications et sur le Bureau"
else
    # S'assurer que le dossier des raccourcis existe
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
    chmod +x "$USER_HOME/.local/share/applications/MadStream_OBS.desktop" 2>/dev/null || true

    # Le raccourci Bureau annonce n existait pas : le .desktop etait ecrit dans
    # .local/share/applications, puis chmod et gio ciblaient ~/Desktop. On le
    # copie donc reellement sur le bureau, en gerant Desktop ET Bureau (locale FR).
    for d in "Desktop" "Bureau"; do
        if [ -d "$USER_HOME/$d" ]; then
            sudo cp "$USER_HOME/.local/share/applications/MadStream_OBS.desktop" "$USER_HOME/$d/MadStream_OBS.desktop"
            sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/$d/MadStream_OBS.desktop"
            sudo chmod +x "$USER_HOME/$d/MadStream_OBS.desktop"
            command -v gio >/dev/null 2>&1 && sudo -u "$REAL_USER" gio set "$USER_HOME/$d/MadStream_OBS.desktop" metadata::trusted true 2>/dev/null || true
        fi
    done
fi

echo -e "    ${CYAN}✅ [SUCCÈS] OBS Studio est configuré en mode 'E-Sport Stream'. Votre RTX est prête à diffuser !${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 36 Terminée.${NC}"
