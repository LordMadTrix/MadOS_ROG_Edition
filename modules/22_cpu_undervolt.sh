#!/bin/bash
# ==========================================
# Module 22 : Tuning CPU (Undervolt & Overclock)
# ==========================================

echo -e "\n${RED}========================================================================${NC}"
echo -e "${RED}║${NC} ${WHITE}${BOLD}[22/23] Application du Profil Thermique : ${YELLOW}${MADOS_TDP_PROFILE:-EQUILIBRE}${NC}"
echo -e "${RED}========================================================================${NC}"

CPU_VENDOR=$(lscpu | awk '/Vendor ID/ || /Fournisseur/ {print $3}' | head -n1)

if [ "$CPU_VENDOR" = "AuthenticAMD" ]; then
    echo -e "    ${WHITE}├─ [AMD CPU] Configuration RyzenAdj...${NC}"
    
    sudo apt install -y git build-essential cmake pciutils || true
    
    RYZEN_DIR="/opt/RyzenAdj"
    if [ ! -d "$RYZEN_DIR" ]; then
        sudo git clone --depth=1 https://github.com/FlyGoat/RyzenAdj.git "$RYZEN_DIR" >/dev/null 2>&1
        sudo bash -c "cd '$RYZEN_DIR' && mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make" >/dev/null 2>&1
        sudo cp "$RYZEN_DIR/build/ryzenadj" /usr/local/bin/ryzenadj
    fi
    
    if command -v ryzenadj &>/dev/null; then
        local AMD_ARGS="--tctl-temp=85"
        case "${MADOS_TDP_PROFILE:-EQUILIBRE}" in
            "SILENCE") AMD_ARGS="--tctl-temp=70 --stapm-limit=25000 --fast-limit=25000" ;;
            "EXTREME") AMD_ARGS="--tctl-temp=95 --stapm-limit=65000 --fast-limit=65000 --slow-limit=54000 --max-performance" ;;
            *) AMD_ARGS="--tctl-temp=85" ;;
        esac

        echo -e "    ${GRAY}├─ Profil AMD injecté : $AMD_ARGS${NC}"
        
        cat <<EOF | sudo tee /etc/systemd/system/mados-amd-thermal.service >/dev/null
[Unit]
Description=MadOS AMD Thermal Limit (${MADOS_TDP_PROFILE:-EQUILIBRE})
After=multi-user.target sleep.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzenadj $AMD_ARGS
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target sleep.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable --now mados-amd-thermal.service >/dev/null 2>&1
    fi
    
elif [ "$CPU_VENDOR" = "GenuineIntel" ]; then
    echo -e "    ${WHITE}├─ [INTEL CPU] Configuration intel-undervolt...${NC}"
    sudo apt install -y intel-undervolt || true
    
    if command -v intel-undervolt &>/dev/null; then
        local CORE_UV="-50"
        local CACHE_UV="-50"
        local TDP_LIMITS=""
        case "${MADOS_TDP_PROFILE:-EQUILIBRE}" in
            "SILENCE") TDP_LIMITS="tdp 25000 25000" ;;
            "EXTREME") CORE_UV="-20"; CACHE_UV="-20"; TDP_LIMITS="tdp 65000 65000" ;;
        esac

        echo -e "    ${GRAY}├─ Profil Intel injecté : $CORE_UV mV | $TDP_LIMITS${NC}"

        sudo sed -i "s/undervolt 0. CPU CORE 0/undervolt 0. CPU CORE $CORE_UV/" /etc/intel-undervolt.conf 2>/dev/null || true
        sudo sed -i "s/undervolt 1. CPU CACHE 0/undervolt 1. CPU CACHE $CACHE_UV/" /etc/intel-undervolt.conf 2>/dev/null || true
        
        if [ -n "$TDP_LIMITS" ]; then
            if grep -q "^tdp " /etc/intel-undervolt.conf; then
                sudo sed -i "s/^tdp .*/$TDP_LIMITS/" /etc/intel-undervolt.conf
            else
                echo "$TDP_LIMITS" | sudo tee -a /etc/intel-undervolt.conf >/dev/null
            fi
        fi
        
        sudo intel-undervolt apply >/dev/null 2>&1 || true
        sudo systemctl enable intel-undervolt.service >/dev/null 2>&1
    fi
else
    echo -e "    ${GRAY}├─ Architecture non supportée pour l'undervoltage. Ignoré.${NC}"
fi

echo -e "✅ [SUCCÈS] Contrôle dynamique du TDP ($MADOS_TDP_PROFILE) injecté."
