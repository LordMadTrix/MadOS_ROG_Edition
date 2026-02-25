#!/bin/bash
# ==========================================
# MadOS ROG V2.3 - 12_mangohud_rog.sh
# ==========================================
# Phase: 12 - Profil MangoHud ROG & GOverlay
# ==========================================

REAL_USER=${SUDO_USER:-$USER}

echo -e "${RED}>>> ${WHITE}[Phase 12] ${BOLD}Génération du Profil MangoHud ROG Edition...${NC}"

# Installation de GOverlay si non présent
sudo apt install -y goverlay || true

# Création de la configuration MangoHud
MANGO_DIR="/home/$REAL_USER/.config/MangoHud"
sudo -u "$REAL_USER" mkdir -p "$MANGO_DIR"

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

echo -e "    ${GRAY}✅ [SUCCÈS] Fichier MangoHud.conf généré aux couleurs ROG.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 12 Terminée.${NC}"
