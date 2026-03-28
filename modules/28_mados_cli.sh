#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 28_mados_cli.sh
# ==============================================================================
# Phase: 28 - Installation du Wrapper CLI 'mados'
# ==============================================================================

# Variables de Couleurs
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
BOLD='\033[1m'

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 28 Déploiement de l'Utilitaire CLI 'mados'${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# Détection des sources
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOLS_DIR="$PROJECT_ROOT/tools"

# Dossier applicatif permanent pour MadOS
sudo mkdir -p /opt/mados-rog || true

if [ -f "$TOOLS_DIR/mados.sh" ]; then
    echo -e "    ${GRAY}├─ Installation vers /usr/local/bin/mados...${NC}"
    sudo cp "$TOOLS_DIR/mados.sh" /usr/local/bin/mados || true
    sudo chmod +x /usr/local/bin/mados || true
    
    # Copie locale des ressources pour que 'mados' fonctionne hors-ligne/hors-montage
    echo -e "    ${GRAY}├─ Cache des modules vers /opt/mados-rog/...${NC}"
    sudo cp -r "$PROJECT_ROOT/modules" /opt/mados-rog/ 2>/dev/null || true
    sudo cp -r "$PROJECT_ROOT/lib" /opt/mados-rog/ 2>/dev/null || true
    sudo cp -r "$PROJECT_ROOT/assets" /opt/mados-rog/ 2>/dev/null || true
    
    echo -e "    ${GRAY}├─ Configuration des alias système...${NC}"
    REAL_USER=${SUDO_USER:-$USER}
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    # Ajout d'alias pour Bash et Zsh
    for rc in ".bashrc" ".zshrc"; do
        if [ -f "$USER_HOME/$rc" ]; then
            if ! grep -q "alias mados=" "$USER_HOME/$rc"; then
                echo "alias mados='sudo /usr/local/bin/mados'" | sudo -u "$REAL_USER" tee -a "$USER_HOME/$rc" > /dev/null
            fi
        fi
    done

    # Installation de l'auto-complétion Bash
    if [ -f "$TOOLS_DIR/mados_completion.sh" ]; then
        sudo cp "$TOOLS_DIR/mados_completion.sh" /etc/bash_completion.d/mados
        sudo chmod +r /etc/bash_completion.d/mados
    fi

    echo -e "    ${GREEN}✓ Utilitaire 'mados' et auto-complétion installés !${NC}"
else
    # Fallback si on est dans un dossier sans tools/ (ex: module lancé en solo depuis un autre dossier)
    echo -e "    ${YELLOW}⚠️  Avertissement: Source tools/mados.sh non trouvée localement.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 28 Terminée.${NC}"
