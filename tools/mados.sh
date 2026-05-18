#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - CLI Wrapper
# "NTSYNC Edition" - Code by LordMadTrix & Antigravity AI
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

show_help() {
    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${RED}MadOS 4.0 CLI${NC}  —  Republic of Gamers Edition"
    echo -e "  Usage: ${CYAN}mados${NC} <commande> [option]"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    echo -e "  ${WHITE}HARDWARE${NC}"
    echo -e "  ${CYAN}shift game${NC}              Profil PERFORMANCE (RTX Boost + RGB Rouge)"
    echo -e "  ${CYAN}shift eco${NC}               Profil SILENCE (GPU Intégré + RGB Off)"
    echo -e "  ${CYAN}shift balance${NC}           Profil ÉQUILIBRÉ (défaut)"
    echo -e "  ${CYAN}aura rainbow${NC}            RGB : cycle arc-en-ciel"
    echo -e "  ${CYAN}aura pulse${NC}              RGB : pulsation"
    echo -e "  ${CYAN}aura static -c RRGGBB${NC}  RGB : couleur fixe (ex: ff003c)"
    echo -e "  ${CYAN}aura off${NC}                RGB : éteint"
    echo -e "  ${CYAN}batt [60|80|100]${NC}        Limite de charge batterie"
    echo -e "  ${CYAN}temps${NC}                   Températures CPU/GPU"
    echo ""
    echo -e "  ${WHITE}SYSTÈME${NC}"
    echo -e "  ${CYAN}status${NC}                  Vue d'ensemble du système ROG"
    echo -e "  ${CYAN}night on|off${NC}            Filtre lumière bleue"
    echo -e "  ${CYAN}doctor${NC}                  État de tous les composants MadOS (vert/rouge)"
    echo -e "  ${CYAN}check${NC}                   Diagnostic de santé du système"
    echo -e "  ${CYAN}clean${NC}                   Nettoyage système (apt + journaux)"
    echo -e "  ${CYAN}snapshot${NC}                Crée un snapshot Timeshift"
    echo -e "  ${CYAN}logs${NC}                    Derniers 100 logs d'installation MadOS"
    echo -e "  ${CYAN}logs --errors${NC}           Affiche uniquement les erreurs"
    echo -e "  ${CYAN}logs grep <motif>${NC}       Recherche dans les logs"
    echo -e "  ${CYAN}logs --follow${NC}           Suit les logs en temps réel"
    echo -e "  ${CYAN}kernel${NC}                  Infos kernel actif et disponibles"
    echo -e "  ${CYAN}update${NC}                  Lance le module de mise à jour MadOS"
    echo ""
    echo -e "  ${WHITE}IA & VR${NC}"
    echo -e "  ${CYAN}ai start${NC}                Démarre le serveur Ollama"
    echo -e "  ${CYAN}ai stop${NC}                 Arrête le serveur Ollama"
    echo -e "  ${CYAN}ai status${NC}               Statut du service Ollama"
    echo -e "  ${CYAN}vr start${NC}                Lance ALVR (streaming Meta Quest)"
    echo ""
    echo -e "  ${WHITE}LOGICIELS${NC}"
    echo -e "  ${CYAN}store [app]${NC}             Installe : steam discord heroic lutris bottles obs nvtop"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

cmd_status() {
    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}MadOS ROG — Statut Système${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local kernel profile gpu_mode batt_limit cpu_temp version

    version=$(cat /opt/mados-rog/VERSION 2>/dev/null || echo "${GRAY}inconnue${NC}")
    echo -e "  ${CYAN}MadOS   :${NC} v${version}"

    kernel=$(uname -r)
    echo -e "  ${CYAN}Kernel  :${NC} $kernel"

    profile=$(asusctl profile 2>/dev/null | grep -oiE 'Performance|Balanced|Quiet')
    [ -z "$profile" ] && profile=$(powerprofilesctl get 2>/dev/null)
    [ -z "$profile" ] && profile="${GRAY}N/A${NC}"
    echo -e "  ${CYAN}Profil  :${NC} $profile"

    gpu_mode=$(supergfxctl --get 2>/dev/null)
    [ -z "$gpu_mode" ] && gpu_mode="${GRAY}N/A${NC}"
    echo -e "  ${CYAN}GPU     :${NC} $gpu_mode"

    batt_limit=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null \
                 || cat /sys/class/power_supply/BAT1/charge_control_end_threshold 2>/dev/null)
    if [ -n "$batt_limit" ]; then
        echo -e "  ${CYAN}Batterie:${NC} ${batt_limit}%"
    else
        echo -e "  ${CYAN}Batterie:${NC} ${GRAY}N/A${NC}"
    fi

    cpu_temp=$(awk 'BEGIN{m=0} {if($1+0>m) m=$1+0} END{if(m>0) printf "%.0f°C", m/1000; else print "N/A"}' \
               /sys/class/thermal/thermal_zone*/temp 2>/dev/null)
    [ -z "$cpu_temp" ] && cpu_temp="${GRAY}N/A${NC}"
    echo -e "  ${CYAN}CPU Temp:${NC} $cpu_temp"

    if systemctl is-active --quiet ollama 2>/dev/null; then
        echo -e "  ${CYAN}Ollama  :${NC} ${GREEN}actif${NC}"
    else
        echo -e "  ${CYAN}Ollama  :${NC} ${GRAY}inactif${NC}"
    fi

    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

case "$1" in
    shift)
        case "$2" in
            game)
                echo -e "${RED}🚀 ENGAGEMENT MODE GAME...${NC}"
                asusctl profile -P Performance 2>/dev/null
                asusctl led-mode static -c ff0000 2>/dev/null
                powerprofilesctl set performance 2>/dev/null
                echo -e "${GREEN}✓ Mode GAME activé${NC}"
                ;;
            eco)
                echo -e "${GREEN}🍃 ENGAGEMENT MODE ECO...${NC}"
                asusctl profile -P Quiet 2>/dev/null
                asusctl led-mode static -c 000000 2>/dev/null
                powerprofilesctl set power-saver 2>/dev/null
                if supergfxctl -m integrated 2>/dev/null; then
                    echo -e "${YELLOW}  ⚠  Basculement GPU → Intégré : déconnexion/reconnexion requise.${NC}"
                fi
                echo -e "${GREEN}✓ Mode ECO activé${NC}"
                ;;
            balance)
                echo -e "${CYAN}⚖️  RETOUR MODE ÉQUILIBRÉ...${NC}"
                asusctl profile -P Balanced 2>/dev/null
                asusctl led-mode static -c ff003c 2>/dev/null
                powerprofilesctl set balanced 2>/dev/null
                echo -e "${GREEN}✓ Mode BALANCE activé${NC}"
                ;;
            *)
                echo -e "${YELLOW}Usage: mados shift [game|eco|balance]${NC}"
                ;;
        esac
        ;;
    aura)
        case "$2" in
            rainbow)
                asusctl led-mode rainbow-cycle 2>/dev/null \
                    && echo -e "${GREEN}✓ RGB : rainbow-cycle${NC}"
                ;;
            pulse)
                asusctl led-mode pulse 2>/dev/null \
                    && echo -e "${GREEN}✓ RGB : pulse${NC}"
                ;;
            off)
                asusctl led-mode static -c 000000 2>/dev/null \
                    && echo -e "${GREEN}✓ RGB : éteint${NC}"
                ;;
            static)
                asusctl led-mode static "${@:3}" 2>/dev/null \
                    && echo -e "${GREEN}✓ RGB : static appliqué${NC}"
                ;;
            *)
                echo -e "${YELLOW}Usage: mados aura [rainbow|pulse|static -c RRGGBB|off]${NC}"
                ;;
        esac
        ;;
    batt)
        case "$2" in
            60|80|100)
                asusctl -c "$2" 2>/dev/null \
                    && echo -e "${GREEN}✓ Limite batterie : $2%${NC}" \
                    || echo -e "${RED}✗ Impossible de régler la limite (asusctl installé ?)${NC}"
                ;;
            *)
                echo -e "${YELLOW}Usage: mados batt [60|80|100]${NC}"
                ;;
        esac
        ;;
    ai)
        case "$2" in
            start)
                sudo systemctl start ollama 2>/dev/null \
                    && echo -e "${GREEN}✓ Ollama démarré${NC}" \
                    || echo -e "${RED}✗ Impossible de démarrer Ollama (module 29 installé ?)${NC}"
                ;;
            stop)
                sudo systemctl stop ollama 2>/dev/null \
                    && echo -e "${GREEN}✓ Ollama arrêté${NC}" \
                    || echo -e "${RED}✗ Impossible d'arrêter Ollama${NC}"
                ;;
            status)
                if systemctl cat ollama &>/dev/null; then
                    systemctl status ollama --no-pager
                else
                    echo -e "${YELLOW}Ollama non installé (module 29)${NC}"
                fi
                ;;
            *)
                echo -e "${YELLOW}Usage: mados ai [start|stop|status]${NC}"
                ;;
        esac
        ;;
    snapshot)
        sudo timeshift --create --comments "MadOS snapshot $(date +%Y-%m-%d)" 2>/dev/null \
            || echo -e "${RED}✗ Timeshift introuvable (module 07 installé ?)${NC}"
        ;;
    vr)
        case "$2" in
            start)
                flatpak run alvr.ALVR 2>/dev/null \
                    || echo -e "${RED}✗ ALVR introuvable (module 26 installé ?)${NC}"
                ;;
            *)
                echo -e "${YELLOW}Usage: mados vr [start]${NC}"
                ;;
        esac
        ;;
    night)
        case "$2" in
            on|off)
                if [ -x "/usr/local/bin/mados-night-mode" ]; then
                    /usr/local/bin/mados-night-mode "$2"
                else
                    echo -e "${RED}✗ mados-night-mode introuvable (module 32 installé ?)${NC}"
                fi
                ;;
            *)
                echo -e "${YELLOW}Usage: mados night [on|off]${NC}"
                ;;
        esac
        ;;
    status)
        cmd_status
        ;;
    check)
        if [ -f "/opt/mados-rog/modules/25_sante_systeme.sh" ]; then
            sudo bash /opt/mados-rog/modules/25_sante_systeme.sh
        else
            echo -e "${RED}✗ Module de diagnostic introuvable (module 25 installé ?)${NC}"
        fi
        ;;
    doctor)
        echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${WHITE}MadOS Doctor — Diagnostic des composants${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

        _ok="${GREEN}✓${NC}"
        _ko="${RED}✗${NC}"
        _warn="${YELLOW}⚠${NC}"

        _check() {
            local label="$1" cmd="$2"
            if eval "$cmd" &>/dev/null; then
                echo -e "  $_ok  $(printf '%-28s' "$label") ${GREEN}OK${NC}"
            else
                echo -e "  $_ko  $(printf '%-28s' "$label") ${RED}MANQUANT${NC}"
            fi
        }

        # Kernel
        if uname -r | grep -q "xanmod"; then
            echo -e "  $_ok  $(printf '%-28s' "Kernel XanMod") ${GREEN}$(uname -r)${NC}"
        else
            echo -e "  $_warn  $(printf '%-28s' "Kernel XanMod") ${YELLOW}$(uname -r) (non-XanMod)${NC}"
        fi

        # NTSYNC
        if [ -c /dev/ntsync ]; then
            echo -e "  $_ok  $(printf '%-28s' "NTSYNC (/dev/ntsync)") ${GREEN}actif${NC}"
        else
            echo -e "  $_warn  $(printf '%-28s' "NTSYNC (/dev/ntsync)") ${YELLOW}absent (reboot requis ?)${NC}"
        fi

        _check "asusctl"           "command -v asusctl"
        _check "supergfxctl"       "command -v supergfxctl"
        _check "asusd.service"     "systemctl is-active asusd"
        _check "supergfxd.service" "systemctl is-active supergfxd"
        _check "auto-cpufreq"      "command -v auto-cpufreq"
        _check "ollama"            "command -v ollama"
        _check "ollama.service"    "systemctl is-active ollama"
        _check "gamemode"          "command -v gamemoded"
        _check "mangohud"          "command -v mangohud"
        _check "gamescope"         "command -v gamescope"
        _check "flatpak"           "command -v flatpak"
        _check "timeshift"         "command -v timeshift"
        _check "plymouth theme"    "plymouth --get-default-theme 2>/dev/null | grep -q mados"
        _check "BBR actif"         "sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr"
        _check "fq_codel qdisc"    "sysctl net.core.default_qdisc 2>/dev/null | grep -q fq_codel"
        _check "zram"              "ls /dev/zram* 2>/dev/null"
        _check "MadOS CLI"         "command -v mados"
        _check "VERSION installée" "[ -f /opt/mados-rog/VERSION ]"

        echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        ;;
    clean)
        echo -e "${CYAN}🧹 Nettoyage système...${NC}"
        sudo apt-get autoremove -y
        sudo apt-get clean
        sudo journalctl --vacuum-time=7d
        echo -e "${GREEN}✓ Nettoyage terminé${NC}"
        ;;
    temps)
        echo -e "${CYAN}Températures :${NC}"
        if command -v sensors &>/dev/null; then
            sensors 2>/dev/null
        else
            echo -e "${YELLOW}⚠  'lm-sensors' non installé — zones thermiques brutes :${NC}"
            for _zone in /sys/class/thermal/thermal_zone*/; do
                _type=$(cat "$_zone/type" 2>/dev/null)
                _temp=$(cat "$_zone/temp" 2>/dev/null)
                [[ "$_temp" =~ ^[0-9]+$ ]] && printf "  %-24s : %s°C\n" "$_type" "$(( _temp / 1000 ))"
            done
        fi
        ;;
    kernel)
        echo -e "${CYAN}Kernel actif  :${NC} $(uname -r)"
        echo -e "${CYAN}Kernels dispo :${NC}"
        dpkg --list 'linux-image-*' 2>/dev/null | awk '/^ii/{print "  "$3}'
        ;;
    logs)
        _LOG=/var/log/mados/mados_install.log
        if [ ! -f "$_LOG" ]; then
            echo -e "${YELLOW}Aucun log trouvé.${NC}"
        else
            case "$2" in
                --errors|-e)
                    echo -e "${CYAN}Erreurs dans les logs MadOS :${NC}"
                    grep -iE '\[ERR\]|error|failed|✗|ÉCHEC' "$_LOG" | tail -n 50
                    ;;
                grep|search)
                    if [ -z "$3" ]; then
                        echo -e "${YELLOW}Usage: mados logs grep <motif>${NC}"
                    else
                        grep -i "$3" "$_LOG" | tail -n 100
                    fi
                    ;;
                --follow|-f)
                    tail -f "$_LOG"
                    ;;
                *)
                    tail -n 100 "$_LOG"
                    ;;
            esac
        fi
        ;;
    guide)
        if [ -f "/opt/mados-rog/docs/PENSE_BETE_MADOS.md" ]; then
            cat /opt/mados-rog/docs/PENSE_BETE_MADOS.md
        else
            echo -e "${YELLOW}Guide introuvable.${NC}"
        fi
        ;;
    store)
        case "$2" in
            steam)   sudo apt-get install -y steam-installer ;;
            discord) flatpak install -y flathub com.discordapp.Discord ;;
            heroic)  flatpak install -y flathub com.heroicgameslauncher.hgl ;;
            lutris)  flatpak install -y flathub net.lutris.Lutris ;;
            bottles) flatpak install -y flathub com.usebottles.bottles ;;
            obs)     flatpak install -y flathub com.obsproject.Studio ;;
            nvtop)   sudo apt-get install -y nvtop ;;
            *)       echo -e "${YELLOW}Usage: mados store [steam|discord|heroic|lutris|bottles|obs|nvtop]${NC}" ;;
        esac
        ;;
    uninstall)
        echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${WHITE}MadOS Uninstall — Suppression des composants${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

        _STATE="/var/lib/mados/install_state"

        if [ ! -f "$_STATE" ]; then
            echo -e "  ${YELLOW}⚠  Aucune installation MadOS détectée (state file absent).${NC}\n"
            exit 0
        fi

        echo -e "  ${GRAY}Modules installés détectés :${NC}"
        grep ":OK:" "$_STATE" 2>/dev/null | cut -d: -f1 | while read -r mod; do
            echo -e "    ${CYAN}·${NC} $mod"
        done

        echo -e "\n  ${YELLOW}Cette opération va supprimer :${NC}"
        echo -e "  ${GRAY}· /opt/mados-rog/          (fichiers MadOS)${NC}"
        echo -e "  ${GRAY}· /usr/local/bin/mados     (CLI)${NC}"
        echo -e "  ${GRAY}· /etc/bash_completion.d/mados${NC}"
        echo -e "  ${GRAY}· /var/lib/mados/          (state + checkpoints)${NC}"
        echo -e "  ${GRAY}· /var/log/mados/          (logs)${NC}"
        echo -e "  ${GRAY}· Alias dans .bashrc / .zshrc${NC}"

        echo ""
        read -r -p "  Confirmer la désinstallation ? [o/N] " _yn
        [[ "$_yn" =~ ^[oO]$ ]] || { echo -e "  ${GRAY}Annulé.${NC}\n"; exit 0; }

        echo -e "\n  ${CYAN}Suppression en cours...${NC}"
        sudo rm -rf /opt/mados-rog                         && echo -e "  ${GREEN}✓${NC} /opt/mados-rog supprimé"
        sudo rm -f  /usr/local/bin/mados                   && echo -e "  ${GREEN}✓${NC} CLI mados supprimé"
        sudo rm -f  /etc/bash_completion.d/mados           && echo -e "  ${GREEN}✓${NC} Completion supprimée"
        sudo rm -rf /var/lib/mados                         && echo -e "  ${GREEN}✓${NC} State supprimé"
        sudo rm -rf /var/log/mados                         && echo -e "  ${GREEN}✓${NC} Logs supprimés"
        sudo rm -f  /etc/systemd/system/mados-thermal.service 2>/dev/null
        sudo systemctl daemon-reload 2>/dev/null

        # Suppression des alias dans les rc files de l'utilisateur courant
        _RUSER="${SUDO_USER:-$USER}"
        _RHOME=$(getent passwd "$_RUSER" | cut -d: -f6)
        for _rc in "$_RHOME/.bashrc" "$_RHOME/.zshrc"; do
            [ -f "$_rc" ] && sudo -u "$_RUSER" sed -i '/alias mados=/d' "$_rc"
        done
        echo -e "  ${GREEN}✓${NC} Alias supprimés de .bashrc / .zshrc"

        echo -e "\n  ${GREEN}✓ MadOS désinstallé. Les paquets système (asusctl, ollama, etc.) sont conservés.${NC}"
        echo -e "  ${GRAY}  Pour les supprimer : sudo apt remove asusctl supergfxctl auto-cpufreq${NC}\n"
        ;;
    update)
        if [ -f "/opt/mados-rog/modules/24_mados_update.sh" ]; then
            sudo bash /opt/mados-rog/modules/24_mados_update.sh
        else
            echo -e "${RED}✗ Module d'update introuvable (module 24 installé ?)${NC}"
        fi
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${YELLOW}Commande inconnue : $1${NC}"
        show_help
        ;;
esac
