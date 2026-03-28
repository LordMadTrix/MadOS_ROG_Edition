#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - install_local.sh
# ==============================================================================
# Usage: Ce script est appelé automatiquement par le bootstrapper install.sh
# Ne pas lancer manuellement avec wget !
# ne coupe le script en plein milieu si l'entrée standard est consommée.
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

main() {
    local AUTO_FLAG=false
    # Analyse des arguments
    for arg in "$@"; do
        case $arg in
            --auto|-y) AUTO_FLAG=true ;;
        esac
    done

    export DEBIAN_FRONTEND=noninteractive
    # IMPORTANT: Mode 'l' (list) pour éviter de couper le SSH en redémarrant le réseau
    export NEEDRESTART_MODE=l
    export CURRENT_MODULE="SAUVETAGE"
    set -uo pipefail

    # ---- OPÉRATION FORCE BRUTE : Libération des verrous APT/DPKG/SNAP ----
    # Évite le blocage infini si l'install précédente a crashé
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} 🧱 ${WHITE}${BOLD}Opération Libération des Verrous Système...${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

    sudo pkill -9 apt 2>/dev/null || true
    sudo pkill -9 apt-get 2>/dev/null || true
    sudo pkill -9 dpkg 2>/dev/null || true
    sudo pkill -9 snapd 2>/dev/null || true
    sudo rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock 2>/dev/null || true
    sudo dpkg --configure -a 2>/dev/null || true
    echo -e '#!/bin/sh\nexit 101' | sudo tee /usr/sbin/policy-rc.d > /dev/null
    sudo chmod +x /usr/sbin/policy-rc.d || true
    # Retirer le blocage à la fin du script (même en cas de crash)
    trap 'sudo rm -f /usr/sbin/policy-rc.d' EXIT

    # ---- BOMBE ANTI-SNAP : On bloque tout de suite l'ennemi ----
    sudo systemctl stop snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true
    sudo systemctl disable snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true
    sudo tee /etc/apt/preferences.d/nosnap.pref > /dev/null <<EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

    # ==============================================================================
    # Charger les fonctions communes
    # ==============================================================================
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export PROJECT_ROOT="$SCRIPT_DIR"
    if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
        source "$SCRIPT_DIR/lib/common.sh"
    else
        echo "ERREUR CRITIQUE: lib/common.sh non trouvé!"
        exit 1
    fi
    
    # Initialiser les optimisations
    wait_for_apt
    ensure_nala

    # 🚧 RÉPARATION CRITIQUE : Recolier les morceau si crash précédent 🚧
    echo -e "${YELLOW}[!] Nettoyage des résidus et restauration des systèmes de fichiers...${NC}"
    # Désactivation temporaire des erreurs pour purger les éléments bloquants
    sudo dpkg --configure -a 2>/dev/null || true
    sudo apt-get install -f -y 2>/dev/null || true
    
    # Restauration impérative du support LVM/Disque (Fix pour l'erreur initramfs /dev/mapper)
    echo -e "${GRAY}    ├─ Restauration du support LVM (Disques Virtuels)...${NC}"
    sudo apt-get install -y lvm2 coreutils thin-provisioning-tools 2>/dev/null || true

    # Forcer la désinstallation de v4l2loopback-dkms s'il est resté dans un état de crash (Bug Critique identifié)
    if dpkg -l | grep -q "v4l2loopback-dkms"; then
        echo -e "${GRAY}    ├─ Neutralisation du pilote caméra corrompu...${NC}"
        sudo apt-get purge -y v4l2loopback-dkms 2>/dev/null || true
    fi
    # Initialiser les pièges d'erreur et logs
    setup_error_traps
    init_mados_logging

    clear
    echo ""
    echo -e "${RED}  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗ ${NC}"
    echo -e "${RED}  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝ ${NC}"
    echo -e "${RED}  ██╔████╔██║███████║██║  ██║██║   ██║███████╗ ${NC}"
    echo -e "${WHITE}  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║ ${NC}"
    echo -e "${WHITE}  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║ ${NC}"
    echo -e "${WHITE}  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝ ${NC}"
    echo ""
    echo -e "${RED}     ╔══════════════════════════════╗${NC}"
    echo -e "${RED}     ║    INSTALLATEUR MadOS 3.0    ║${NC}"
    echo -e "${RED}     ║     by LordMadTrix           ║${NC}"
    echo -e "${RED}     ╚══════════════════════════════╝${NC}"
    echo ""

    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  [1/1] Vérifications Pré-Installation...${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Vérifications critiques
    check_sudo_access || exit 1
    check_disk_space 10 || exit 1
    
    # ---- PROTECTION GOD-TIER : Auto-Clonage vers /opt (Safe Zone) ----
    if [[ "$SCRIPT_DIR" == *"/mnt/"* || "$SCRIPT_DIR" == *"/media/"* ]]; then
        local TMP_RUN="/opt/mados_run"
        if [ "$SCRIPT_DIR" != "$TMP_RUN" ]; then
            echo -e "${YELLOW}[!] Source sur dossier partagé détectée. Optimisation du déploiement...${NC}"
            sudo mkdir -p "$TMP_RUN"
            
            # Copie sélective pour éviter les fichiers lourds (ISO, VM)
            echo -e "${GRAY}    ├─ Clonage du cœur MadOS (lib, modules, scripts)...${NC}"
            for item in "lib" "modules" "scripts" "assets" "docs"; do
                [ -d "$SCRIPT_DIR/$item" ] && sudo cp -rf "$SCRIPT_DIR/$item" "$TMP_RUN/" || true
            done
            sudo cp -f "$SCRIPT_DIR"/*.sh "$TMP_RUN/" 2>/dev/null || true
            sudo cp -f "$SCRIPT_DIR"/*.md "$TMP_RUN/" 2>/dev/null || true
            sudo cp -f "$SCRIPT_DIR"/.nojekyll "$TMP_RUN/" 2>/dev/null || true
            
            echo -e "${GREEN}[OK] Proxy local établi dans /opt. Vérification de l'intégrité...${NC}"
            # Vérification vitale
            if [ ! -f "$TMP_RUN/lib/common.sh" ] || [ ! -d "$TMP_RUN/assets" ]; then
                 echo -e "${RED}[!] Échec critique du clonage vers /opt. Repli sur source originale...${NC}"
            else
                 cd "$TMP_RUN"
                 sudo bash ./install_local.sh "$@"
                 exit $?
            fi
        fi
    fi

    check_internet_connection || exit 1
    
    log_info "Toutes les vérifications pré-installation réussies"
    
    # ==============================================================================
    # Détection de l'hyperviseur et installation des drivers
    # ==============================================================================
    echo ""
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  [1.5/4] Détection Hyperviseur & Installation Drivers...${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    log_info "Détection de l'hyperviseur..."
    local DETECTED_HYPERVISOR=$(detect_hypervisor)
    
    if [ "$DETECTED_HYPERVISOR" != "none" ]; then
        log_success "Hyperviseur détecté: $DETECTED_HYPERVISOR"
        install_hypervisor_drivers "$DETECTED_HYPERVISOR" || {
            log_warning "Installation des drivers hyperviseur échouée - continuant l'installation"
        }
    else
        log_info "Installation sur matériel physique détectée"
    fi

    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  [2/4] Démarrage de l'Interface Interactive...${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    export MODULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/modules"

    echo -e "${YELLOW}[!] Optimisation du réseau et des miroirs Ubuntu...${NC}"
    
    # 1. DNS Fix : Config APT - Forcer IPv4 + Retries (fix VM DNS timeout)
    echo -e "${GRAY}    Config APT : Force IPv4 + 5 tentatives (fix DNS VM)...${NC}"
    cat <<'APTCONF' | sudo tee /etc/apt/apt.conf.d/99mados-network > /dev/null
// MadOS - Fix DNS & stabilité réseau en VM
Acquire::ForceIPv4 "true";
Acquire::Retries "5";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
APTCONF

    # 2. DNS Fix : Forcer DNS stables si la VM galère
    if ! ping -c 1 -W 3 archive.ubuntu.com >/dev/null 2>&1; then
        echo -e "${GRAY}    Injecteur DNS de secours (8.8.8.8 + 1.1.1.1)...${NC}"
        # Backup resolv.conf
        sudo cp /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null || true
        printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\nnameserver 8.8.4.4\n' | sudo tee /etc/resolv.conf > /dev/null
        # Aussi configurer systemd-resolved si disponible
        if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
            sudo mkdir -p /etc/systemd/resolved.conf.d/
            printf '[Resolve]\nDNS=8.8.8.8 1.1.1.1\nFallbackDNS=8.8.4.4\n' | sudo tee /etc/systemd/resolved.conf.d/mados-dns.conf > /dev/null
            sudo systemctl restart systemd-resolved 2>/dev/null || true
        fi
        echo -e "${GRAY}    DNS de secours injectés.${NC}"
    else
        echo -e "${GRAY}    Réseau OK, pas de fix DNS nécessaire.${NC}"
    fi

    # 3. Mirror Switch Global : Remplacer TOUS les miroirs régionaux par l'archive principale
    # Supporte l'ancien format /etc/apt/sources.list et le nouveau format DEB822 (24.04+)
    echo -e "${GRAY}    Bascule vers les serveurs de l'archive globale (Stabilité Max)...${NC}"
    
    # Backup
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
    [ -f /etc/apt/sources.list.d/ubuntu.sources ] && sudo cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak 2>/dev/null || true

    # Remplacement dans l'ancien format .list
    sudo sed -i 's|http://[a-z][a-z]\.archive\.ubuntu\.com/ubuntu|http://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list 2>/dev/null || true
    
    # Remplacement dans le nouveau format DEB822 (utilisé par Ubuntu 24.10+)
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
        sudo sed -i 's|[a-z][a-z]\.archive\.ubuntu\.com|archive.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true
    fi

    # 3. Installation immédiate des propriétés logicielles (requis pour add-apt-repository)
    echo -e "${GRAY}    Préparation des outils de dépôts (software-properties-common)...${NC}"
    sudo apt-get update -o Acquire::Retries=3 -qq >/dev/null 2>&1
    sudo apt-get install -y software-properties-common dirmngr gpg curl wget 2>/dev/null || true


    # Empêcher sudo de réinitialiser les variables cruciales pour l'installation silencieuse
    echo 'Defaults env_keep += "DEBIAN_FRONTEND NEEDRESTART_MODE"' | sudo tee /etc/sudoers.d/mados-apt-env >/dev/null
    sudo chmod 0440 /etc/sudoers.d/mados-apt-env || true
    export NEEDRESTART_MODE=a

# ------------------------------------------------------------------------------
# FONCTION : Déverrouillage APT (Auto-Fix)
# ------------------------------------------------------------------------------
wait_for_apt() {
    echo -ne "    ${GRAY}🕒 Attente des verrous système (APT/DPKG)...${NC}"
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
        echo -ne "."
        sleep 1
    done
    echo -e " ${GREEN}OK${NC}"
}

# ------------------------------------------------------------------------------
# FONCTION : Injection de NALA (APT Turbo)
# ------------------------------------------------------------------------------
ensure_nala() {
    if ! command -v nala &>/dev/null; then
        echo -e "    ${CYAN}🚀 Injection de Nala (Accélérateur de téléchargement)...${NC}"
        sudo apt update -q || true && sudo apt install -y nala -q >/dev/null 2>&1 || true
    fi
    # Alias automatique pour toutes les commandes suivantes
    shopt -s expand_aliases
    alias apt='sudo nala'
}
    export LOG_FILE="/var/log/mados_install.log"
    echo "=== Début de l'installation MadOS ===" > "$LOG_FILE"
    echo "Date: $(date)" >> "$LOG_FILE"

    export NEWT_COLORS='
root=black,black
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

    # ---- MENU DE BIENVENUE (OOBE) ----
    if [ "$AUTO_FLAG" = "true" ]; then
        installation_totale --silent
    else
        local WELCOME_CHOICE
        WELCOME_CHOICE=$(whiptail --title "MadOS 3.5 - BIENVENUE" \
            --menu "Choisissez votre mode d'entrée dans la matrice :" 15 65 2 \
            "1" "AUTO : Installation Totale (Recommandé ROG)" \
            "2" "MENU : Sélection Personnalisée (Expert)" 3>&1 1>&2 2>&3)

        case $WELCOME_CHOICE in
            1) installation_totale --silent ;;
            2) menu_principal ;;
            *) exit 0 ;;
        esac
    fi
}

run_module() {
    local SCRIPT="$1"
    local DESCRIPTION="${2:-}"
    
    export CURRENT_MODULE="$SCRIPT"
    
    # Vérifier si module déjà exécuté avec succès
    if skip_if_completed "$SCRIPT"; then
        return 0
    fi
    
    local attempt=1
    local max_attempts=3
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Injection : ${SCRIPT}${NC}"
        echo -e "${RED}║${NC} 📌 ${GRAY}${DESCRIPTION}${NC}"
        echo -e "${RED}║${NC} 📊 ${GRAY}Tentative ${attempt}/${max_attempts}${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}\n"
        
        log_info "Exécution du module: $SCRIPT (tentative $attempt/$max_attempts)"
        
        if bash "$MODULES_DIR/$SCRIPT" 2>&1 | tee -a "$MADOS_LOG_DIR/mados_install.log"; then
            # Succès - enregistrer le checkpoint
            save_checkpoint "$SCRIPT" "OK"
            log_success "Module $SCRIPT complété avec succès"
            return 0
        else
            # Échec
            local exit_code=$?
            log_error "Échec du module $SCRIPT (code: $exit_code)"
            
            if [ $attempt -lt $max_attempts ]; then
                log_warning "Nouvelle tentative du module $SCRIPT dans 10 secondes..."
                sleep 10
            else
                # Max tentatives atteintes - demander à l'utilisateur
                local CHOICE
                CHOICE=$(whiptail --title "MadOS 3.0 - ERREUR MODULE" --menu "Le script $SCRIPT a échoué après $max_attempts tentatives.\n\nConsultez les logs: $MADOS_LOG_DIR/mados_install.log" 15 65 3 \
                    "1" "Réessayer encore une fois" \
                    "2" "Ignorer l'erreur et continuer" \
                    "3" "Arrêter l'installation" 3>&1 1>&2 2>&3)
                
                if [ -z "$CHOICE" ]; then CHOICE="3"; fi
                
                case $CHOICE in
                    1) 
                        ((attempt--))  # Relancer une fois
                        ;;
                    2) 
                        log_warning "Ignorance de l'erreur sur $SCRIPT. L'installation continue."
                        save_checkpoint "$SCRIPT" "SKIPPED_ERROR"
                        return 0
                        ;;
                    3) 
                        log_error "Installation arrêtée par l'utilisateur"
                        print_installation_report
                        exit 1
                        ;;
                esac
            fi
        fi
        
        ((attempt++))
    done
}


menu_principal() {
    clear
    echo -e "${RED}${BOLD}"
    echo "  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗ "
    echo "  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝ "
    echo "  ██╔████╔██║███████║██║  ██║██║   ██║███████╗ "
    echo "  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║ "
    echo "  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║ "
    echo "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝ "
    echo -e "${NC}${WHITE}${BOLD}           --- INSTALLATEUR SYSTÈME MadOS ---${NC}\n"

    # Détection d'une installation interrompue
    if [ -f "$STATE_FILE" ]; then
        if (whiptail --title "MadOS 3.0 - REPRISE DÉTECTÉE" \
            --yesno "Une installation précédente semble avoir été interrompue.\n\nSouhaitez-vous REPRENDRE l'installation là où elle s'est arrêtée ?\n(Répondre 'Non' effacera l'ancien état)" 12 65); then
            log_info "Reprise de l'installation demandée par l'utilisateur."
        else
            reset_install_state
        fi
    fi

    if CHOIX=$(whiptail --title "MadOS 3.0 - Menu Principal" \
        --cancel-button "Quitter" \
        --ok-button "Sélectionner" \
        --menu "Choisissez le profil d'installation pour votre machine :" 16 75 3 \
        "1" "Installation Totale (Recommandée : E-Sport & Gamers)" \
        "2" "Installation Personnalisée (Avancée : Sélection Manuelle)" \
        "3" "Purge du Système (Nettoyage agressif d'Ubuntu)" 3>&1 1>&2 2>&3); then
        
        case $CHOIX in
            1) installation_totale ;;
            2) installation_custom ;;
            3) mode_destruction ;;
        esac
    else
        echo -e "${RED}Désengagement de la matrice... Au revoir.${NC}"
        exit 0
    fi
}

installation_totale() {
    local SILENT_MODE=false
    if [ "${1:-}" = "--silent" ]; then
        SILENT_MODE=true
    fi

    local CHOIX_BONUS
    if [ "$SILENT_MODE" = "true" ]; then
        # Sélection par défaut (Tout ce qui est à 'ON' d'habitude)
        CHOIX_BONUS="SNAP PROT SOND BATT MANG OLAM NET ZRAM ADS SSD USB BOOT THEM VOLT TUNE STLT DASH LINK PLMY OBSP GUI CLI SAN"
    else
        # Affichage des options facultatives auto-sélectionnées ou non
        if ! CHOIX_BONUS=$(whiptail --title "MadOS 3.0 - Options Bonus (Déploiement Total)" \
            --checklist "Espace pour (dés)activer, Entrée pour valider.\nLes fonctions vitales sont cochées par défaut." 20 65 12 \
            "SNAP" "Bouclier Système Timeshift" ON \
            "PROT" "Ultra Gaming (Proton-GE & GameScope)" ON \
            "NTFS" "Montage NTFS des jeux Windows" OFF \
            "SOND" "Son d'épée au démarrage" ON \
            "BATT" "Gestion de Batterie Extrême (auto-cpufreq)" ON \
            "MANG" "Profil dynamique MangoHud Rouge" ON \
            "STRM" "Pack Streamer (OBS + NoiseTorch)" OFF \
            "CLAW" "Assistant IA OpenClaw (Local)" OFF \
            "OLAM" "IA Local MadChat (Ollama + Llama 3)" ON \
            "NET"  "Réseau eSport BBR+ (Low Latency)" ON \
            "ZRAM" "RAM Compressée au vol (ZSTD)" ON \
            "ADS"  "Bouclier Anti-Pub Global (Hosts)" ON \
            "DEV"  "Pack Pro Dev (VSCodium, Docker, QEMU)" OFF \
            "EMU"  "Retro-Console EmuDeck (Elite Player)" OFF \
            "SSD"  "Maintenance NVMe (Auto Fstrim)" ON \
            "USB"  "Zero Latency E-Sport (Polling forcée)" ON \
            "BOOT" "Démarrage Éclair (Initramfs LZ4)" ON \
            "THEM" "Choix du Thème Visuel (ROG / Cyber / Carbon)" ON \
            "VOLT" "Undervolt CPU / Thermiques 85C" ON \
            "TUNE" "Turbo-Tuner (Auto-Benchmark & Hugepages)" ON \
            "STLT" "Stealth-Mode (Privacité Totale & Anti-Télémétrie)" ON \
            "DASH" "MadCenter (Tableau de Bord Graphique ROG)" ON \
            "LINK" "MadLink (Sync Téléphone & PC)" ON \
            "PLMY" "Boot Animé Pulsar (Splash Screen ROG Pulse)" ON \
            "OBSP" "MadStream OBS Pack (RTX NVENC P7 Tuning)" ON \
            "GUI"  "MadOS Control Center (Bureau)" ON \
            "UPD"  "Mise à jour automatique MadOS" OFF \
            "CLI"  "Utilitaire CLI 'mados' Unifié" ON \
            "SAN"  "Diagnostic Santé Système" ON \
            "VR"   "Suite VR (Meta Quest 3, ALVR, SideQuest)" OFF \
            "MAK"  "Station Maker (Imprimante 3D & Graveur Laser)" OFF 3>&1 1>&2 2>&3); then
            
            menu_principal
            return
        fi
    fi

    # Menu Overclocking si le module est coché
    if [[ "$CHOIX_BONUS" == *"VOLT"* ]]; then
        if [ "$SILENT_MODE" = "true" ]; then
            export MADOS_TDP_PROFILE="EQUILIBRE"
        else
            if ! export MADOS_TDP_PROFILE=$(whiptail --title "MadOS 3.0 - Profils Thermiques" --radiolist "Comportement énergétique du processeur (TDP) :" 18 65 4 \
                "SILENCE" "Bridage 25W - Calme Absolu" OFF \
                "EQUILIBRE" "Stock 45W - Usine (Défaut)" ON \
                "EXTREME" "Débridage 65W - E-Sport Max" OFF 3>&1 1>&2 2>&3); then
                menu_principal
                return
            fi
        fi
    else
        export MADOS_TDP_PROFILE="EQUILIBRE"
    fi

    # KDE Plasma 6 est désormais l'interface standard et obligatoire pour MadOS ROG Edition
    export MADOS_DESKTOP="KDE"

    # Sélection du Thème Visuel
    if [ "$SILENT_MODE" = "true" ]; then
        export MADOS_THEME="ROG"
    else
        if ! export MADOS_THEME=$(whiptail --title "MadOS 3.0 - Charte Graphique" --radiolist "Quel style visuel appliquer ?" 12 60 3 \
            "ROG" "ROG Classic (Rouge & Noir)" ON \
            "CYBER" "Cyberpunk Neon (Bleu & Rose)" OFF \
            "CARBON" "Carbon Stealth (Gris & Noir)" OFF 3>&1 1>&2 2>&3); then
            menu_principal
            return
        fi
    fi

    clear
    if [ "$SILENT_MODE" = "true" ]; then
        echo -e "${RED}⚠️  DÉPLOIEMENT TOTAL AUTOMATIQUE ENGAGÉ ⚠️${NC}"
    else
        echo -e "${RED}⚠️  DÉPLOIEMENT TOTAL ENGAGÉ [Bureau: $MADOS_DESKTOP | Theme: $MADOS_THEME] ⚠️${NC}"
    fi
    echo -e "${GRAY}Le système va configurer automatiquement votre machine...${NC}\n"
    sleep 2

    # Optimisation APT (Passage en NALA pour la vitesse)
    ensure_nala

    # ---- BOUNCLIER DE CONTINUITÉ DÉPLOYÉ ----
    # On désactive la "paranoïa" de Bash pour que l'installation ne s'arrête PAS 
    # même si un petit logiciel ne peut pas s'installer.
    set +u
    set +o pipefail

    # Modules obligatoires
    run_module "00_nettoyage_ubuntu.sh" "Purification du système & Dépôts"
    run_module "01_noyau_xanmod.sh"     "Injection du Noyau XanMod EDGE"
    run_module "02_pilotes_gpu_auto.sh" "Détection Pilotes Graphiques"
    run_module "03_integration_rog.sh"  "Couplage Hardware (asusctl)"
    run_module "04_arsenal_logiciel.sh" "Logiciels Gamers & IA"
    
    run_module "05_bureau_kde_plasma.sh" "Interface KDE Plasma 6 Wayland"
    
    run_module "06_thematique_mados.sh" "Esthétique MadOS (GRUB, ZSH)"
    
    # Modules Bonus selon checklist
    [[ "$CHOIX_BONUS" == *"SNAP"* ]] && run_module "07_snapshots_systeme.sh" "Bouclier Système"
    [[ "$CHOIX_BONUS" == *"PROT"* ]] && run_module "08_proton_gamescope.sh" "Options Ultra Gaming"
    [[ "$CHOIX_BONUS" == *"NTFS"* ]] && run_module "09_montage_ntfs.sh" "Montage NTFS Windows"
    [[ "$CHOIX_BONUS" == *"SOND"* ]] && run_module "10_son_demarrage.sh" "Son de Démarrage"
    [[ "$CHOIX_BONUS" == *"BATT"* ]] && run_module "11_batterie_extreme.sh" "Auto-cpufreq"
    [[ "$CHOIX_BONUS" == *"MANG"* ]] && run_module "12_mangohud_rog.sh" "MangoHud Profil"
    [[ "$CHOIX_BONUS" == *"STRM"* ]] && run_module "13_pack_streamer.sh" "OBS Streamer Pack"
    [[ "$CHOIX_BONUS" == *"CLAW"* ]] && run_module "14_openclaw_ai.sh" "Installation Agent IA"
    [[ "$CHOIX_BONUS" == *"OLAM"* ]] && run_module "29_ollama_ia_locale.sh" "IA Local MadChat (Ollama)"
    [[ "$CHOIX_BONUS" == *"NET"* ]]  && run_module "15_reseau_antilag.sh" "Réseau eSport BBR+ (Low Latency)"
    [[ "$CHOIX_BONUS" == *"ZRAM"* ]] && run_module "16_zram_memoire.sh" "Compression RAM"
    [[ "$CHOIX_BONUS" == *"ADS"* ]]  && run_module "17_bouclier_antipub.sh" "Patch Fichier Hosts"
    [[ "$CHOIX_BONUS" == *"DEV"* ]]  && run_module "18_pack_pro_dev.sh" "Déploiement IDE & VM"
    [[ "$CHOIX_BONUS" == *"EMU"* ]]  && run_module "30_emudeck_retro.sh" "Retro-Console EmuDeck"
    [[ "$CHOIX_BONUS" == *"SSD"* ]]  && run_module "19_donnees_fstrim.sh" "Trim Auto SSD"
    [[ "$CHOIX_BONUS" == *"USB"* ]]  && run_module "20_esport_usb_1000hz.sh" "Zero Latency USB"
    [[ "$CHOIX_BONUS" == *"BOOT"* ]] && run_module "21_boot_eclair.sh" "Fast Boot System"
    [[ "$CHOIX_BONUS" == *"THEM"* ]] && run_module "06_thematique_mados.sh" "Choix du Thème Visuel"
    [[ "$CHOIX_BONUS" == *"VOLT"* ]] && run_module "22_cpu_undervolt.sh" "Protection Thermique"
    [[ "$CHOIX_BONUS" == *"GUI"* ]]  && run_module "23_control_center.sh" "Panneau de Contrôle GUI"
    [[ "$CHOIX_BONUS" == *"UPD"* ]]  && run_module "24_mados_update.sh" "Mise à jour MadOS depuis GitHub"
    [[ "$CHOIX_BONUS" == *"CLI"* ]]  && run_module "28_mados_cli.sh" "Installation Utilitaire CLI 'mados'"
    [[ "$CHOIX_BONUS" == *"SAN"* ]]  && run_module "25_sante_systeme.sh" "Diagnostic Santé du Système"
    [[ "$CHOIX_BONUS" == *"TUNE"* ]] && run_module "31_turbo_tuner.sh" "Auto-Performance (Turbo-Tuner)"
    [[ "$CHOIX_BONUS" == *"STLT"* ]] && run_module "32_stealth_privacy.sh" "Confidentialité Totale (Stealth-Mode)"
    [[ "$CHOIX_BONUS" == *"DASH"* ]] && run_module "33_mad_center_gui.sh" "Tableau de Bord MadCenter Dashboard"
    [[ "$CHOIX_BONUS" == *"LINK"* ]] && run_module "34_mad_link_sync.sh" "Synchronisation Smartphone (MadLink)"
    [[ "$CHOIX_BONUS" == *"PLMY"* ]] && run_module "35_plymouth_animated.sh" "Boot Splash Pulsar ROG"
    [[ "$CHOIX_BONUS" == *"OBSP"* ]] && run_module "36_obs_nvenc_streaming.sh" "Pack OBS Streamer (RTX)"
    [[ "$CHOIX_BONUS" == *"VR"* ]]   && run_module "26_vr_oculus_quest.sh" "Intégration VR (Meta Quest)"
    [[ "$CHOIX_BONUS" == *"MAK"* ]]  && run_module "27_creation_maker.sh" "Station Maker (Imprimante 3D & Laser)"
    run_module "99_integration_systeme.sh" "Finalisation & Intégration Système"

    cloture_installation
}

installation_custom() {
    local CHOIX_ALL
    if ! CHOIX_ALL=$(whiptail --title "MadOS 3.0 - Déploiement Custom (Expert)" \
        --checklist "Espace pour sélectionner, Entrée pour valider :" 20 65 12 \
        "00_clean" "Nettoyer système (Bloatwares)" OFF \
        "01_kern" "Noyau Gaming XanMod EDGE" OFF \
        "02_gpu" "Pilotes GPU auto (Nvidia/AMD)" OFF \
        "03_rog" "Intégration Hardware ASUS" OFF \
        "04_soft" "Arsenal logiciel (Steam, Discord...)" OFF \
        "05_kde" "Injecter KDE Plasma 6 Wayland" ON \
        "06_them" "Thème visuel MadOS" OFF \
        "07_snap" "Bouclier Snapshots Timeshift" OFF \
        "08_prot" "Performances Proton-GE / GameScope" OFF \
        "09_ntfs" "Auto-montage disques NTFS" OFF \
        "10_snd" "Son de démarrage ROG" OFF \
        "11_batt" "Auto-cpufreq Batterie" OFF \
        "12_mang" "MangoHud MadOS Edition" OFF \
        "13_strm" "Pack OBS Stream" OFF \
        "14_claw" "Assistant IA OpenClaw" OFF \
        "29_olam" "IA Locale MadChat (Ollama)" OFF \
        "15_net" "Optimisation Réseau eSport BBR+" OFF \
        "16_zrm" "Compression Mémoire ZRAM" OFF \
        "17_ads" "Bouclier Anti-Pub" OFF \
        "18_dev" "Pack Développeur (VSCode, Docker)" OFF \
        "30_emu" "Retro-Console EmuDeck" OFF \
        "19_ssd" "Auto-Trim NVMe" OFF \
        "20_usb" "Polling Rate USB 1000Hz" OFF \
        "21_bot" "Fix Boot Ultra-Rapide (LZ4)" OFF \
        "22_vlt" "Undervolt CPU Auto" OFF \
        "23_gui" "MadOS Control Center" OFF \
        "06_them" "Thème visuel (ROG/Cyber/Carbon)" OFF \
        "24_upd" "Updater GitHub" OFF \
        "28_cli" "Utilitaire CLI 'mados'" OFF \
        "25_san" "Diagnostics Système" OFF \
        "31_tun" "Turbo-Tuner (Performances i9/RTX)" OFF \
        "32_stl" "Stealth-Mode Privacy" OFF \
        "33_dsh" "MadCenter Dashboard (GUI)" OFF \
        "34_lnk" "MadLink (Sync Mobile)" OFF \
        "35_plm" "Boot Splash Animé (Plymouth)" OFF \
        "36_obs" "Pack OBS RTX Stream" OFF \
        "26_vr" "Casque VR (Meta Quest, ALVR)" OFF \
        "27_mak" "Station Maker (3D & Laser)" OFF 3>&1 1>&2 2>&3); then
        
        menu_principal
        return
    fi

    if [[ "$CHOIX_ALL" == *"22_vlt"* ]]; then
        if ! export MADOS_TDP_PROFILE=$(whiptail --title "MadOS 3.0 - Surcadençage & Profils Thermiques" --radiolist "Comportement énergétique du processeur (TDP) :" 18 70 4 \
            "SILENCE" "Bridage 25W - Calme Absolu" OFF \
            "EQUILIBRE" "Stock 45W - Normal (Défaut)" ON \
            "EXTREME" "Débridage 65W - E-Sport Max" OFF 3>&1 1>&2 2>&3); then
            menu_principal
            return
        fi
    else
        export MADOS_TDP_PROFILE="EQUILIBRE"
    fi

    clear
    echo -e "${RED}Début du protocole custom...${NC}\n"
    sleep 2

    # ---- BOUNCLIER DE CONTINUITÉ DÉPLOYÉ ----
    # On désactive la "paranoïa" de Bash pour que l'installation ne s'arrête PAS 
    set +u
    set +o pipefail

    [[ "$CHOIX_ALL" == *"00_clean"* ]] && run_module "00_nettoyage_ubuntu.sh" "Purification du système"
    [[ "$CHOIX_ALL" == *"01_kern"* ]] && run_module "01_noyau_xanmod.sh" "Injection du Noyau"
    [[ "$CHOIX_ALL" == *"02_gpu"* ]] && run_module "02_pilotes_gpu_auto.sh" "Détection Pilotes"
    [[ "$CHOIX_ALL" == *"03_rog"* ]] && run_module "03_integration_rog.sh" "Couplage Hardware"
    [[ "$CHOIX_ALL" == *"04_soft"* ]] && run_module "04_arsenal_logiciel.sh" "Logiciels Gamers"
    run_module "05_bureau_kde_plasma.sh" "KDE Plasma 6"
    [[ "$CHOIX_ALL" == *"06_them"* ]] && run_module "06_thematique_mados.sh" "Esthétique MadOS"
    [[ "$CHOIX_ALL" == *"07_snap"* ]] && run_module "07_snapshots_systeme.sh" "Snapshots"
    [[ "$CHOIX_ALL" == *"08_prot"* ]] && run_module "08_proton_gamescope.sh" "Proton-GE"
    [[ "$CHOIX_ALL" == *"09_ntfs"* ]] && run_module "09_montage_ntfs.sh" "Montage NTFS"
    [[ "$CHOIX_ALL" == *"10_snd"* ]] && run_module "10_son_demarrage.sh" "Son de dèmarrage"
    [[ "$CHOIX_ALL" == *"11_batt"* ]] && run_module "11_batterie_extreme.sh" "Auto-cpufreq"
    [[ "$CHOIX_ALL" == *"12_mang"* ]] && run_module "12_mangohud_rog.sh" "MangoHud Profil"
    [[ "$CHOIX_ALL" == *"13_strm"* ]] && run_module "13_pack_streamer.sh" "OBS et Capture"
    [[ "$CHOIX_ALL" == *"14_claw"* ]] && run_module "14_openclaw_ai.sh" "Agent IA OpenClaw"
    [[ "$CHOIX_ALL" == *"29_olam"* ]] && run_module "29_ollama_ia_locale.sh" "IA MadChat (Ollama)"
    run_module "05_bureau_kde_plasma.sh" "KDE Plasma 6"
    [[ "$CHOIX_ALL" == *"15_net"* ]] && run_module "15_reseau_antilag.sh" "TCP BBR+ Anti-Lag"
    [[ "$CHOIX_ALL" == *"16_zrm"* ]] && run_module "16_zram_memoire.sh" "Swap ZRAM"
    [[ "$CHOIX_ALL" == *"17_ads"* ]] && run_module "17_bouclier_antipub.sh" "Hosts StevenBlack"
    [[ "$CHOIX_ALL" == *"18_dev"* ]] && run_module "18_pack_pro_dev.sh" "Pack Docker/QEMU"
    [[ "$CHOIX_ALL" == *"30_emu"* ]] && run_module "30_emudeck_retro.sh" "Retro-Console EmuDeck"
    [[ "$CHOIX_ALL" == *"19_ssd"* ]] && run_module "19_donnees_fstrim.sh" "SSD Auto Trim"
    [[ "$CHOIX_ALL" == *"20_usb"* ]] && run_module "20_esport_usb_1000hz.sh" "USB Mod E-Sport"
    [[ "$CHOIX_ALL" == *"21_bot"* ]] && run_module "21_boot_eclair.sh" "GRUB Initramfs Lz4"
    [[ "$CHOIX_ALL" == *"22_vlt"* ]] && run_module "22_cpu_undervolt.sh" "Undervolt & Thermiques"
    [[ "$CHOIX_ALL" == *"23_gui"* ]] && run_module "23_control_center.sh" "Interface Control Center"
    [[ "$CHOIX_ALL" == *"06_them"* ]] && run_module "06_thematique_mados.sh" "Esthétique MadOS"
    [[ "$CHOIX_ALL" == *"24_upd"* ]] && run_module "24_mados_update.sh" "Mise à jour depuis GitHub"
    [[ "$CHOIX_ALL" == *"28_cli"* ]] && run_module "28_mados_cli.sh" "Installation Utilitaire CLI 'mados'"
    [[ "$CHOIX_ALL" == *"25_san"* ]] && run_module "25_sante_systeme.sh" "Diagnostic Santé"
    [[ "$CHOIX_ALL" == *"31_tun"* ]] && run_module "31_turbo_tuner.sh" "Performances Turbo-Tuner"
    [[ "$CHOIX_ALL" == *"32_stl"* ]] && run_module "32_stealth_privacy.sh" "Confidentialité Stealth-Mode"
    [[ "$CHOIX_ALL" == *"33_dsh"* ]] && run_module "33_mad_center_gui.sh" "Dashboard MadCenter"
    [[ "$CHOIX_ALL" == *"34_lnk"* ]] && run_module "34_mad_link_sync.sh" "Sync MadLink"
    [[ "$CHOIX_ALL" == *"35_plm"* ]] && run_module "35_plymouth_animated.sh" "Boot Pulsar Animé"
    [[ "$CHOIX_ALL" == *"36_obs"* ]] && run_module "36_obs_nvenc_streaming.sh" "Pack OBS RTX Stream"
    [[ "$CHOIX_ALL" == *"26_vr"* ]] && run_module "26_vr_oculus_quest.sh" "Suite VR Meta Quest"
    [[ "$CHOIX_ALL" == *"27_mak"* ]] && run_module "27_creation_maker.sh" "Station Maker (Imprimante 3D & Laser)"
    run_module "99_integration_systeme.sh" "Finalisation & Intégration Système"

    cloture_installation
}

mode_destruction() {
    if whiptail --title "MadOS 3.0 - MODE DESTRUCTION" --yesno "Ceci va PURGER Canonical de tous ses bloatwares (snapd, cloud-init) de manière agressive.\n\nÊtes-vous absolument sûr de vouloir détruire la trace d'Ubuntu ?" 12 70; then
        clear
        run_module "00_nettoyage_ubuntu.sh" "Purification Extrême de l'Hôte"
        sleep 2
    fi
    menu_principal
}

cloture_installation() {
    clear
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} 🏁 ${WHITE}${BOLD}Séquence de Clôture MadOS 3.5 Ultimate-Test${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

    # ---- RÉPARATION DES PERMISSIONS (Fix Écran Noir) ----
    echo -e "    ${GRAY}├─ [REPAIR] Restauration des droits utilisateur sur $USER_HOME...${NC}"
    sudo chown -R "$REAL_USER:$REAL_USER" "$USER_HOME" >/dev/null 2>&1 || true
    sudo chmod -R u+rw "$USER_HOME" >/dev/null 2>&1 || true

    # Vérification et installation asynchrone de netcat pour l'upload
    if ! command -v nc &>/dev/null; then
        echo -e "${GRAY}    Installation de netcat-openbsd pour le diagnostic...${NC}"
        sudo apt-get install -y netcat-openbsd -qq >/dev/null 2>&1
    fi

    echo -e "${CYAN}📡 Génération du rapport de mission (Termbin)...${NC}"
    local ACTUAL_LOG="$MADOS_LOG_DIR/mados_install.log"
    local LOG_URL="https://termbin.com/indisponible"
    
    if [ -f "$ACTUAL_LOG" ]; then
        LOG_URL=$(tail -n 10000 "$ACTUAL_LOG" | nc termbin.com 9999 2>/dev/null || echo "Échec de l'upload")
    fi

    # UI Finale Premium
    whiptail --title "MadOS 3.5 — DÉPLOIEMENT TERMINÉ 🚀" --msgbox \
    "MAD-OS EST MAINTENANT ACTIF SUR VOTRE SYSTÈME !\n\n\
    [STATUT] : OPÉRATIONNEL\n\
    [LOG DIAG] : $LOG_URL\n\n\
    Prochaines étapes :\n\
    1. Redémarrez pour charger le Kernel XanMod.\n\
    2. Le bureau KDE Plasma 6 (MadEdition) sera actif.\n\
    3. Vos modules Turbo-Tuner & Stealth-Mode sont scellés.\n\n\
    Bon jeu, $(whoami) !" 18 70

    if whiptail --title "SÉQUENCE DE REDÉMARRAGE" --yesno "Voulez-vous engager le redémarrage immédiat ?" 10 50; then
        clear
        echo -e "${RED}🚀 REBOOT ENGAGÉ. Rendez-vous dans la matrice...${NC}"
        sleep 2
        sudo reboot
    else
        clear
        echo -e "${GREEN}Séquence terminée. Votre station MadOS est prête.${NC}"
        exit 0
    fi
}

# Lancement de la fonction principale
main
