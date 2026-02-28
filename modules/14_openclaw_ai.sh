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

echo -e "    ${GRAY}├─ [INTELLIGENCE LOCALE] Installation du moteur Ollama...${NC}"
if ! command -v ollama >/dev/null 2>&1; then
    curl -fsSL https://ollama.com/install.sh | sudo -E bash - >/dev/null 2>&1
    sudo systemctl enable --now ollama >/dev/null 2>&1 || true
fi

OC_DIR="$USER_HOME/OpenClaw"

echo -e "    ${GRAY}├─ Clonage du dépôt OpenClaw...${NC}"
if [ ! -d "$OC_DIR" ]; then
    sudo -u "$REAL_USER" git clone --depth=1 https://github.com/openclaw/openclaw.git "$OC_DIR" >/dev/null 2>&1
else
    echo -e "    ${GRAY}│  Le dossier existe déjà. Mise à jour via git pull...${NC}"
    sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && git pull" >/dev/null 2>&1 || true
fi

echo -e "    ${GRAY}├─ Configuration du cerveau IA (.env)...${NC}"
cat <<ENV_EOF | sudo -u "$REAL_USER" tee "$OC_DIR/.env" >/dev/null
ALLOW_LOCAL_SHELL=true
AUTO_APPROVE_SAFE_COMMANDS=true
gateway.mode=local
gateway.models.local=ollama
DEFAULT_SYSTEM_PROMPT="Vous êtes OpenClaw, l'Intelligence Artificielle intégrée au noyau de MadOS ROG Edition (V3.0), un système Linux extrême forgé par LordMadTrix. Vous avez un accès direct au terminal. Votre but est d'assister le joueur dans l'optimisation E-Sport, le débogage système, et la gestion du hardware ASUS. Soyez analytique, direct, et répondez toujours en français avec un ton d'ingénierie tactique."
ENV_EOF

echo -e "    ${GRAY}├─ Compilation de l'IA (pnpm install & build) - Cela peut prendre 1 à 5 minutes selon le CPU...${NC}"
sudo npm install -g pnpm >/dev/null 2>&1 || true

# Execution du build STRICTEMENT sous l'utilisateur réel avec affichage (plus de freeze silencieux)
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && pnpm install" || true
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && pnpm run build" || true
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && pnpm ui:build" || true

echo -e "    ${GRAY}├─ Création du service d'arrière-plan système...${NC}"
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config/systemd/user"

# Créer un script wrapper pour garantir le bon environnement au démarrage
cat <<'WRP_EOF' | sudo -u "$REAL_USER" tee "$OC_DIR/start-gateway.sh" > /dev/null
#!/bin/bash
# Wrapper OpenClaw Gateway — charge l'environnement utilisateur complet
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/.nvm/versions/node/$(ls $HOME/.nvm/versions/node/ 2>/dev/null | tail -1)/bin"
export HOME="${HOME:-/home/$(whoami)}"

cd "$HOME/OpenClaw" || exit 1

# Démarrer le Gateway Node en arrière-plan
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

echo -e "    ${GRAY}├─ Création du Terminal Neuronal V3.0 (OpenClaw_Launcher.sh)...${NC}"
cat <<'LCH_EOF' | sudo -u "$REAL_USER" tee "$OC_DIR/OpenClaw_Launcher.sh" >/dev/null
#!/bin/bash
export NEWT_COLORS='
    root=,black
    window=white,black
    border=red,black
    shadow=black,black
    title=white,red
    button=white,black
    actbutton=white,red
    compactbutton=white,black
    textbox=white,black
    listbox=white,black
    actlistbox=white,red
    sellistbox=white,black
    actsellistbox=white,red
    checkbox=white,black
    actcheckbox=white,red
'
while true; do
  CHOICE=$(whiptail --title "🤖 Cœur Neuronal OpenClaw (V3.0)" --menu "Interface de Gestion de l'IA Locale" 19 68 7 \
    "1" "Accéder au Terminal Neuronal (Web UI)" \
    "2" "Ouvrir le Canal de Communication Brut (TUI)" \
    "3" "Engager le Noyau IA (Démarrer Gateway)" \
    "4" "Désactiver le Noyau IA (Arrêter Gateway)" \
    "5" "Re-Séquençage (Restart de l'IA)" \
    "6" "Diagnostic Matriciel (Logs Système)" \
    "7" "Fermer la connexion" 3>&1 1>&2 2>&3)

  if [ -z "$CHOICE" ] || [ "$CHOICE" = "7" ]; then break; fi

  case $CHOICE in
    1)
      if systemctl --user is-active --quiet openclaw.service; then
        echo -e "\n${BLUE}[+] Ouverture automatique de l'interface OpenClaw via le navigateur...${NC}"
        # 1. Tenter de lire le token depuis la configuration JSON persistante (Bypass suppression des logs systemd)
        OC_CONFIG="$HOME/.openclaw/openclaw.json"
        TOKEN=""
        if [ -f "$OC_CONFIG" ] && command -v jq >/dev/null 2>&1; then
            TOKEN=$(jq -r '.gateway.auth.token // empty' "$OC_CONFIG" 2>/dev/null)
        fi

        if [ -n "$TOKEN" ]; then
            TOKEN_URL="http://localhost:18789/?token=$TOKEN"
        else
            # 2. Fallback: Chercher dans les anciens logs systemd (si présents)
            TOKEN_URL=$(journalctl --user -u openclaw.service --no-pager | grep '?token=' | tail -n 1 | grep -oE 'https?://[a-zA-Z0-9./?=&_-]+')
        fi
        
        if [ -n "$TOKEN_URL" ]; then
          google-chrome --app="$TOKEN_URL" 2>/dev/null || xdg-open "$TOKEN_URL"
        else
          google-chrome --app=http://localhost:18789 2>/dev/null || xdg-open http://localhost:18789
        fi
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
      whiptail --msgbox "✅ Moteur OpenClaw démarré en tâche de fond !\nL'interface Web est désormais accessible sur le port 18789." 9 55
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
