#!/bin/bash
# ==========================================
# Module 22 : Undervoltage CPU & Contrôle Thermique
# ==========================================

echo -e "\n${RED}========================================================================${NC}"
echo -e "${RED}║${NC} ${WHITE}${BOLD}[22/23] Configuration Extreme Undervolting & Thermique${NC}"
echo -e "${RED}========================================================================${NC}"

CPU_VENDOR=$(lscpu | awk '/Vendor ID/ || /Fournisseur/ {print $3}' | head -n1)

if [ "$CPU_VENDOR" = "AuthenticAMD" ]; then
    echo -e "    ${WHITE}├─ [AMD CPU] Configuration RyzenAdj (Capped à 85°C)...${NC}"
    
    sudo apt install -y git build-essential cmake pciutils || true
    
    RYZEN_DIR="/opt/RyzenAdj"
    if [ ! -d "$RYZEN_DIR" ]; then
        sudo git clone --depth=1 https://github.com/FlyGoat/RyzenAdj.git "$RYZEN_DIR" >/dev/null 2>&1
        sudo bash -c "cd '$RYZEN_DIR' && mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make" >/dev/null 2>&1
        sudo cp "$RYZEN_DIR/build/ryzenadj" /usr/local/bin/ryzenadj
    fi
    
    if command -v ryzenadj &>/dev/null; then
        echo -e "    ${GRAY}├─ Création du service systemd Auto-AMD-Boost...${NC}"
        # Set max temp to 85°C (85000) to avoid noisy fans and thermal throttling
        cat <<'EOF' | sudo tee /etc/systemd/system/mados-amd-thermal.service >/dev/null
[Unit]
Description=MadOS AMD Thermal Limit (85C)
After=multi-user.target sleep.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzenadj --tctl-temp=85
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target sleep.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable --now mados-amd-thermal.service >/dev/null 2>&1
    fi
    
elif [ "$CPU_VENDOR" = "GenuineIntel" ]; then
    echo -e "    ${WHITE}├─ [INTEL CPU] Configuration intel-undervolt (-50mV Cache/Core)...${NC}"
    sudo apt install -y intel-undervolt || true
    
    if command -v intel-undervolt &>/dev/null; then
        # Default safe undervolt config
        sudo sed -i 's/undervolt 0. CPU CORE 0/undervolt 0. CPU CORE -50/' /etc/intel-undervolt.conf 2>/dev/null || true
        sudo sed -i 's/undervolt 1. CPU CACHE 0/undervolt 1. CPU CACHE -50/' /etc/intel-undervolt.conf 2>/dev/null || true
        
        sudo intel-undervolt apply >/dev/null 2>&1 || true
        sudo systemctl enable intel-undervolt.service >/dev/null 2>&1
    fi
else
    echo -e "    ${GRAY}├─ Architecture non supportée pour l'undervoltage. Ignoré.${NC}"
fi

echo -e "✅ [SUCCÈS] Contrôle thermique CPU injecté."
