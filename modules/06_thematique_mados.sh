#!/bin/bash
# ==========================================
# MadOS ROG V2 - 06_thematique_mados.sh
# ==========================================
# Phase: 6 - Identité OS complète + Visuals
# Transforme le rendu pour correspondre au style ROG
# ==========================================

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$PROJECT_ROOT/assets"

echo -e "\n${RED}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}   ${WHITE}${BOLD}MadOS ROG V2 — APPLICATION DE LA CHARTE GRAPHIQUE${NC}  ${RED}║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════╝${NC}\n"

# 1. OS Identity
echo -e "${RED}>>> ${WHITE}[1/5] ${BOLD}Configuration de l'identité système...${NC}"
cat > /etc/os-release <<'OSRELEASE'
NAME="MadOS ROG Edition"
VERSION="2.6 (Noble)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="MadOS ROG Edition 2.6"
VERSION_ID="24.04"
HOME_URL="https://github.com/mados-rog"
OSRELEASE

echo "mados-rog" > /etc/hostname
hostname mados-rog 2>/dev/null || true

cat > /etc/update-motd.d/00-mados-header <<'MOTD'
#!/bin/bash
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'
echo -e "${RED}${BOLD}  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗${RESET}"
echo -e "${RED}${BOLD}  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝${RESET}"
echo -e "${RED}${BOLD}  ██╔████╔██║███████║██║  ██║██║   ██║███████╗${RESET}"
echo -e "${RED}${BOLD}  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║${RESET}"
echo -e "${RED}${BOLD}  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║${RESET}"
echo -e "${RED}${BOLD}  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝${RESET}"
echo -e "  \${CYAN}\${BOLD}MadOS ROG Edition 2.6\${RESET}  |  Kernel: \$(uname -r)"
MOTD
chmod +x /etc/update-motd.d/00-mados-header 2>/dev/null || true

# 2. ZSH & P10K
echo -e "\n${RED}>>> ${WHITE}[2/5] ${BOLD}Déploiement Console ZSH & Neofetch...${NC}"
chsh -s /bin/zsh "$REAL_USER" 2>/dev/null || true

if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    sudo -u "$REAL_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || true
fi
if [ ! -d "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    sudo -u "$REAL_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k" 2>/dev/null || true
fi

cat > "$USER_HOME/.zshrc" <<'ZSHRC'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git sudo history command-not-found)
source $ZSH/oh-my-zsh.sh
alias ll='ls -alF --color=auto'
alias update='sudo apt update && sudo apt upgrade -y'
alias rog-boost='asusctl profile -P Performance'
alias rog-gpu='supergfxctl -g'
if command -v neofetch &>/dev/null; then neofetch; fi
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHRC
chown "$REAL_USER:$REAL_USER" "$USER_HOME/.zshrc"

# 3. Wallpapers & SDDM
echo -e "\n${RED}>>> ${WHITE}[3/5] ${BOLD}Intégration des Fonds d'écran Officiels...${NC}"
WALLPAPER_DIR="/usr/share/wallpapers/MadOS"
sudo mkdir -p "$WALLPAPER_DIR"

if [ -d "$ASSETS_DIR/wallpapers" ]; then
    echo -e "    ${GRAY}├─ Déploiement du pack complet de fonds d'écran...${NC}"
    sudo cp -r "$ASSETS_DIR/wallpapers/"* "$WALLPAPER_DIR/" 2>/dev/null || true
    
    # Sync sur SDDM avec le premier wallpaper (MadRog1.jpg)
    sudo mkdir -p /usr/share/sddm/themes/breeze/
    cat <<'THEME_EOF' | sudo tee /usr/share/sddm/themes/breeze/theme.conf.user > /dev/null
[General]
background=/usr/share/wallpapers/MadOS/MadRog1.jpg
THEME_EOF

    # Configurer l'application automatique du wallpaper pour la session KDE via autostart
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/autostart"
    cat <<'EOF' | sudo -u "$REAL_USER" tee "$USER_HOME/.config/autostart/set-wallpaper.desktop" >/dev/null
[Desktop Entry]
Type=Application
Exec=sh -c "sleep 4 && plasma-apply-wallpaperimage /usr/share/wallpapers/MadOS/MadRog1.jpg && rm -f ~/.config/autostart/set-wallpaper.desktop"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Set MadOS Wallpaper
EOF
    sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/autostart/set-wallpaper.desktop"
fi

# 4. GRUB Theme
echo -e "\n${RED}>>> ${WHITE}[4/5] ${BOLD}Installation d'un Thème GRUB Premium...${NC}"

# Installation des prérequis de thème
sudo apt install -y git tar || true

# Téléchargement de distro-grub-themes
GRUB_THEME_DIR="/tmp/grub-themes"
rm -rf "$GRUB_THEME_DIR" 2>/dev/null || true
git clone --depth=1 https://github.com/AdisonCavani/distro-grub-themes.git "$GRUB_THEME_DIR" >/dev/null 2>&1 || true

if [ -d "$GRUB_THEME_DIR" ]; then
    echo -e "    ${GRAY}├─ Déploiement du thème GRUB (ROG/Cyberpunk)...${NC}"
    sudo mkdir -p /boot/grub/themes
    # Copie du thème "cyberpunk" (qui colle bien à l'esthétique rouge/neon ROG)
    sudo cp -r "$GRUB_THEME_DIR/customize/cyberpunk" /boot/grub/themes/mados-rog 2>/dev/null || true
    
    GRUB_CONF="/etc/default/grub"
    if [ -f "$GRUB_CONF" ]; then
        # On s'assure que le thème est activé dans GRUB
        sed -i 's/^#GRUB_THEME=.*/GRUB_THEME=\"\/boot\/grub\/themes\/mados-rog\/theme.txt\"/' "$GRUB_CONF" 2>/dev/null || true
        if ! grep -q "^GRUB_THEME=" "$GRUB_CONF"; then
            echo 'GRUB_THEME="/boot/grub/themes/mados-rog/theme.txt"' | sudo tee -a "$GRUB_CONF" >/dev/null
        fi
        
        # Décommenter GRUB_GFXMODE pour la 1080p
        sed -i 's/^#GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080,auto/' "$GRUB_CONF" 2>/dev/null || true
        
        sed -i 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="MadOS ROG Edition"/' "$GRUB_CONF" 2>/dev/null || true
        sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' "$GRUB_CONF" 2>/dev/null || true
        
        if grep -q 'GRUB_CMDLINE_LINUX_DEFAULT' "$GRUB_CONF"; then
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 quiet splash\"/' "$GRUB_CONF" 2>/dev/null || true
        fi
    fi
    update-grub > /dev/null 2>&1 || true
    rm -rf "$GRUB_THEME_DIR"
else
    echo -e "    ${GRAY}├─ Échec du téléchargement du thème GRUB. (Ignoré)${NC}"
fi

# 5. Accent Rouge & Papirus Icons
echo -e "\n${RED}>>> ${WHITE}[5/5] ${BOLD}Configuration UI et Accentuation KDE Plasma (Rouge)...${NC}"
sudo apt install -y papirus-icon-theme plymouth plymouth-theme-spinner || true

wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/install.sh | sh 2>/dev/null || true
if command -v papirus-folders &>/dev/null; then
    sudo papirus-folders -C red --theme Papirus-Dark 2>/dev/null || true
fi

sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config"
cat <<'KDEGLOBALS' | sudo -u "$REAL_USER" tee "$USER_HOME/.config/kdeglobals" >/dev/null
[General]
ColorScheme=BreezeDark
Name=Breeze Dark
[Icons]
Theme=Papirus-Dark
[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
[Colors:Selection]
BackgroundAlternate=200,0,0
BackgroundNormal=255,0,0
KDEGLOBALS
sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/kdeglobals"

# Plymouth Custom Theme Setup
if [ -f "$ASSETS_DIR/logo.png" ]; then
    echo -e "    ${GRAY}├─ Construction du thème de démarrage Plymouth (MadOS ROG)...${NC}"
    sudo DEBIAN_FRONTEND=noninteractive apt install -y imagemagick plymouth-label >/dev/null 2>&1 || true
    
    PLY_DIR="/usr/share/plymouth/themes/mados-rog"
    sudo mkdir -p "$PLY_DIR"
    
    # Préparation des assets visuels figés, évitant les problèmes de scale dynamiques d'Ubuntu
    sudo convert "$ASSETS_DIR/logo.png" -resize 250x250 "$PLY_DIR/logo.png" 2>/dev/null || sudo cp "$ASSETS_DIR/logo.png" "$PLY_DIR/logo.png"
    sudo convert -size 600x100 xc:transparent -fill "#FFFFFF" -gravity center -pointsize 38 -annotate +0+0 "MadOS ROG Edition" "$PLY_DIR/text.png" 2>/dev/null
    
    # Création du descripteur de thème
    cat <<'PLY_EOF' | sudo tee "$PLY_DIR/mados-rog.plymouth" >/dev/null
[Plymouth Theme]
Name=MadOS ROG Custom
Description=A custom boot theme for MadOS ROG
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/mados-rog
ScriptFile=/usr/share/plymouth/themes/mados-rog/mados-rog.script
PLY_EOF

    # Création de la logique d'animation (Script Plymouth)
    cat <<'SCRIPT_EOF' | sudo tee "$PLY_DIR/mados-rog.script" >/dev/null
Window.SetBackgroundTopColor(0.0, 0.0, 0.0);
Window.SetBackgroundBottomColor(0.0, 0.0, 0.0);

logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2 - 30);

text.image = Image("text.png");
text.sprite = Sprite(text.image);
text.sprite.SetX(Window.GetWidth() / 2 - text.image.GetWidth() / 2);
text.sprite.SetY(logo.sprite.GetY() + logo.image.GetHeight() + 40);

logo.opacity_angle = 0;
fun refresh_callback () {
  logo.opacity_angle += 0.05;
  logo.sprite.SetOpacity(0.6 + Math.Sin(logo.opacity_angle) * 0.4);
}
Plymouth.SetRefreshFunction(refresh_callback);
SCRIPT_EOF

    # Application brute du thème personnalisé sur le système
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/mados-rog/mados-rog.plymouth 100 >/dev/null 2>&1
    sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/mados-rog/mados-rog.plymouth >/dev/null 2>&1
    
    echo -e "    ${GRAY}├─ Recompilation du Kernel et de l'initramfs (Patientez svp)...${NC}"
    sudo update-initramfs -u >/dev/null 2>&1 || true
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 6 Terminée.${NC}"
