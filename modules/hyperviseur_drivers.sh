#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - hyperviseur_drivers.sh
# ==============================================================================
# Installation optimisée des drivers pour QEMU, VMware, VirtualBox et Hyper-V
#
# OUTIL MANUEL : ce script n'est PAS appele par install.sh, qui invoque
# directement detect_hypervisor() et install_hypervisor_drivers() de
# lib/common.sh. Il sert de point d'entree autonome pour relancer la detection
# et afficher un diagnostic :  sudo bash modules/hyperviseur_drivers.sh
# ==============================================================================

# Charger les fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

setup_error_traps

main() {
    export CURRENT_MODULE="hyperviseur_drivers.sh"
    
    echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} 🖥️  ${WHITE}${BOLD}Installation des Drivers Hyperviseur${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

    log_info "Détection de l'hyperviseur..."
    
    local hypervisor
    hypervisor=$(detect_hypervisor)
    
    log_info "Hyperviseur détecté: $hypervisor"
    
    case "$hypervisor" in
        qemu)
            log_success "Configuration pour QEMU/KVM"
            install_qemu_drivers || {
                log_error "Installation drivers QEMU échouée"
                return 1
            }
            ;;
        vmware)
            log_success "Configuration pour VMware"
            install_vmware_drivers || {
                log_error "Installation drivers VMware échouée"
                return 1
            }
            ;;
        virtualbox)
            log_success "Configuration pour VirtualBox"
            install_virtualbox_drivers || {
                log_error "Installation drivers VirtualBox échouée"
                return 1
            }
            ;;
        hyperv)
            log_success "Configuration pour Hyper-V"
            install_hyperv_drivers || {
                log_error "Installation drivers Hyper-V échouée"
                return 1
            }
            ;;
        none)
            log_info "Installation sur matériel physique détectée"
            log_info "Aucun driver hyperviseur nécessaire"
            ;;
        *)
            log_warning "Hyperviseur inconnu: $hypervisor"
            ;;
    esac
    
    # ==============================================================================
    # Optimisations Réseau Communes
    # ==============================================================================
    log_info "Optimisation réseau pour la VM..."
    
    # Activer les optimisations réseau si possible
    if command -v ethtool >/dev/null 2>&1; then
        for iface in eth0 ens0 ens33 ens160 enp0s3; do
            if [ -e "/sys/class/net/$iface" ]; then
                log_info "Optimisation réseau pour $iface"
                sudo ethtool -K "$iface" gso off gro off 2>/dev/null || true
                sudo ethtool -K "$iface" tso off 2>/dev/null || true
            fi
        done
    fi
    
    # ==============================================================================
    # Optimisations Système pour VM
    # ==============================================================================
    log_info "Optimisation système pour l'environnement virtualisé..."
    
    # Désactiver le watchdog s'il existe (peut causer des ralentissements)
    sudo bash -c 'echo "GRUB_CMDLINE_LINUX_DEFAULT=\"\$GRUB_CMDLINE_LINUX_DEFAULT nowatchdog\"" >> /etc/default/grub' 2>/dev/null || true
    
    # Configuration de l'I/O scheduler pour les VMs
    if [ -f "/sys/block/sda/queue/scheduler" ]; then
        sudo bash -c 'echo "noop" > /sys/block/sda/queue/scheduler' 2>/dev/null || \
        sudo bash -c 'echo "deadline" > /sys/block/sda/queue/scheduler' 2>/dev/null || true
    fi
    
    # ==============================================================================
    # Diagnostic Final
    # ==============================================================================
    echo ""
    log_info "Vérification post-installation..."
    
    echo ""
    echo -e "${CYAN}📊 Diagnostic:${NC}"
    
    # Vérifier les services d'hyperviseur
    case "$hypervisor" in
        qemu)
            if systemctl is-active --quiet qemu-guest-agent; then
                echo -e "  ${GREEN}✓${NC} QEMU Guest Agent: ${GREEN}Actif${NC}"
            else
                echo -e "  ${YELLOW}⚠${NC}  QEMU Guest Agent: ${YELLOW}Inactif${NC}"
            fi
            ;;
        vmware)
            if systemctl is-active --quiet vmtoolsd; then
                echo -e "  ${GREEN}✓${NC} VMware Tools: ${GREEN}Actif${NC}"
            else
                echo -e "  ${YELLOW}⚠${NC}  VMware Tools: ${YELLOW}Inactif${NC}"
            fi
            ;;
        virtualbox)
            if systemctl is-active --quiet vboxadd-service; then
                echo -e "  ${GREEN}✓${NC} VirtualBox Guest Service: ${GREEN}Actif${NC}"
            else
                echo -e "  ${YELLOW}⚠${NC}  VirtualBox Guest Service: ${YELLOW}Inactif${NC}"
            fi
            ;;
    esac
    
    # Afficher les modules Hyper-V
    if [ "$hypervisor" = "hyperv" ]; then
        echo -e "  ${CYAN}Modules Hyper-V:${NC}"
        lsmod | grep "hv_" | awk '{print "    - " $1}' || echo "    (aucun)"
    fi
    
    # Vérifier les interfaces réseau
    echo -e "  ${CYAN}Interfaces réseau:${NC}"
    ip link show | grep -E "^[0-9]+:" | awk '{print "    - " $2}' | sed 's/:$//'
    
    echo ""
    log_success "Module Drivers Hyperviseur complété avec succès"
    
    return 0
}

# Exécuter si appelé directement
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
