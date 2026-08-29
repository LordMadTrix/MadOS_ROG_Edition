#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 11_batterie_extreme.sh
# ==============================================================================
# Phase: 11 - Batterie Extrême (auto-cpufreq)
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

export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 11 Installation du gestionnaire Batterie Extrême${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Résolution des conflits système
# Sur Ubuntu 24/25, power-profiles-daemon empêche auto-cpufreq de fonctionner.
# TLP aussi : le module 03 (obligatoire) l'installe et l'active, et la
# documentation d'auto-cpufreq demande explicitement de le retirer. Les deux
# etaient actifs par defaut et pilotaient le meme gouverneur CPU en concurrence,
# avec des reglages qui se reecrivaient l'un l'autre.
echo -e "    ${GRAY}├─ Suppression des conflits (power-profiles-daemon, TLP)...${NC}"
if is_dry_run; then
    log_simu "désactiverait et purgerait power-profiles-daemon, et désactiverait TLP au profit d'auto-cpufreq"
else
    sudo systemctl disable --now power-profiles-daemon 2>/dev/null || true
    sudo apt purge -y power-profiles-daemon 2>/dev/null || true

    # TLP est desactive, pas desinstalle : sa configuration reste en place si
    # l'utilisateur veut faire marche arriere (systemctl enable --now tlp).
    if systemctl is-enabled --quiet tlp 2>/dev/null || systemctl is-active --quiet tlp 2>/dev/null; then
        echo -e "    ${YELLOW}├─ TLP détecté : désactivé au profit d'auto-cpufreq (incompatibles).${NC}"
        echo -e "    ${GRAY}│  Pour revenir à TLP : ${GREEN}sudo systemctl disable --now auto-cpufreq && sudo systemctl enable --now tlp${NC}"
        sudo systemctl disable --now tlp 2>/dev/null || true
        sudo systemctl mask tlp 2>/dev/null || true
    fi
fi

# 2. Installation de auto-cpufreq (Moteur d'optimisation processeur)
if ! command -v auto-cpufreq >/dev/null 2>&1; then
    if is_dry_run; then
        log_simu "clonerait auto-cpufreq depuis GitHub et l'installerait via auto-cpufreq-installer"
    else
        echo -e "    ${WHITE}├─ [DOWNLOAD] Recuperation du moteur auto-cpufreq...${NC}"
        TEMP_DIR=$(mktemp -d)
        if git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git "$TEMP_DIR" >/dev/null 2>&1; then
            cd "$TEMP_DIR" && sudo ./auto-cpufreq-installer --install >/dev/null 2>&1
            rm -rf "$TEMP_DIR"
        fi
    fi
fi

if is_dry_run; then
    log_simu "configurerait et activerait le service auto-cpufreq"
elif command -v auto-cpufreq >/dev/null 2>&1; then
    # On force la configuration initiale
    sudo auto-cpufreq --install >/dev/null 2>&1 || true
    sudo systemctl enable --now auto-cpufreq >/dev/null 2>&1
    echo -e "    ${GREEN}✅ [SUCCÈS] auto-cpufreq est operationnel et le conflit power-profiles est regle.${NC}"
else
    echo -e "    ${RED}❌ [ERREUR] Impossible d'installer le moteur de batterie.${NC}"
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 11 Terminée.${NC}"
