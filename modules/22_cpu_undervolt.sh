#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 22_cpu_undervolt.sh
# ==============================================================================
# Module 22 : Tuning CPU (Undervolt & Overclock)
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

echo -e "\n${RED}========================================================================${NC}"
echo -e "${RED}║${NC} ${WHITE}${BOLD}[22/23] Application du Profil Thermique : ${YELLOW}${MADOS_TDP_PROFILE:-EQUILIBRE}${NC}"
echo -e "${RED}========================================================================${NC}"

CPU_VENDOR=$(lscpu | awk '/Vendor ID/ || /Fournisseur/ {print $3}' | head -n1)

if [ "$CPU_VENDOR" = "AuthenticAMD" ]; then
    echo -e "    ${WHITE}├─ [AMD CPU] Configuration RyzenAdj...${NC}"

    run_action "installer git, build-essential, cmake, pciutils" sudo apt install -y git build-essential cmake pciutils || true

    RYZEN_DIR="/opt/RyzenAdj"
    if [ ! -d "$RYZEN_DIR" ]; then
        run_action "cloner RyzenAdj dans $RYZEN_DIR" sudo git clone --depth=1 https://github.com/FlyGoat/RyzenAdj.git "$RYZEN_DIR" >/dev/null 2>&1 || true
        run_action "compiler RyzenAdj (cmake + make)" sudo bash -c "cd '$RYZEN_DIR' && mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make" >/dev/null 2>&1 || true
        run_action "installer le binaire ryzenadj dans /usr/local/bin" sudo cp "$RYZEN_DIR/build/ryzenadj" /usr/local/bin/ryzenadj || true
        run_action "nettoyer le dossier de build RyzenAdj" sudo rm -rf "$RYZEN_DIR/build" # Nettoyage post-compilation
    fi

    if command -v ryzenadj &>/dev/null; then
        AMD_ARGS="--tctl-temp=85"
        case "${MADOS_TDP_PROFILE:-EQUILIBRE}" in
            "SILENCE") AMD_ARGS="--tctl-temp=70 --stapm-limit=25000 --fast-limit=25000" ;;
            "EXTREME") AMD_ARGS="--tctl-temp=98 --stapm-limit=95000 --fast-limit=125000 --slow-limit=85000 --max-performance" ;;
            *) AMD_ARGS="--tctl-temp=85 --stapm-limit=54000" ;;
        esac

        # Le profil EXTREME est ecrit dans un service systemd reapplique a chaque
        # demarrage ET a chaque sortie de veille. 95 W soutenus / 125 W en pic et
        # une limite thermique a 98 degres sur un chassis de portable : ce n'est
        # pas un reglage anodin, et rien ne le disait ni n'expliquait comment le
        # retirer.
        if [ "${MADOS_TDP_PROFILE:-EQUILIBRE}" = "EXTREME" ]; then
            echo -e "    ${RED}⚠️  PROFIL EXTREME : 95 W soutenus, 125 W en pic, limite thermique 98 °C.${NC}"
            echo -e "    ${YELLOW}    Réappliqué à chaque démarrage et à chaque sortie de veille.${NC}"
            echo -e "    ${GRAY}    Pour revenir en arrière à tout moment :${NC}"
            echo -e "      ${GREEN}sudo systemctl disable --now mados-amd-thermal.service${NC}"
        fi

        echo -e "    ${GRAY}├─ Profil AMD injecte : $AMD_ARGS${NC}"

        if is_dry_run; then
            log_simu "écrirait le service systemd mados-amd-thermal.service (profil $AMD_ARGS) et l'activerait"
        else
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
            run_action "rechargerait la configuration de systemd" sudo systemctl daemon-reload
            sudo systemctl enable --now mados-amd-thermal.service >/dev/null 2>&1
        fi
    fi

elif [ "$CPU_VENDOR" = "GenuineIntel" ]; then
    echo -e "    ${WHITE}├─ [INTEL CPU] Configuration intel-undervolt...${NC}"
    echo -e "    ${YELLOW}⚠️  Note: L'undervolt peut echouer si 'Undervolt Protection' est actif dans le BIOS.${NC}"
    run_action "installer intel-undervolt" sudo apt install -y intel-undervolt || true

    if command -v intel-undervolt &>/dev/null; then
        CORE_UV="-60"
        CACHE_UV="-60"
        TDP_LIMITS=""
        case "${MADOS_TDP_PROFILE:-EQUILIBRE}" in
            "SILENCE") TDP_LIMITS="tdp 25000 25000" ;;
            "EXTREME") CORE_UV="-80"; CACHE_UV="-80"; TDP_LIMITS="tdp 115000 115000" ;;
            *) TDP_LIMITS="tdp 45000 65000" ;;
        esac

        echo -e "    ${GRAY}├─ Profil Intel injecte : $CORE_UV mV | $TDP_LIMITS${NC}"

        if is_dry_run; then
            log_simu "modifierait /etc/intel-undervolt.conf (core=$CORE_UV mV, cache=$CACHE_UV mV, $TDP_LIMITS) puis appliquerait et activerait le service"
        else
            # Les anciens motifs cherchaient "undervolt 0. CPU CORE 0" : ce
            # format n'existe pas. Le fichier livre par le paquet contient
            #   undervolt 0 'CPU' 0
            #   undervolt 2 'CPU Cache' 0
            # Aucune substitution n'avait donc lieu et l'undervolt restait a 0 mV.
            sudo sed -i -E "s/^(undervolt[[:space:]]+0[[:space:]]+'[^']*'[[:space:]]+)-?[0-9]+/\1$CORE_UV/" /etc/intel-undervolt.conf 2>/dev/null || true
            sudo sed -i -E "s/^(undervolt[[:space:]]+2[[:space:]]+'[^']*'[[:space:]]+)-?[0-9]+/\1$CACHE_UV/" /etc/intel-undervolt.conf 2>/dev/null || true

            # Controle : si rien n'a change, on le dit au lieu d'annoncer un succes.
            if ! grep -qE "^undervolt[[:space:]]+0[[:space:]]+'[^']*'[[:space:]]+$CORE_UV" /etc/intel-undervolt.conf 2>/dev/null; then
                echo -e "    ${YELLOW}⚠️  Format de /etc/intel-undervolt.conf inattendu : undervolt NON appliqué.${NC}"
            fi

            if [ -n "$TDP_LIMITS" ]; then
                if grep -q "^tdp " /etc/intel-undervolt.conf; then
                    sudo sed -i "s/^tdp .*/$TDP_LIMITS/" /etc/intel-undervolt.conf || true
                else
                    echo "$TDP_LIMITS" | sudo tee -a /etc/intel-undervolt.conf >/dev/null
                fi
            fi

            sudo intel-undervolt apply >/dev/null 2>&1 || true
            activer_service "sous-voltage du processeur" enable-now intel-undervolt.service
        fi
    fi
else
    echo -e "    ${GRAY}├─ Architecture non supportée pour l'undervoltage. Ignoré.${NC}"
fi

echo -e "✅ [SUCCÈS] Contrôle dynamique du TDP (${MADOS_TDP_PROFILE:-EQUILIBRE}) injecté."
