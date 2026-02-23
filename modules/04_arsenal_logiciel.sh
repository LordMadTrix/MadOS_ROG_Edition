#!/bin/bash
# ==========================================
# MadOS ROG V2 - 04_arsenal_logiciel.sh
# ==========================================
# Phase: 4 - Arsenal Logiciel & IA (OpenClaw)
# Installe Chrome, Steam, Lutris, et les outils Gaming.
# ==========================================

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# ---- Couleurs & Styles ----
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "${RED}>>> ${WHITE}[Phase 4] ${BOLD}Installation de l'Arsenal Logiciel...${NC}"

install_pkg() {
    for pkg in "$@"; do
        if apt-cache show "$pkg" &>/dev/null 2>&1; then
            sudo apt install -y "$pkg" 2>/dev/null || true
        fi
    done
}

echo -e "    ${WHITE}├─ [WEB] Intégration Navigateur Chrome...${NC}"
install_pkg google-chrome-stable

echo -e "    ${WHITE}├─ [MULTIMÉDIA] Déploiement de Spotify...${NC}"
install_pkg spotify-client

echo -e "    ${WHITE}├─ [GAMING] Installation Steam & Lutris...${NC}"
install_pkg steam-installer steam-devices lutris

echo -e "    ${WHITE}├─ [Outils] Injection Utilitaires (VLC, OBS...)...${NC}"
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
install_pkg vlc obs-studio stacer mangohud goverlay ttf-mscorefonts-installer pipx

echo -e "    ${WHITE}├─ [PROTON] Déploiement Console ProtonUp-Qt...${NC}"
sudo -u "$REAL_USER" pipx install protonup-qt 2>/dev/null || true

# Option OpenClaw IA
echo -e "\n${RED}>>> ${WHITE}[INTELLIGENCE ARTIFICIELLE] ${BOLD}Voulez-vous installer OpenClaw AI Assistant ?${NC}"
read -p "    👉 (o/N) : " install_ai
if [[ "$install_ai" =~ ^[oO]$ ]]; then
    echo -e "    ${GRAY}├─ Préparation du Framework OpenClaw...${NC}"
    if ! command -v node &>/dev/null; then
        sudo apt install -y ca-certificates curl gnupg 2>/dev/null || true
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
        sudo apt update -q > /dev/null 2>&1
        sudo apt install -y nodejs > /dev/null 2>&1
    fi
    # Création du lanceur/installer OpenClaw
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/Bureau" "$USER_HOME/Desktop" 2>/dev/null || true
    cat <<'OC_EOF' | sudo tee "$USER_HOME/Desktop/Install_OpenClaw.sh" > /dev/null
#!/bin/bash
set -e
echo "========================================="
echo "  🚀 Déploiement OpenClaw 🚀"
echo "========================================="
sudo apt install -y git build-essential
OC_DIR="$HOME/OpenClaw"
if [ ! -d "$OC_DIR" ]; then git clone https://github.com/openclaw/openclaw.git "$OC_DIR"; fi
cd "$OC_DIR"
cat <<ENV_EOF > .env
ALLOW_LOCAL_SHELL=true
AUTO_APPROVE_SAFE_COMMANDS=true
DEFAULT_SYSTEM_PROMPT="Tu es l'Agent IA de MadOS ROG Edition. Tu es intégré au noyau Linux pour hardcore gamers. Sois précis et expéditif."
ENV_EOF
sudo corepack enable pnpm
pnpm install
pnpm run build
mkdir -p "$HOME/.config/systemd/user"
cat <<SRV_EOF > "$HOME/.config/systemd/user/openclaw.service"
[Unit]
Description=OpenClaw AI UI Service
[Service]
Type=simple
WorkingDirectory=$OC_DIR
ExecStart=/usr/bin/env pnpm run start
Restart=on-failure
[Install]
WantedBy=default.target
SRV_EOF
systemctl --user daemon-reload
systemctl --user enable --now openclaw.service
cat <<DSK_EOF > "$HOME/Bureau/OpenClaw.desktop"
[Desktop Entry]
Name=OpenClaw AI
Exec=google-chrome --app=http://localhost:3000
Icon=utilities-terminal
Type=Application
DSK_EOF
chmod +x "$HOME/Bureau/OpenClaw.desktop" || true
echo "✅ Installation d'OpenClaw Terminée !"
sleep 5
rm -- "\$0"
OC_EOF
    sudo chown "$REAL_USER:$REAL_USER" "$USER_HOME/Desktop/Install_OpenClaw.sh"
    sudo chmod +x "$USER_HOME/Desktop/Install_OpenClaw.sh"
    # Fallback traduction fr: Bureau
    sudo cp "$USER_HOME/Desktop/Install_OpenClaw.sh" "$USER_HOME/Bureau/Install_OpenClaw.sh" 2>/dev/null || true
    echo -e "    ${GRAY}✅ Script 'Install_OpenClaw.sh' déployé sur votre Bureau.${NC}"
else
    echo -e "    ${GRAY}├─ Installation IA ignorée.${NC}"
fi

echo -e "    ${WHITE}✅ Phase 4 Terminée.${NC}"
