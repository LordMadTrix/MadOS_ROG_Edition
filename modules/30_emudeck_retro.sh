#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 30_emudeck_retro.sh
# ==============================================================================
# Phase: 30 - Retro-Console EmuDeck (Emulation Station & Retroarch)
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🕹️ ${WHITE}${BOLD}Phase 30 Déploiement de la Console Retro (EmuDeck/Retroarch)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation des dépendances Retro
echo -e "    ${WHITE}├─ [SYSTEM] Dépendances pour l'émulation...${NC}"
run_action "mettre à jour le cache apt" sudo apt update -q || true
run_action "installer curl, wget, unzip, p7zip-full, flatpak, libfuse2" sudo apt install -y curl wget unzip p7zip-full flatpak libfuse2 || true

# 2. Téléchargement d'EmuDeck (Moteur d'installation)
echo -e "    ${WHITE}├─ [INSTALL] Téléchargement du script EmuDeck...${NC}"
# mkdir/wget/cp/chmod tournaient en ROOT, contrairement au reste du projet, et
# aucun chown ne suivait : le raccourci appartenait a root, donc l'utilisateur
# ne pouvait ni le lancer ni le supprimer, et le `gio set` lance en tant
# qu'utilisateur echouait derriere.
EMU_DIR="$USER_HOME/Documents/MadOS_Downloads"
run_action "créer le dossier $EMU_DIR" sudo -u "$REAL_USER" mkdir -p "$EMU_DIR"
run_action "télécharger EmuDeck.desktop" sudo -u "$REAL_USER" wget -qO "$EMU_DIR/EmuDeck.desktop" https://www.emudeck.com/EmuDeck.desktop
run_action "rendre exécutable EmuDeck.desktop" sudo -u "$REAL_USER" chmod +x "$EMU_DIR/EmuDeck.desktop"

# 3. Installation de EmulationStation (Flatpak)
echo -e "    ${WHITE}├─ [BUREAU] Pré-installation de EmulationStation (Frontend)...${NC}"
run_action "ajouter le dépôt Flathub" sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
# Firefox retire : le module 05 vient de le purger (snap + apt) a la demande de
# l utilisateur. Le reinstaller ici en flatpak annulait ce choix. Le scraper
# d EmuDeck fonctionne sans navigateur dedie.
run_action "installer RetroArch (flatpak)" sudo flatpak install -y flathub org.libretro.RetroArch 2>/dev/null || true

# 4. Raccourci vers le centre de jeux (Desktop ET Bureau, locale FR)
echo -e "    ${WHITE}├─ [UI] Création du raccourci EmuDeck sur le Bureau...${NC}"
if is_dry_run; then
    log_simu "copierait EmuDeck.desktop sur le bureau de $REAL_USER (Desktop ou Bureau)"
elif [ -f "$EMU_DIR/EmuDeck.desktop" ]; then
    for d in "Desktop" "Bureau"; do
        if [ -d "$USER_HOME/$d" ]; then
            sudo -u "$REAL_USER" cp "$EMU_DIR/EmuDeck.desktop" "$USER_HOME/$d/EmuDeck.desktop"
            sudo -u "$REAL_USER" chmod +x "$USER_HOME/$d/EmuDeck.desktop"
            command -v gio >/dev/null 2>&1 && sudo -u "$REAL_USER" gio set "$USER_HOME/$d/EmuDeck.desktop" metadata::trusted true 2>/dev/null || true
        fi
    done
else
    echo -e "    ${YELLOW}⚠️  EmuDeck.desktop non téléchargé : raccourci non créé.${NC}"
fi

echo -e "    ${CYAN}✅ [SUCCÈS] EmuDeck est disponible. Lancez l'icône sur votre bureau pour configurer vos émulateurs !${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 30 Terminée.${NC}"
