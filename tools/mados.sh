#!/bin/bash
# ==============================================================================
# MadOS ROG Edition - mados CLI Wrapper
# ==============================================================================
# Usage : mados [subcommand] [args]
# ==============================================================================

# Variables de Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

# Installation Path (détecter si exécuté localement ou installé)
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "/usr/local/bin/mados" ] && INSTALL_DIR="/opt/mados-rog"

# --- Aide ---
show_help() {
    echo -e "${RED}${BOLD}MadOS ROG Edition — Interface CLI v1.0${NC}"
    echo -e "Usage: ${CYAN}mados <commande> [options]${NC}\n"
    echo -e "${BOLD}Commandes Disponibles :${NC}"
    echo -e "  ${GREEN}shift <mode>${NC}     Bascule instantanément de profil (game|eco|dev|balance)"
    echo -e "  ${GREEN}check${NC}            Lance le diagnostic de santé système (Module 25)"
    echo -e "  ${GREEN}update${NC}           Vérifie et applique les mises à jour MadOS"
    echo -e "  ${GREEN}aura <mode>${NC}      Change l'éclairage RGB (rainbow|pulse|static|off)"
    echo -e "  ${GREEN}batt <limit>${NC}     Limite la charge batterie (60|80|100)"
    echo -e "  ${GREEN}ai <start|stop>${NC}  Gère le service OpenClaw IA"
    echo -e "  ${GREEN}gui${NC}              Lance le Centre de Contrôle Graphique"
    echo ""
}

# --- shift ---
do_shift() {
    local mode=$1
    case "$mode" in
        game)
            echo -e "${RED}🚀 Activation Profil GAME...${NC}"
            asusctl profile -P Performance 2>/dev/null
            supergfxctl -m Dedicated 2>/dev/null
            asusctl led-mode static -c ff0000 2>/dev/null
            echo -e "${GREEN}✓ GPU Dédié + Mode Performance + RGB Rouge.${NC}"
            ;;
        eco)
            echo -e "${GREEN}🍃 Activation Profil ECO...${NC}"
            asusctl profile -P Quiet 2>/dev/null
            supergfxctl -m Integrated 2>/dev/null
            asusctl led-mode static -c 000000 2>/dev/null
            asusctl -c 60 2>/dev/null
            echo -e "${GREEN}✓ GPU Intégré + Mode Silencieux + RGB OFF + Limite 60%.${NC}"
            ;;
        dev)
            echo -e "${CYAN}💻 Activation Profil DEV...${NC}"
            asusctl profile -P Balanced 2>/dev/null
            asusctl led-mode static -c 0000ff 2>/dev/null
            echo -e "${GREEN}✓ Mode Balanced + RGB Bleu + Focus IDE.${NC}"
            ;;
        balance|default)
            echo -e "${YELLOW}⚖️ Activation Profil BALANCE...${NC}"
            asusctl profile -P Balanced 2>/dev/null
            supergfxctl -m Hybrid 2>/dev/null
            echo -e "${GREEN}✓ Mode Équilibré + GPU Hybride.${NC}"
            ;;
        *)
            echo -e "${RED}Erreur: Mode inconnu ($mode). Utilisez: game, eco, dev, balance.${NC}"
            exit 1
            ;;
    esac
}

# --- check ---
do_check() {
    local script="$INSTALL_DIR/modules/25_sante_systeme.sh"
    if [ -f "$script" ]; then
        bash "$script"
    else
        echo -e "${RED}Erreur: Module de santé non trouvé dans $INSTALL_DIR${NC}"
    fi
}

# --- update ---
do_update() {
    local script="$INSTALL_DIR/modules/24_mados_update.sh"
    if [ -f "$script" ]; then
        sudo bash "$script"
    else
        echo -e "${RED}Erreur: Module d'update non trouvé dans $INSTALL_DIR${NC}"
    fi
}

# --- Main logic ---
case "$1" in
    shift)  do_shift "${2:-""}" ;;
    check)  do_check ;;
    update) do_update ;;
    aura)   asusctl led-mode "$2" 2>/dev/null ;;
    batt)   asusctl -c "$2" 2>/dev/null ;;
    ai)     systemctl --user "$2" openclaw.service 2>/dev/null ;;
    gui)    python3 "$INSTALL_DIR/assets/mados_cc.py" & ;;
    help|-h|--help) show_help ;;
    *)      show_help ;;
esac
