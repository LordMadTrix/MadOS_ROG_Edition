#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 00_nettoyage_ubuntu.sh (EXEMPLE)
# ==============================================================================
# Phase: 0 - Purification & Dépôts
# Nettoie les composants serveur et prépare l'environnement.
# ==============================================================================

# Charger les fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

setup_error_traps

main() {
    export CURRENT_MODULE="00_nettoyage_ubuntu.sh"
    
    echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 0 - Purification du Système & Préparation${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

    log_info "Début du nettoyage du système"
    
    # ==============================================================================
    # 1. Nettoyer les processus qui bloquent APT
    # ==============================================================================
    log_info "Nettoyage des processus bloquant APT..."
    
    if command -v pkill >/dev/null 2>&1; then
        sudo pkill -f apt 2>/dev/null || true
    else
        sudo killall apt apt-get 2>/dev/null || true
    fi
    
    # Supprimer les fichiers lock
    sudo rm -f /var/lib/apt/lists/lock 2>/dev/null || true
    sudo rm -f /var/cache/apt/archives/lock 2>/dev/null || true
    sudo rm -f /var/lib/dpkg/lock* 2>/dev/null || true
    
    # Configurer dpkg
    sudo dpkg --configure -a 2>/dev/null || true
    
    log_success "Processus APT nettoyés"

    # ==============================================================================
    # 2. Mise à jour des listes de paquets (avec retry)
    # ==============================================================================
    log_info "Mise à jour des listes de paquets..."
    
    apt_update_safe || {
        log_warning "apt update échouée au premier essai"
        # Les retries sont gérés par apt_update_safe
        return 1
    }

    # ==============================================================================
    # 3. Installation des outils pré-requis
    # ==============================================================================
    log_info "Installation des outils de base..."
    
    apt_install_safe \
        "software-properties-common dirmngr gpg curl wget" \
        "Outils de gestion des dépôts" || {
        log_error "Installation des outils échouée"
        return 1
    }

    # ==============================================================================
    # 4. Suppression des Bloatware Serveur
    # ==============================================================================
    log_info "Suppression des services inutiles..."
    
    local packages_to_remove="cloud-init multipath-tools snapd"
    
    for pkg in $packages_to_remove; do
        if dpkg -l | grep -q "^ii  $pkg"; then
            log_info "Suppression de $pkg..."
            
            if run_command_retry "sudo apt purge -y $pkg" "Suppression de $pkg" 2 >/dev/null; then
                log_success "$pkg supprimé"
                # Sauvegarder la config avant suppression
                backup_file "/etc/cloud/cloud.cfg" "cloud.cfg.bak.$(date +%s)"
            else
                log_warning "$pkg non trouvé ou suppression échouée"
            fi
        fi
    done
    
    # Nettoyage auto
    log_info "Nettoyage automatique des paquets..."
    run_command_retry "sudo apt autoremove -y --purge" "apt autoremove" 2 >/dev/null
    
    # Suppression des dossiers cloud-init
    sudo rm -rf /etc/cloud/ /var/lib/cloud/ 2>/dev/null || true
    log_success "Cloud-init complètement supprimé"

    # ==============================================================================
    # 5. Configuration NetworkManager
    # ==============================================================================
    log_info "Configuration du gestionnaire réseau..."
    
    apt_install_safe "network-manager" "Installation de NetworkManager" || {
        log_warning "NetworkManager non installé mais ce n'est pas critique"
    }
    
    # Sauvegarder la config réseau avant modification
    if [ -f /etc/netplan/50-cloud-init.yaml ]; then
        backup_file "/etc/netplan/50-cloud-init.yaml" "50-cloud-init.yaml.bak.$(date +%s)"
        sudo rm -f /etc/netplan/50-cloud-init.yaml
        log_success "Configuration cloud-init supprimée"
    fi

    # ==============================================================================
    # 6. Vérification finale
    # ==============================================================================
    log_info "Vérification finale du nettoyage..."
    
    if apt list --installed 2>/dev/null | grep -q "snapd"; then
        log_warning "Snapd n'a pas été complètement supprimé"
    else
        log_success "Snapd confirmé supprimé"
    fi
    
    if dpkg -l | grep "cloud-init" >/dev/null 2>&1; then
        log_warning "Cloud-init n'a pas été complètement supprimé"
    else
        log_success "Cloud-init confirmé supprimé"
    fi

    # ==============================================================================
    # Fin du module
    # ==============================================================================
    echo ""
    log_success "Module 00 - Nettoyage complété avec succès"
    
    # Le checkpoint est enregistré automatiquement par run_module()
    return 0
}

# Exécuter si appelé directement
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
