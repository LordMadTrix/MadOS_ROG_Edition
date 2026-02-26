#!/bin/bash
# ==========================================
# MadOS ROG V2.4 - 14_openclaw_ai.sh
# ==========================================
# Phase: 14 - Assistant IA OpenClaw
# ==========================================

export DEBIAN_FRONTEND=noninteractive

CYAN='\033[0;36m'

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "${RED}>>> ${WHITE}[Phase 14] ${BOLD}Déploiement Automatique de l'IA OpenClaw...${NC}"

echo -e "    ${GRAY}├─ Installation des dépendances systèmes (Node.js, Git)...${NC}"
if ! command -v node >/dev/null 2>&1; then
    sudo apt-get install -y ca-certificates curl gnupg || true
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -yes -o /etc/apt/keyrings/nodesource.gpg || true
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
    sudo apt-get update -q
    sudo apt-get install -y nodejs
fi

sudo apt-get install -y git build-essential || true

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

echo -e "    ${GRAY}├─ Compilation de l'IA (pnpm install & build) - Cela peut prendre 1 à 5 minutes selon le CPU...${NC}"
sudo corepack enable pnpm >/dev/null 2>&1 || true

# Execution du build STRICTEMENT sous l'utilisateur réel avec affichage (plus de freeze silencieux)
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && CI=true pnpm install" || true
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && CI=true pnpm run build" || true

echo -e "    ${GRAY}├─ Création du service d'arrière-plan système...${NC}"
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/systemd/user"

cat <<SRV_EOF | sudo -u "$REAL_USER" tee "$USER_HOME/.config/systemd/user/openclaw.service" >/dev/null
[Unit]
Description=OpenClaw AI Gateway Service
After=network.target

[Service]
Type=simple
WorkingDirectory=$OC_DIR
ExecStart=/usr/bin/env pnpm run start gateway
Restart=on-failure

[Install]
WantedBy=default.target
SRV_EOF

# Recharger les démons user-level
sudo loginctl enable-linger "$REAL_USER" 2>/dev/null || true

# Workaround for enabling user systemd service during a sudo script without active DBUS session:
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/systemd/user/default.target.wants"
sudo -u "$REAL_USER" ln -sf "$USER_HOME/.config/systemd/user/openclaw.service" "$USER_HOME/.config/systemd/user/default.target.wants/openclaw.service"

sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" systemctl --user daemon-reload 2>/dev/null || true

echo -e "    ${GRAY}├─ Création du Control Panel (OpenClaw_Launcher.sh)...${NC}"
cat <<'LCH_EOF' | sudo -u "$REAL_USER" tee "$OC_DIR/OpenClaw_Launcher.sh" >/dev/null
#!/bin/bash
while true; do
  CHOICE=$(whiptail --title "🤖 OpenClaw AI - Control Panel" --menu "Gestion du Cerveau OpenClaw" 19 64 7 \
    "1" "Ouvrir l'Interface Graphique (Web UI)" \
    "2" "Ouvrir l'Interface Chat (TUI / Terminal)" \
    "3" "Démarrer le moteur de l'IA (Gateway)" \
    "4" "Arrêter le moteur de l'IA" \
    "5" "Redémarrer l'IA (Restart)" \
    "6" "Diagnostic (Mode Doctor / Logs)" \
    "7" "Quitter" 3>&1 1>&2 2>&3)

  if [ -z "$CHOICE" ] || [ "$CHOICE" = "7" ]; then break; fi

  case $CHOICE in
    1)
      if systemctl --user is-active --quiet openclaw.service; then
        google-chrome --app=http://localhost:3000 2>/dev/null || xdg-open http://localhost:3000
      else
        whiptail --msgbox "⚠️ Le moteur OpenClaw est éteint ! Veuillez le démarrer (Option 3) d'abord." 8 60
      fi
      ;;
    2)
      cd "$HOME/OpenClaw" && pnpm run start tui
      ;;
    3)
      systemctl --user start openclaw.service
      whiptail --msgbox "✅ Moteur OpenClaw démarré en tâche de fond !\nL'interface Web est désormais accessible sur le port 3000." 9 55
      ;;
    4)
      systemctl --user stop openclaw.service
      whiptail --msgbox "🛑 Moteur OpenClaw arrêté avec succès." 8 50
      ;;
    5)
      systemctl --user restart openclaw.service
      whiptail --msgbox "🔄 Moteur OpenClaw redémarré à neuf !" 8 50
      ;;
    6)
      echo "=== DIAGNOSTIC OPENCLAW (DOCTOR) ===" > /tmp/oc_doctor.txt
      echo "--- STATUT SYSTEMD ---" >> /tmp/oc_doctor.txt
      systemctl --user status openclaw.service --no-pager | head -n 12 >> /tmp/oc_doctor.txt
      echo -e "\n--- DERNIERES ERREURS (LOGS) ---" >> /tmp/oc_doctor.txt
      journalctl --user -u openclaw.service -n 15 --no-pager >> /tmp/oc_doctor.txt
      whiptail --title "OpenClaw Doctor 🩺" --scrolltext --textbox /tmp/oc_doctor.txt 22 80
      ;;
  esac
done
LCH_EOF

sudo chmod +x "$OC_DIR/OpenClaw_Launcher.sh" 2>/dev/null || true

echo -e "    ${GRAY}├─ Création du raccourci Bureau (Control Panel)...${NC}"
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/Bureau" "$USER_HOME/Desktop" 2>/dev/null || true

cat <<DSK_EOF | sudo -u "$REAL_USER" tee "$USER_HOME/Bureau/OpenClaw.desktop" >/dev/null
[Desktop Entry]
Name=OpenClaw AI Control
Exec="$USER_HOME/OpenClaw/OpenClaw_Launcher.sh"
Icon=utilities-terminal
Terminal=true
Type=Application
DSK_EOF

sudo chmod +x "$USER_HOME/Bureau/OpenClaw.desktop" 2>/dev/null || true
# Copie vers Desktop s'il existe (pour systèmes anglophones)
sudo -u "$REAL_USER" cp "$USER_HOME/Bureau/OpenClaw.desktop" "$USER_HOME/Desktop/" 2>/dev/null || true

echo -e "    ${WHITE}✅ [SUCCÈS] L'Agent IA OpenClaw a été forgé avec succès.${NC}"
echo -e "    ${CYAN}ℹ️  Il démarrera automatiquement à votre prochaine connexion.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 14 Terminée.${NC}"
