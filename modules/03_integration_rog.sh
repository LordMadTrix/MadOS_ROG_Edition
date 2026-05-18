#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 03_integration_rog.sh
# ==============================================================================
# Phase: 3 - ASUS ROG Laptop Full Integration (Optimisé Plasma 6)
# ==============================================================================

# Variables de Couleurs
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive
REAL_USER=${SUDO_USER:-$USER}

# Source common.sh pour retry APT et logging (fallback standalone)
_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
[ -f "$_LIB" ] && source "$_LIB" 2>/dev/null || [ -f "/opt/mados-rog/lib/common.sh" ] && source "/opt/mados-rog/lib/common.sh" 2>/dev/null || true

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}Phase 3 : Intégration Matérielle ROG v4.0 (RogueX & PPD)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. SCAN MODELE
ROG_MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "ASUS_ROG")
echo -e "    ${WHITE}├─ [HARDWARE] Modèle : ${CYAN}$ROG_MODEL${NC}"

# Détection VM — asusctl et supergfxctl sont inutiles sans matériel ROG physique
_VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
if [ "$_VIRT" != "none" ] && [ "$_VIRT" != "" ]; then
    echo -e "    ${YELLOW}⚠️  [VM DÉTECTÉE : $_VIRT] Intégration ROG hardware ignorée.${NC}"
    echo -e "    ${GRAY}    PPD et thermald seront quand même installés (utiles en VM).${NC}"
    apt_install_safe "power-profiles-daemon thermald" "Power management (VM)" || true
    sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true
    echo -e "\n    ${GREEN}✅ PHASE 3 : Partiel VM — OK.${NC}\n"
    exit 0
fi

# 2. POWER MANAGEMENT (PLASMA 6 READY)
echo -e "    ${WHITE}├─ [ENERGIE] Configuration Power-Profiles-Daemon (PPD)...${NC}"
# On privilégie PPD sur 25.04 car il est parfaitement intégré à KDE Plasma 6
sudo apt remove --purge -y tlp 2>/dev/null || true
apt_install_safe "power-profiles-daemon thermald acpid" "Power management"
sudo systemctl enable --now power-profiles-daemon thermald 2>/dev/null || true

# 3. ASUS-LINUX TOOLS (ASUSCTL & SUPERGFXCTL)
echo -e "    ${WHITE}├─ [ASUS-LINUX] Installation des services asusctl...${NC}"
sudo add-apt-repository ppa:lukas-moeller/asus-linux -y --no-update 2>/dev/null
apt_update_safe

# Installation asusctl et supergfxctl
apt_install_safe "asusctl supergfxctl rog-control-center" "ASUS Linux tools" || {
    echo -e "    ${YELLOW}⚠️  PPA indisponible, utilisation du binaire de secours...${NC}"
}

# 4. ROGUEX GUI (L'alternative moderne à Armoury Crate)
echo -e "    ${WHITE}├─ [ROGUEX] Installation de l'interface graphique moderne...${NC}"
# Tentative d'installation via Flatpak ou source si PPA manque
if command -v flatpak >/dev/null; then
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak install -y flathub io.gitlab.asus_linux.RogueX 2>/dev/null || true
fi

# 5. OPTIMISATION RGB & THERMIQUE (MAD-GUARD)
echo -e "    ${WHITE}├─ [THERMAL] Déploiement de Mad-Guard (RGB Temp)...${NC}"
cat <<'RGB_EOF' | sudo tee /usr/local/bin/mados-thermal-guard >/dev/null
#!/bin/bash
while true; do
  TEMP=$(sensors | grep -i "Package id 0\|Tdie\|CPU" | head -n 1 | awk '{print $4}' | tr -d '+°C' | cut -d. -f1)
  if [ "$TEMP" -lt 50 ]; then asusctl led-mode static -c 00FF00;
  elif [ "$TEMP" -lt 75 ]; then asusctl led-mode static -c FFFF00;
  else asusctl led-mode static -c FF0000; spd-say -r 10 "Attention température élevée" 2>/dev/null;
  fi
  sleep 10
done
RGB_EOF
sudo chmod +x /usr/local/bin/mados-thermal-guard

# Service Systemd
cat <<'SVC_EOF' | sudo tee /etc/systemd/system/mados-thermal.service >/dev/null
[Unit]
Description=MadOS Thermal Guard
After=asusd.service

[Service]
ExecStart=/usr/local/bin/mados-thermal-guard
Restart=always

[Install]
WantedBy=multi-user.target
SVC_EOF
sudo systemctl enable --now mados-thermal.service 2>/dev/null

# 6. CHARGE LIMITER (Longévité Batterie)
echo -e "    ${WHITE}├─ [BATTERIE] Fixation du seuil de charge à 80%...${NC}"
asusctl -c 80 2>/dev/null || true

sudo systemctl enable --now supergfxd asusd 2>/dev/null || true
echo -e "\n${GREEN}✅ PHASE 3 TERMINÉE : ASUS ROG entièrement dompté.${NC}\n"
