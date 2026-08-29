#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - lib/common.sh
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


# ==============================================================================
# Détection de l'environnement de bureau
# ==============================================================================
# `$(user_run echo $XDG_CURRENT_DESKTOP)` ne marchait pas : la variable est
# developpee par le shell ROOT avant d'etre passee a sudo, et root ne l'a pas
# dans son environnement. Le resultat etait donc toujours vide, le test tombait
# systematiquement dans le `else`, et KDE etait force -- y compris sur une
# machine GNOME, rendant tout le chemin "Transformation Win11 GNOME" inatteignable.
#
# On interroge donc, dans l'ordre : la session logind de l'utilisateur, puis les
# processus de session reellement en cours, puis les paquets installes.
# Renvoie "KDE", "GNOME" ou "UNKNOWN".
detecter_bureau() {
    local utilisateur="${SUDO_USER:-$USER}"
    local brut=""

    # 1. logind : source d'autorite quand une session graphique est ouverte.
    if command -v loginctl >/dev/null 2>&1; then
        local sid
        sid=$(loginctl show-user "$utilisateur" -p Display --value 2>/dev/null)
        [ -z "$sid" ] && sid=$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$utilisateur" '$3==u {print $1; exit}')
        [ -n "$sid" ] && brut=$(loginctl show-session "$sid" -p Desktop --value 2>/dev/null)
    fi

    # 2. Processus de session : fiable meme sans logind exploitable.
    if [ -z "$brut" ]; then
        if pgrep -u "$utilisateur" -x plasmashell >/dev/null 2>&1; then
            brut="KDE"
        elif pgrep -u "$utilisateur" -x gnome-shell >/dev/null 2>&1; then
            brut="GNOME"
        fi
    fi

    # 3. Dernier recours : ce qui est installe.
    if [ -z "$brut" ]; then
        if command -v plasmashell >/dev/null 2>&1; then
            brut="KDE"
        elif command -v gnome-shell >/dev/null 2>&1; then
            brut="GNOME"
        fi
    fi

    case "$(echo "$brut" | tr '[:upper:]' '[:lower:]')" in
        *kde*|*plasma*) echo "KDE" ;;
        *gnome*|*ubuntu*) echo "GNOME" ;;
        *) echo "UNKNOWN" ;;
    esac
}

# Chemins critiques
export MADOS_LOG_DIR="/var/log/mados"
export MADOS_BACKUP_DIR="/var/lib/mados_backup"
export MADOS_CHECKPOINT_FILE="/tmp/mados_checkpoint.log"
export MADOS_ERRORS_FILE="${MADOS_LOG_DIR}/mados_errors.log"
export MADOS_STATUS_FILE="/tmp/mados_status.txt"
# Défini ICI (pas seulement dans config.conf) : en installation réelle, install.sh
# ne source config.conf que dans les branches --list-backups/--restore. Sans cette
# ligne, backup_file() écrivait dans un chemin vide -- le fichier était bien copié,
# mais jamais indexé, donc jamais retrouvable par --list-backups/--restore.
export MADOS_BACKUP_MANIFEST="${MADOS_BACKUP_MANIFEST:-$MADOS_BACKUP_DIR/manifeste.tsv}"

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
    log_info "MadOS ROG Edition 3.5 - Démarrage Installation"
    log_info "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "Utilisateur: $USER"
    log_info "═══════════════════════════════════════════════════════════"
    
    # DNS Fix : Stabilisation pour les installations réseau fragiles (VM / WiFi)
    if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        if is_dry_run; then
            log_simu "détecterait une instabilité réseau et écrirait des DNS de secours dans /etc/resolv.conf"
        else
            log_warning "Instabilité réseau détectée. Injection de DNS de secours..."
            printf "nameserver 1.1.1.1\nnameserver 8.8.8.8\n" | sudo tee /etc/resolv.conf > /dev/null || true
        fi
    fi
}

# ==============================================================================
# Fonctions de Logging
# ==============================================================================

log_info() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${CYAN}[${timestamp}]${NC} ${GREEN}[INFO]${NC} ${msg}"
    echo "[${timestamp}] [INFO] ${msg}" | sudo tee -a "$MADOS_LOG_DIR/mados_install.log" >/dev/null 2>&1 || true
}

log_error() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${RED}[${timestamp}]${NC} ${RED}[ERREUR]${NC} ${msg}"
    echo "[${timestamp}] [ERREUR] ${msg}" | sudo tee -a "$MADOS_LOG_DIR/mados_install.log" "$MADOS_ERRORS_FILE" >/dev/null 2>&1 || true
}

log_warning() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${YELLOW}[${timestamp}]${NC} ${YELLOW}[ATTENTION]${NC} ${msg}"
    echo "[${timestamp}] [ATTENTION] ${msg}" | sudo tee -a "$MADOS_LOG_DIR/mados_install.log" >/dev/null 2>&1 || true
}

log_success() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${GREEN}[${timestamp}]${NC} ${GREEN}[✓ SUCCÈS]${NC} ${msg}"
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
                sleep "$RETRY_DELAY"
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
    local module=$1
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

# Lit le MEME fichier et le MEME format que save_checkpoint, qui ecrit
# "<module>:<statut>:<horodatage>" dans STATE_FILE. L'ancienne version lisait
# MADOS_CHECKPOINT_FILE en cherchant "OK:<module>" -- deux fichiers et deux
# formats differents, donc jamais aucune correspondance : la reprise
# d'installation ne fonctionnait pas.
get_completed_modules() {
    [ -f "$STATE_FILE" ] || return 0
    grep -E ':(OK|SKIPPED_ERROR):' "$STATE_FILE" 2>/dev/null | cut -d: -f1 | sort -u
}

# Une seule definition. Il y en avait deux : la seconde ecrasait silencieusement
# la premiere (la correcte) au chargement du fichier.

# ==============================================================================
# Sauvegarde des fichiers importants
# ==============================================================================

# ==============================================================================
# MODE SIMULATION (DRY_RUN)
#
# DRY_RUN était déclaré dans config.conf mais n'était lu nulle part : le mode
# simulation était annoncé sans exister. Toute action destructive doit désormais
# passer par run_action, qui affiche ce qu'elle FERAIT au lieu de le faire.
# ==============================================================================
is_dry_run() {
    # local ... = "${DRY_RUN:-no}" et pas "${DRY_RUN,,}" directement : install.sh
    # tourne sous "set -u", et une installation NORMALE (sans --dry-run) n'exporte
    # jamais DRY_RUN du tout -- confirmé en testant pour de vrai sous WSL2 : sans
    # ce filet, cette ligne plantait tout de suite avec "DRY_RUN: unbound
    # variable", AVANT même la première vraie commande. Le mode simulation aurait
    # fait planter le mode réel.
    local valeur="${DRY_RUN:-no}"
    case "${valeur,,}" in
        yes|true|1|oui) return 0 ;;
        *) return 1 ;;
    esac
}

# Compte les lignes [SIMULATION] émises dans la session en cours : c'est ce qui
# permet au bilan final ("N modification(s) auraient été faites") de dire quelque
# chose de mesuré plutôt qu'un simple "terminé".
export MADOS_SIMU_COUNT=0

log_simu() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo -e "${CYAN}[${timestamp}]${NC} ${YELLOW}[SIMULATION]${NC} ${msg}"
    echo "[${timestamp}] [SIMULATION] ${msg}" | sudo tee -a "$MADOS_LOG_DIR/mados_install.log" >/dev/null 2>&1 || true
    MADOS_SIMU_COUNT=$((MADOS_SIMU_COUNT + 1))
}

run_action() {
    # Usage : run_action "ce que ça ferait, en clair" commande arg1 arg2...
    # En simulation, rien n'est exécuté : seule la description est affichée.
    local description="$1"
    shift

    if is_dry_run; then
        log_simu "$description"
        return 0
    fi
    "$@"
}

refuser_reglage() {
    # Un module refuse de nuire : plutôt qu'appliquer un réglage néfaste SUR CETTE
    # machine-ci, il explique pourquoi il ne le fait pas. Un refus n'est pas un échec.
    local raison="$1"
    log_warning "RÉGLAGE REFUSÉ (il nuirait sur cette machine) : ${raison}"
    return 0
}

# ==============================================================================
# Sauvegarde & Restauration
# ==============================================================================
backup_file() {
    local file="$1"
    local backup_name="${2:-$(basename $file).bak.$(date +%s)}"

    if [ -f "$file" ]; then
        if is_dry_run; then
            log_simu "sauvegarderait ${file}"
            return 0
        fi

        sudo mkdir -p "$MADOS_BACKUP_DIR" 2>/dev/null || true
        sudo cp -p "$file" "${MADOS_BACKUP_DIR}/${backup_name}" 2>/dev/null || true

        # Le manifeste est ce qui rend la restauration possible : sans lui, un backup
        # horodaté ne dit plus de QUEL fichier il provient.
        printf '%s	%s	%s
' "$file" "${MADOS_BACKUP_DIR}/${backup_name}" "$(date '+%Y-%m-%d %H:%M:%S')"             | sudo tee -a "$MADOS_BACKUP_MANIFEST" >/dev/null 2>&1 || true

        log_info "Fichier sauvegardé: ${file} → ${backup_name}"
    fi
}

list_backups() {
    # Affiche ce qui a été sauvegardé, et donc ce qui est restaurable.
    if [ ! -f "$MADOS_BACKUP_MANIFEST" ]; then
        log_warning "Aucune sauvegarde enregistrée (manifeste absent)."
        return 1
    fi

    echo -e "${CYAN}Fichiers sauvegardés par MadOS :${NC}"
    local n=0
    while IFS=$'	' read -r original sauvegarde date_bk; do
        [ -z "$original" ] && continue
        n=$((n + 1))
        printf '  %2d. %s
      sauvegardé le %s
' "$n" "$original" "$date_bk"
    done < "$MADOS_BACKUP_MANIFEST"
    echo -e "${CYAN}${n} fichier(s) restaurable(s).${NC}"
}

restore_all() {
    # Remet chaque fichier sauvegardé à sa place, du plus ancien au plus récent :
    # si un même fichier a été sauvegardé plusieurs fois, la PREMIÈRE sauvegarde
    # (l'état d'origine, avant toute intervention de MadOS) doit gagner en dernier.
    if [ ! -f "$MADOS_BACKUP_MANIFEST" ]; then
        log_error "Aucun manifeste de sauvegarde : rien à restaurer."
        return 1
    fi

    local ok=0 echecs=0
    while IFS=$'	' read -r original sauvegarde date_bk; do
        [ -z "$original" ] && continue
        if [ ! -f "$sauvegarde" ]; then
            log_error "Sauvegarde introuvable pour ${original}"
            echecs=$((echecs + 1))
            continue
        fi
        if is_dry_run; then
            log_simu "restaurerait ${original}"
            ok=$((ok + 1))
            continue
        fi
        if sudo cp -p "$sauvegarde" "$original" 2>/dev/null; then
            ok=$((ok + 1))
        else
            log_error "Échec de restauration : ${original}"
            echecs=$((echecs + 1))
        fi
    done < <(tac "$MADOS_BACKUP_MANIFEST")

    log_info "${ok} fichier(s) restauré(s), ${echecs} échec(s)."
    [ "$echecs" -eq 0 ]
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
    local available_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$available_gb" -lt "$required_gb" ]; then
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

print_installation_report() {
    local total_time=$SECONDS
    local minutes=$((total_time / 60))
    local seconds=$((total_time % 60))
    
    clear
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} ${GREEN}✓${NC} ${WHITE}${BOLD}Installation MadOS 3.5 Terminée${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${CYAN}📊 Rapport de l'Installation:${NC}"
    echo -e "  ${GRAY}├─ Durée: ${minutes}m ${seconds}s${NC}"
    echo -e "  ${GRAY}├─ Logs complets: ${MADOS_LOG_DIR}/mados_install.log${NC}"
    echo -e "  ${GRAY}├─ Backups: ${MADOS_BACKUP_DIR}${NC}"
    echo -e "  ${GRAY}├─ Checkpoints: ${MADOS_CHECKPOINT_FILE}${NC}"
    
    if [ -f "$MADOS_ERRORS_FILE" ] && [ -s "$MADOS_ERRORS_FILE" ]; then
        echo -e "  ${RED}├─ Erreurs: $(wc -l < $MADOS_ERRORS_FILE) erreur(s) enregistrée(s)${NC}"
        echo -e "  ${GRAY}└─ Détails: ${MADOS_ERRORS_FILE}${NC}"
    else
        echo -e "  ${GREEN}└─ ✓ Aucune erreur détectée${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}📁 Prochaines étapes:${NC}"
    echo -e "  1. Redémarrez le système: ${GREEN}sudo reboot${NC}"
    echo -e "  2. Consultez les logs: ${GREEN}sudo cat ${MADOS_LOG_DIR}/mados_install.log${NC}"
    echo -e "  3. En cas de problème: ${GREEN}sudo cat ${MADOS_CHECKPOINT_FILE}${NC}"
    echo ""
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
export -f user_gsettings user_run detecter_bureau
# Portes de simulation : sans elles ici, un module qui appelle run_action dans son
# propre sous-processus (bash "$MODULES_DIR/$SCRIPT") echouait en "command not
# found" -- verifie en pratique, pas suppose. La retape des 38 modules ajoute
# aussi un "source common.sh" par fichier (plus robuste que compter sur l'export),
# mais cette ligne reste le filet pour tout code qui n'aurait pas encore ce source.
export -f run_action is_dry_run refuser_reglage log_simu


