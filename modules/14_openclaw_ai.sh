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
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - >/dev/null 2>&1
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
gateway.mode=local
DEFAULT_SYSTEM_PROMPT="Tu es l'Agent IA de MadOS ROG Edition, forge par LordMadTrix. Tu connais Linux et le gaming. Reponds en francais."
ENV_EOF

echo -e "    ${GRAY}├─ Compilation de l'IA (pnpm install & build) - Cela peut prendre 1 à 5 minutes selon le CPU...${NC}"
sudo npm install -g pnpm >/dev/null 2>&1 || true

# Execution du build STRICTEMENT sous l'utilisateur réel avec affichage (plus de freeze silencieux)
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && pnpm install" || true
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && pnpm run build" || true

echo -e "    ${GRAY}├─ Création du service d'arrière-plan système...${NC}"
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/systemd/user"

# Créer un script wrapper pour garantir le bon environnement au démarrage
cat <<'WRP_EOF' | sudo -u "$REAL_USER" tee "$OC_DIR/start-gateway.sh" > /dev/null
#!/bin/bash
# Wrapper OpenClaw Gateway — charge l'environnement utilisateur complet
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/.nvm/versions/node/$(ls $HOME/.nvm/versions/node/ 2>/dev/null | tail -1)/bin"
export HOME="${HOME:-/home/$(whoami)}"

cd "$HOME/OpenClaw" || exit 1

# Vérifier que node est accessible
if command -v node &>/dev/null; then
    exec node scripts/run-node.mjs gateway --allow-unconfigured
elif command -v pnpm &>/dev/null; then
    exec pnpm run start gateway -- --allow-unconfigured
else
    echo "ERROR: node/pnpm not found in PATH: $PATH" >&2
    exit 1
fi
WRP_EOF
sudo -u "$REAL_USER" chmod +x "$OC_DIR/start-gateway.sh"

cat <<SRV_EOF | sudo -u "$REAL_USER" tee "$USER_HOME/.config/systemd/user/openclaw.service" > /dev/null
[Unit]
Description=OpenClaw AI Gateway Service
After=network.target graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
WorkingDirectory=$OC_DIR
ExecStartPre=/bin/sleep 10
ExecStart=$OC_DIR/start-gateway.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

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
      if systemctl --user is-active --quiet openclaw.service; then
        clear
        cd "$HOME/OpenClaw" && node scripts/run-node.mjs tui
      else
        whiptail --msgbox "⚠️ Le moteur OpenClaw est éteint ! Veuillez le démarrer (Option 3) d'abord." 8 60
      fi
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

# Les raccourcis OpenClaw sont désormais intégrés dans MadOS Control Center.
# Supprimer l'éventuel ancien raccourci OpenClaw séparé.
sudo -u "$REAL_USER" rm -f "$USER_HOME/Bureau/OpenClaw.desktop" "$USER_HOME/Desktop/OpenClaw.desktop" 2>/dev/null || true

echo -e "    ${WHITE}✅ [SUCCÈS] L'Agent IA OpenClaw a été forgé avec succès.${NC}"
echo -e "    ${CYAN}ℹ️  Il démarrera automatiquement à votre prochaine connexion.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 14 Terminée.${NC}"
