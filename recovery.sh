#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - recovery.sh
# ==============================================================================
# Script de récupération en cas d'erreur lors de l'installation
# Permet de continuer depuis un checkpoint ou de reverter les changements
# ==============================================================================

# Charger les fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

setup_error_traps

show_recovery_menu() {
    clear
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} 🔧 ${WHITE}${BOLD}MadOS ROG - Mode Récupération${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    if [ ! -f "$MADOS_CHECKPOINT_FILE" ] || [ ! -s "$MADOS_CHECKPOINT_FILE" ]; then
        echo -e "${YELLOW}⚠️  Aucun checkpoint trouvé. Première installation ou logs effacés.${NC}\n"
        return 1
    fi
    
    echo -e "${CYAN}📊 Checkpoints d'Installation:${NC}\n"
    cat "$MADOS_CHECKPOINT_FILE" | nl
    
    echo ""
    whiptail --title "MadOS 3.0 - Récupération" --menu "Que voulez-vous faire ?" 20 65 6 \
        "1" "📖 Afficher les logs complets" \
        "2" "🔄 Continuer depuis le dernier checkpoint" \
        "3" "🔙 Afficher les erreurs détectées" \
        "4" "🗑️  Réinitialiser les checkpoints (recommencer)" \
        "5" "📦 Lister les fichiers sauvegardés" \
        "6" "❌ Quitter" 3>&1 1>&2 2>&3
}

show_logs() {
    if [ ! -f "$MADOS_LOG_DIR/mados_install.log" ]; then
        echo -e "${RED}Aucun log trouvé.${NC}"
        read -p "Appuyez sur Entrée pour continuer..."
        return
    fi
    
    less "$MADOS_LOG_DIR/mados_install.log"
}

show_errors() {
    if [ ! -f "$MADOS_ERRORS_FILE" ] || [ ! -s "$MADOS_ERRORS_FILE" ]; then
        echo -e "${GREEN}✓ Aucune erreur enregistrée!${NC}"
        read -p "Appuyez sur Entrée pour continuer..."
        return
    fi
    
    echo -e "${RED}🔴 Erreurs Détectées:${NC}\n"
    cat "$MADOS_ERRORS_FILE" | nl
    read -p "Appuyez sur Entrée pour continuer..."
}

show_checkpoints() {
    if [ ! -f "$MADOS_CHECKPOINT_FILE" ] || [ ! -s "$MADOS_CHECKPOINT_FILE" ]; then
        echo -e "${YELLOW}Aucun checkpoint.${NC}"
        read -p "Appuyez sur Entrée pour continuer..."
        return
    fi
    
    echo -e "${CYAN}📋 Détail des Checkpoints:${NC}\n"
    cat "$MADOS_CHECKPOINT_FILE"
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

reset_checkpoints() {
    echo -e "${YELLOW}⚠️  Êtes-vous sûr? Cela effacera tous les checkpoints.${NC}"
    read -p "Tapez 'OUI' pour confirmer: " confirm
    
    if [ "$confirm" = "OUI" ]; then
        rm -f "$MADOS_CHECKPOINT_FILE" "$MADOS_STATUS_FILE"
        log_success "Checkpoints réinitialisés"
        echo -e "${GREEN}✓ Les checkpoints ont été supprimés.${NC}"
        echo -e "${CYAN}Vous pouvez relancer: sudo bash install_local.sh${NC}"
    else
        echo -e "${YELLOW}Annulé.${NC}"
    fi
    
    read -p "Appuyez sur Entrée pour continuer..."
}

list_backups() {
    if [ ! -d "$MADOS_BACKUP_DIR" ] || [ -z "$(ls -A $MADOS_BACKUP_DIR 2>/dev/null)" ]; then
        echo -e "${YELLOW}Aucun fichier sauvegardé.${NC}"
        read -p "Appuyez sur Entrée pour continuer..."
        return
    fi
    
    echo -e "${CYAN}📦 Fichiers Sauvegardés:${NC}\n"
    ls -lah "$MADOS_BACKUP_DIR" | awk '{print $9, "(" $5 ")"}'
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

continue_from_checkpoint() {
    local last_failed_module=$(grep "FAILED:" "$MADOS_CHECKPOINT_FILE" 2>/dev/null | tail -1 | cut -d: -f2)
    
    if [ -z "$last_failed_module" ]; then
        echo -e "${CYAN}Aucun module en erreur détecté.${NC}"
    else
        echo -e "${YELLOW}Dernier module en erreur: ${last_failed_module}${NC}"
    fi
    
    echo -e "\n${CYAN}Modules déjà complétés:${NC}"
    get_completed_modules | nl
    
    echo ""
    echo -e "${GREEN}Pour continuer l'installation, relancez:${NC}"
    echo -e "${BOLD}  sudo bash install_local.sh${NC}"
    echo -e "\nLes modules déjà complétés seront automatiquement ignorés."
    
    read -p "Appuyez sur Entrée pour continuer..."
}

# ==============================================================================
# Main Menu Loop
# ==============================================================================

main() {
    init_mados_logging
    
    while true; do
        choice=$(show_recovery_menu)
        
        case $choice in
            1) show_logs ;;
            2) continue_from_checkpoint ;;
            3) show_errors ;;
            4) reset_checkpoints ;;
            5) list_backups ;;
            6) echo -e "\n${GREEN}Au revoir!${NC}\n"; exit 0 ;;
            *) echo -e "${RED}Option invalide${NC}" ;;
        esac
    done
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
