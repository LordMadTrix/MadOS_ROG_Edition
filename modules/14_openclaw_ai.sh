#!/bin/bash
# ==========================================
# MadOS ROG V2.4 - 14_openclaw_ai.sh
# ==========================================
# Phase: 14 - Assistant IA OpenClaw
# ==========================================


export DEBIAN_FRONTEND=noninteractive

RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
CYAN='\033[0;36m'
NC='\033[0m'

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "${RED}>>> ${WHITE}[Phase 14] ${BOLD}Déploiement Automatique de l'IA OpenClaw...${NC}"

echo -e "    ${GRAY}├─ Installation des dépendances systèmes (Node.js, Git)...${NC}"
if ! command -v node >/dev/null 2>&1; then
    sudo apt-get install -y ca-certificates curl gnupg 2>/dev/null || true
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null || true
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
    sudo apt-get update -q >/dev/null 2>&1
    sudo apt-get install -y nodejs >/dev/null 2>&1
fi

sudo apt-get install -y git build-essential >/dev/null 2>&1 || true

OC_DIR="$USER_HOME/OpenClaw"

echo -e "    ${GRAY}├─ Clonage du dépôt OpenClaw...${NC}"
if [ ! -d "$OC_DIR" ]; then
    sudo -u "$REAL_USER" git clone https://github.com/openclaw/openclaw.git "$OC_DIR" >/dev/null 2>&1
else
    echo -e "    ${GRAY}│  Le dossier existe déjà. Mise à jour via git pull...${NC}"
    sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && git pull" >/dev/null 2>&1 || true
fi

echo -e "    ${GRAY}├─ Configuration du cerveau IA (.env)...${NC}"
cat <<ENV_EOF | sudo -u "$REAL_USER" tee "$OC_DIR/.env" >/dev/null
ALLOW_LOCAL_SHELL=true
AUTO_APPROVE_SAFE_COMMANDS=true
DEFAULT_SYSTEM_PROMPT="Tu es l'Agent IA de MadOS ROG Edition. Tu es intégré au cœur du système Linux pour assister un gamer passionné. Sois précis, pertinent, et concis."
ENV_EOF

echo -e "    ${GRAY}├─ Compilation de l'IA (pnpm install & build) - Cela peut prendre 1 à 3 minutes...${NC}"
sudo corepack enable pnpm >/dev/null 2>&1 || true

# Execution du build STRICTEMENT sous l'utilisateur réel
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && pnpm install" >/dev/null 2>&1 || true
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && pnpm run build" >/dev/null 2>&1 || true

echo -e "    ${GRAY}├─ Création du service d'arrière-plan système...${NC}"
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/systemd/user"

cat <<SRV_EOF | sudo -u "$REAL_USER" tee "$USER_HOME/.config/systemd/user/openclaw.service" >/dev/null
[Unit]
Description=OpenClaw AI UI Service
After=network.target

[Service]
Type=simple
WorkingDirectory=$OC_DIR
ExecStart=/usr/bin/env pnpm run start
Restart=on-failure

[Install]
WantedBy=default.target
SRV_EOF

# Recharger les démons user-level (requires DBUS_SESSION_BUS_ADDRESS which sudo drops, so we run via machinectl or su -l but su is tricky.
# In a post-install chroot context, systemctl --user may fail if no active session.
# We just enable it globally for the user using loginctl linger or by symlinking.
sudo loginctl enable-linger "$REAL_USER" 2>/dev/null || true

# Workaround for enabling user systemd service during a sudo script:
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" systemctl --user daemon-reload 2>/dev/null || true
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" systemctl --user enable openclaw.service 2>/dev/null || true

echo -e "    ${GRAY}├─ Création du raccourci Bureau...${NC}"
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/Bureau" "$USER_HOME/Desktop" 2>/dev/null || true

cat <<DSK_EOF | sudo -u "$REAL_USER" tee "$USER_HOME/Bureau/OpenClaw.desktop" >/dev/null
[Desktop Entry]
Name=OpenClaw AI
Exec=google-chrome --app=http://localhost:3000
Icon=utilities-terminal
Type=Application
DSK_EOF

sudo chmod +x "$USER_HOME/Bureau/OpenClaw.desktop" 2>/dev/null || true
# Copie vers Desktop s'il existe (pour systèmes anglophones)
sudo -u "$REAL_USER" cp "$USER_HOME/Bureau/OpenClaw.desktop" "$USER_HOME/Desktop/" 2>/dev/null || true

echo -e "    ${WHITE}✅ L'Agent IA OpenClaw a été forgé avec succès.${NC}"
echo -e "    ${CYAN}ℹ️  Il démarrera automatiquement à votre prochaine connexion.${NC}"
echo -e "    ${WHITE}✅ Phase 14 Terminée.${NC}"
