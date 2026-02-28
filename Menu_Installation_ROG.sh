#!/bin/bash
# ==========================================
# MadOS ROG V2.3 - Menu Principal TUI (Whiptail)
# ==========================================
# Script de Post-Installation - Interface Graphique
# ==========================================

set -euo pipefail

# S'assurer que whiptail est installé
if ! command -v whiptail >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y whiptail dialog
fi

if [ "$EUID" -ne 0 ]; then
    whiptail --title "ERREUR DE PRIVILÈGES" --msgbox "La matrice refuse votre accès.\n\nVeuillez lancer le script avec sudo :\n\nsudo bash Menu_Installation_ROG.sh" 10 60
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MODULES_DIR="$SCRIPT_DIR/modules"

if [ ! -d "$MODULES_DIR" ]; then
    whiptail --title "ERREUR FATALE" --msgbox "Le dossier 'modules/' est introuvable." 8 45
    exit 1
fi

chmod +x "$MODULES_DIR"/*.sh 2>/dev/null || true

# Réattacher stdin au terminal et nettoyer l'affichage (indispensable avec wget pipe)
exec < /dev/tty
tput reset 2>/dev/null || true

# Empêcher sudo de réinitialiser les variables cruciales pour l'installation silencieuse
echo 'Defaults env_keep += "DEBIAN_FRONTEND NEEDRESTART_MODE"' | sudo tee /etc/sudoers.d/mados-apt-env >/dev/null
sudo chmod 0440 /etc/sudoers.d/mados-apt-env
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

export LOG_FILE="/var/log/mados_install.log"
echo "=== Début de l'installation MadOS ROG ===" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"

# ---- Couleurs & Styles Shell ----
export RED='\033[0;31m'
export WHITE='\033[1;37m'
export CYAN='\033[0;36m'
export GRAY='\033[0;90m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export NC='\033[0m'
export BOLD='\033[1m'

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

run_module() {
    local SCRIPT="$1"
    local DESCRIPTION="${2:-}"
    
    while true; do
        echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Injection : ${SCRIPT}${NC}"
        echo -e "${RED}║${NC} 📌 ${GRAY}${DESCRIPTION}${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}\n"
        
        echo -e "\n--- Exécution: $SCRIPT ---" >> "$LOG_FILE"
        if bash "$MODULES_DIR/$SCRIPT" 2>&1 | tee -a "$LOG_FILE"; then
            break # Succès, on sort de la boucle
        else
            # Échec
            local CHOICE
            CHOICE=$(whiptail --title "ERREUR MODULE" --menu "Le script $SCRIPT a échoué.\nConsultez les logs : /var/log/mados_install.log" 15 65 3 \
                "1" "Réessayer (Relancer le module)" \
                "2" "Ignorer l'erreur et continuer" \
                "3" "Arrêter l'installation" 3>&1 1>&2 2>&3)
            
            if [ -z "$CHOICE" ]; then CHOICE="3"; fi
            
            case $CHOICE in
                1) echo -e "\n${YELLOW}Relance du module $SCRIPT...${NC}" ;;
                2) echo -e "\n${YELLOW}Ignorance de l'erreur sur $SCRIPT. L'installation continue.${NC}"; break ;;
                *) echo -e "${RED}Arrêt critique du déploiement suite à l'échec de $SCRIPT.${NC}"; exit 1 ;;
            esac
        fi
    done
}

menu_principal() {
    clear
    echo -e "${RED}${BOLD}"
    echo "  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗"
    echo "  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝"
    echo "  ██╔████╔██║███████║██║  ██║██║   ██║███████╗"
    echo "  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║"
    echo "  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║"
    echo "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝"
    echo -e "${NC}${WHITE}${BOLD}         --- CŒUR MATRICIEL ROG EDITION ---${NC}\n"

    local CHOIX
    CHOIX=$(whiptail --title "⚡ MadOS ROG Edition (v3.0) ⚡" \
        --cancel-button "Annuler" \
        --ok-button "Engager" \
        --menu "Sélectionnez le protocole de déploiement :" 16 65 3 \
        "1" "Déploiement Total (Expérience E-Sport)" \
        "2" "Déploiement Custom (Options Ingénieurs)" \
        "3" "Protocole Destruction (Purge Ubuntu)" 3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
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
    CHOIX_BONUS=$(whiptail --title "Déploiement Total - Options Bonus (v3.0)" \
        --checklist "Espace pour (dés)activer, Entrée pour valider.\nLes fonctions vitales sont cochées par défaut." 20 65 12 \
        "SNAP" "Bouclier Système Timeshift" ON \
        "PROT" "Ultra Gaming (Proton-GE & GameScope)" ON \
        "NTFS" "Montage NTFS des jeux Windows" OFF \
        "SOND" "Son d'épée ROG au démarrage" ON \
        "BATT" "Gestion de Batterie Extrême (auto-cpufreq)" ON \
        "MANG" "Profil dynamique MangoHud Rouge ROG" ON \
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
        "VR"   "Suite VR (Meta Quest 3, ALVR, SideQuest)" OFF 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then menu_principal; return; fi

    # Menu Overclocking si le module est coché
    if [[ "$CHOIX_BONUS" == *"VOLT"* ]]; then
        export MADOS_TDP_PROFILE=$(whiptail --title "Profils Thermiques" --radiolist "Comportement énergétique du processeur (TDP) :" 18 65 4 \
            "SILENCE" "Bridage 25W - Calme Absolu" OFF \
            "EQUILIBRE" "Stock 45W - Usine (Défaut)" ON \
            "EXTREME" "Débridage 65W - E-Sport Max" OFF 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then menu_principal; return; fi
    else
        export MADOS_TDP_PROFILE="EQUILIBRE"
    fi

    clear
    echo -e "${RED}⚠️  DÉPLOIEMENT TOTAL ENGAGÉ ⚠️${NC}"
    echo -e "${GRAY}Le système va configurer automatiquement votre ROG...${NC}\n"
    sleep 2

    # Modules obligatoires
    run_module "00_nettoyage_ubuntu.sh" "Purification du système & Dépôts"
    run_module "01_noyau_xanmod.sh"     "Injection du Noyau XanMod EDGE"
    run_module "02_pilotes_gpu_auto.sh" "Détection Pilotes Graphiques"
    run_module "03_integration_rog.sh"  "Couplage Hardware ROG (asusctl)"
    run_module "04_arsenal_logiciel.sh" "Logiciels Gamers & IA"
    run_module "05_bureau_kde_plasma.sh" "Interface Graphique Wayland (KDE 6)"
    run_module "06_thematique_mados.sh" "Esthétique ROG (GRUB, ZSH)"
    
    # Modules Bonus selon checklist
    [[ "$CHOIX_BONUS" == *"SNAP"* ]] && run_module "07_snapshots_systeme.sh" "Bouclier Système"
    [[ "$CHOIX_BONUS" == *"PROT"* ]] && run_module "08_proton_gamescope.sh" "Options Ultra Gaming"
    [[ "$CHOIX_BONUS" == *"NTFS"* ]] && run_module "09_montage_ntfs.sh" "Montage NTFS Windows"
    [[ "$CHOIX_BONUS" == *"SOND"* ]] && run_module "10_son_demarrage.sh" "Son ROG"
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

    cloture_installation
}

installation_custom() {
    local CHOIX_ALL
    CHOIX_ALL=$(whiptail --title "Déploiement Custom (Expert)" \
        --checklist "Espace pour sélectionner, Entrée pour valider :" 20 65 12 \
        "00_clean" "Nettoyer système (Bloatwares)" OFF \
        "01_kern" "Noyau Gaming XanMod EDGE" OFF \
        "02_gpu" "Pilotes GPU auto (Nvidia/AMD)" OFF \
        "03_rog" "Intégration Hardware ASUS ROG" OFF \
        "04_soft" "Arsenal logiciel (Steam, Discord...)" OFF \
        "05_kde" "Injecter KDE Plasma 6 Wayland" OFF \
        "06_them" "Thème visuel MadOS ROG" OFF \
        "07_snap" "Bouclier Snapshots Timeshift" OFF \
        "08_prot" "Performances Proton-GE / GameScope" OFF \
        "09_ntfs" "Auto-montage disques NTFS" OFF \
        "10_snd" "Son de démarrage ROG" OFF \
        "11_batt" "Auto-cpufreq Batterie" OFF \
        "12_mang" "MangoHud ROG Edition" OFF \
        "13_strm" "Pack OBS Stream" OFF \
        "14_claw" "Assistant IA OpenClaw" OFF \
        "15_net" "Optimisation Réseau TCP" OFF \
        "16_zrm" "Compression Mémoire ZRAM" OFF \
        "17_ads" "Bouclier Anti-Pub" OFF \
        "18_dev" "Pack Professionnel" OFF \
        "19_ssd" "Auto Trim NVMe" OFF \
        "20_usb" "Latence USB E-Sport" OFF \
        "21_bot" "Démarrage LZ4 Éclair" OFF \
        "22_cpu" "Undervolt CPU (Intel/AMD)" OFF \
        "23_gui" "Interface Graphique MadOS" OFF \
        "24_upd" "Mise à jour Auto MadOS" OFF \
        "25_san" "Diagnostic Santé Système" OFF \
        "26_vr"  "Casque VR (Meta Quest)" OFF 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then menu_principal; return; fi

    if [[ "$CHOIX_ALL" == *"22_cpu"* ]]; then
        export MADOS_TDP_PROFILE=$(whiptail --title "Surcadençage & Profils Thermiques" --radiolist "Sélectionnez le comportement énergétique de votre processeur (TDP/Chauffe) :" 18 75 4 \
            "SILENCE" "Bridage 25W - Autonomie & Calme Absolu" OFF \
            "EQUILIBRE" "Stock 45W - Performances d'Usine (Défaut)" ON \
            "EXTREME" "Débridage 65W - E-Sport & FPS Maximum" OFF 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then menu_principal; return; fi
    else
        export MADOS_TDP_PROFILE="EQUILIBRE"
    fi

    clear
    echo -e "${RED}Début du protocole custom...${NC}\n"
    sleep 2

    [[ "$CHOIX_ALL" == *"00_clean"* ]] && run_module "00_nettoyage_ubuntu.sh" "Purification du système"
    [[ "$CHOIX_ALL" == *"01_kern"* ]] && run_module "01_noyau_xanmod.sh" "Injection du Noyau"
    [[ "$CHOIX_ALL" == *"02_gpu"* ]] && run_module "02_pilotes_gpu_auto.sh" "Détection Pilotes"
    [[ "$CHOIX_ALL" == *"03_rog"* ]] && run_module "03_integration_rog.sh" "Couplage Hardware ROG"
    [[ "$CHOIX_ALL" == *"04_soft"* ]] && run_module "04_arsenal_logiciel.sh" "Logiciels Gamers"
    [[ "$CHOIX_ALL" == *"05_kde"* ]] && run_module "05_bureau_kde_plasma.sh" "KDE Plasma 6"
    [[ "$CHOIX_ALL" == *"06_them"* ]] && run_module "06_thematique_mados.sh" "Esthétique ROG"
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
    [[ "$CHOIX_ALL" == *"22_cpu"* ]] && run_module "22_cpu_undervolt.sh" "Undervolt & Thermiques"
    [[ "$CHOIX_ALL" == *"23_gui"* ]] && run_module "23_control_center.sh" "Interface Control Center"
    [[ "$CHOIX_ALL" == *"24_upd"* ]] && run_module "24_mados_update.sh" "Mise à jour depuis GitHub"
    [[ "$CHOIX_ALL" == *"25_san"* ]] && run_module "25_sante_systeme.sh" "Diagnostic Santé"
    [[ "$CHOIX_ALL" == *"26_vr"* ]] && run_module "26_vr_oculus_quest.sh" "Suite VR Meta Quest"

    cloture_installation
}

mode_destruction() {
    if whiptail --title "⚠️ MODE DESTRUCTION ⚠️" --yesno "Ceci va PURGER Canonical de tous ses bloatwares (snapd, cloud-init) de manière agressive.\n\nÊtes-vous absolument sûr de vouloir détruire la trace d'Ubuntu ?" 12 60; then
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

    whiptail --title "MAD OS ROG TERMINÉ 🎉" --msgbox "Déploiement Terminé avec Succès !\n\nLien de Diagnostic (Copiez-le pour le dev) :\n$LOG_URL\n\nAu prochain redémarrage, vous entrerez dans la Matrice :\n - Kernel XanMod EDGE\n - Interface Wayland / KDE\n - Modules Avancés Actifs" 16 68
    if whiptail --title "REDÉMARRAGE" --yesno "Voulez-vous redémarrer le système maintenant pour savourer le fruit de votre travail ?" 10 50; then
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

menu_principal
