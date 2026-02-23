#!/bin/bash
# ==========================================
# MadOS ROG V2 - 06_thematique_mados.sh
# ==========================================
# Phase: 6 - Identité OS complète + Visuals
# Transforme le rendu pour correspondre au style ROG
# ==========================================

set -u
export DEBIAN_FRONTEND=noninteractive

# ---- Couleurs & Styles ----
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$PROJECT_ROOT/assets/installer"

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
RED='\033[0;31m'
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
fi

# 4. GRUB Theme
echo -e "\n${RED}>>> ${WHITE}[4/5] ${BOLD}Surcharge du menu BIOS / GRUB...${NC}"
GRUB_CONF="/etc/default/grub"
if [ -f "$GRUB_CONF" ]; then
    sed -i 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="MadOS ROG Edition"/' "$GRUB_CONF"
    sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' "$GRUB_CONF"
    if grep -q 'GRUB_CMDLINE_LINUX_DEFAULT' "$GRUB_CONF"; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' "$GRUB_CONF" 2>/dev/null || true
    fi
fi
update-grub > /dev/null 2>&1 || true

# 5. Accent Rouge & Papirus Icons
echo -e "\n${RED}>>> ${WHITE}[5/5] ${BOLD}Configuration UI et Accentuation KDE Plasma (Rouge)...${NC}"
sudo apt install -y papirus-icon-theme plymouth plymouth-theme-spinner >/dev/null 2>&1 || true

wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/install.sh | sh 2>/dev/null || true
if command -v papirus-folders &>/dev/null; then
    sudo papirus-folders -C red --theme Papirus-Dark 2>/dev/null || true
fi

sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config"
cat > /tmp/kdeglobals_mados <<'KDEGLOBALS'
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
sudo cp /tmp/kdeglobals_mados "$USER_HOME/.config/kdeglobals"
sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/kdeglobals"
rm -f /tmp/kdeglobals_mados

# Plymouth simple setup
if [ -f "$ASSETS_DIR/logo.png" ]; then
    sudo mkdir -p /usr/share/plymouth/themes/mados-rog
    cp "$ASSETS_DIR/logo.png" /usr/share/plymouth/themes/mados-rog/logo.png 2>/dev/null || true
fi

echo -e "    ${WHITE}✅ Phase 6 Terminée.${NC}"
