#!/bin/bash
# ==============================================================================
# OpenClaw — Installation de l'agent IA avec contrôle total du PC
# MadOS ROG Edition v4.0 — par LordMadTrix
# Lancer avec : sudo bash install_openclaw.sh
# ==============================================================================

set -e
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Dossier source (là où ce script se trouve)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_PY="$SCRIPT_DIR/assets/openclaw.py"

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${WHITE}OpenClaw — Agent IA Contrôle Total PC${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Vérifier Ollama
echo -e "${CYAN}[1/5]${NC} Vérification Ollama..."
if ! command -v ollama >/dev/null 2>&1; then
    echo -e "    ${YELLOW}⚠️  Ollama non installé — installation en cours...${NC}"
    curl -fsSL https://ollama.com/install.sh | bash || true
else
    echo -e "    ${GREEN}✅ Ollama présent${NC}"
fi

# Démarrer Ollama si nécessaire
sudo systemctl enable --now ollama 2>/dev/null || true
sleep 2

# Lister les modèles disponibles
AVAILABLE=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -v '^$' | tr '\n' ' ')
if [ -z "$AVAILABLE" ]; then
    echo -e "    ${YELLOW}⚠️  Aucun modèle. Téléchargement de gemma2:9b...${NC}"
    sudo -u "$REAL_USER" ollama pull gemma2:9b || true
else
    echo -e "    ${GREEN}✅ Modèles disponibles: ${CYAN}$AVAILABLE${NC}"
fi

# 2. Déployer le Python agent
echo -e "${CYAN}[2/5]${NC} Déploiement de l'agent Python..."
mkdir -p /opt/openclaw

if [ -f "$SRC_PY" ]; then
    cp "$SRC_PY" /opt/openclaw/openclaw.py
    echo -e "    ${GREEN}✅ Agent copié depuis $SRC_PY${NC}"
else
    echo -e "    ${RED}❌ Fichier source introuvable: $SRC_PY${NC}"
    echo -e "    ${YELLOW}   Assurez-vous que ce script est lancé depuis le dossier MadOS_ROG_Edition${NC}"
    exit 1
fi

chmod 755 /opt/openclaw/openclaw.py
chown -R "$REAL_USER:$REAL_USER" /opt/openclaw

# 3. Créer le lanceur /usr/local/bin/openclaw
echo -e "${CYAN}[3/5]${NC} Création du lanceur système..."
cat > /usr/local/bin/openclaw << 'LAUNCHER_EOF'
#!/bin/bash
exec python3 /opt/openclaw/openclaw.py "$@"
LAUNCHER_EOF
chmod 755 /usr/local/bin/openclaw
echo -e "    ${GREEN}✅ Commande 'openclaw' disponible globalement${NC}"

# 4. Créer le raccourci Bureau (KDE/GNOME)
echo -e "${CYAN}[4/5]${NC} Création du raccourci Bureau..."

# Trouver le bureau (FR ou EN)
DESKTOP_DIR=""
for d in "$USER_HOME/Bureau" "$USER_HOME/Desktop"; do
    [ -d "$d" ] && DESKTOP_DIR="$d" && break
done
[ -z "$DESKTOP_DIR" ] && DESKTOP_DIR="$USER_HOME/Desktop" && mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/OpenClaw_IA.desktop" << EOF
[Desktop Entry]
Name=OpenClaw IA
GenericName=Agent IA MadOS ROG
Comment=Intelligence Artificielle avec contrôle total du PC
Exec=konsole -e bash -c 'openclaw; bash'
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Utility;System;
Keywords=IA;AI;Ollama;OpenClaw;MadOS;
EOF
chown "$REAL_USER:$REAL_USER" "$DESKTOP_DIR/OpenClaw_IA.desktop"
chmod +x "$DESKTOP_DIR/OpenClaw_IA.desktop"

# Marquer comme de confiance (KDE)
sudo -u "$REAL_USER" gio set "$DESKTOP_DIR/OpenClaw_IA.desktop" metadata::trusted true 2>/dev/null || true
echo -e "    ${GREEN}✅ Raccourci créé sur le Bureau${NC}"

# 5. Test rapide
echo -e "${CYAN}[5/5]${NC} Test de connectivité Ollama..."
if curl -s --max-time 5 http://localhost:11434/api/tags >/dev/null 2>&1; then
    MODEL_COUNT=$(curl -s http://localhost:11434/api/tags | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('models',[])))" 2>/dev/null || echo "?")
    echo -e "    ${GREEN}✅ Ollama actif — $MODEL_COUNT modèle(s) chargé(s)${NC}"
else
    echo -e "    ${YELLOW}⚠️  Ollama ne répond pas encore (peut prendre quelques secondes au démarrage)${NC}"
fi

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ OpenClaw installé avec succès !                           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e ""
echo -e "  ${WHITE}Lancer OpenClaw :${NC}"
echo -e "  ${CYAN}  openclaw${NC}                     (depuis n'importe quel terminal)"
echo -e "  ${CYAN}  openclaw qwen3.6:27b${NC}         (forcer un modèle spécifique)"
echo -e "  ${CYAN}  Icône 'OpenClaw IA' sur le Bureau${NC}"
echo -e ""
echo -e "  ${GRAY}Modèles recommandés : qwen3.6:27b (meilleur), shadow:latest, gemma2:9b (rapide)${NC}"
echo -e ""
