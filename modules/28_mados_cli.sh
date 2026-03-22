#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 28_mados_cli.sh
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOLS_DIR="$PROJECT_ROOT/tools"

if [ -f "$TOOLS_DIR/mados.sh" ]; then
    echo -e "    ${GRAY}├─ Installation vers /usr/local/bin/mados...${NC}"
    sudo cp "$TOOLS_DIR/mados.sh" /usr/local/bin/mados
    sudo chmod +x /usr/local/bin/mados
    
    # Création du dossier applicatif permanent pour les ressources CLI
    sudo mkdir -p /opt/mados-rog
    sudo cp -r "$PROJECT_ROOT/modules" /opt/mados-rog/
    sudo cp -r "$PROJECT_ROOT/lib" /opt/mados-rog/
    sudo cp -r "$PROJECT_ROOT/assets" /opt/mados-rog/
    
    echo -e "    ${GRAY}├─ Configuration des alias système...${NC}"
    # Ajout d'alias pour tous les utilisateurs (ou au moins le courant)
    REAL_USER=${SUDO_USER:-$USER}
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    if [ -f "$USER_HOME/.zshrc" ]; then
        if ! grep -q "alias mados=" "$USER_HOME/.zshrc"; then
            echo "alias mados='sudo /usr/local/bin/mados'" | sudo -u "$REAL_USER" tee -a "$USER_HOME/.zshrc" > /dev/null
        fi
    fi
    if [ -f "$USER_HOME/.bashrc" ]; then
        if ! grep -q "alias mados=" "$USER_HOME/.bashrc"; then
            echo "alias mados='sudo /usr/local/bin/mados'" | sudo -u "$REAL_USER" tee -a "$USER_HOME/.bashrc" > /dev/null
        fi
    fi

    # Installation de l'auto-complétion Bash
    if [ -f "$TOOLS_DIR/mados_completion.sh" ]; then
        sudo cp "$TOOLS_DIR/mados_completion.sh" /etc/bash_completion.d/mados
        sudo chmod +r /etc/bash_completion.d/mados
    fi

    echo -e "    ${GREEN}✓ Utilitaire 'mados' et auto-complétion installés !${NC}"
    echo -e "    ${GRAY}Usage: mados help | mados shift game | mados check${NC}"
else
    echo -e "    ${RED}❌ [ERREUR] Erreur: Source tools/mados.sh non trouvée.${NC}"
    exit 1
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 28 Terminée.${NC}"
