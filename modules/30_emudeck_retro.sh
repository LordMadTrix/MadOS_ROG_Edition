#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 30_emudeck_retro.sh
# ==============================================================================
# Phase: 30 - Retro-Console EmuDeck (Emulation Station & Retroarch)
# ==============================================================================

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🕹️ ${WHITE}${BOLD}Phase 30 Déploiement de la Console Retro (EmuDeck/Retroarch)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation des dépendances Retro
echo -e "    ${WHITE}├─ [SYSTEM] Dépendances pour l'émulation...${NC}"
sudo apt update -q
sudo apt install -y curl wget unzip p7zip-full flatpak libfuse2

# 2. Téléchargement d'EmuDeck (Moteur d'installation)
echo -e "    ${WHITE}├─ [INSTALL] Téléchargement du script EmuDeck...${NC}"
mkdir -p "$USER_HOME/Documents/MadOS_Downloads"
wget -qO "$USER_HOME/Documents/MadOS_Downloads/EmuDeck.desktop" https://www.emudeck.com/EmuDeck.desktop
chmod +x "$USER_HOME/Documents/MadOS_Downloads/EmuDeck.desktop"

# 3. Installation de EmulationStation (Flatpak)
echo -e "    ${WHITE}├─ [BUREAU] Pré-installation de EmulationStation (Frontend)...${NC}"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub org.mozilla.firefox 2>/dev/null || true # Browser pour scraping
sudo flatpak install -y flathub org.libretro.RetroArch 2>/dev/null || true

# 4. Raccourci vers le centre de jeux
echo -e "    ${WHITE}├─ [UI] Création du raccourci EmuDeck sur le Bureau...${NC}"
cp "$USER_HOME/Documents/MadOS_Downloads/EmuDeck.desktop" "$USER_HOME/Desktop/"
chmod +x "$USER_HOME/Desktop/EmuDeck.desktop" 2>/dev/null || true

if command -v gio &>/dev/null; then
    sudo -u "$REAL_USER" gio set "$USER_HOME/Desktop/EmuDeck.desktop" metadata::trusted true
fi

echo -e "    ${CYAN}✅ [SUCCÈS] EmuDeck est disponible. Lancez l'icône sur votre bureau pour configurer vos émulateurs !${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 30 Terminée.${NC}"
