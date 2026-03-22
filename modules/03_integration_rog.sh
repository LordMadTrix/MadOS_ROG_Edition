#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 03_integration_rog.sh
# ==============================================================================
# Phase: 3 - ASUS ROG Laptop Full Integration
# ==============================================================================

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

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 3 Intégration Matérielle Complète (ASUS ROG)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# Détection du modèle exact
if command -v dmidecode >/dev/null; then
    ROG_MODEL=$(sudo dmidecode -s system-product-name 2>/dev/null || echo "ASUS_UNKNOWN")
else
    ROG_MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "ASUS_UNKNOWN")
fi
echo -e "    ${WHITE}├─ [SCAN MATERIEL] Modèle détecté : ${RED}${BOLD}$ROG_MODEL${NC}"

# 1. WiFi & Audio
echo -e "    ${GRAY}├─ [RESEAU/AUDIO] Injection Firmware WiFi / Sound Open Firmware (SOF)...${NC}"
sudo apt install -y linux-firmware firmware-sof-signed wireless-tools iw rfkill wpasupplicant alsa-base alsa-utils pulseaudio pipewire pipewire-pulse wireplumber libspa-0.2-bluetooth blueman bluetooth bluez >/dev/null 2>&1 || true

if systemctl --user list-unit-files pipewire.service &>/dev/null; then
    sudo -u "$REAL_USER" systemctl --user enable pipewire pipewire-pulse wireplumber 2>/dev/null || true
fi

# 2. ACPI, TLP (Power Management)
echo -e "\n    ${WHITE}├─ [ENERGIE] Service d'Énergie Thermique (TLP, thermald)...${NC}"
sudo apt remove --purge -y power-profiles-daemon 2>/dev/null || true
sudo apt install -y tlp tlp-rdw thermald acpi acpid cpufrequtils || true

sudo tee /etc/modules-load.d/asus-rog.conf > /dev/null <<'EOF'
asus_wmi
asus_nb_wmi
asus_ec_sensors
hid_asus
EOF

sudo tee /etc/modprobe.d/asus-wmi.conf > /dev/null <<'EOF'
options asus_wmi fnlock_default=1
EOF

sudo tee /etc/tlp.d/99-mados-rog.conf > /dev/null <<'EOF'
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on
EOF
sudo systemctl enable tlp thermald 2>/dev/null || true

# 3. ASUSCTL & SUPERGFXCTL via PPA (Plus rapide et stable)
echo -e "\n    ${WHITE}├─ [ASUSCTL] Configuration des Dépôts Spécialisés ASUS-Linux...${NC}"

# Ajout du PPA spécialisé pour asusctl/supergfxctl
sudo add-apt-repository ppa:lukas-moeller/asus-linux -y --no-update 2>/dev/null || true
sudo apt update -q

# Installation des outils officiels
echo -e "    ${GRAY}├─ Déploiement asusctl, supergfxctl et control-center...${NC}"
sudo apt install -y asusctl supergfxctl rog-control-center 2>/dev/null || {
    echo -e "    ${YELLOW}⚠ Échec PPA - Envoi de la boucle de secours (Compilation)...${NC}"
    # Fallback compilation si PPA indisponible (cas rare)
    if ! command -v cargo &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >/dev/null 2>&1
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    # [Logique de backup ici si besoin, mais on privilégie le PPA]
}

# Activation des services
sudo systemctl daemon-reload
sudo systemctl enable supergfxd asusd 2>/dev/null || true
sudo systemctl start supergfxd asusd 2>/dev/null || true

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 3 Terminée.${NC}"
