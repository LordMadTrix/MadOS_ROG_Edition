#!/bin/bash
# ==========================================
# MadOS ROG V2 - 03_integration_rog.sh
# ==========================================
# Phase: 3 - ASUS ROG Laptop Full Integration
# ==========================================

export DEBIAN_FRONTEND=noninteractive

REAL_USER=${SUDO_USER:-$USER}

echo -e "${RED}>>> ${WHITE}[Phase 3] ${BOLD}Intégration Matérielle Complète (ASUS ROG)...${NC}"

# Détection du modèle exact
if command -v dmidecode >/dev/null; then
    ROG_MODEL=$(sudo dmidecode -s system-product-name 2>/dev/null || echo "ASUS_UNKNOWN")
else
    ROG_MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "ASUS_UNKNOWN")
fi
echo -e "    ${WHITE}├─ [SCAN MATERIEL] Modèle détecté : ${RED}${BOLD}$ROG_MODEL${NC}"

# 1. WiFi & Audio
echo -e "    ${WHITE}├─ [RESEAU/AUDIO] Injection Firmware WiFi / Sound Open Firmware (SOF)...${NC}"
sudo apt install -y firmware-misc-nonfree linux-firmware wireless-tools iw rfkill wpasupplicant firmware-sof-signed sof-firmware alsa-base alsa-utils pulseaudio pipewire pipewire-pulse wireplumber libspa-0.2-bluetooth blueman bluetooth bluez || true

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

# 3. ASUSCTL & SUPERGFXCTL
echo -e "\n    ${WHITE}├─ [ASUSCTL] Compilation des Moteurs de Contrôle ASUS (Rust)...${NC}"
if ! command -v cargo &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >/dev/null 2>&1
    export PATH="$HOME/.cargo/bin:$PATH"
    if [ -f "$HOME/.cargo/env" ]; then source "$HOME/.cargo/env"; fi
fi

sudo apt install -y libclang-dev libudev-dev libfontconfig1-dev libseat-dev libinput-dev libdbus-1-dev libgdk-pixbuf-2.0-dev libglib2.0-dev libxml2-dev protobuf-compiler libfreetype-dev libexpat1-dev libgtk-3-dev libayatana-appindicator3-dev clang llvm

BUILD_DIR="$HOME/rog_v2_build"
mkdir -p "$BUILD_DIR"

build_tool() {
    local REPO="$1"
    local NAME="$2"
    local REPO_DIR="$BUILD_DIR/$NAME"
    cd "$BUILD_DIR"
    if [ ! -d "$REPO_DIR" ]; then git clone -q "$REPO" "$REPO_DIR"; else cd "$REPO_DIR" && git pull -q; fi
    cd "$REPO_DIR"
    if [ -f "Makefile" ]; then
        make -j"$(nproc)" >/dev/null 2>&1
        sudo make install >/dev/null 2>&1
    elif [ -f "Cargo.toml" ]; then
        cargo build --release -j"$(nproc)" >/dev/null 2>&1
        sudo cp "target/release/$NAME" /usr/local/bin/ 2>/dev/null || true
        if [ -f "target/release/rog-control-center" ]; then
            sudo cp "target/release/rog-control-center" /usr/local/bin/ 2>/dev/null || true
        fi
        if [ -d "data" ]; then
            sudo find data -name "*.service" -exec cp {} /etc/systemd/system/ \; >/dev/null 2>&1 || true
            sudo make install-data >/dev/null 2>&1 || true
        fi
    fi
    sudo systemctl daemon-reload
    sudo systemctl enable "$NAME" 2>/dev/null || true
    sudo systemctl start "$NAME" 2>/dev/null || true
}

echo -e "    ${GRAY}├─ Traitement supergfxctl...${NC}"
build_tool "https://gitlab.com/asus-linux/supergfxctl.git" "supergfxctl"
echo -e "    ${GRAY}├─ Traitement asusctl et rog-control-center...${NC}"
build_tool "https://gitlab.com/asus-linux/asusctl.git" "asusctl"

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 3 Terminée.${NC}"
