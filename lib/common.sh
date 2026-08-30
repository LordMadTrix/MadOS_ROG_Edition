#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - lib/common.sh
# ==============================================================================
# Fonctions communes, logging, gestion d'erreurs et rollback
# ==============================================================================

# ==============================================================================
# Variables Globales
# ==============================================================================

# Couleurs (Globales)
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export GRAY='\033[0;37m'
export YELLOW='\033[0;33m'
export BOLD='\033[1m'
export NC='\033[0m'

# ==============================================================================
# Helpers Environnement Utilisateur (D-Bus / X11)
# ==============================================================================

# Fonction pour exécuter gsettings au nom de l'utilisateur réel
user_gsettings() {
    local REAL_USER=${SUDO_USER:-$USER}
    local USER_ID=$(id -u "$REAL_USER")
    
    # Tentative de détection du bus D-Bus
    local DBUS_ADDR="unix:path=/run/user/${USER_ID}/bus"
    if [ ! -S "/run/user/${USER_ID}/bus" ]; then
        # Fallback : chercher dans les processus
        local DBUS_SESSION_PID=$(pgrep -u "$USER_ID" gnome-session | head -n 1)
        [ -n "$DBUS_SESSION_PID" ] && DBUS_ADDR=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$DBUS_SESSION_PID/environ | cut -d= -f2-)
    fi

    sudo -u "$REAL_USER" \
        DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" \
        XDG_RUNTIME_DIR="/run/user/${USER_ID}" \
        DISPLAY="${DISPLAY:-:0}" \
        gsettings "$@"
}

# Fonction pour exécuter une commande simple au nom de l'utilisateur réel avec env complet
user_run() {
    local REAL_USER=${SUDO_USER:-$USER}
    local USER_ID=$(id -u "$REAL_USER")
    sudo -u "$REAL_USER" \
        XDG_RUNTIME_DIR="/run/user/${USER_ID}" \
        DISPLAY="${DISPLAY:-:0}" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${USER_ID}/bus" \
        "$@"
}


# Chemins critiques
export MADOS_LOG_DIR="/var/log/mados"
export MADOS_BACKUP_DIR="/var/lib/mados_backup"
export MADOS_CHECKPOINT_FILE="/tmp/mados_checkpoint.log"
export MADOS_ERRORS_FILE="${MADOS_LOG_DIR}/mados_errors.log"
export MADOS_STATUS_FILE="/tmp/mados_status.txt"

# Compteurs de tentatives
export RETRY_COUNT=3
export RETRY_DELAY=5

# ==============================================================================
# Initialisation
# ==============================================================================

init_mados_logging() {
    # Créer répertoires de logs et backups
    sudo mkdir -p "$MADOS_LOG_DIR" "$MADOS_BACKUP_DIR" 2>/dev/null || true
    sudo chmod 755 "$MADOS_LOG_DIR" "$MADOS_BACKUP_DIR" 2>/dev/null || true
    
    # Initialiser les fichiers
    touch "$MADOS_CHECKPOINT_FILE" "$MADOS_STATUS_FILE" 2>/dev/null || true
    
    log_info "═══════════════════════════════════════════════════════════"
    log_info "MadOS ROG Edition 4.0 - Démarrage Installation"
    log_info "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "Utilisateur: $USER"
    log_info "═══════════════════════════════════════════════════════════"
    
    # DNS Fix : Stabilisation pour les installations réseau fragiles (VM / WiFi)
    if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        log_warning "Instabilité réseau détectée. Injection de DNS de secours..."
        printf "nameserver 1.1.1.1\nnameserver 8.8.8.8\n" | sudo tee /etc/resolv.conf > /dev/null || true
    fi
}

# ==============================================================================
# Fonctions de Logging
# ==============================================================================

log_info() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${CYAN}[${timestamp}]${NC} ${GREEN}[INFO]${NC} ${msg}" | tee -a "$MADOS_LOG_DIR/mados_install.log" 2>/dev/null
    echo "[${timestamp}] [INFO] ${msg}" | sudo tee -a "$MADOS_LOG_DIR/mados_install.log" >/dev/null 2>&1 || true
}

log_error() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${RED}[${timestamp}]${NC} ${RED}[ERREUR]${NC} ${msg}" | tee -a "$MADOS_LOG_DIR/mados_install.log" 2>/dev/null
    echo "[${timestamp}] [ERREUR] ${msg}" | sudo tee -a "$MADOS_LOG_DIR/mados_install.log" "$MADOS_ERRORS_FILE" >/dev/null 2>&1 || true
}

log_warning() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${YELLOW}[${timestamp}]${NC} ${YELLOW}[ATTENTION]${NC} ${msg}" | tee -a "$MADOS_LOG_DIR/mados_install.log" 2>/dev/null
    echo "[${timestamp}] [ATTENTION] ${msg}" | sudo tee -a "$MADOS_LOG_DIR/mados_install.log" >/dev/null 2>&1 || true
}

log_success() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${GREEN}[${timestamp}]${NC} ${GREEN}[✓ SUCCÈS]${NC} ${msg}" | tee -a "$MADOS_LOG_DIR/mados_install.log" 2>/dev/null
    echo "[${timestamp}] [SUCCÈS] ${msg}" | sudo tee -a "$MADOS_LOG_DIR/mados_install.log" >/dev/null 2>&1 || true
}

# ==============================================================================
# Gestion des Erreurs & Pièges
# ==============================================================================

setup_error_traps() {
    # On capture les erreurs mais on ne sort plus violemment (set +e)
    trap 'handle_error $? $LINENO' ERR
    trap 'handle_interrupt' INT TERM
    # Désactivation du pipefail global pour laisser le flux couler vers la fin
    set +o pipefail
}

handle_error() {
    local exit_code=$1
    local line_number=$2
    local command="${BASH_COMMAND}"
    
    # Fallback si CURRENT_MODULE n'est pas défini (set -u safety)
    local active_mod="${CURRENT_MODULE:-unknown}"
    
    # Noter l'erreur discrètement sans couper le script
    log_warning "Signal d'erreur détecté (Code: $exit_code) à la ligne $line_number : $command"
    echo "[!] Erreur non-critique enregistrée à $(date '+%H:%M:%S') - Ligne $line_number" >> "$MADOS_ERRORS_FILE"
    
    # Sauvegarder l'état d'erreur
    echo "FAILED:${active_mod}:line_${line_number}" >> "$MADOS_CHECKPOINT_FILE"
    
    # NE PAS EXIT - continuer le script
    return 0
}

handle_interrupt() {
    log_warning "Installation interrompue par l'utilisateur"
    log_info "Checkpoints sauvegardés dans: $MADOS_CHECKPOINT_FILE"
    exit 130
}

# ==============================================================================
# Exécution de Commandes avec Retry
# ==============================================================================

run_command_retry() {
    local cmd="$1"
    local description="${2:-Commande}"
    local max_retries="${3:-$RETRY_COUNT}"
    local attempt=1
    
    log_info "Exécution: ${description}"
    
    while [ $attempt -le $max_retries ]; do
        if eval "$cmd" >/dev/null 2>&1; then
            log_success "${description} (tentative $attempt/$max_retries)"
            return 0
        else
            if [ $attempt -lt $max_retries ]; then
                log_warning "${description} échouée (tentative $attempt/$max_retries) - Nouvelle tentative dans ${RETRY_DELAY}s..."
                ( trap '' INT; sleep "$RETRY_DELAY" ) 2>/dev/null; true
            else
                log_error "${description} échouée après $max_retries tentatives"
                return 1
            fi
        fi
        ((attempt++))
    done
    
    return 1
}

# ==============================================================================
# Sauvegarde & Restauration (Checkpoints Persistants)
# ==============================================================================
STATE_FILE="/var/lib/mados/install_state"

save_checkpoint() {
    local module="$1"
    local status="${2:-OK}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    sudo mkdir -p "$(dirname "$STATE_FILE")"
    echo "$module:$status:$timestamp" | sudo tee -a "$STATE_FILE" > /dev/null
    log_info "Checkpoint sauvegardé: ${module} (${status})"
}

skip_if_completed() {
    local module="$1"
    if [ -f "$STATE_FILE" ] && grep -q "^$module:OK" "$STATE_FILE"; then
        log_info "Module $module déjà complété (skip)."
        return 0
    fi
    return 1
}

reset_install_state() {
    sudo rm -f "$STATE_FILE" 2>/dev/null
    log_info "État d'installation réinitialisé."
}

get_completed_modules() {
    [ -f "$STATE_FILE" ] && grep ":OK:" "$STATE_FILE" | cut -d: -f1 | sort -u
}

# ==============================================================================
# Sauvegarde des fichiers importants
# ==============================================================================

backup_file() {
    local file="$1"
    local backup_name="${2:-$(basename $file).bak.$(date +%s)}"
    
    if [ -f "$file" ]; then
        sudo cp "$file" "${MADOS_BACKUP_DIR}/${backup_name}" 2>/dev/null || true
        log_info "Fichier sauvegardé: ${file} → ${backup_name}"
    fi
}

restore_file() {
    local original="$1"
    local backup_file="$2"
    
    if [ -f "$backup_file" ]; then
        sudo cp "$backup_file" "$original" 2>/dev/null || true
        log_success "Fichier restauré: ${original}"
        return 0
    else
        log_error "Backup non trouvé: ${backup_file}"
        return 1
    fi
}

# ==============================================================================
# Vérifications Pré-Exécution
# ==============================================================================

check_disk_space() {
    local required_gb="${1:-40}"

    # Détection mode LIVE (casper/ISO) : ne pas vérifier / (ramdisk 2GB)
    if grep -q 'boot=casper\|live\|squashfs' /proc/cmdline 2>/dev/null || \
       [ -d /cdrom ] || [ -f /etc/casper.conf ]; then
        log_info "Mode Live détecté — vérification disque cible (pas /)"
        # Chercher le plus grand disque disponible (ex: /dev/vdb, /dev/sdb)
        local target_disk
        target_disk=$(lsblk -bnd -o NAME,SIZE 2>/dev/null | \
                      awk '{if($2+0 > max+0) {max=$2; dev=$1}} END{print dev}')
        if [ -n "$target_disk" ]; then
            local disk_gb=$(lsblk -bnd -o SIZE /dev/"$target_disk" 2>/dev/null | \
                           awk '{printf "%d", $1/1024/1024/1024}')
            if [ "${disk_gb:-0}" -ge "$required_gb" ]; then
                log_success "Disque cible /dev/$target_disk : ${disk_gb}GB disponibles"
                return 0
            else
                log_error "Disque cible trop petit: ${disk_gb:-0}GB (/dev/$target_disk) — ${required_gb}GB requis"
                return 1
            fi
        else
            log_warning "Aucun disque cible détecté — installation live continue"
            return 0
        fi
    fi

    # Mode normal : vérifier l'espace libre sur /
    local available_gb
    available_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "${available_gb:-0}" -lt "$required_gb" ]; then
        log_error "Espace disque insuffisant: ${available_gb}GB disponibles (${required_gb}GB requis)"
        return 1
    fi
    log_success "Espace disque OK: ${available_gb}GB disponibles"
    return 0
}

check_internet_connection() {
    log_info "Vérification de la connexion Internet..."
    
    # On tente le ping, mais on ne bloque pas si ça échoue (cas des pare-feux restrictifs)
    if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 3 archive.ubuntu.com >/dev/null 2>&1; then
        log_success "Connexion Internet OK"
        return 0
    else
        log_warning "Le test de connexion (Ping) a échoué. On continue quand même car vous semblez avoir internet."
        return 0
    fi
}

check_sudo_access() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Privilèges root requis"
        return 1
    fi
    
    log_success "Privilèges root confirmés"
    return 0
}

# ==============================================================================
# Utilitaires APT
# ==============================================================================

apt_update_safe() {
    log_info "Mise à jour des listes de paquets..."
    
    run_command_retry \
        "sudo apt-get update -o Acquire::Retries=3 -qq" \
        "apt-get update" \
        3 || return 1
}

apt_install_safe() {
    local packages="$1"
    local description="${2:-Installation de paquets}"
    
    log_info "${description}: ${packages}"
    
    run_command_retry \
        "sudo apt-get install -y --no-install-recommends ${packages}" \
        "${description}" \
        2 || return 1
}

# ==============================================================================
# Rapport d'Installation
# ==============================================================================

# ==============================================================================
# Helpers Visuels — Barre de progression, Headers, Steps
# ==============================================================================

print_module_header() {
    local desc="$1" attempt="${2:-1}" max="${3:-3}"
    local cur="${MADOS_MODULE_CURRENT:-0}" tot="${MADOS_MODULE_TOTAL:-1}"
    [ "$tot" -le 0 ] && tot=1
    local pct=$(( cur * 100 / tot ))
    [ "$pct" -gt 100 ] && pct=100
    local filled=$(( cur * 40 / tot ))
    [ "$filled" -gt 40 ] && filled=40
    local empty=$(( 40 - filled ))
    local bar_g="" bar_e=""
    [ "$filled" -gt 0 ] && bar_g=$(printf '█%.0s' $(seq 1 "$filled"))
    [ "$empty"  -gt 0 ] && bar_e=$(printf '░%.0s' $(seq 1 "$empty"))

    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${CYAN}$(printf '[%02d/%02d]' "$cur" "$tot")${NC}  ${WHITE}${BOLD}${desc}${NC}"
    echo -e "  ${GREEN}${bar_g}${GRAY}${bar_e}${NC}  ${WHITE}${pct}%${NC}  ${GRAY}━  Tentative ${attempt}/${max}${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_step()    { echo -e "    ${RED}▶${NC}  ${WHITE}$*${NC}"; }
print_ok()      { echo -e "    ${GREEN}✓${NC}  $*"; }
print_warn_v()  { echo -e "    ${YELLOW}⚠${NC}  ${YELLOW}$*${NC}"; }
print_err_v()   { echo -e "    ${RED}✗${NC}  ${RED}$*${NC}"; }
print_section() {
    echo -e "\n  ${GRAY}──────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}${BOLD}  $*${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────────────────────${NC}\n"
}

print_installation_report() {
    local total_time=$SECONDS
    local minutes=$((total_time / 60))
    local secs=$((total_time % 60))
    local mods="${MADOS_MODULE_CURRENT:-?}/${MADOS_MODULE_TOTAL:-?}"
    local kernel
    kernel=$(uname -r 2>/dev/null || echo "N/A")
    local errors=0
    [ -f "$MADOS_ERRORS_FILE" ] && [ -s "$MADOS_ERRORS_FILE" ] && errors=$(wc -l < "$MADOS_ERRORS_FILE")

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}✓${NC}  ${WHITE}${BOLD}MADOS 4.0 — DÉPLOIEMENT TERMINÉ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GRAY}Durée      :${NC}  ${WHITE}${minutes}m ${secs}s${NC}"
    echo -e "  ${GRAY}Modules    :${NC}  ${WHITE}${mods} complétés${NC}"
    if [ "$errors" -eq 0 ]; then
        echo -e "  ${GRAY}Erreurs    :${NC}  ${GREEN}Aucune${NC}"
    else
        echo -e "  ${GRAY}Erreurs    :${NC}  ${RED}${errors} enregistrée(s) → ${MADOS_ERRORS_FILE}${NC}"
    fi
    echo -e "  ${GRAY}Kernel     :${NC}  ${CYAN}${kernel}${NC}"
    echo -e "  ${GRAY}Logs       :${NC}  ${GRAY}${MADOS_LOG_DIR}/mados_install.log${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "  ${YELLOW}Prochaine étape :${NC}  ${GREEN}sudo reboot${NC}"
    echo -e ""
}

# ==============================================================================
# Détection d'Hyperviseur & Installation de Drivers
# ==============================================================================

detect_hypervisor() {
    local hypervisor="none"
    
    # Détection QEMU/KVM
    if grep -q "QEMU" /proc/cpuinfo 2>/dev/null || \
       lspci 2>/dev/null | grep -iq "qemu"; then
        hypervisor="qemu"
    fi
    
    # Détection VMware
    if dmidecode 2>/dev/null | grep -iq "vmware" || \
       grep -q "VMware" /sys/class/dmi/id/sys_vendor 2>/dev/null || \
       lspci 2>/dev/null | grep -iq "vmware"; then
        hypervisor="vmware"
    fi
    
    # Détection VirtualBox
    if grep -q "VirtualBox" /sys/devices/virtual/dmi/id/product_name 2>/dev/null || \
       lspci 2>/dev/null | grep -iq "virtualbox"; then
        hypervisor="virtualbox"
    fi
    
    # Détection Hyper-V
    if grep -q "Hyper-V" /sys/hypervisor/properties/identity 2>/dev/null || \
       systemd-detect-virt 2>/dev/null | grep -q "hyperv"; then
        hypervisor="hyperv"
    fi
    
    echo "$hypervisor"
}

install_hypervisor_drivers() {
    local hypervisor="$1"
    
    if [ -z "$hypervisor" ] || [ "$hypervisor" = "none" ]; then
        log_warning "Aucun hyperviseur détecté - Installation de drivers physiques"
        return 0
    fi
    
    log_info "Hyperviseur détecté: ${hypervisor} - Installation des drivers optimisés..."
    
    case "$hypervisor" in
        qemu)
            install_qemu_drivers
            ;;
        vmware)
            install_vmware_drivers
            ;;
        virtualbox)
            install_virtualbox_drivers
            ;;
        hyperv)
            install_hyperv_drivers
            ;;
        *)
            log_warning "Hyperviseur inconnu: $hypervisor"
            ;;
    esac
}

install_qemu_drivers() {
    log_info "Installation drivers QEMU/KVM..."
    
    # Mettre à jour les listes de paquets
    apt_update_safe || return 1
    
    # Paquets requis pour QEMU
    local packages=(
        "qemu-guest-agent"           # Agent invité QEMU
        "spice-vdagent"              # Agent SPICE pour le clipboard/souris
        "virtio-win"                 # Drivers VirtIO (optionnel)
        "acpid"                      # ACPI daemon pour gestion d'événements
        "open-vm-tools"              # Support cross-hypervisor
    )
    
    # Installer les paquets
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg"; then
            apt_install_safe "$pkg" "Installation $pkg (QEMU)" || log_warning "$pkg non disponible"
        fi
    done
    
    # Configuration réseau optimisée pour QEMU
    log_info "Optimisation réseau QEMU..."
    if command -v ethtool >/dev/null 2>&1; then
        for iface in eth0 ens0 ens33 ens160 enp0s1; do
            if [ -e "/sys/class/net/$iface" ]; then
                sudo ethtool -K "$iface" gso off gro off tso off 2>/dev/null || true
            fi
        done
    fi

    # Désactiver le watchdog (Vitesse de boot & VM friendly)
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nowatchdog"/' /etc/default/grub 2>/dev/null || true
    
    # I/O Scheduler pour SSD Virtuels
    if [ -f "/sys/block/sda/queue/scheduler" ]; then
        echo "noop" | sudo tee /sys/block/sda/queue/scheduler >/dev/null 2>&1 || true
    fi

    log_success "Drivers QEMU installés avec succès"
    return 0
}

install_vmware_drivers() {
    log_info "Installation drivers VMware..."
    
    # Mettre à jour les listes de paquets
    apt_update_safe || return 1
    
    # Paquets requis pour VMware
    local packages=(
        "open-vm-tools"              # Tools VMware principal
        "open-vm-tools-desktop"      # Support graphique (Wayland/X11)
        "open-vm-tools-dev"          # Headers pour compilation
        "build-essential"             # Pour compiler si nécessaire
        "linux-headers-generic"      # Headers noyau
    )
    
    # Installer les paquets
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg"; then
            apt_install_safe "$pkg" "Installation $pkg (VMware)" || log_warning "$pkg non disponible"
        fi
    done
    
    # Démarrer et activer les services VMware Tools
    if systemctl is-active --quiet vmtoolsd 2>/dev/null; then
        sudo systemctl enable vmtoolsd 2>/dev/null
        sudo systemctl start vmtoolsd 2>/dev/null
        log_success "VMware Tools Service activé"
    fi
    
    # Activer le support SVGA 3D si disponible
    if lspci 2>/dev/null | grep -q "SVGA III"; then
        log_info "Carte vidéo SVGA III détectée - Configuration optimisée"
        sudo mkdir -p /etc/modprobe.d/
        echo "options vmwgfx enable_fbdev=1" | sudo tee /etc/modprobe.d/vmware-gfx.conf >/dev/null 2>&1
        log_success "Drivers graphiques VMware optimisés"
    fi
    
    # Configuration réseau optimisée pour VMware
    log_info "Optimisation réseau VMware..."
    if command -v ethtool >/dev/null 2>&1; then
        for iface in eth0 ens33 ens160; do
            if [ -e "/sys/class/net/$iface" ]; then
                sudo ethtool -K "$iface" gso off gro off tso off 2>/dev/null || true
            fi
        done
    fi

    log_success "Drivers VMware installés avec succès"
    return 0
}

install_virtualbox_drivers() {
    log_info "Installation drivers VirtualBox..."
    
    # Mettre à jour les listes de paquets
    apt_update_safe || return 1
    
    # Paquets requis pour VirtualBox
    local packages=(
        "virtualbox-guest-utils"     # Utils invité
        "virtualbox-guest-x11"       # Support graphique X11
        "virtualbox-guest-dkms"      # Module noyau dynamique
        "build-essential"             # Pour DKMS
        "linux-headers-generic"      # Headers noyau
    )
    
    # Installer les paquets
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg"; then
            apt_install_safe "$pkg" "Installation $pkg (VirtualBox)" || log_warning "$pkg non disponible"
        fi
    done
    
    # Reconstruire les modules DKMS
    log_info "Reconstruction modules VirtualBox..."
    sudo dkms autoinstall 2>&1 | grep -v "^$" | while read line; do
        log_info "  $line"
    done || true
    
    # Activer le service
    if systemctl list-unit-files | grep -q "vboxadd-service"; then
        sudo systemctl enable vboxadd-service 2>/dev/null
        sudo systemctl start vboxadd-service 2>/dev/null
        log_success "VirtualBox Guest Service activé"
    fi
    
    log_success "Drivers VirtualBox installés avec succès"
    return 0
}

install_hyperv_drivers() {
    log_info "Installation drivers Hyper-V..."
    
    # Mettre à jour les listes de paquets
    apt_update_safe || return 1
    
    # Les drivers Hyper-V sont intégrés au noyau Linux
    # On installe juste les outils supplémentaires
    local packages=(
        "linux-image-generic"        # Noyau avec support Hyper-V
        "linux-tools-generic"        # Outils de diagnostic
        "build-essential"
    )
    
    # Installer les paquets
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg"; then
            apt_install_safe "$pkg" "Installation $pkg (Hyper-V)" || log_warning "$pkg non disponible"
        fi
    done
    
    # Activer les modules Hyper-V
    log_info "Configuration modules Hyper-V..."
    sudo modprobe hv_vmbus
    sudo modprobe hv_storvsc
    sudo modprobe hv_netvsc
    
    # Rendre persistants
    echo "hv_vmbus" | sudo tee -a /etc/modules >/dev/null 2>&1
    echo "hv_storvsc" | sudo tee -a /etc/modules >/dev/null 2>&1
    echo "hv_netvsc" | sudo tee -a /etc/modules >/dev/null 2>&1
    
    log_success "Drivers Hyper-V configurés"
    return 0
}

# ==============================================================================
# Export pour sous-scripts
# ==============================================================================

export -f log_info log_error log_warning log_success
export -f run_command_retry save_checkpoint skip_if_completed
export -f backup_file restore_file
export -f check_disk_space check_internet_connection check_sudo_access
export -f apt_update_safe apt_install_safe
export -f detect_hypervisor install_hypervisor_drivers
export -f install_qemu_drivers install_vmware_drivers
export -f install_virtualbox_drivers install_hyperv_drivers
export -f user_gsettings user_run
export -f print_module_header print_step print_ok print_warn_v print_err_v print_section


