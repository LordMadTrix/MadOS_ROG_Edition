#!/bin/bash
# ==========================================
# MadOS ROG V2.3 - 11_batterie_extreme.sh
# ==========================================
# Phase: 11 - Batterie Extrême (auto-cpufreq)
# ==========================================

export DEBIAN_FRONTEND=noninteractive

echo -e "${RED}>>> ${WHITE}[Phase 11] ${BOLD}Installation du gestionnaire Batterie Extrême...${NC}"

# auto-cpufreq est particulièrement efficace pour les PC portables
sudo apt update -q >/dev/null 2>&1
# Il est préférable de l'installer via snap sur ubuntu 24.04 pour éviter les conflits pythons capricieux,
# mais vu que nous avons purgé snap, nous allons l'installer manuellement via git/python-installer.
# Cependant, une version APT communautaire ou le script officiel est mieux.
# On utilise le script d'installation officiel de git.

if ! command -v auto-cpufreq >/dev/null 2>&1; then
    TEMP_DIR=$(mktemp -d)
    git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git "$TEMP_DIR" >/dev/null 2>&1
    cd "$TEMP_DIR"
    sudo ./auto-cpufreq-installer --install >/dev/null 2>&1 || true
    rm -rf "$TEMP_DIR"
fi

if command -v auto-cpufreq >/dev/null 2>&1; then
    sudo systemctl enable auto-cpufreq >/dev/null 2>&1 || true
    echo -e "    ✅ [SUCCÈS] auto-cpufreq est installé et activé en service."
else
    echo -e "    ❌ [ERREUR] Erreur lors de l'installation de auto-cpufreq."
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 11 Terminée.${NC}"
