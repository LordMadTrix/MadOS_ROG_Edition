#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 Ultimate - install.sh
# ==============================================================================
# Optimized for Ubuntu 24.04 LTS (Stable)
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

# ==============================================================================
# Fonctions de Support Globales
# ==============================================================================

wait_for_apt() {
    echo -ne "    ${GRAY}🕒 Attente des verrous système (APT/DPKG)...${NC}"
    if type is_dry_run >/dev/null 2>&1 && is_dry_run; then
        log_simu "tuerait apt/apt-get/dpkg et lèverait leurs verrous (wait_for_apt)"
        echo -e " ${GREEN}OK (simulation)${NC}"
        return 0
    fi
    sudo killall -9 apt apt-get dpkg 2>/dev/null || true
    sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock 2>/dev/null || true
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
        echo -ne "."
        sleep 1
    done
    echo -e " ${GREEN}OK${NC}"
}

# ensure_nala() supprimee.
#   - `alias apt='sudo nala'` ne pouvait structurellement jamais s'appliquer :
#     en Bash les alias sont resolus a l'ANALYSE, et toutes les fonctions
#     appelantes etaient deja lues quand l'alias etait cree.
#   - Le projet appelle de toute facon `sudo apt` / `sudo apt-get`, jamais `apt`
#     nu : meme un alias fonctionnel n'aurait rien intercepte.
#   - Resultat : nala etait telecharge et installe pour n'etre jamais utilise.

# ==============================================================================
# Amorçage : récupérer l'arborescence complète quand install.sh est lancé seul
# ==============================================================================
# Déclenché quand lib/ ou modules/ manquent à côté de ce fichier, c'est-à-dire :
#   - la commande du site : wget -qO install.sh <raw>/install.sh && sudo bash install.sh
#   - le raccourci mados-install : curl -sL <raw>/install.sh | sudo bash
# Dans ces deux cas, un seul fichier est téléchargé et il n'y a rien à installer.
# Ne peut pas utiliser log_* ni is_dry_run : common.sh n'est pas encore chargé.
mados_amorcage() {
    local depot="https://github.com/LordMadTrix/MadOS_ROG_Edition"
    local cible="/opt/mados_src"
    local archive="/tmp/mados_src.tar.gz"

    # Filet anti-récursion : si la relance retombe ici, on s'arrête net.
    if [ -n "${MADOS_AMORCAGE_FAIT:-}" ]; then
        echo -e "${RED}[ERREUR] L'amorçage a déjà eu lieu et lib/common.sh reste introuvable.${NC}"
        exit 1
    fi
    export MADOS_AMORCAGE_FAIT=1

    echo -e "${CYAN}[AMORÇAGE]${NC} install.sh a été lancé sans ses modules."
    echo -e "${GRAY}    ├─ Récupération de l'arborescence complète depuis GitHub...${NC}"

    sudo rm -rf "$cible" 2>/dev/null || true
    sudo mkdir -p "$cible"

    if ! command -v git >/dev/null 2>&1; then
        sudo apt-get update -qq >/dev/null 2>&1 || true
        sudo apt-get install -y git >/dev/null 2>&1 || true
    fi

    if command -v git >/dev/null 2>&1; then
        sudo git clone --depth=1 "${depot}.git" "$cible" >/dev/null 2>&1 || true
    fi

    # Repli sans git : archive tar.gz de la branche main.
    if [ ! -f "$cible/lib/common.sh" ]; then
        echo -e "${GRAY}    ├─ Clonage indisponible, téléchargement de l'archive...${NC}"
        rm -f "$archive"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "${depot}/archive/refs/heads/main.tar.gz" -o "$archive" 2>/dev/null || true
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$archive" "${depot}/archive/refs/heads/main.tar.gz" 2>/dev/null || true
        fi
        if [ -s "$archive" ]; then
            sudo tar -xzf "$archive" -C "$cible" --strip-components=1 2>/dev/null || true
        fi
        rm -f "$archive"
    fi

    if [ ! -f "$cible/lib/common.sh" ] || [ ! -d "$cible/modules" ]; then
        echo -e "${RED}[ERREUR] Impossible de récupérer MadOS depuis GitHub.${NC}"
        echo -e "${GRAY}    Vérifiez votre connexion, ou installez à la main :${NC}"
        echo -e "      ${GREEN}git clone ${depot}.git${NC}"
        echo -e "      ${GREEN}cd MadOS_ROG_Edition && sudo bash install.sh${NC}"
        exit 1
    fi

    echo -e "${GREEN}[OK]${NC} Dépôt récupéré dans ${cible}. Relance de l'installateur...\n"
    cd "$cible" || exit 1
    exec sudo -E bash "$cible/install.sh" "$@"
}

main() {
    local AUTO_FLAG=false
    for arg in "$@"; do
        case $arg in
            --auto|-y) AUTO_FLAG=true ;;
            # Simulation : montre ce qui serait fait, sans rien modifier.
            --dry-run|--simulation) export DRY_RUN="yes" ;;
            # Remet les fichiers sauvegardés par MadOS dans leur état d'origine.
            --restore) MADOS_ACTION="restore" ;;
            --list-backups) MADOS_ACTION="list" ;;
            --help|-h) MADOS_ACTION="help" ;;
        esac
    done

    case "${MADOS_ACTION:-}" in
        help)
            cat <<'AIDE'
MadOS ROG Edition - options

  sudo bash install.sh                 Installation complete
  sudo bash install.sh --auto          Installation sans questions
  sudo bash install.sh --dry-run       SIMULATION : montre tout, n'ecrit rien
  sudo bash install.sh --list-backups  Liste les fichiers sauvegardes
  sudo bash install.sh --restore       Restaure les fichiers sauvegardes
  sudo bash install.sh --help          Cette aide
AIDE
            exit 0 ;;
        list)
            source "$(dirname "$0")/lib/config.conf" 2>/dev/null || true
            source "$(dirname "$0")/lib/common.sh" 2>/dev/null || true
            list_backups
            exit $? ;;
        restore)
            source "$(dirname "$0")/lib/config.conf" 2>/dev/null || true
            source "$(dirname "$0")/lib/common.sh" 2>/dev/null || true
            restore_all
            exit $? ;;
    esac

    if is_dry_run 2>/dev/null || [ "${DRY_RUN:-no}" = "yes" ]; then
        echo -e "[1;33m[SIMULATION] Aucune modification ne sera ecrite sur ce systeme.[0m"
    fi

    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=l
    export CURRENT_MODULE="SAUVETAGE"
    set -uo pipefail

    # ---- INITIALISATION CORE ----
    # Sourcé ICI, avant la moindre commande destructrice : sans ça, is_dry_run et
    # run_action n'existent pas encore et tout le préambule (verrous APT, snapd,
    # dpkg --configure -a...) s'exécutait pour de vrai même avec --dry-run, quoi
    # que dise la bannière [SIMULATION] affichée plus haut.
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
    export PROJECT_ROOT="$SCRIPT_DIR"

    # install.sh seul ne sait rien faire : toute la logique vit dans lib/ et
    # modules/. La commande affichee sur le site ("wget -qO install.sh ..." ) et
    # le raccourci mados-install ("curl ... | sudo bash") ne fournissent que ce
    # fichier -- l'installeur sortait donc immediatement sur "Erreur
    # lib/common.sh". On recupere desormais l'arborescence complete au lieu
    # d'abandonner.
    if [ ! -f "$SCRIPT_DIR/lib/common.sh" ] || [ ! -d "$SCRIPT_DIR/modules" ]; then
        mados_amorcage "$@"
    fi

    source "$SCRIPT_DIR/lib/common.sh"

    # config.conf n'etait charge que dans les branches --list-backups/--restore :
    # le modifier ne changeait donc rien a une installation reelle. Il est
    # desormais lu ici, apres common.sh, pour que ses valeurs (espace disque
    # requis, nombre de tentatives, miroir APT...) pilotent vraiment le script.
    [ -f "$SCRIPT_DIR/lib/config.conf" ] && source "$SCRIPT_DIR/lib/config.conf" 2>/dev/null || true

    # ---- OPÉRATION LIBÉRATION DES VERROUS SYSTÈME ----
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} 🧱 ${WHITE}${BOLD}Amorçage du Système MadOS (Optimisation Verrous)${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

    if is_dry_run; then
        log_simu "tuerait les process apt/apt-get/dpkg/snapd en cours et lèverait les verrous DPKG/APT"
    else
        sudo pkill -9 apt 2>/dev/null || true
        sudo pkill -9 apt-get 2>/dev/null || true
        sudo pkill -9 dpkg 2>/dev/null || true
        sudo pkill -9 snapd 2>/dev/null || true
        sudo rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock 2>/dev/null || true
    fi

    # Nettoyage préventif des pilotes cassés
    echo -e "${GRAY}    ├─ Nettoyage des résidus DPKG/DKMS...${NC}"
    if is_dry_run; then
        log_simu "lancerait dpkg --configure -a et poserait un policy-rc.d temporaire (exit 101)"
    else
        sudo dpkg --configure -a 2>/dev/null || true
        echo -e '#!/bin/sh\nexit 101' | sudo tee /usr/sbin/policy-rc.d > /dev/null
        sudo chmod +x /usr/sbin/policy-rc.d || true
        trap 'sudo rm -f /usr/sbin/policy-rc.d' EXIT
    fi

    # ---- BLOCAGE SNAPD (Performance Boost) ----
    if is_dry_run; then
        log_simu "arrêterait/désactiverait snapd.service et snapd.socket, et épinglerait snapd à -10 dans /etc/apt/preferences.d/nosnap.pref"
    else
        sudo systemctl stop snapd.service snapd.socket 2>/dev/null || true
        sudo systemctl disable snapd.service snapd.socket 2>/dev/null || true
        sudo tee /etc/apt/preferences.d/nosnap.pref > /dev/null <<EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
    fi

    wait_for_apt

    # Restauration support matériel
    echo -e "${GRAY}    ├─ Restauration du support LVM & Coretools...${NC}"
    run_action "installerait lvm2, coreutils, thin-provisioning-tools" \
        sudo apt-get install -y lvm2 coreutils thin-provisioning-tools 2>/dev/null || true

    setup_error_traps
    init_mados_logging

    clear
    echo -e "${RED}"
    echo -e "  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗ "
    echo -e "  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝ "
    echo -e "  ██╔████╔██║███████║██║  ██║██║   ██║███████╗ "
    echo -e "  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║ "
    echo -e "  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║ "
    echo -e "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝ "
    echo -ne "${NC}"
    echo -e "${RED}     ╔══════════════════════════════╗${NC}"
    echo -e "${RED}     ║   Ultimate MadOS 3.5 Stable  ║${NC}"
    echo -e "${RED}     ║     Edition Kubuntu LTS      ║${NC}"
    echo -e "${RED}     ╚══════════════════════════════╝${NC}\n"

    # Snapd déjà arrêté/désactivé et common.sh déjà sourcé plus haut (une seule
    # fois) -- ce bloc dupliquait intégralement l'amorçage ci-dessus (verrous,
    # snapd, dpkg --configure -a, lvm2), y compris sans garde --dry-run. Seules
    # les deux actions RÉELLEMENT nouvelles de ce second passage restent ici.
    run_action "lancerait apt-get install -f -y (réparation des dépendances cassées)" \
        sudo apt-get install -f -y 2>/dev/null || true

    # Purge de v4l2loopback-dkms UNIQUEMENT s'il est reellement casse.
    # L'ancien test (`dpkg -l | grep -q`) matchait la simple PRESENCE du paquet :
    # une installation parfaitement saine etait donc purgee au demarrage, puis le
    # module 36 (Pack OBS, coche par defaut) la reinstallait quelques minutes
    # plus tard. On ne purge maintenant que si le statut dpkg n'est pas "ii"
    # (installe et configure), c'est-a-dire un etat de configuration a moitie
    # terminee -- le vrai cas que ce contournement visait.
    V4L2_STATUT=$(dpkg-query -W -f='${db:Status-Abbrev}' v4l2loopback-dkms 2>/dev/null | tr -d ' ')
    if [ -n "$V4L2_STATUT" ] && [ "$V4L2_STATUT" != "ii" ]; then
        if is_dry_run; then
            log_simu "purgerait le pilote camera v4l2loopback-dkms (etat dpkg casse : $V4L2_STATUT)"
        else
            echo -e "${GRAY}    ├─ Pilote caméra v4l2loopback dans un état cassé ($V4L2_STATUT) : neutralisation...${NC}"
            sudo apt-get purge -y v4l2loopback-dkms 2>/dev/null || true
        fi
    fi
    # setup_error_traps et init_mados_logging sont deja appeles plus haut :
    # les pieges ERR etaient poses deux fois et la banniere de demarrage
    # ecrite en double dans le journal.

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
    echo -e "${RED}     ║    INSTALLATEUR MadOS 3.5    ║${NC}"
    echo -e "${RED}     ║     by LordMadTrix           ║${NC}"
    echo -e "${RED}     ╚══════════════════════════════╝${NC}"
    echo ""

    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  [1/1] Vérifications Pré-Installation...${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Vérifications critiques
    check_sudo_access || exit 1
    check_disk_space "${REQUIRED_DISK_SPACE:-10}" || exit 1
    # Avertissement non bloquant sous le seuil recommande.
    _libre_gb=$(df -BG / 2>/dev/null | awk 'NR==2 {gsub(/G/,"",$4); print $4}')
    if [ -n "${_libre_gb:-}" ] && [ "$_libre_gb" -lt "${RECOMMENDED_DISK_SPACE:-40}" ] 2>/dev/null; then
        log_warning "${_libre_gb} Go libres : MadOS en recommande ${RECOMMENDED_DISK_SPACE:-40}. L'installation continue."
    fi
    unset _libre_gb
    
    # ---- PROTECTION GOD-TIER : Auto-Clonage vers /opt (Safe Zone) ----
    if [[ "$SCRIPT_DIR" == *"/mnt/"* || "$SCRIPT_DIR" == *"/media/"* ]]; then
        local TMP_RUN="/opt/mados_run"
        if [ "$SCRIPT_DIR" != "$TMP_RUN" ]; then
            if is_dry_run; then
                log_simu "clonerait lib/modules/scripts/assets/docs vers ${TMP_RUN} puis relancerait l'installeur depuis là (auto-clonage /mnt ou /media)"
            else
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
                     sudo bash ./install.sh "$@"
                     exit $?
                fi
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
    if is_dry_run; then
        log_simu "écrirait /etc/apt/apt.conf.d/99mados-network (ForceIPv4, retries, timeouts)"
    else
        cat <<'APTCONF' | sudo tee /etc/apt/apt.conf.d/99mados-network > /dev/null
// MadOS - Fix DNS & stabilité réseau en VM
Acquire::ForceIPv4 "true";
Acquire::Retries "5";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
APTCONF
    fi

    # 2. DNS Fix : Forcer DNS stables si la VM galère
    #
    # L'ancienne version ecrasait /etc/resolv.conf par un fichier STATIQUE, ce
    # qui remplacait le lien symbolique vers systemd-resolved. Consequence : la
    # configuration DNS-over-TLS que le module 32 (Stealth-Mode) ecrit plus tard
    # dans resolved.conf n'etait JAMAIS utilisee -- le systeme continuait
    # d'interroger Google en clair. On ne touche donc plus a resolv.conf quand
    # resolved est actif : on passe par son drop-in, ce qui laisse le module 32
    # reprendre la main ensuite.
    if ! ping -c 1 -W 3 archive.ubuntu.com >/dev/null 2>&1; then
        if is_dry_run; then
            log_simu "injecterait des DNS de secours via systemd-resolved (drop-in), ou dans /etc/resolv.conf seulement si resolved est absent"
        elif systemctl is-active --quiet systemd-resolved 2>/dev/null; then
            echo -e "${GRAY}    Injecteur DNS de secours via systemd-resolved...${NC}"
            sudo mkdir -p /etc/systemd/resolved.conf.d/
            printf '[Resolve]\nDNS=8.8.8.8 1.1.1.1\nFallbackDNS=8.8.4.4\n' \
                | sudo tee /etc/systemd/resolved.conf.d/mados-dns.conf > /dev/null
            # On retablit le lien symbolique attendu si une execution precedente
            # (ou un autre outil) l'avait remplace par un fichier statique.
            if [ ! -L /etc/resolv.conf ] && [ -e /run/systemd/resolve/stub-resolv.conf ]; then
                backup_file "/etc/resolv.conf"
                sudo cp /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null || true
                sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
            fi
            sudo systemctl restart systemd-resolved 2>/dev/null || true
            echo -e "${GRAY}    DNS de secours injectés (systemd-resolved conservé).${NC}"
        else
            echo -e "${GRAY}    Injecteur DNS de secours (8.8.8.8 + 1.1.1.1)...${NC}"
            backup_file "/etc/resolv.conf"
            sudo cp /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null || true
            printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\nnameserver 8.8.4.4\n' | sudo tee /etc/resolv.conf > /dev/null
            echo -e "${GRAY}    DNS de secours injectés.${NC}"
        fi
    else
        echo -e "${GRAY}    Réseau OK, pas de fix DNS nécessaire.${NC}"
    fi

    # 3. Mirror Switch Global : Remplacer TOUS les miroirs régionaux par l'archive principale
    # Supporte l'ancien format /etc/apt/sources.list et le nouveau format DEB822 (24.04+)
    echo -e "${GRAY}    Bascule vers les serveurs de l'archive globale (Stabilité Max)...${NC}"
    if is_dry_run; then
        log_simu "remplacerait les miroirs régionaux par archive.ubuntu.com dans sources.list et ubuntu.sources"
    else
        # Backup
        # Route par le manifeste : les .bak manuels existaient bien sur le disque
        # mais --list-backups et --restore les ignoraient totalement.
        backup_file "/etc/apt/sources.list"
        backup_file "/etc/apt/sources.list.d/ubuntu.sources"
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
        [ -f /etc/apt/sources.list.d/ubuntu.sources ] && sudo cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak 2>/dev/null || true

        # Remplacement dans l'ancien format .list
        sudo sed -i 's|http://[a-z][a-z]\.archive\.ubuntu\.com/ubuntu|http://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list 2>/dev/null || true

        # Remplacement dans le nouveau format DEB822 (utilisé par Ubuntu 24.10+)
        if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
            sudo sed -i 's|[a-z][a-z]\.archive\.ubuntu\.com|archive.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true
        fi
    fi

    # 3. Installation immédiate des propriétés logicielles (requis pour add-apt-repository)
    echo -e "${GRAY}    Préparation des outils de dépôts (software-properties-common)...${NC}"
    if is_dry_run; then
        log_simu "lancerait apt-get update et installerait software-properties-common, dirmngr, gpg, curl, wget"
    else
        sudo apt-get update -o Acquire::Retries=3 -qq >/dev/null 2>&1
        sudo apt-get install -y software-properties-common dirmngr gpg curl wget 2>/dev/null || true
    fi

    # Empêcher sudo de réinitialiser les variables cruciales pour l'installation silencieuse
    if is_dry_run; then
        log_simu "écrirait /etc/sudoers.d/mados-apt-env (env_keep DEBIAN_FRONTEND/NEEDRESTART_MODE)"
    else
        echo 'Defaults env_keep += "DEBIAN_FRONTEND NEEDRESTART_MODE"' | sudo tee /etc/sudoers.d/mados-apt-env >/dev/null
        sudo chmod 0440 /etc/sudoers.d/mados-apt-env || true
    fi
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
        
        # Le code de retour teste doit etre celui du MODULE, pas celui de tee.
        # `set +o pipefail` etant actif, `if bash module | tee ...` renvoyait
        # toujours 0 : aucun echec n'etait jamais detecte, et les 3 tentatives,
        # le menu d'erreur et l'etat SKIPPED_ERROR etaient du code mort.
        bash "$MODULES_DIR/$SCRIPT" 2>&1 | tee -a "$MADOS_LOG_DIR/mados_install.log"
        local exit_code=${PIPESTATUS[0]}

        if [ "$exit_code" -eq 0 ]; then
            # Succès - enregistrer le checkpoint
            save_checkpoint "$SCRIPT" "OK"
            log_success "Module $SCRIPT complété avec succès"
            return 0
        else
            log_error "Échec du module $SCRIPT (code: $exit_code)"
            
            if [ $attempt -lt $max_attempts ]; then
                log_warning "Nouvelle tentative du module $SCRIPT dans 10 secondes..."
                sleep 10
            else
                # Max tentatives atteintes - demander à l'utilisateur
                local CHOICE
                CHOICE=$(whiptail --title "MadOS 3.5 - ERREUR MODULE" --menu "Le script $SCRIPT a échoué après $max_attempts tentatives.\n\nConsultez les logs: $MADOS_LOG_DIR/mados_install.log" 15 65 3 \
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
        if (whiptail --title "MadOS 3.5 - REPRISE DÉTECTÉE" \
            --yesno "Une installation précédente semble avoir été interrompue.\n\nSouhaitez-vous REPRENDRE l'installation là où elle s'est arrêtée ?\n(Répondre 'Non' effacera l'ancien état)" 12 65); then
            log_info "Reprise de l'installation demandée par l'utilisateur."
        else
            reset_install_state
        fi
    fi

    if CHOIX=$(whiptail --title "MadOS 3.5 - Menu Principal" \
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
        # Expose aux modules le fait qu aucun humain n est devant l ecran :
        # sans ca, le module 25 ouvrait un whiptail bloquant en pleine
        # installation "sans questions".
        export MADOS_SILENT=1
    fi

    local CHOIX_BONUS
    if [ "$SILENT_MODE" = "true" ]; then
        # Sélection par défaut (Tout ce qui est à 'ON' d'habitude)
        CHOIX_BONUS="SNAP PROT SOND BATT MANG OLAM NET ZRAM ADS SSD USB BOOT VOLT TUNE STLT DASH LINK PLMY OBSP GUI CLI SAN"
    else
        # Affichage des options facultatives auto-sélectionnées ou non
        if ! CHOIX_BONUS=$(whiptail --title "MadOS 3.5 - Options Bonus (Déploiement Total)" \
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
            if ! export MADOS_TDP_PROFILE=$(whiptail --title "MadOS 3.5 - Profils Thermiques" --radiolist "Comportement énergétique du processeur (TDP) :" 18 65 4 \
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

    # Détection automatique de l'interface graphique (DE)
    # Detection via detecter_bureau() (lib/common.sh) : interroge logind puis les
    # processus de session. L'ancienne ligne developpait $XDG_CURRENT_DESKTOP
    # cote root, ou la variable n'existe pas -> toujours vide -> KDE force.
    export MADOS_DE_DETECTED="$(detecter_bureau)"
    if [ "$MADOS_DE_DETECTED" = "GNOME" ]; then
        export MADOS_DESKTOP="GNOME"
    else
        # UNKNOWN inclus : KDE reste le defaut, c'est le bureau que MadOS installe.
        export MADOS_DESKTOP="KDE"
    fi
    echo -e "    ${GRAY}├─ Bureau détecté : ${MADOS_DE_DETECTED} → profil ${MADOS_DESKTOP}${NC}"

    # Sélection du Thème Visuel
    if [ "$SILENT_MODE" = "true" ]; then
        export MADOS_THEME="ROG"
    else
        if ! export MADOS_THEME=$(whiptail --title "MadOS 3.5 - Charte Graphique" --radiolist "Quel style visuel appliquer ?" 12 60 3 \
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
    echo -e "${RED}⚠️  DÉPLOIEMENT TOTAL ENGAGÉ [Bureau: ${BOLD}${CYAN}$MADOS_DESKTOP${NC}${RED} | Theme: $MADOS_THEME] ⚠️${NC}"
    fi
    echo -e "${GRAY}Le système va configurer automatiquement votre machine...${NC}\n"
    sleep 2


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
    
    if [ "$MADOS_DESKTOP" = "KDE" ]; then
        run_module "05_bureau_kde_plasma.sh" "Interface KDE Plasma 6 Wayland"
    else
        echo -e "    ${GREEN}├─ [GNOME] Conservation de l'interface système optimisée...${NC}"
    fi
    
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
    if ! CHOIX_ALL=$(whiptail --title "MadOS 3.5 - Déploiement Custom (Expert)" \
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
        "10_snd" "Son de dèmarrage ROG" OFF \
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
        if ! export MADOS_TDP_PROFILE=$(whiptail --title "MadOS 3.5 - Surcadençage & Profils Thermiques" --radiolist "Comportement énergétique du processeur (TDP) :" 18 70 4 \
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
    # La case "05_kde" existait dans la liste mais n etait jamais testee :
    # le module tournait de toute facon, deux fois, quoi que coche l utilisateur.
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
    [[ "$CHOIX_ALL" == *"29_olam"* ]] && run_module "29_ollama_ia_locale.sh" "IA MadChat (Ollama)"
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
    if whiptail --title "MadOS 3.5 - MODE DESTRUCTION" --yesno "Ceci va PURGER Canonical de tous ses bloatwares (snapd, cloud-init) de manière agressive.\n\nÊtes-vous absolument sûr de vouloir détruire la trace d'Ubuntu ?" 12 70; then
        clear
        run_module "00_nettoyage_ubuntu.sh" "Purification Extrême de l'Hôte"
        sleep 2
    fi
    menu_principal
}

cloture_installation() {
    clear
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} 🏁 ${WHITE}${BOLD}Séquence de Clôture MadOS 3.5 Ultimate${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

    # Ni REAL_USER ni USER_HOME n'etaient definis dans install.sh : le chown
    # ci-dessous s'executait donc en `chown -R ":" ""`, echouait, et l'erreur
    # etait avalee par `|| true`. La "reparation ecran noir" ne reparait rien.
    local REAL_USER="${SUDO_USER:-$USER}"
    local USER_HOME
    USER_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
    if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
        log_warning "Dossier personnel introuvable pour ${REAL_USER} : reparation des droits ignoree."
        REAL_USER=""
        USER_HOME=""
    fi

    # ---- RÉPARATION DES PERMISSIONS (Fix Écran Noir) ----
    echo -e "    ${GRAY}├─ [REPAIR] Restauration des droits utilisateur sur $USER_HOME...${NC}"
    if is_dry_run; then
        log_simu "chown -R + chmod -R u+rw sur \$USER_HOME (réparation des droits)"
    else
        sudo chown -R "$REAL_USER:$REAL_USER" "$USER_HOME" >/dev/null 2>&1 || true
        sudo chmod -R u+rw "$USER_HOME" >/dev/null 2>&1 || true
    fi

    # ---- RAPPORT DE DIAGNOSTIC (envoi EXPLICITEMENT optionnel) ----
    # Le journal partait automatiquement sur termbin.com, un pastebin PUBLIC,
    # sans rien demander. Il contient le nom de la machine, le nom d'utilisateur,
    # l'inventaire materiel et la liste des paquets. Sur un projet qui vend un
    # module anti-telemetrie, c'est difficilement defendable. L'envoi est
    # desormais un choix explicite, refuse par defaut, et jamais propose en mode
    # automatique (personne n'est la pour consentir).
    local ACTUAL_LOG="$MADOS_LOG_DIR/mados_install.log"
    local LOG_URL=""
    local PARTAGER=1

    if is_dry_run; then
        log_simu "proposerait (sans l'imposer) d'envoyer les 10000 dernieres lignes du log vers termbin.com"
    elif [ "${AUTO_FLAG:-false}" = "true" ]; then
        echo -e "${GRAY}    ├─ Mode automatique : aucun envoi de diagnostic.${NC}"
    elif [ -f "$ACTUAL_LOG" ]; then
        if whiptail --title "MadOS — Partage du diagnostic" \
            --yes-button "Envoyer" --no-button "Garder en local" --defaultno \
            --yesno "Envoyer le journal d'installation sur termbin.com pour obtenir un lien de diagnostic ?\n\nCe journal est PUBLIC une fois envoyé. Il contient :\n  - le nom de votre machine et votre nom d'utilisateur\n  - votre inventaire matériel\n  - la liste des paquets installés\n\nRépondre « Garder en local » n'envoie rien : le journal reste sur votre disque." 18 74; then
            PARTAGER=0
        fi
    fi

    if [ "$PARTAGER" -eq 0 ]; then
        if ! command -v nc &>/dev/null; then
            echo -e "${GRAY}    Installation de netcat-openbsd pour l'envoi...${NC}"
            sudo apt-get install -y netcat-openbsd -qq >/dev/null 2>&1
        fi
        echo -e "${CYAN}📡 Envoi du rapport de diagnostic...${NC}"
        LOG_URL=$(tail -n 10000 "$ACTUAL_LOG" | nc termbin.com 9999 2>/dev/null || echo "")
        [ -z "$LOG_URL" ] && LOG_URL="échec de l'envoi"
    else
        LOG_URL="non envoyé — journal local : $ACTUAL_LOG"
    fi

    # En simulation, rien n'a été installé : le message de succès et la
    # proposition de redémarrage immédiat n'auraient aucun sens (et un reboot
    # réel resterait un reboot réel, même après une session "--dry-run").
    if is_dry_run; then
        clear
        echo -e "${YELLOW}[SIMULATION] Terminée. Relis les lignes [SIMULATION] ci-dessus : rien n'a été écrit sur ce système.${NC}"
        exit 0
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
# BUG CRITIQUE trouvé en testant pour de vrai (pas en relisant le code) : "main"
# sans "$@" ne transmettait JAMAIS les arguments de la ligne de commande. --dry-run
# n'a donc jamais été lu, depuis toujours -- confirmé : bash install.sh --dry-run
# plantait immédiatement sur "DRY_RUN: unbound variable", la preuve que DRY_RUN
# n'était jamais exporté du tout.
main "$@"
