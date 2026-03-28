#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 29_ollama_ia_locale.sh
# ==============================================================================
# Phase: 29 - IA Locale MadChat (Ollama Engine + Models)
# ==============================================================================

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🧠 ${WHITE}${BOLD}Phase 29 Déploiement du Cerveau IA Local (MadChat/Ollama)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation de Ollama (via script officiel)
echo -e "    ${WHITE}├─ [SYSTEM] Installation de l'orchestrateur Ollama...${NC}"
curl -fsSL https://ollama.com/install.sh | sh

# 2. Configuration du Service
sudo systemctl enable ollama || true
sudo systemctl start ollama || true

# 3. Pré-chargement des modèles (Mistral & Llama 3)
echo -e "    ${WHITE}├─ [MODELS] Téléchargement des modèles IA légers (Mistral 7B)...${NC}"
# On lance le pull en arrière-plan sans bloquer l'installation
sudo -u "$REAL_USER" ollama pull mistral &>/dev/null &

# 4. Création du raccourci de bureau MadChat
echo -e "    ${WHITE}├─ [UI] Création du raccourci MadChat sur le Bureau...${NC}"
cat <<'EOF' | sudo -u "$REAL_USER" tee "$USER_HOME/Desktop/MadChat_IA.desktop" >/dev/null
[Desktop Entry]
Name=MadChat IA (Local)
Comment=Discuter avec l'IA MadOS sans Internet
Exec=konsole -e ollama run mistral
Icon=brain
Terminal=false
Type=Application
Categories=Utility;
EOF
chmod +x "$USER_HOME/Desktop/MadChat_IA.desktop" 2>/dev/null || true

# 5. Autoriser l'exécution du raccourci (KDE/GNOME trust)
if command -v gio &>/dev/null; then
    sudo -u "$REAL_USER" gio set "$USER_HOME/Desktop/MadChat_IA.desktop" metadata::trusted true
fi

echo -e "    ${CYAN}✅ [SUCCÈS] Ollama est installé. Votre IA locale est disponible via l'icône 'MadChat' sur le bureau.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 29 Terminée.${NC}"
