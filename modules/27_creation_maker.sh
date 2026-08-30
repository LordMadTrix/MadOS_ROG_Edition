#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 27_creation_maker.sh
# ==============================================================================
# Phase: 27 - Station Maker & IA
# Intègre OrcaSlicer (Creality K1), LaserWeb (TwoTrees TTS) et optimise l'IA OpenClaw
# pour l'assistance à l'impression 3D et la gravure Laser.
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

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 27 Station Maker (Imprimante 3D & Graveur Laser)                 ${NC}${RED}║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Droits USB (Crucial pour Klipper/LaserGRBL)
echo -e "    ${WHITE}├─ [SYSTÈME] Configuration des accès ports USB / Séries (dialout, tty)...${NC}"
run_action "ajouterait $REAL_USER au groupe dialout" sudo usermod -aG dialout "$REAL_USER" || true
run_action "ajouterait $REAL_USER au groupe tty" sudo usermod -aG tty "$REAL_USER" || true
run_action "ajouterait $REAL_USER au groupe uucp" sudo usermod -aG uucp "$REAL_USER" 2>/dev/null || true

# 2. Utilitaires de base
echo -e "    ${WHITE}├─ [PRÉREQUIS] Installation des bibliothèques de communication matérielle...${NC}"
run_action "installerait curl wget unzip p7zip-full python3 python3-pip python3-venv libfuse2" sudo apt install -y curl wget unzip p7zip-full python3 python3-pip python3-venv libfuse2 > /dev/null 2>&1 || true

# 3. Création du répertoire AppImages pour les outils Maker
MAKER_DIR="$USER_HOME/Applications/Maker"
run_action "créerait le répertoire $MAKER_DIR" sudo -u "$REAL_USER" mkdir -p "$MAKER_DIR" || true

# 4. Impression 3D (Gestion Globale : OrcaSlicer, Cura, PrusaSlicer)
echo -e "    ${WHITE}├─ [IMPRESSION 3D] Installation des Slicers Majeurs (K1, Marlin, RepRap)...${NC}"

# OrcaSlicer (Klipper / K1)
ORCA_URL=$(curl -s https://api.github.com/repos/SoftFever/OrcaSlicer/releases/latest | grep "browser_download_url.*Ubuntu.*\.AppImage\"" | cut -d '"' -f 4 | head -n 1)
if [ -n "$ORCA_URL" ]; then
    if is_dry_run; then
        log_simu "téléchargerait OrcaSlicer ($ORCA_URL) dans $MAKER_DIR et créerait son raccourci .desktop"
    else
        sudo -u "$REAL_USER" wget -q --show-progress "$ORCA_URL" -O "$MAKER_DIR/OrcaSlicer.AppImage" || true
        sudo chmod +x "$MAKER_DIR/OrcaSlicer.AppImage" || true
        sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.local/share/applications" || true
        cat << EOF | sudo -u "$REAL_USER" tee "$USER_HOME/.local/share/applications/orcaslicer.desktop" > /dev/null
[Desktop Entry]
Name=OrcaSlicer (Rapide / Klipper)
Comment=Trancheur 3D optimisé pour Klipper et Creality K1
Exec=$MAKER_DIR/OrcaSlicer.AppImage
Icon=printer
Terminal=false
Type=Application
Categories=Graphics;3DGraphics;Engineering;
EOF
        # Copie sur le Bureau
        cp "$USER_HOME/.local/share/applications/orcaslicer.desktop" "$USER_HOME/Desktop/" 2>/dev/null || true
        chmod +x "$USER_HOME/Desktop/orcaslicer.desktop" 2>/dev/null || true
        echo -e "    ${GRAY}    ├─ OrcaSlicer configuré avec succès !${NC}"
    fi
fi

# PrusaSlicer (Global / Très stable)
PRUSA_URL=$(curl -s https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest | grep "browser_download_url.*linux-x64-GTK3.*\.AppImage\"" | cut -d '"' -f 4 | head -n 1)
if [ -n "$PRUSA_URL" ]; then
    if is_dry_run; then
        log_simu "téléchargerait PrusaSlicer ($PRUSA_URL) dans $MAKER_DIR et créerait son raccourci .desktop"
    else
        sudo -u "$REAL_USER" wget -q --show-progress "$PRUSA_URL" -O "$MAKER_DIR/PrusaSlicer.AppImage" || true
        sudo chmod +x "$MAKER_DIR/PrusaSlicer.AppImage" || true
        sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.local/share/applications" || true
        cat << EOF | sudo -u "$REAL_USER" tee "$USER_HOME/.local/share/applications/prusaslicer.desktop" > /dev/null
[Desktop Entry]
Name=PrusaSlicer (Universel)
Comment=Trancheur 3D universel et très stable
Exec=$MAKER_DIR/PrusaSlicer.AppImage
Icon=printer
Terminal=false
Type=Application
Categories=Graphics;3DGraphics;Engineering;
EOF
        # Copie sur le Bureau
        cp "$USER_HOME/.local/share/applications/prusaslicer.desktop" "$USER_HOME/Desktop/" 2>/dev/null || true
        chmod +x "$USER_HOME/Desktop/prusaslicer.desktop" 2>/dev/null || true
        echo -e "    ${GRAY}    ├─ PrusaSlicer configuré avec succès !${NC}"
    fi
fi

# UltiMaker Cura (Le plus populaire / Historique)
echo -e "    ${GRAY}    ├─ Installation d'UltiMaker Cura (Dépôts)...${NC}"
run_action "installerait UltiMaker Cura" sudo apt install -y cura >/dev/null 2>&1 || true
echo -e "    ${GRAY}    └─ Suite d'Impression 3D Globale parée au lancement.${NC}"

# 5. Gravure Laser (TwoTrees TTS 55 Pro) -> LaserWeb 4
echo -e "    ${WHITE}├─ [GRAVURE LASER] Préparation pour TwoTrees TTS-55 Pro (LaserWeb)...${NC}"
echo -e "    ${GRAY}    Création du raccourci vers LightBurn (Logiciel Pro recommandé)...${NC}"

# S'assurer que le dossier des raccourcis existe
if is_dry_run; then
    log_simu "créerait le raccourci $USER_HOME/.local/share/applications/lightburn-download.desktop (lien vers LightBurn)"
else
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.local/share/applications" 2>/dev/null || true

    cat << EOF | sudo -u "$REAL_USER" tee "$USER_HOME/.local/share/applications/lightburn-download.desktop" > /dev/null
[Desktop Entry]
Name=Télécharger LightBurn (Laser)
Comment=Lien vers le logiciel pro de gravure laser LightBurn (Natifs Linux)
Exec=xdg-open "https://lightburnsoftware.com/pages/trial-version-try-before-you-buy"
Icon=laser
Terminal=false
Type=Application
Categories=Graphics;
EOF
fi

# 6. Intégration IA OpenClaw
echo -e "    ${WHITE}├─ [IA ASSISTANT] Injection des connaissances Maker dans OpenClaw...${NC}"
OC_DIR="$USER_HOME/OpenClaw"
if [ -f "$OC_DIR/.env" ]; then
    # Modifier la directive de l'IA pour qu'elle sache qu'elle gère du matériel Maker
    if is_dry_run; then
        log_simu "injecterait le contexte Maker (G-Code/Klipper/Marlin/Laser) dans $OC_DIR/.env"
    else
        sudo sed -i 's/DEFAULT_SYSTEM_PROMPT="/DEFAULT_SYSTEM_PROMPT="[MAKER MODE ACTIVE: L utilisateur gère un atelier d impression 3D multimarque (Creality K1, Prusa, Marlin, Klipper) via Cura\/OrcaSlicer\/PrusaSlicer, et un graveur laser TwoTrees TTS-55 Pro via Lightburn. Vous êtes son assistant ingénieur en G-Code, calibrage de slicers, et paramètres de découpe laser.] /' "$OC_DIR/.env" 2>/dev/null || true
        echo -e "    ${GRAY}    OpenClaw IA configurée pour le support G-Code et Klipper/Marlin !${NC}"
    fi
else
    echo -e "    ${YELLOW}    OpenClaw non détecté, cette étape est ignorée.${NC}"
fi

echo -e "\n    ${WHITE}✅ [SUCCÈS] Phase 27 Terminée.${NC}\n"
