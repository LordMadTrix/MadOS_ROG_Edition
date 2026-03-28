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
    echo -e "${RED}${BOLD}MadOS ROG Edition — Interface CLI v1.3${NC}"
    echo -e "Usage: ${CYAN}mados <commande> [options]${NC}\n"
    echo -e "${BOLD}Commandes Disponibles :${NC}"
    echo -e "  ${GREEN}shift <mode>${NC}     Bascule de profil (game|eco|dev|balance)"
    echo -e "  ${GREEN}check${NC}            Diagnostic santé & Benchmark (Module 25)"
    echo -e "  ${GREEN}update${NC}           Mises à jour MadOS (GitHub)"
    echo -e "  ${GREEN}stealth <on|off>${NC} Mode Discret (Privacy, DNS, Firewall)"
    echo -e "  ${GREEN}night <on|off>${NC}   Mode Night-Rider (Confort Visuel & RGB Minimal)"
    echo -e "  ${GREEN}logs${NC}             Centre de Diagnostic (Installation & Système)"
    echo -e "  ${GREEN}guide${NC}            Pense-Bête Interactif (Cheat Sheet God-Tier)"
    echo -e "  ${GREEN}store <apps>${NC}     Installeur Gamer (steam|heroic|discord|lutris)"
    echo -e "  ${GREEN}aura <mode>${NC}      Éclairage (rainbow|pulse|static|off)"
    echo -e "  ${GREEN}batt <limit>${NC}     Limite batterie (60|80|100)"
    echo -e "  ${GREEN}gui${NC}              Centre de Contrôle Graphique"
    echo ""
}

# --- stealth ---
do_stealth() {
    if [ "$1" == "on" ]; then
        echo -e "${CYAN}🕶️ Activation Mode STEALTH (Privacy Hardened)...${NC}"
        sudo systemctl stop apport.service 2>/dev/null || true
        sudo systemctl disable apport.service 2>/dev/null || true
        # DNS Quad9 via resolved
        sudo mkdir -p /etc/systemd/resolved.conf.d/
        printf "[Resolve]\nDNS=9.9.9.9#dns.quad9.net\nDNSOverTLS=yes\n" | sudo tee /etc/systemd/resolved.conf.d/mados-stealth.conf >/dev/null
        sudo systemctl restart systemd-resolved 2>/dev/null || true
        # Firewall
        sudo ufw --force enable >/dev/null 2>&1 || true
        echo -e "${GREEN}✓ DNS Sécurisé + Télémétrie OFF + Firewall ON.${NC}"
    else
        echo -e "${YELLOW}🔓 Désactivation Mode STEALTH...${NC}"
        sudo rm -f /etc/systemd/resolved.conf.d/mados-stealth.conf 2>/dev/null || true
        sudo systemctl restart systemd-resolved 2>/dev/null || true
        echo -e "${GREEN}✓ Paramètres standards restaurés.${NC}"
    fi
}

# --- store ---
do_store() {
    local app=$1
    echo -e "${CYAN}🛒 MadOS Store — Déploiement de $app...${NC}"
    case "$app" in
        steam)   sudo apt install -y steam-installer 2>/dev/null || true ;;
        heroic)  sudo nala install -y heroic 2>/dev/null || true ;;
        discord) sudo nala install -y discord 2>/dev/null || true ;;
        lutris)  sudo nala install -y lutris 2>/dev/null || true ;;
        *) echo -e "${RED}Option inconnue. Choix: steam, heroic, discord, lutris.${NC}" ;;
    esac
}

# --- shift ---
do_shift() {
    local mode=$1
    case "$mode" in
        game)
            echo -e "${RED}🚀 Activation Profil GAME...${NC}"
            asusctl profile -P Performance 2>/dev/null
            supergfxctl -m Dedicated 1>/dev/null 2>&1
            asusctl led-mode static -c ff0000 2>/dev/null
            echo -e "${GREEN}✓ GPU Dédié + Performance + RGB Rouge.${NC}"
            ;;
        eco)
            echo -e "${GREEN}🍃 Activation Profil ECO...${NC}"
            asusctl profile -P Quiet 2>/dev/null
            supergfxctl -m Integrated 1>/dev/null 2>&1
            asusctl led-mode static -c 000000 2>/dev/null
            echo -e "${GREEN}✓ GPU Intégré + Silencieux + RGB OFF.${NC}"
            ;;
        dev)
            echo -e "${CYAN}💻 Activation Profil DEV...${NC}"
            asusctl profile -P Balanced 2>/dev/null
            asusctl led-mode static -c 0000ff 2>/dev/null
            echo -e "${GREEN}✓ Mode Balanced + RGB Bleu.${NC}"
            ;;
        balance|default)
            echo -e "${YELLOW}⚖️ Activation Profil BALANCE...${NC}"
            asusctl profile -P Balanced 2>/dev/null
            supergfxctl -m Hybrid 1>/dev/null 2>&1
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
    [ -f "$script" ] && bash "$script" || echo -e "${RED}Erreur: Module non trouvé.${NC}"
}

# --- update ---
do_update() {
    local script="$INSTALL_DIR/modules/24_mados_update.sh"
    [ -f "$script" ] && sudo bash "$script" || echo -e "${RED}Erreur: Module non trouvé.${NC}"
}

# --- logs ---
do_logs() {
    echo -e "${CYAN}📂 MadOS Diagnostic Center...${NC}"
    echo -e "--------------------------------------------------------"
    echo -e "${YELLOW}[INSTALL] : /var/log/mados/mados_install.log"
    echo -e "[SYSTÈME] : journalctl -xe${NC}"
    echo -e "--------------------------------------------------------"
    if [ -f "/var/log/mados/mados_install.log" ]; then
        tail -n 20 "/var/log/mados/mados_install.log"
    else
        echo -e "${RED}Log d'installation introuvable.${NC}"
    fi
}

# --- guide (Pense-Bête) ---
do_guide() {
    clear
    echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} 📘 ${WHITE}${BOLD}PENSE-BÊTE MADOS 3.5 — GOD-TIER CHEAT SHEET${NC}             ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${CYAN}${BOLD}[ RACCOURCIS CLAVIER ]${NC}"
    echo -e " 🚀 ${YELLOW}Meta+Shift+G${NC} : Bascule Mode GAME (GPU/Max FPS)"
    echo -e " 🍃 ${YELLOW}Meta+Shift+E${NC} : Bascule Mode ECO (Silencieux)"
    echo -e " 🕶️ ${YELLOW}Meta+Shift+S${NC} : Bascule Mode STEALTH (Privacy)"
    echo -e " 💣 ${YELLOW}Ctrl+Alt+Backspace${NC} : RAGE-QUIT (Kill process freeze)"
    echo -e "\n${CYAN}${BOLD}[ COMMANDES CLI ]${NC}"
    echo -e " ⚡ ${GREEN}mados shift game${NC}   : Mode Brute Performance"
    echo -e " 🌙 ${GREEN}mados night on${NC}     : Mode Confort Nocturne"
    echo -e " 🛒 ${GREEN}mados store steam${NC}  : Installation rapide Steam"
    echo -e " 📂 ${GREEN}mados logs${NC}         : Voir les erreurs d'installation"
    echo -e "\n${CYAN}${BOLD}[ FONCTIONS CACHÉES ]${NC}"
    echo -e " 🔥 ${WHITE}Thermal Guard${NC}  : Ventilation max forcée à 90°C auto."
    echo -e " 🛰️ ${WHITE}QoS Gamer${NC}      : Priorité UDP (Réseau) active."
    echo -e " 🧠 ${WHITE}HugePages${NC}      : 2Go RAM verrouillés pour stabilité FPS."
    echo -e "--------------------------------------------------------"
    echo -e "Documentation complète : /opt/mados-rog/DOCS/PENSE_BETE.md"
    echo ""
}

# --- Main logic ---
case "$1" in
    shift)   do_shift "${2:-""}" ;;
    check)   do_check ;;
    update)  do_update ;;
    stealth) do_stealth "${2:-"on"}" ;;
    night)   /usr/local/bin/mados-night-mode "${2:-"on"}" ;;
    logs)    do_logs ;;
    guide)   do_guide ;;
    store)   do_store "${2:-""}" ;;
    aura)    asusctl led-mode "$2" 2>/dev/null ;;
    batt)    asusctl -c "$2" 2>/dev/null ;;
    ai)      systemctl --user "$2" openclaw.service 2>/dev/null ;;
    gui)     python3 "$INSTALL_DIR/assets/mados_cc.py" & ;;
    help|-h|--help) show_help ;;
    *)       show_help ;;
esac
