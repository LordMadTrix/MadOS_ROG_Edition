#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 12_mangohud_rog.sh
# ==============================================================================
# Phase: 12 - Profil MangoHud ROG & GOverlay
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 12 Génération du Profil MangoHud ROG Edition${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# Installation de GOverlay si non présent
run_action "installerait le paquet goverlay" sudo apt install -y goverlay || true

# Création de la configuration MangoHud
MANGO_DIR="$USER_HOME/.config/MangoHud"
run_action "créerait le dossier $MANGO_DIR" sudo -u "$REAL_USER" mkdir -p "$MANGO_DIR"

if is_dry_run; then
    log_simu "écrirait le profil MangoHud.conf (couleurs ROG) dans $MANGO_DIR"
else
cat <<'EOF' | sudo -u "$REAL_USER" tee "$MANGO_DIR/MangoHud.conf" >/dev/null
### MadOS ROG Edition - MangoHud Profile
legacy_layout=false
text_color=FFFFFF
gpu_color=FF0000
cpu_color=FF4500
vram_color=FF0000
ram_color=FF4500
engine_color=FFFFFF
frametime_color=FF0000
background_color=000000
background_alpha=0.6
font_size=20
position=top-left
toggle_hud=Shift_R+F12

cpu_temp
gpu_temp
cpu_mhz
gpu_core_clock
gpu_mem_clock
ram
vram

fps
frametime
frame_timing=1
histogram
EOF
fi

echo -e "    ${GRAY}✅ [SUCCÈS] Fichier MangoHud.conf généré aux couleurs ROG.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 12 Terminée.${NC}"
