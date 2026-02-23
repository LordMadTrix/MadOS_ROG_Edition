#!/bin/bash
# ==========================================
# MadOS ROG V2 - Menu Principal d'Installation
# ==========================================
# Script de Post-Installation Interactif
# Détection GPU intelligente & Options Fun !
# ==========================================

set -euo pipefail

# Vérification des privilèges Root
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31m❌ ERREUR: La matrice refuse votre accès.\033[0m"
    echo -e "Veuillez lancer le script avec les privilèges administrateur (sudo) :"
    echo -e "   sudo bash Menu_Installation_ROG.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MODULES_DIR="$SCRIPT_DIR/modules"

if [ ! -d "$MODULES_DIR" ]; then
    echo -e "\033[0;31m❌ ERREUR FATALE: Le dossier 'modules/' est introuvable.\033[0m"
    echo -e "\033[0;90mAvez-vous extrait l'archive MadOS correctement ?\033[0m"
    exit 1
fi

chmod +x "$MODULES_DIR"/*.sh 2>/dev/null || true

# ---- Couleurs & Styles ----
RED='\033[0;31m'
DARK_RED='\033[38;5;88m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Effet Machine à écrire pour l'intro
type_text() {
    local text="$1"
    local delay="${2:-0.03}"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

# ASCII Art dynamique
afficher_logo() {
    clear
    echo -e "${RED}${BOLD}  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗${NC}"
    echo -e "${RED}${BOLD}  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝${NC}"
    echo -e "${RED}${BOLD}  ██╔████╔██║███████║██║  ██║██║   ██║███████╗${NC}"
    echo -e "${RED}${BOLD}  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║${NC}"
    echo -e "${RED}${BOLD}  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║${NC}"
    echo -e "${RED}${BOLD}  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}       REPUBLIC OF GAMERS - SCRIPT POST-INSTALL V2${NC}"
    echo -e "${GRAY}       -------------------------------------------${NC}"
    echo ""
}

intro_fun() {
    clear
    echo -e "${GREEN}"
    type_text "Wake up, Neo..." 0.05
    sleep 1
    type_text "The MadOS Matrix has you..." 0.05
    sleep 1
    type_text "Follow the red rabbit. 🐇" 0.05
    echo -e "${NC}"
    sleep 2
    afficher_logo
}

run_module() {
    local SCRIPT="$1"
    local DESCRIPTION="${2:-}"
    
    echo -e "\n${CYAN}╭──────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} 🚀 ${WHITE}${BOLD}Exécution : ${SCRIPT}${NC}"
    echo -e "${CYAN}│${NC} 📌 ${GRAY}${DESCRIPTION}${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────╯${NC}\n"
    
    if ! bash "$MODULES_DIR/$SCRIPT"; then
        echo -e "\n${RED}${BOLD}❌ [ERREUR] Le module $SCRIPT a signalé une anomalie.${NC}"
        echo -e "${RED}Voulez-vous ignorer l'erreur et continuer ? (o/N)${NC}"
        read -r choix
        if [[ ! "$choix" =~ ^[oO]$ ]]; then
            echo -e "${RED}Arrêt du déploiement. Rapportez l'erreur sur le registre GitHub.${NC}"
            exit 1
        fi
    fi
}

menu_principal() {
    afficher_logo
    echo -e "${WHITE}${BOLD}Que souhaitez-vous faire ?${NC}\n"
    echo -e " ${RED}[1]${NC} ${BOLD}Déploiement Total (Recommandé)${NC} - Fait tout automatiquement."
    echo -e " ${RED}[2]${NC} ${BOLD}Déploiement Personnalisé${NC} - Choisir chaque étape (Experts)."
    echo -e " ${RED}[3]${NC} ${BOLD}Mode Destruction 🔥${NC} - Purger Ubuntu de tous ses bloatwares (Snap, Cloud-Init)."
    echo -e " ${GRAY}[0]${NC} Sortir de la Matrice.\n"
    
    read -p "$(echo -e ${WHITE}👉 Votre choix : ${NC})" CHOIX_MENU
    
    case $CHOIX_MENU in
        1) installation_totale ;;
        2) installation_custom ;;
        3) mode_destruction ;;
        0) echo -e "${GRAY}Désengagement... Au revoir.${NC}"; exit 0 ;;
        *) echo -e "${RED}Choix invalide.${NC}"; sleep 1; menu_principal ;;
    esac
}

installation_totale() {
    clear
    afficher_logo
    echo -e "${RED}${BOLD}⚠️  DÉPLOIEMENT TOTAL ENGAGÉ ⚠️${NC}"
    echo -e "${GRAY}Le système va configurer automatiquement votre ROG sans autre intervention.${NC}\n"
    sleep 2

    run_module "00_nettoyage_ubuntu.sh" "Purification du système & Dépôts"
    run_module "01_noyau_xanmod.sh"     "Injection du Noyau XanMod EDGE"
    run_module "02_pilotes_gpu_auto.sh" "Détection et Installation des Pilotes Graphiques (NVIDIA/AMD/Intel)"
    run_module "03_integration_rog.sh"  "Couplage Hardware ROG (asusctl, audio, WIFI)"
    run_module "04_arsenal_logiciel.sh" "Logiciels Gamers & IA (Steam, Chrome, Lutris...)"
    run_module "05_bureau_kde_plasma.sh" "Interface Graphique Wayland (KDE Plasma 6)"
    run_module "06_thematique_mados.sh" "Esthétique ROG absolue (GRUB, ZSH, Plymouth)"

    cloture_installation
}

installation_custom() {
    clear
    afficher_logo
    echo -e "${WHITE}${BOLD}Mode Personnalisé - Répondez (o/N) pour chaque module :${NC}\n"
    
    read -p "Voulez-vous nettoyer le système (Bloatwares/Snap) ? [o/N]: " r_clean
    read -p "Voulez-vous installer le noyau Gaming XanMod EDGE ? [o/N]: " r_kern
    read -p "Voulez-vous configurer les pilotes GPU auto ? [o/N]: " r_gpu
    read -p "Voulez-vous intégrer les pilotes spécifiques ASUS ROG ? [o/N]: " r_rog
    read -p "Voulez-vous compiler l'arsenal logiciel (Steam, Discord...) ? [o/N]: " r_soft
    read -p "Voulez-vous injecter KDE Plasma 6 Wayland ? [o/N]: " r_kde
    read -p "Voulez-vous appliquer le thème visuel intégral MadOS ROG ? [o/N]: " r_theme

    echo -e "\n${GREEN}Début du protocole custom...${NC}"
    sleep 2

    [[ "$r_clean" =~ ^[oO]$ ]] && run_module "00_nettoyage_ubuntu.sh" "Purification du système"
    [[ "$r_kern" =~ ^[oO]$ ]] && run_module "01_noyau_xanmod.sh" "Injection du Noyau"
    [[ "$r_gpu"  =~ ^[oO]$ ]] && run_module "02_pilotes_gpu_auto.sh" "Détection Pilotes"
    [[ "$r_rog"  =~ ^[oO]$ ]] && run_module "03_integration_rog.sh" "Couplage Hardware ROG"
    [[ "$r_soft" =~ ^[oO]$ ]] && run_module "04_arsenal_logiciel.sh" "Logiciels Gamers"
    [[ "$r_kde"  =~ ^[oO]$ ]] && run_module "05_bureau_kde_plasma.sh" "KDE Plasma 6"
    [[ "$r_theme" =~ ^[oO]$ ]] && run_module "06_thematique_mados.sh" "Esthétique ROG"

    cloture_installation
}

mode_destruction() {
    clear
    echo -e "${RED}${BOLD}"
    cat << "EOF"
         .-""-.
        / _  _ \
        |(_)(_)|
        \  __  /
         \ \/ /
          '--'
EOF
    echo -e "MODES DESTRUCTION: PURGE DE CANONICAL${NC}"
    echo -e "${GRAY}Attention: Ceci va détruire les services serveurs par défaut et Snap sans retour !${NC}\n"
    read -p "Continuer ? (o/N): " conf
    if [[ "$conf" =~ ^[oO]$ ]]; then
        run_module "00_nettoyage_ubuntu.sh" "Purification Extrême de l'Hôte"
    fi
    sleep 2
    menu_principal
}

cloture_installation() {
    echo -e "\n${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}   🎉 ${WHITE}${BOLD}DÉPLOIEMENT MADOS ROG TERMINÉ !${NC}                      ${RED}║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${RED}║${NC} ${WHITE}Que va-t-il se passer au redémarrage ?${NC}                       ${RED}║${NC}"
    echo -e "${RED}║${NC}  🔸 Chargement du Kernel XanMod EDGE (Optimisé AVX2)${NC}         ${RED}║${NC}"
    echo -e "${RED}║${NC}  🔸 Activation de l'environnement matériel KDE/Wayland${NC}       ${RED}║${NC}"
    echo -e "${RED}║${NC}  🔸 Prêt pour la Domination Mondiale 🌍${NC}                      ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}\n"
    
    read -p "Voulez-vous redémarrer le système maintenant pour savourer ? (O/n): " r_reboot
    if [[ ! "$r_reboot" =~ ^[nN]$ ]]; then
        echo -e "${RED}Initiation de la séquence de reboot...${NC}"
        sleep 2
        reboot
    else
        echo -e "${GRAY}À bientôt dans la Matrice.${NC}"
        exit 0
    fi
}

# Lancement script
intro_fun
menu_principal
