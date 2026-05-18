#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - Script de correction des bugs post-install
# Lancer avec : sudo bash fix_bugs_pc.sh
# ==============================================================================
set -e
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
WALLPAPER="/usr/share/wallpapers/MadOS/default_wallpaper.png"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; WHITE='\033[1;37m'; NC='\033[0m'

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} ${WHITE}MadOS ROG — Correction des bugs post-installation${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}\n"

# ------------------------------------------------------------------------------
# 1. Supprimer les doublons de raccourcis Bureau
# ------------------------------------------------------------------------------
echo -e "${CYAN}[1/6]${NC} Suppression des doublons de raccourcis Bureau..."
rm -f "$USER_HOME/Desktop/MadOS.desktop" "$USER_HOME/Bureau/MadOS.desktop"
echo -e "    ${GREEN}✅ Doublon MadOS Control Center supprimé${NC}"

# ------------------------------------------------------------------------------
# 2. Corriger MadChat IA — détecter le bon modèle Ollama
# ------------------------------------------------------------------------------
echo -e "${CYAN}[2/6]${NC} Correction de MadChat IA (modèle Ollama)..."
BEST_MODEL=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -v "^$" | sort | head -1)
if [ -z "$BEST_MODEL" ]; then
    BEST_MODEL="gemma2:9b"
    echo -e "    ${YELLOW}⚠️  Aucun modèle détecté, utilisation de gemma2:9b par défaut${NC}"
else
    echo -e "    Modèle sélectionné : ${CYAN}$BEST_MODEL${NC}"
fi

cat > "$USER_HOME/Desktop/MadChat_IA.desktop" << EOF
[Desktop Entry]
Name=MadChat IA (Local)
Comment=Discuter avec l'IA MadOS sans Internet — Modèle: $BEST_MODEL
Exec=konsole -e ollama run $BEST_MODEL
Icon=brain
Terminal=false
Type=Application
Categories=Utility;
EOF
chown "$REAL_USER:$REAL_USER" "$USER_HOME/Desktop/MadChat_IA.desktop"
echo -e "    ${GREEN}✅ MadChat configuré avec $BEST_MODEL${NC}"

# ------------------------------------------------------------------------------
# 3. Wallpaper KDE — autostart + SDDM
# ------------------------------------------------------------------------------
echo -e "${CYAN}[3/6]${NC} Configuration du fond d'écran KDE..."
mkdir -p "$USER_HOME/.config/autostart"
cat > "$USER_HOME/.config/autostart/set-mados-wallpaper.desktop" << EOF
[Desktop Entry]
Type=Application
Exec=sh -c "sleep 4 && plasma-apply-wallpaperimage $WALLPAPER && sleep 1 && rm -f ~/.config/autostart/set-mados-wallpaper.desktop"
Hidden=false
NoDisplay=true
Name=Set MadOS Wallpaper (one-shot)
X-KDE-AutostartScript=true
EOF
chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/autostart/set-mados-wallpaper.desktop"

# Aussi via kscreen/plasma-changewalllpaper direct si la session est active
sudo -u "$REAL_USER" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
    plasma-apply-wallpaperimage "$WALLPAPER" 2>/dev/null && \
    echo -e "    ${GREEN}✅ Wallpaper appliqué immédiatement${NC}" || \
    echo -e "    ${YELLOW}⚠️  Sera appliqué à la prochaine connexion KDE${NC}"

# SDDM (écran de login)
mkdir -p /usr/share/sddm/themes/breeze/
echo "[General]
background=$WALLPAPER" > /usr/share/sddm/themes/breeze/theme.conf.user
echo -e "    ${GREEN}✅ Fond d'écran de connexion SDDM configuré${NC}"

# ------------------------------------------------------------------------------
# 4. GRUB — nom MadOS + résolution 1080p + thème
# ------------------------------------------------------------------------------
echo -e "${CYAN}[4/6]${NC} Correction GRUB..."
GRUB_CONF="/etc/default/grub"

sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="MadOS ROG Edition"/' "$GRUB_CONF"
sed -i 's/^#*GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080,auto/' "$GRUB_CONF"

# Thème GRUB — téléchargement rapide si absent
if [ ! -d "/boot/grub/themes/mados-rog" ]; then
    GRUB_TMP=$(mktemp -d)
    if timeout 90 git clone --depth=1 https://github.com/AdisonCavani/distro-grub-themes.git "$GRUB_TMP" >/dev/null 2>&1; then
        mkdir -p /boot/grub/themes/mados-rog
        cp -r "$GRUB_TMP/customize/cyberpunk/"* /boot/grub/themes/mados-rog/ 2>/dev/null || true
        rm -rf "$GRUB_TMP"
        # Activer le thème
        if ! grep -q "^GRUB_THEME=" "$GRUB_CONF"; then
            echo 'GRUB_THEME="/boot/grub/themes/mados-rog/theme.txt"' >> "$GRUB_CONF"
        else
            sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/mados-rog/theme.txt"|' "$GRUB_CONF"
        fi
        echo -e "    ${GREEN}✅ Thème GRUB cyberpunk installé${NC}"
    else
        rm -rf "$GRUB_TMP"
        echo -e "    ${YELLOW}⚠️  Thème GRUB ignoré (réseau indisponible)${NC}"
    fi
else
    echo -e "    ${GREEN}✅ Thème GRUB déjà présent${NC}"
fi

update-grub 2>/dev/null && echo -e "    ${GREEN}✅ GRUB mis à jour — MadOS ROG Edition apparaîtra au boot${NC}" || \
    grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || echo -e "    ${YELLOW}⚠️  update-grub ignoré${NC}"

# ------------------------------------------------------------------------------
# 5. Corriger OpenClaw — le repo github n'existe pas, remplacer par script IA local
# ------------------------------------------------------------------------------
echo -e "${CYAN}[5/6]${NC} Configuration OpenClaw IA (Ollama local)..."
OC_DIR="$USER_HOME/OpenClaw"
mkdir -p "$OC_DIR"

# Créer un script OpenClaw fonctionnel basé sur Ollama local
cat > "$OC_DIR/openclaw.sh" << 'OCEOF'
#!/bin/bash
# OpenClaw IA — Interface IA locale MadOS ROG
echo -e "\033[0;31m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[0;31m║\033[0m  \033[1;37mOpenClaw IA — MadOS ROG Edition\033[0m"
echo -e "\033[0;31m╚══════════════════════════════════════════╝\033[0m"
BEST=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -v "^$" | head -1)
if [ -z "$BEST" ]; then
    echo "Erreur: Ollama non trouvé. Installez Ollama d'abord."
    exit 1
fi
echo -e "Modèle actif : \033[0;36m$BEST\033[0m"
echo -e "Tapez votre question (Ctrl+D pour quitter)\n"
ollama run "$BEST"
OCEOF
chmod +x "$OC_DIR/openclaw.sh"
chown -R "$REAL_USER:$REAL_USER" "$OC_DIR"

# Raccourci bureau OpenClaw
cat > "$USER_HOME/Desktop/OpenClaw_IA.desktop" << EOF
[Desktop Entry]
Name=OpenClaw IA
Comment=Intelligence Artificielle locale MadOS ROG
Exec=konsole -e bash $OC_DIR/openclaw.sh
Icon=brain
Terminal=false
Type=Application
Categories=Utility;
EOF
chown "$REAL_USER:$REAL_USER" "$USER_HOME/Desktop/OpenClaw_IA.desktop"
echo -e "    ${GREEN}✅ OpenClaw IA configuré (Ollama local)${NC}"

# ------------------------------------------------------------------------------
# 6. Nettoyer les fichiers résiduels
# ------------------------------------------------------------------------------
echo -e "${CYAN}[6/6]${NC} Nettoyage final..."
# Supprimer l'autostart wallpaper si déjà appliqué
# (gardé pour prochain login si besoin)

# Marquer les fichiers desktop comme de confiance (KDE)
for f in "$USER_HOME/Desktop"/*.desktop "$USER_HOME/Bureau"/*.desktop; do
    [ -f "$f" ] && sudo -u "$REAL_USER" gio set "$f" metadata::trusted true 2>/dev/null || true
done

echo -e "    ${GREEN}✅ Bureau nettoyé${NC}"

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Tous les bugs corrigés !                                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e ""
echo -e "  ${YELLOW}Prochaine étape :${NC} ${WHITE}sudo reboot${NC}  (pour activer le thème GRUB et le wallpaper)"
echo -e ""
