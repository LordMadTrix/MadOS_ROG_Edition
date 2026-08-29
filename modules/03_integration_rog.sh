#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 03_integration_rog.sh
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

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

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
run_action "installerait les paquets firmware WiFi/audio ROG" sudo apt install -y linux-firmware firmware-sof-signed wireless-tools iw rfkill wpasupplicant alsa-base alsa-utils pulseaudio pipewire pipewire-pulse wireplumber libspa-0.2-bluetooth blueman bluetooth bluez >/dev/null 2>&1 || true

if systemctl --user list-unit-files pipewire.service &>/dev/null; then
    run_action "activerait pipewire/pipewire-pulse/wireplumber pour $REAL_USER" sudo -u "$REAL_USER" systemctl --user enable pipewire pipewire-pulse wireplumber 2>/dev/null || true
fi

# 2. ACPI, TLP (Power Management)
echo -e "\n    ${WHITE}├─ [ENERGIE] Service d'Énergie Thermique (TLP, thermald)...${NC}"
run_action "supprimerait power-profiles-daemon" sudo apt remove --purge -y power-profiles-daemon 2>/dev/null || true
run_action "installerait tlp, tlp-rdw, thermald, acpi, acpid, cpufrequtils" sudo apt install -y tlp tlp-rdw thermald acpi acpid cpufrequtils || true

if is_dry_run; then
    log_simu "écrirait /etc/modules-load.d/asus-rog.conf, /etc/modprobe.d/asus-wmi.conf et /etc/tlp.d/99-mados-rog.conf, puis activerait tlp/thermald"
else
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
fi

# 3. ASUSCTL & SUPERGFXCTL
echo -e "\n    ${WHITE}├─ [ASUSCTL] Configuration des Dépôts Spécialisés ASUS-Linux...${NC}"

# Ajout du PPA Officiel
run_action "ajouterait le PPA lukas-moeller/asus-linux" sudo add-apt-repository ppa:lukas-moeller/asus-linux -y --no-update 2>/dev/null || true
run_action "rafraîchirait les index APT (apt update)" sudo apt update -q || true

# Installation des outils officiels
echo -e "    ${GRAY}├─ Déploiement asusctl, supergfxctl et control-center...${NC}"
if is_dry_run; then
    log_simu "installerait asusctl, supergfxctl et rog-control-center (avec repli sur compilation cargo/git si le PPA échoue)"
else
    sudo apt install -y asusctl supergfxctl rog-control-center 2>/dev/null || {
        echo -e "    ${YELLOW}⚠ Échec PPA - Tentative de Compilation de Sauvetage...${NC}"
        sudo apt install -y libudev-dev libfontconfig-dev libseat-dev libinput-dev libdbus-1-dev libxkbcommon-dev libgtk-3-dev pkg-config cmake clang libclang-dev || true
        if ! command -v cargo &>/dev/null; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >/dev/null 2>&1
            source "$HOME/.cargo/env"
        fi

        BUILD_DIR="/tmp/mados-asus-build"
        mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"

        # asusctl compile
        echo -e "    ${GRAY}├─ Compilation de asusctl...${NC}"
        git clone --depth 1 https://gitlab.com/asus-linux/asusctl.git && cd asusctl
        cargo build --release --locked && sudo make install PREFIX=/usr || true
        cd ..

        # supergfxctl compile
        echo -e "    ${GRAY}├─ Compilation de supergfxctl...${NC}"
        git clone --depth 1 https://gitlab.com/asus-linux/supergfxctl.git && cd supergfxctl
        cargo build --release --locked && sudo make install || true
    }
fi
run_action "rechargerait la configuration systemd (daemon-reload)" sudo systemctl daemon-reload || true

# 4. OpenRGB Integration
echo -e "\n    ${WHITE}├─ [OPENRGB] Installation du contrôleur LED universel...${NC}"
run_action "ajouterait le PPA th337/openrgb" sudo add-apt-repository ppa:th337/openrgb -y --no-update 2>/dev/null || true
run_action "rafraîchirait les index APT (apt update)" sudo apt update -q || true
run_action "installerait openrgb" sudo apt install -y openrgb 2>/dev/null || echo -e "    ${YELLOW}⚠ Échec installation OpenRGB.${NC}"

    # ---- NOUVEAU : Script RGB Dynamique (Réaction Température) ----
    echo -e "    ${GRAY}├─ Injection du Moniteur RGB Réactif (ASUS ROG)...${NC}"
    run_action "installerait lm-sensors" sudo apt install -y lm-sensors 2>/dev/null || true
    if is_dry_run; then
        log_simu "installerait /usr/local/bin/mados-rgb-temp, le service systemd mados-rgb.service, puis l'activerait et le démarrerait"
    else
    cat <<'RGB_EOF' | sudo tee /usr/local/bin/mados-rgb-temp >/dev/null
#!/bin/bash
while true; do
  TEMP=$(sensors | grep "Package id 0" | awk '{print $4}' | tr -d '+°C' | cut -d. -f1)
  if [ "$TEMP" -lt 55 ]; then COLOR="00FF00"; # Green (Cool)
  elif [ "$TEMP" -lt 80 ]; then COLOR="FFFF00"; # Yellow (Warm)
  else COLOR="FF0000"; # Red (Hot)
  fi
  asusctl led-mode static -c $COLOR >/dev/null 2>&1

  # ---- NOUVEAU : Thermal Safety Guard (Alerte 90C) ----
  if [ "$TEMP" -gt 90 ]; then
    # Alerte Vocale
    spd-say -v fr-fr -r 0 "Alerte Thermique ! Ventilation forcée engagée." 2>/dev/null
    # Force les ventilateurs au maximum (Profil Performance/Turbo)
    asusctl profile -P Performance 2>/dev/null
  fi
  sleep 5
done
RGB_EOF
    sudo chmod +x /usr/local/bin/mados-rgb-temp || true

    # Création du service pour le démarrage automatique
    cat <<'SVC_EOF' | sudo tee /etc/systemd/system/mados-rgb.service >/dev/null
[Unit]
Description=MadOS RGB Temp Monitor
After=multi-user.target

[Service]
ExecStart=/usr/local/bin/mados-rgb-temp
Restart=always

[Install]
WantedBy=multi-user.target
SVC_EOF
    sudo systemctl enable mados-rgb.service >/dev/null 2>&1 || true
    sudo systemctl start mados-rgb.service >/dev/null 2>&1 || true
    fi

run_action "activerait le service supergfxd et asusd" sudo systemctl enable supergfxd asusd 2>/dev/null || true
run_action "démarrerait le service supergfxd et asusd" sudo systemctl start supergfxd asusd 2>/dev/null || true

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 3 Terminée.${NC}"
