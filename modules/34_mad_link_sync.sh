#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 34_mad_link_sync.sh
# ==============================================================================
# Phase: 34 - MadLink Device Sync (Smartphone & PC Coupling)
# ==============================================================================

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🔗 ${WHITE}${BOLD}Phase 34 Déploiement de MadLink (Sync Smartphone & PC)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation du Moteur KDE Connect
echo -e "    ${WHITE}├─ [SYSTEM] Injection du moteur de synchronisation universel...${NC}"
sudo apt update -q
sudo apt install -y kdeconnect openssh-server

# 2. Ouverture des ports Firewall (Indispensable pour la découverte mobile)
echo -e "    ${WHITE}├─ [NETWORK] Débridage des ports de communication MadLink...${NC}"
sudo ufw allow 1714:1764/udp 2>/dev/null || true
sudo ufw allow 1714:1764/tcp 2>/dev/null || true
sudo ufw reload 2>/dev/null || true

# 3. Création du raccourci de couplage "MadLink"
echo -e "    ${WHITE}├─ [UI] Création du raccourci de couplage sur le Bureau...${NC}"
cat <<EOF | sudo -u "$REAL_USER" tee "$USER_HOME/Desktop/MadLink_Sync.desktop" >/dev/null
[Desktop Entry]
Name=MadLink Sync
Comment=Connecter votre smartphone à MadOS
Exec=kdeconnect-app
Icon=phone
Terminal=false
Type=Application
Categories=Network;
EOF
chmod +x "$USER_HOME/Desktop/MadLink_Sync.desktop" 2>/dev/null || true

# 4. Autoriser le démarrage automatique du service de découverte
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/autostart"
cp /usr/share/applications/org.kde.kdeconnect.daemon.desktop "$USER_HOME/.config/autostart/" 2>/dev/null || true

echo -e "    ${CYAN}✅ [SUCCÈS] MadLink est prêt. Téléchargez 'KDE Connect' sur votre Android/iOS pour coupler votre machine !${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 34 Terminée.${NC}"
