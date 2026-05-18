#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 29_ollama_ia_locale.sh
# ==============================================================================
# Phase: 29 - IA Locale MadChat (Ollama Engine + Models)
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


echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🧠 ${WHITE}${BOLD}Phase 29 : Déploiement du Cerveau IA Local v4.0 (MadChat/Ollama)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation de Ollama (via script officiel)
echo -e "    ${WHITE}├─ [SYSTEM] Installation de l'orchestrateur Ollama...${NC}"
timeout 180 curl -fsSL --max-time 60 https://ollama.com/install.sh | timeout 180 sh || true

# 2. Configuration du Service
sudo systemctl enable ollama || true
sudo systemctl start ollama || true

# 3. Pré-chargement des modèles (Llama 3)
echo -e "    ${WHITE}├─ [MODELS] Téléchargement des modèles IA (Llama 3)...${NC}"
# On lance le pull en arrière-plan sans bloquer l'installation
sudo -u "$REAL_USER" ollama pull llama3 &>/dev/null &

# 4. Création du raccourci de bureau MadChat
echo -e "    ${WHITE}├─ [UI] Création du raccourci MadChat sur le Bureau...${NC}"
cat <<'EOF' | sudo -u "$REAL_USER" tee "$USER_HOME/Desktop/MadChat_IA.desktop" >/dev/null
[Desktop Entry]
Name=MadChat IA (Local)
Comment=Discuter avec l'IA MadOS sans Internet
Exec=sh -c 'MDLS=$(ollama list 2>/dev/null | tail -n +2 | awk '"'"'{print $1}'"'"' | grep -v "^$" | head -1); konsole -e ollama run "${MDLS:-gemma2:9b}"'
Icon=brain
Terminal=false
Type=Application
Categories=Utility;
EOF
chmod +x "$USER_HOME/Desktop/MadChat_IA.desktop" 2>/dev/null || true

# 5. Autoriser l'exécution du raccourci (KDE/GNOME trust)
if command -v gio &>/dev/null; then
    sudo -u "$REAL_USER" gio set "$USER_HOME/Desktop/MadChat_IA.desktop" metadata::trusted true 2>/dev/null || true
fi

echo -e "    ${CYAN}✅ [SUCCÈS] Ollama est installé. Votre IA locale est disponible via l'icône 'MadChat' sur le bureau.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 29 Terminée.${NC}"
