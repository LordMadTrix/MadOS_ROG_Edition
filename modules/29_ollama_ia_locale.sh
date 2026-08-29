#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 29_ollama_ia_locale.sh
# ==============================================================================
# Phase: 29 - IA Locale MadChat (Ollama Engine + Models)
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🧠 ${WHITE}${BOLD}Phase 29 Déploiement du Cerveau IA Local (MadChat/Ollama)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation de Ollama (via script officiel)
echo -e "    ${WHITE}├─ [SYSTEM] Installation de l'orchestrateur Ollama...${NC}"
if is_dry_run; then
    log_simu "installerait Ollama via le script officiel (curl | sh)"
else
    curl -fsSL https://ollama.com/install.sh | sh
fi

# 2. Configuration du Service
run_action "activer le service ollama" sudo systemctl enable ollama || true
run_action "démarrer le service ollama" sudo systemctl start ollama || true

# 3. Pré-chargement des modèles (Mistral & Llama 3)
echo -e "    ${WHITE}├─ [MODELS] Téléchargement des modèles IA légers (Mistral 7B)...${NC}"
# On lance le pull en arrière-plan sans bloquer l'installation
run_action "télécharger le modèle mistral (ollama pull, arrière-plan)" sudo -u "$REAL_USER" ollama pull mistral &>/dev/null &

# 4. Création du raccourci de bureau MadChat
echo -e "    ${WHITE}├─ [UI] Création du raccourci MadChat...${NC}"
# L'ancienne version ecrivait en dur dans ~/Desktop : en locale francaise
# (imposee par le module 05) ce dossier s'appelle "Bureau" et ~/Desktop n'existe
# pas, donc le raccourci n'apparaissait jamais. Le terminal etait aussi code en
# dur sur konsole, absent sur GNOME.
TERM_CMD="x-terminal-emulator -e"
for t in konsole gnome-terminal xfce4-terminal x-terminal-emulator; do
    if command -v "$t" >/dev/null 2>&1; then
        case "$t" in
            gnome-terminal) TERM_CMD="gnome-terminal --" ;;
            *)              TERM_CMD="$t -e" ;;
        esac
        break
    fi
done

if is_dry_run; then
    log_simu "écrirait le raccourci MadChat_IA.desktop sur le bureau de $REAL_USER (Desktop ou Bureau) et dans le menu applications"
else
    MADCHAT_TMP=$(mktemp)
    cat > "$MADCHAT_TMP" <<EOF
[Desktop Entry]
Name=MadChat IA (Local)
Comment=Discuter avec l'IA MadOS sans Internet
Exec=$TERM_CMD ollama run mistral
Icon=brain
Terminal=false
Type=Application
Categories=Utility;
EOF
    # Toujours dans le menu applications : c'est le seul emplacement garanti.
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.local/share/applications"
    sudo cp "$MADCHAT_TMP" "$USER_HOME/.local/share/applications/MadChat_IA.desktop"
    sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/.local/share/applications/MadChat_IA.desktop"

    for d in "Desktop" "Bureau"; do
        if [ -d "$USER_HOME/$d" ]; then
            sudo cp "$MADCHAT_TMP" "$USER_HOME/$d/MadChat_IA.desktop"
            sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/$d/MadChat_IA.desktop"
            sudo chmod +x "$USER_HOME/$d/MadChat_IA.desktop"
            command -v gio >/dev/null 2>&1 && sudo -u "$REAL_USER" gio set "$USER_HOME/$d/MadChat_IA.desktop" metadata::trusted true 2>/dev/null || true
        fi
    done
    rm -f "$MADCHAT_TMP"
fi

echo -e "    ${CYAN}✅ [SUCCÈS] Ollama est installé. Votre IA locale est disponible via l'icône 'MadChat' sur le bureau.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 29 Terminée.${NC}"
