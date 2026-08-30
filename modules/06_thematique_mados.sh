#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 06_thematique_mados.sh
# ==============================================================================
# Phase: 6 - Identité OS complète + Visuals
# Transforme le rendu pour correspondre au style ROG
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$PROJECT_ROOT/assets"

# ==============================================================================
# Choix du Thème (ROG / CYBER / CARBON)
# ==============================================================================
# MADOS_THEME est exporté par install.sh. Valeur de repli "ROG" pour que le
# module reste exécutable seul (et sous set -u).
case "${MADOS_THEME:-ROG}" in
    "CYBER")
        THEME_COLOR='\033[1;35m'      # Magenta/violet Cyberpunk
        ZSH_LOGO_COLOR='\033[1;36m'   # Cyan
        WALLPAPER_NAME="MadCyber.png"
        THEME_DESC="Cyberpunk Neon Edition"
        ;;
    "CARBON")
        THEME_COLOR='\033[0;37m'      # Gris
        ZSH_LOGO_COLOR='\033[1;37m'   # Blanc
        WALLPAPER_NAME="MadCarbon.png"
        THEME_DESC="Carbon Stealth Edition"
        ;;
    *)  # ROG par défaut
        THEME_COLOR='\033[0;31m'      # Rouge
        ZSH_LOGO_COLOR='\033[1;31m'   # Rouge gras
        WALLPAPER_NAME="MadRog.png"
        THEME_DESC="Republic of Gamers Edition"
        ;;
esac

# Détection de l'interface graphique (DE)
# Detection de l'interface graphique via detecter_bureau() (lib/common.sh).
# $XDG_CURRENT_DESKTOP etait developpe cote root : toujours vide.
# MADOS_DESKTOP est exporte par install.sh ; on le reutilise s'il est present,
# sinon on detecte nous-memes (cas d'un lancement du module en solo).
MADOS_DE="${MADOS_DESKTOP:-}"
if [ -z "$MADOS_DE" ]; then
    if type detecter_bureau >/dev/null 2>&1; then
        MADOS_DE="$(detecter_bureau)"
    else
        MADOS_DE="UNKNOWN"
    fi
fi
export CURRENT_DE="$MADOS_DE"

echo -e "\n${THEME_COLOR}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${THEME_COLOR}║${NC}   ${WHITE}${BOLD}MadOS 3.6 — APPLICATION DU THÈME : ${THEME_DESC}${NC}  ${THEME_COLOR}║${NC}"
echo -e "${THEME_COLOR}║${NC}   ${GRAY}Interface détectée : ${BOLD}$MADOS_DE${NC}                 ${THEME_COLOR}║${NC}"
echo -e "${THEME_COLOR}╚══════════════════════════════════════════════════════╝${NC}\n"

# 1. OS Identity
# On PRESERVE les champs techniques d'origine avant de rebrander. L'ancienne
# version ecrasait /etc/os-release avec 6 lignes seulement et faisait
# disparaitre VERSION_CODENAME : `lsb_release -sc` renvoyait ensuite "n/a" pour
# toujours. Mesure en VM apres une installation complete :
#     VERSION_CODENAME present ? NON -> disparu
#     lsb_release -sc : n/a
# Consequence bien au-dela de MadOS : add-apt-repository, les depots tiers et
# tout installeur qui detecte la version d'Ubuntu cessent de fonctionner.
MADOS_CODENAME="$(. /etc/os-release 2>/dev/null; echo "${VERSION_CODENAME:-}")"
MADOS_VERSION_ID="$(. /etc/os-release 2>/dev/null; echo "${VERSION_ID:-24.04}")"
[ -z "$MADOS_CODENAME" ] && MADOS_CODENAME="$(lsb_release -sc 2>/dev/null)"
case "$MADOS_CODENAME" in ""|"n/a") MADOS_CODENAME="noble" ;; esac

if is_dry_run; then
    log_simu "écrirait /etc/os-release (en conservant VERSION_CODENAME=$MADOS_CODENAME), /etc/hostname et le MOTD MadOS ROG"
else
cat > /etc/os-release <<OSRELEASE
NAME="MadOS ROG Edition"
VERSION="3.6 (Ultimate Stable)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="MadOS ROG Edition 3.6 ($THEME_DESC)"
VERSION_ID="$MADOS_VERSION_ID"
VERSION_CODENAME=$MADOS_CODENAME
UBUNTU_CODENAME=$MADOS_CODENAME
HOME_URL="https://lordmadtrix.github.io/MadOS_ROG_Edition/"
SUPPORT_URL="https://github.com/LordMadTrix/MadOS_ROG_Edition"
OSRELEASE

echo "mados-rog" > /etc/hostname
hostname mados-rog 2>/dev/null || true
backup_file "/etc/hosts"
# Sans l'entrée correspondante dans /etc/hosts, chaque sudo affiche
# "unable to resolve host mados-rog" et attend la résolution DNS.
if grep -qE '^127\.0\.1\.1[[:space:]]' /etc/hosts 2>/dev/null; then
    sed -i 's/^127\.0\.1\.1[[:space:]].*/127.0.1.1\tmados-rog/' /etc/hosts
else
    printf '127.0.1.1\tmados-rog\n' >> /etc/hosts
fi

cat > /etc/update-motd.d/00-mados-header <<MOTD
#!/bin/bash
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗\033[0m"
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝\033[0m"
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ██╔████╔██║███████║██║  ██║██║   ██║███████╗\033[0m"
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║\033[0m"
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║\033[0m"
echo -e "${ZSH_LOGO_COLOR}${BOLD}  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝\033[0m"
echo -e "  \033[0;36m\033[1mMadOS 3.6 ($THEME_DESC)\033[0m  |  Kernel: \$(uname -r)"
MOTD
chmod +x /etc/update-motd.d/00-mados-header 2>/dev/null || true
fi

# 2. ZSH & P10K
echo -e "\n${RED}>>> ${WHITE}[2/5] ${BOLD}Déploiement Console ZSH & Neofetch...${NC}"
if is_dry_run; then
    log_simu "changerait le shell par défaut vers zsh, installerait oh-my-zsh + powerlevel10k et écrirait ~/.zshrc"
else
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
fi

# 3. Wallpapers
echo -e "\n${THEME_COLOR}>>> ${WHITE}[3/5] ${BOLD}Intégration du Fond d'écran $WALLPAPER_NAME...${NC}"
WALLPAPER_DIR="/usr/share/wallpapers/MadOS"

if is_dry_run; then
    log_simu "déploierait le fond d'écran MadOS dans $WALLPAPER_DIR et l'appliquerait via $MADOS_DE"
else
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
fi

# 4. GRUB Theme
echo -e "\n${RED}>>> ${WHITE}[4/5] ${BOLD}Installation d'un Thème GRUB Premium...${NC}"

if is_dry_run; then
    log_simu "installerait le thème GRUB Cyberpunk (téléchargement, édition de /etc/default/grub, update-grub)"
else
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
            # Ajout IDEMPOTENT. L'ancien sed collait " quiet splash" a chaque
            # execution sans jamais verifier. Mesure en VM apres UNE SEULE
            # installation :
            #   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash quiet splash loglevel=3 ..."
            for _p in quiet splash; do
                if ! grep -q "GRUB_CMDLINE_LINUX_DEFAULT=.*[\" ]${_p}[ \"]" "$GRUB_CONF" 2>/dev/null; then
                    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"|GRUB_CMDLINE_LINUX_DEFAULT=\"\1 ${_p}\"|" "$GRUB_CONF" 2>/dev/null || true
                fi
            done
        fi
    fi
    regenerer_amorcage "régénération du menu GRUB (thème MadOS)" update-grub
    rm -rf "$GRUB_THEME_DIR"
else
    echo -e "    ${GRAY}├─ Échec du téléchargement du thème GRUB. (Ignoré)${NC}"
fi
fi

# 5. Accent Rouge & Papirus Icons (Transformation Windows-Style)
echo -e "\n${RED}>>> ${WHITE}[5/5] ${BOLD}Sculpture du Bureau (ROG Windows-Style)...${NC}"

if is_dry_run; then
    log_simu "installerait Papirus/Plymouth/dconf-cli, appliquerait les dossiers rouges Papirus et sculpterait le bureau ($MADOS_DE)"
else
sudo apt install -y papirus-icon-theme plymouth plymouth-theme-spinner dconf-cli 2>/dev/null || true

# Application des dossiers rouges Papirus
wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/install.sh | sh 2>/dev/null || true
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
fi

# Plymouth Custom Theme Setup
if [ -f "$ASSETS_DIR/logo.png" ]; then
    echo -e "    ${GRAY}├─ Construction du thème de démarrage Plymouth (MadOS ROG)...${NC}"
    if is_dry_run; then
        log_simu "construirait et activerait le thème Plymouth MadOS ROG (assets, update-alternatives, update-initramfs)"
    else
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
    regenerer_amorcage "reconstruction de l'initramfs (thème MadOS)" sudo update-initramfs -u
    fi
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 6 Terminée.${NC}"
