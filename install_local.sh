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
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
    set -uo pipefail
    
    # ==============================================================================
    # Charger les fonctions communes
    # ==============================================================================
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
        source "$SCRIPT_DIR/lib/common.sh"
    else
        echo "ERREUR CRITIQUE: lib/common.sh non trouvé!"
        exit 1
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
    check_disk_space 40 || exit 1
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
    sudo chmod 0440 /etc/sudoers.d/mados-apt-env
    export NEEDRESTART_MODE=a

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

    menu_principal
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
                *) echo -e "${RED}Arrêt critique du déploiement suite à l'échec de $SCRIPT.${NC}"; exit 1 ;;
            esac
        fi
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
    local CHOIX_BONUS
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
        "NET"  "Réseau Anti-Lag BBR (Multijoueur)" ON \
        "ZRAM" "RAM Compressée au vol (ZSTD)" ON \
        "ADS"  "Bouclier Anti-Pub Global (Hosts)" ON \
        "DEV"  "Pack Pro Dev (VSCodium, Docker, QEMU)" OFF \
        "SSD"  "Maintenance NVMe (Auto Fstrim)" ON \
        "USB"  "Zero Latency E-Sport (Polling forcée)" ON \
        "BOOT" "Démarrage Éclair (Initramfs LZ4)" ON \
        "VOLT" "Undervolt CPU / Thermiques 85C" ON \
        "GUI"  "MadOS Control Center (Bureau)" ON \
        "UPD"  "Mise à jour automatique MadOS" OFF \
        "SAN"  "Diagnostic Santé Système" ON \
        "VR"   "Suite VR (Meta Quest 3, ALVR, SideQuest)" OFF \
        "MAK"  "Station Maker (Imprimante 3D & Graveur Laser)" OFF 3>&1 1>&2 2>&3); then
        
        menu_principal
        return
    fi

    # Menu Overclocking si le module est coché
    if [[ "$CHOIX_BONUS" == *"VOLT"* ]]; then
        if ! export MADOS_TDP_PROFILE=$(whiptail --title "MadOS 3.0 - Profils Thermiques" --radiolist "Comportement énergétique du processeur (TDP) :" 18 65 4 \
            "SILENCE" "Bridage 25W - Calme Absolu" OFF \
            "EQUILIBRE" "Stock 45W - Usine (Défaut)" ON \
            "EXTREME" "Débridage 65W - E-Sport Max" OFF 3>&1 1>&2 2>&3); then
            menu_principal
            return
        fi
    else
        export MADOS_TDP_PROFILE="EQUILIBRE"
    fi

    clear
    echo -e "${RED}⚠️  DÉPLOIEMENT TOTAL ENGAGÉ ⚠️${NC}"
    echo -e "${GRAY}Le système va configurer automatiquement votre machine...${NC}\n"
    sleep 2

    # Modules obligatoires
    run_module "00_nettoyage_ubuntu.sh" "Purification du système & Dépôts"
    run_module "01_noyau_xanmod.sh"     "Injection du Noyau XanMod EDGE"
    run_module "02_pilotes_gpu_auto.sh" "Détection Pilotes Graphiques"
    run_module "03_integration_rog.sh"  "Couplage Hardware (asusctl)"
    run_module "04_arsenal_logiciel.sh" "Logiciels Gamers & IA"
    run_module "05_bureau_kde_plasma.sh" "Interface Graphique Wayland (KDE 6)"
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
    [[ "$CHOIX_BONUS" == *"NET"* ]]  && run_module "15_reseau_antilag.sh" "Optimisation TCP BBR"
    [[ "$CHOIX_BONUS" == *"ZRAM"* ]] && run_module "16_zram_memoire.sh" "Compression RAM"
    [[ "$CHOIX_BONUS" == *"ADS"* ]]  && run_module "17_bouclier_antipub.sh" "Patch Fichier Hosts"
    [[ "$CHOIX_BONUS" == *"DEV"* ]]  && run_module "18_pack_pro_dev.sh" "Déploiement IDE & VM"
    [[ "$CHOIX_BONUS" == *"SSD"* ]]  && run_module "19_donnees_fstrim.sh" "Trim Auto SSD"
    [[ "$CHOIX_BONUS" == *"USB"* ]]  && run_module "20_esport_usb_1000hz.sh" "Zero Latency USB"
    [[ "$CHOIX_BONUS" == *"BOOT"* ]] && run_module "21_boot_eclair.sh" "Fast Boot System"
    [[ "$CHOIX_BONUS" == *"VOLT"* ]] && run_module "22_cpu_undervolt.sh" "Protection Thermique"
    [[ "$CHOIX_BONUS" == *"GUI"* ]]  && run_module "23_control_center.sh" "Panneau de Contrôle GUI"
    [[ "$CHOIX_BONUS" == *"UPD"* ]]  && run_module "24_mados_update.sh" "Mise à jour MadOS depuis GitHub"
    [[ "$CHOIX_BONUS" == *"SAN"* ]]  && run_module "25_sante_systeme.sh" "Diagnostic Santé du Système"
    [[ "$CHOIX_BONUS" == *"VR"* ]]   && run_module "26_vr_oculus_quest.sh" "Intégration VR (Meta Quest)"
    [[ "$CHOIX_BONUS" == *"MAK"* ]]  && run_module "27_creation_maker.sh" "Station Maker (Imprimante 3D & Laser)"

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
        "05_kde" "Injecter KDE Plasma 6 Wayland" OFF \
        "06_them" "Thème visuel MadOS" OFF \
        "07_snap" "Bouclier Snapshots Timeshift" OFF \
        "08_prot" "Performances Proton-GE / GameScope" OFF \
        "09_ntfs" "Auto-montage disques NTFS" OFF \
        "10_snd" "Son de démarrage ROG" OFF \
        "11_batt" "Auto-cpufreq Batterie" OFF \
        "12_mang" "MangoHud MadOS Edition" OFF \
        "13_strm" "Pack OBS Stream" OFF \
        "14_claw" "Assistant IA OpenClaw" OFF \
        "15_net" "Optimisation Réseau TCP" OFF \
        "16_zrm" "Compression Mémoire ZRAM" OFF \
        "17_ads" "Bouclier Anti-Pub" OFF \
        "18_dev" "Pack Développeur (VSCode, Docker)" OFF \
        "19_ssd" "Auto-Trim NVMe" OFF \
        "20_usb" "Polling Rate USB 1000Hz" OFF \
        "21_bot" "Fix Boot Ultra-Rapide (LZ4)" OFF \
        "22_vlt" "Undervolt CPU Auto" OFF \
        "23_gui" "MadOS Control Center" OFF \
        "24_upd" "Updater GitHub" OFF \
        "25_san" "Diagnostics Système" OFF \
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

    [[ "$CHOIX_ALL" == *"00_clean"* ]] && run_module "00_nettoyage_ubuntu.sh" "Purification du système"
    [[ "$CHOIX_ALL" == *"01_kern"* ]] && run_module "01_noyau_xanmod.sh" "Injection du Noyau"
    [[ "$CHOIX_ALL" == *"02_gpu"* ]] && run_module "02_pilotes_gpu_auto.sh" "Détection Pilotes"
    [[ "$CHOIX_ALL" == *"03_rog"* ]] && run_module "03_integration_rog.sh" "Couplage Hardware"
    [[ "$CHOIX_ALL" == *"04_soft"* ]] && run_module "04_arsenal_logiciel.sh" "Logiciels Gamers"
    [[ "$CHOIX_ALL" == *"05_kde"* ]] && run_module "05_bureau_kde_plasma.sh" "KDE Plasma 6"
    [[ "$CHOIX_ALL" == *"06_them"* ]] && run_module "06_thematique_mados.sh" "Esthétique MadOS"
    [[ "$CHOIX_ALL" == *"07_snap"* ]] && run_module "07_snapshots_systeme.sh" "Snapshots"
    [[ "$CHOIX_ALL" == *"08_prot"* ]] && run_module "08_proton_gamescope.sh" "Proton-GE"
    [[ "$CHOIX_ALL" == *"09_ntfs"* ]] && run_module "09_montage_ntfs.sh" "Montage NTFS"
    [[ "$CHOIX_ALL" == *"10_snd"* ]] && run_module "10_son_demarrage.sh" "Son de dèmarrage"
    [[ "$CHOIX_ALL" == *"11_batt"* ]] && run_module "11_batterie_extreme.sh" "Auto-cpufreq"
    [[ "$CHOIX_ALL" == *"12_mang"* ]] && run_module "12_mangohud_rog.sh" "MangoHud Profil"
    [[ "$CHOIX_ALL" == *"13_strm"* ]] && run_module "13_pack_streamer.sh" "OBS et Capture"
    [[ "$CHOIX_ALL" == *"14_claw"* ]] && run_module "14_openclaw_ai.sh" "Agent IA OpenClaw"
    [[ "$CHOIX_ALL" == *"15_net"* ]] && run_module "15_reseau_antilag.sh" "TCP BBR Anti-Lag"
    [[ "$CHOIX_ALL" == *"16_zrm"* ]] && run_module "16_zram_memoire.sh" "Swap ZRAM"
    [[ "$CHOIX_ALL" == *"17_ads"* ]] && run_module "17_bouclier_antipub.sh" "Hosts StevenBlack"
    [[ "$CHOIX_ALL" == *"18_dev"* ]] && run_module "18_pack_pro_dev.sh" "Pack Docker/QEMU"
    [[ "$CHOIX_ALL" == *"19_ssd"* ]] && run_module "19_donnees_fstrim.sh" "SSD Auto Trim"
    [[ "$CHOIX_ALL" == *"20_usb"* ]] && run_module "20_esport_usb_1000hz.sh" "USB Mod E-Sport"
    [[ "$CHOIX_ALL" == *"21_bot"* ]] && run_module "21_boot_eclair.sh" "GRUB Initramfs Lz4"
    [[ "$CHOIX_ALL" == *"22_vlt"* ]] && run_module "22_cpu_undervolt.sh" "Undervolt & Thermiques"
    [[ "$CHOIX_ALL" == *"23_gui"* ]] && run_module "23_control_center.sh" "Interface Control Center"
    [[ "$CHOIX_ALL" == *"24_upd"* ]] && run_module "24_mados_update.sh" "Mise à jour depuis GitHub"
    [[ "$CHOIX_ALL" == *"25_san"* ]] && run_module "25_sante_systeme.sh" "Diagnostic Santé"
    [[ "$CHOIX_ALL" == *"26_vr"* ]] && run_module "26_vr_oculus_quest.sh" "Suite VR Meta Quest"
    [[ "$CHOIX_ALL" == *"27_mak"* ]] && run_module "27_creation_maker.sh" "Station Maker (Imprimante 3D & Laser)"

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
    echo -e "${CYAN}Génération du lien de diagnostic (Upload sécurisé vers Termbin)...${NC}"
    if [ -f "$LOG_FILE" ]; then
        LOG_URL=$(cat "$LOG_FILE" | nc termbin.com 9999 || echo "Échec de l'upload")
    else
        LOG_URL="Aucun log généré."
    fi

    whiptail --title "MadOS 3.0 - DÉPLOIEMENT TERMINÉ 🎉" --msgbox "Déploiement Terminé avec Succès !\n\nLien de Diagnostic (Copiez-le pour le dev) :\n$LOG_URL\n\nAu prochain redémarrage, vous profiterez de MadOS 3.0 :\n - Kernel XanMod EDGE\n - Interface Wayland / KDE Plasma 6\n - Modules Avancés Actifs" 16 70
    if whiptail --title "MadOS 3.0 - REDÉMARRAGE" --yesno "Voulez-vous redémarrer le système maintenant pour savourer MadOS 3.0 ?" 10 55; then
        clear
        echo -e "${RED}Initiation de la séquence de reboot...${NC}"
        sleep 2
        sudo reboot
    else
        clear
        echo -e "${GRAY}À bientôt dans la Matrice. Lien de log : $LOG_URL${NC}"
        exit 0
    fi
}

# Lancement de la fonction principale
main
