#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 06_thematique_mados.sh
# ==============================================================================
# Phase: 6 - Identité OS complète + Visuals
# Transforme le rendu pour correspondre au style ROG
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Source common.sh si les fonctions user_run/user_gsettings ne sont pas exportées
if ! declare -f user_run &>/dev/null; then
    _LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
    [ -f "$_LIB" ] && source "$_LIB" 2>/dev/null || [ -f "/opt/mados-rog/lib/common.sh" ] && source "/opt/mados-rog/lib/common.sh" 2>/dev/null || true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$PROJECT_ROOT/assets"

# ==============================================================================
# Choix du Thème (ROG / CYBER / CARBON)
# ==============================================================================
case "${MADOS_THEME:-ROG}" in
    "CYBER")
        THEME_DESC="Cyberpunk Neon"
        THEME_COLOR='\033[0;35m'
        ZSH_LOGO_COLOR='\033[0;35m'
        WALLPAPER_NAME="cyberpunk_neon.png"
        ;;
    "CARBON")
        THEME_DESC="Carbon Stealth"
        THEME_COLOR='\033[0;37m'
        ZSH_LOGO_COLOR='\033[0;37m'
        WALLPAPER_NAME="carbon_stealth.png"
        ;;
    *)
        THEME_DESC="ROG Classic"
        THEME_COLOR='\033[0;31m'
        ZSH_LOGO_COLOR='\033[0;31m'
        WALLPAPER_NAME="rog_wallpaper.png"
        ;;
esac

# Détection de l'interface graphique (DE) — utilise MADOS_DESKTOP si disponible
if [ -n "${MADOS_DESKTOP:-}" ]; then
    MADOS_DE="$MADOS_DESKTOP"
else
    _DE_RAW=$(user_run echo "$XDG_CURRENT_DESKTOP" 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "")
    if [[ "$_DE_RAW" == *"gnome"* ]]; then
        MADOS_DE="GNOME"
    elif [[ "$_DE_RAW" == *"kde"* ]] || [[ "$_DE_RAW" == *"plasma"* ]]; then
        MADOS_DE="KDE"
    else
        MADOS_DE="KDE"  # Défaut MadOS
    fi
fi

echo -e "\n${THEME_COLOR}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${THEME_COLOR}║${NC}   ${WHITE}${BOLD}MadOS 4.0 — APPLICATION DU THÈME : ${THEME_DESC}${NC}  ${THEME_COLOR}║${NC}"
echo -e "${THEME_COLOR}║${NC}   ${GRAY}Interface détectée : ${BOLD}$MADOS_DE${NC}                 ${THEME_COLOR}║${NC}"
echo -e "${THEME_COLOR}╚══════════════════════════════════════════════════════╝${NC}\n"

# 1. OS Identity
cat > /etc/os-release <<OSRELEASE
NAME="MadOS ROG Edition"
VERSION="4.0 (Ultimate Stable)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="MadOS ROG Edition 4.0 ($THEME_DESC)"
VERSION_ID="25.04"
OSRELEASE

echo "mados-rog" > /etc/hostname
hostname mados-rog 2>/dev/null || true

cat > /etc/update-motd.d/00-mados-header <<MOTD
#!/bin/bash
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗\033[0m"
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝\033[0m"
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ██╔████╔██║███████║██║  ██║██║   ██║███████╗\033[0m"
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║\033[0m"
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║\033[0m"
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝\033[0m"
echo -e "  \033[0;36m\033[1mMadOS 4.0 ($THEME_DESC)\033[0m  |  Kernel: \$(uname -r)"
MOTD
chmod +x /etc/update-motd.d/00-mados-header 2>/dev/null || true

# 2. ZSH & P10K
echo -e "\n${RED}>>> ${WHITE}[2/5] ${BOLD}Déploiement Console ZSH & Neofetch...${NC}"
chsh -s /bin/zsh "$REAL_USER" 2>/dev/null || true

if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    # RUNZSH=no CHSH=no : évite que le script lance zsh interactif et bloque sans TTY
    sudo -u "$REAL_USER" env RUNZSH=no CHSH=no \
        timeout 90 sh -c "$(curl -fsSL --max-time 30 https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null || true
fi
if [ ! -d "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    sudo -u "$REAL_USER" timeout 120 git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k" 2>/dev/null || true
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

# 3. Wallpapers
echo -e "\n${THEME_COLOR}>>> ${WHITE}[3/5] ${BOLD}Intégration du Fond d'écran $WALLPAPER_NAME...${NC}"
WALLPAPER_DIR="/usr/share/wallpapers/MadOS"
sudo mkdir -p "$WALLPAPER_DIR"

# Fallback links si les assets locaux manquent
ROG_WALLPAPER_URL="https://raw.githubusercontent.com/T-Book/Wallpapers/master/ASUS_ROG_G751.jpg"

if [ -f "$ASSETS_DIR/wallpapers/$WALLPAPER_NAME" ]; then
    sudo cp "$ASSETS_DIR/wallpapers/$WALLPAPER_NAME" "$WALLPAPER_DIR/default_wallpaper.png"
else
    echo -e "    ${GRAY}├─ Téléchargement du wallpaper ROG 4K de secours...${NC}"
    sudo wget -q -O "$WALLPAPER_DIR/default_wallpaper.png" "$ROG_WALLPAPER_URL" || true
fi

# Application du wallpaper (KDE)
if [ "$MADOS_DE" = "KDE" ]; then
    sudo mkdir -p /usr/share/sddm/themes/breeze/
    cat <<THEME_EOF | sudo tee /usr/share/sddm/themes/breeze/theme.conf.user > /dev/null
[General]
background=$WALLPAPER_DIR/default_wallpaper.png
THEME_EOF

    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/autostart"
    cat <<EOF | sudo -u "$REAL_USER" tee "$USER_HOME/.config/autostart/set-wallpaper.desktop" >/dev/null
[Desktop Entry]
Type=Application
Exec=sh -c "sleep 6 && (plasma-apply-wallpaperimage $WALLPAPER_DIR/default_wallpaper.png &) && rm -f ~/.config/autostart/set-wallpaper.desktop"
Hidden=false
NoDisplay=false
Name=Set MadOS Wallpaper
EOF
    sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/autostart/set-wallpaper.desktop"
fi

# Application du wallpaper (GNOME)
if [ "$MADOS_DE" = "GNOME" ]; then
    user_gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_DIR/default_wallpaper.png"
    user_gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_DIR/default_wallpaper.png"
fi

# 4. GRUB Theme
echo -e "\n${RED}>>> ${WHITE}[4/5] ${BOLD}Installation d'un Thème GRUB Premium...${NC}"

# Installation des prérequis de thème
sudo apt install -y git tar || true

# Téléchargement de distro-grub-themes
GRUB_THEME_DIR="/tmp/grub-themes"
rm -rf "$GRUB_THEME_DIR" 2>/dev/null || true
timeout 120 git clone --depth=1 https://github.com/AdisonCavani/distro-grub-themes.git "$GRUB_THEME_DIR" >/dev/null 2>&1 || true

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

# 5. Accent Rouge & Papirus Icons (Transformation Windows-Style)
echo -e "\n${RED}>>> ${WHITE}[5/5] ${BOLD}Sculpture du Bureau (ROG Windows-Style)...${NC}"
sudo apt install -y papirus-icon-theme plymouth plymouth-theme-spinner dconf-cli 2>/dev/null || true

# Application des dossiers rouges Papirus
timeout 60 wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/install.sh | timeout 60 sh 2>/dev/null || true
if command -v papirus-folders &>/dev/null; then
    sudo papirus-folders -C red --theme Papirus-Dark 2>/dev/null || true
fi

# ---- SCULPTURE BUREAU (GNOME & KDE) ----

if [ "$MADOS_DE" = "GNOME" ]; then
    echo -e "    ${GRAY}├─ Injection du Pack Transformation Win11 (GNOME)...${NC}"
    
    # 1. Désactiver le Dock Ubuntu
    user_gsettings set org.gnome.shell.extensions.dash-to-dock autohide true 2>/dev/null || true
    
    # 2. Installer les extensions indispensables
    INSTALLER_URL="https://raw.githubusercontent.com/brunelli/gnome-shell-extension-installer/master/gnome-shell-extension-installer"
    wget -q "$INSTALLER_URL" -O /tmp/extension-installer
    chmod +x /tmp/extension-installer
    
    # Dash to Panel (1160), ArcMenu (3628), Blur my Shell (3193)
    user_run /tmp/extension-installer --yes 1160 3628 3193 || true
    
    # 3. Configuration Dash to Panel (Barre centrée)
    user_gsettings set org.gnome.shell.extensions.dash-to-panel panel-position 'BOTTOM'
    user_gsettings set org.gnome.shell.extensions.dash-to-panel taskbar-position 'CENTER'
    user_gsettings set org.gnome.shell.extensions.dash-to-panel appicon-margin-bottom 2
    user_gsettings set org.gnome.shell.extensions.dash-to-panel appicon-padding 4
    
    # 4. Configuration ArcMenu (Style Win11, bouton à GAUCHE comme demandé)
    user_gsettings set org.gnome.shell.extensions.arcmenu menu-layout 'Windows 11'
    user_gsettings set org.gnome.shell.extensions.arcmenu menu-button-appearance 'Icon'
    user_gsettings set org.gnome.shell.extensions.arcmenu menu-button-icon 'Distro_Icon'
    user_gsettings set org.gnome.shell.extensions.arcmenu arc-menu-placement 'Left'
    
    # 5. Thèmes & Icônes
    user_gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark' # Fallback
    user_gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    
elif [ "$MADOS_DE" = "KDE" ]; then
    echo -e "    ${GRAY}├─ Injection du Layout Plasma 6 (Elite Gaming)...${NC}"
    sudo -u "$REAL_USER" plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || true
    sudo -u "$REAL_USER" plasma-apply-colorscheme BreezeDark 2>/dev/null || true
fi

# ---- FIN SCULPTURE BUREAU ----

# Injection des constantes de couleurs KDE
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
