#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 35_plymouth_animated.sh
# ==============================================================================
# Phase: 35 - Plymouth Animated (Boot Splash ROG Eye Pulse)
# ==============================================================================

export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🌀 ${WHITE}${BOLD}Phase 35 Déploiement du Splash Screen Animé (Plymouth Pulsar)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Installation des outils Plymouth
echo -e "    ${WHITE}├─ [SYSTEM] Injection du moteur de démarrage graphique...${NC}"
sudo apt update -q
sudo apt install -y plymouth plymouth-themes

# 2. Création du Thème MadOS-Pulsar
echo -e "    ${WHITE}├─ [THEME] Création de l'animation MadOS-ROG-Pulse...${NC}"
sudo mkdir -p /usr/share/plymouth/themes/mados-pulsar

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

# Copie du logo ROG (on utilise l'image déjà présente dans les assets si possible)
if [ -f "/usr/share/wallpapers/MadOS/default_wallpaper.png" ]; then
    sudo cp "/usr/share/wallpapers/MadOS/default_wallpaper.png" "/usr/share/plymouth/themes/mados-pulsar/logo.png"
fi

# 3. Activation du Thème
echo -e "    ${WHITE}├─ [CONFIG] Validation du thème de démarrage...${NC}"
sudo plymouth-set-default-theme mados-pulsar -R 2>/dev/null || true

# Mise à jour de l'initramfs pour inclure le splash
echo -e "    ${WHITE}├─ [BOOT] Reconstruction de l'image de démarrage (Initramfs)...${NC}"
sudo update-initramfs -u 2>/dev/null || true

echo -e "    ${CYAN}✅ [SUCCÈS] Séquence de démarrage animée activée. Votre logo va pulser de lumière au prochain boot !${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 35 Terminée.${NC}"
