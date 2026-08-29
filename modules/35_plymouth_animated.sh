#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 35_plymouth_animated.sh
# ==============================================================================
# Phase: 35 - Plymouth Animated (Boot Splash ROG Eye Pulse)
# ==============================================================================

export DEBIAN_FRONTEND=noninteractive

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🌀 ${WHITE}${BOLD}Phase 35 Déploiement du Splash Screen Animé (Plymouth Pulsar)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation des outils Plymouth
echo -e "    ${WHITE}├─ [SYSTEM] Injection du moteur de démarrage graphique...${NC}"
run_action "mettrait à jour les index apt" sudo apt update -q || true
run_action "installerait plymouth plymouth-themes" sudo apt install -y plymouth plymouth-themes || true

# 2. Création du Thème MadOS-Pulsar
echo -e "    ${WHITE}├─ [THEME] Création de l'animation MadOS-ROG-Pulse...${NC}"
run_action "créerait /usr/share/plymouth/themes/mados-pulsar" sudo mkdir -p /usr/share/plymouth/themes/mados-pulsar || true

if is_dry_run; then
    log_simu "écrirait le thème Plymouth animé (mados-pulsar.script et mados-pulsar.plymouth) dans /usr/share/plymouth/themes/mados-pulsar"
else
    # Utilisation d'un script Plymouth simple pour l'animation de fondu
    cat <<'EOF' | sudo tee /usr/share/plymouth/themes/mados-pulsar/mados-pulsar.script >/dev/null
# Plymouth ROG Pulse Script
Window.SetBackgroundTopColor (0, 0, 0);
Window.SetBackgroundBottomColor (0, 0, 0);

logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.x = Window.GetWidth()  / 2 - logo.image.GetWidth()  / 2;
logo.y = Window.GetHeight() / 2 - logo.image.GetHeight() / 2;
logo.sprite.SetX (logo.x);
logo.sprite.SetY (logo.y);

progress = 0;
fun refresh_callback() {
  progress += 0.05;
  opacity = (Math.Sin(progress) + 1) / 2;
  logo.sprite.SetOpacity(opacity);
}
Plymouth.SetRefreshFunction(refresh_callback);
EOF

    # Configuration du fichier .plymouth
    cat <<'EOF' | sudo tee /usr/share/plymouth/themes/mados-pulsar/mados-pulsar.plymouth >/dev/null
[Plymouth Theme]
Name=MadOS ROG Pulse
Description=Animated pulsing ROG logo for MadOS 3.5
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/mados-pulsar
ScriptFile=/usr/share/plymouth/themes/mados-pulsar/mados-pulsar.script
EOF
fi

# Logo du thème animé.
# L'ancienne version copiait /usr/share/wallpapers/MadOS/default_wallpaper.png,
# c'est-a-dire un fond d'ecran 4K, comme "logo.png" : le splash affichait donc
# l'image en pleine resolution, centree et pulsante -- exactement le defaut de
# taille qu'un commit anterieur avait corrige pour le theme du module 06.
# On repart du vrai logo, redimensionne, comme le fait le module 06.
PLY_PULSAR_DIR="/usr/share/plymouth/themes/mados-pulsar"
LOGO_SRC=""
for candidat in "$PROJECT_ROOT/assets/logo.png" "/usr/share/plymouth/themes/mados-rog/logo.png"; do
    [ -f "$candidat" ] && { LOGO_SRC="$candidat"; break; }
done

if [ -z "$LOGO_SRC" ]; then
    echo -e "    ${YELLOW}⚠️  Aucun logo source trouvé : thème animé non finalisé.${NC}"
elif is_dry_run; then
    log_simu "installerait $LOGO_SRC redimensionné à 250px comme logo du thème Plymouth animé"
else
    run_action "installerait imagemagick" sudo apt install -y imagemagick >/dev/null 2>&1 || true
    if command -v convert >/dev/null 2>&1; then
        sudo convert "$LOGO_SRC" -resize 250x250 "$PLY_PULSAR_DIR/logo.png" 2>/dev/null \
            || sudo cp "$LOGO_SRC" "$PLY_PULSAR_DIR/logo.png"
    elif command -v magick >/dev/null 2>&1; then
        sudo magick "$LOGO_SRC" -resize 250x250 "$PLY_PULSAR_DIR/logo.png" 2>/dev/null \
            || sudo cp "$LOGO_SRC" "$PLY_PULSAR_DIR/logo.png"
    else
        sudo cp "$LOGO_SRC" "$PLY_PULSAR_DIR/logo.png"
    fi
fi

# Ce module et le module 06 posent chacun un theme Plymouth. Celui-ci s'execute
# apres et l'emporte : on le dit, au lieu de laisser croire que les deux
# coexistent.
if [ -d /usr/share/plymouth/themes/mados-rog ]; then
    echo -e "    ${GRAY}├─ Thème 'mados-rog' (module 06) remplacé par 'mados-pulsar' (animé).${NC}"
fi

# 3. Activation du Thème
echo -e "    ${WHITE}├─ [CONFIG] Validation du thème de démarrage...${NC}"
run_action "activerait le thème Plymouth mados-pulsar" sudo plymouth-set-default-theme mados-pulsar -R 2>/dev/null || true

# Mise à jour de l'initramfs pour inclure le splash
echo -e "    ${WHITE}├─ [BOOT] Reconstruction de l'image de démarrage (Initramfs)...${NC}"
run_action "reconstruirait l'initramfs (update-initramfs -u)" sudo update-initramfs -u 2>/dev/null || true

echo -e "    ${CYAN}✅ [SUCCÈS] Séquence de démarrage animée activée. Votre logo va pulser de lumière au prochain boot !${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 35 Terminée.${NC}"
