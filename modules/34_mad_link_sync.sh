#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 34_mad_link_sync.sh
# ==============================================================================
# Phase: 34 - MadLink Device Sync (Smartphone & PC Coupling)
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🔗 ${WHITE}${BOLD}Phase 34 Déploiement de MadLink (Sync Smartphone & PC)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation du Moteur KDE Connect
echo -e "    ${WHITE}├─ [SYSTEM] Injection du moteur de synchronisation universel...${NC}"
run_action "lancerait apt update" sudo apt update -q || true
# openssh-server retire : KDE Connect utilise son PROPRE protocole sur les ports
# 1714-1764, il n'a aucun besoin d'un serveur SSH. L'installer exposait un
# demon SSH sur un poste de jeu, sans que rien ne le demande ni ne le signale.
run_action "installerait kdeconnect" sudo apt install -y kdeconnect || true

# 2. Ouverture des ports Firewall (Indispensable pour la découverte mobile)
echo -e "    ${WHITE}├─ [NETWORK] Débridage des ports de communication MadLink...${NC}"
if is_dry_run; then
    log_simu "ouvrirait les ports firewall 1714:1764 (udp+tcp) pour KDE Connect et rechargerait ufw"
else
# Le port 22 n'est plus ouvert ici : il n'a rien a voir avec KDE Connect.
sudo ufw allow 1714:1764/udp 2>/dev/null || true
sudo ufw allow 1714:1764/tcp 2>/dev/null || true
sudo ufw reload 2>/dev/null || true
fi

# 3. Création du raccourci de couplage "MadLink"
echo -e "    ${WHITE}├─ [UI] Création du raccourci de couplage sur le Bureau...${NC}"
if is_dry_run; then
    log_simu "créerait le raccourci MadLink_Sync.desktop sur le bureau de $REAL_USER (Desktop ou Bureau)"
else
# En locale francaise (imposee par le module 05), le dossier s'appelle "Bureau".
# L'ancienne version ecrivait en dur dans ~/Desktop, dossier souvent inexistant :
# le raccourci n'apparaissait jamais.
MADLINK_TMP=$(mktemp)
cat > "$MADLINK_TMP" <<EOF
[Desktop Entry]
Name=MadLink Sync
Comment=Connecter votre smartphone à MadOS
Exec=kdeconnect-app
Icon=phone
Terminal=false
Type=Application
Categories=Network;
EOF
MADLINK_POSE=0
for d in "Desktop" "Bureau"; do
    if [ -d "$USER_HOME/$d" ]; then
        sudo cp "$MADLINK_TMP" "$USER_HOME/$d/MadLink_Sync.desktop"
        sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/$d/MadLink_Sync.desktop"
        sudo chmod +x "$USER_HOME/$d/MadLink_Sync.desktop"
        sudo -u "$REAL_USER" gio set "$USER_HOME/$d/MadLink_Sync.desktop" metadata::trusted true 2>/dev/null || true
        MADLINK_POSE=1
    fi
done
# Repli : au moins dans le menu applications, toujours present.
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.local/share/applications"
sudo cp "$MADLINK_TMP" "$USER_HOME/.local/share/applications/MadLink_Sync.desktop"
sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/.local/share/applications/MadLink_Sync.desktop"
rm -f "$MADLINK_TMP"
[ "$MADLINK_POSE" -eq 0 ] && echo -e "    ${GRAY}├─ Aucun dossier Bureau/Desktop : raccourci placé dans le menu applications.${NC}"
fi

# 4. Autoriser le démarrage automatique du service de découverte
if is_dry_run; then
    log_simu "activerait le démarrage automatique de KDE Connect pour $REAL_USER"
else
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/autostart"
cp /usr/share/applications/org.kde.kdeconnect.daemon.desktop "$USER_HOME/.config/autostart/" 2>/dev/null || true
fi

echo -e "    ${CYAN}✅ [SUCCÈS] MadLink est prêt. Téléchargez 'KDE Connect' sur votre Android/iOS pour coupler votre machine !${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 34 Terminée.${NC}"
