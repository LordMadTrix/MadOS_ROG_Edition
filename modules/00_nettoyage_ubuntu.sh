#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 00_nettoyage_ubuntu.sh
# ==============================================================================
# Phase: 0 - Purification & Dépôts
# Nettoie les composants serveur et prépare l'environnement.
# Enlever 'set -e' pour éviter qu'une simple erreur réseau/apt update ne fasse crasher tout le script
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Kill process that could lock APT temporarily on fresh boot
if is_dry_run; then
    log_simu "tuerait les processus apt bloqués et purgerait les verrous dpkg/apt résiduels"
else
    if command -v pkill >/dev/null 2>&1; then
        sudo pkill -f apt 2>/dev/null || true
    else
        sudo killall apt apt-get 2>/dev/null || true
    fi
    sudo rm /var/lib/apt/lists/lock 2>/dev/null || true
    sudo rm /var/cache/apt/archives/lock 2>/dev/null || true
    sudo rm /var/lib/dpkg/lock* 2>/dev/null || true
    sudo dpkg --configure -a 2>/dev/null || true
fi

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 0 Purification du Système & Préparation${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 0. Installation des outils de base requis pour la suite
# Note: apt update centralisé déjà effectué dans install.sh avant le lancement des modules
echo -e "    ${WHITE}├─ [PREREQUIS] Installation des outils de dépôts...${NC}"
run_action "installerait software-properties-common, dirmngr, gpg, curl, wget, lsb-release" sudo apt install -y software-properties-common dirmngr gpg curl wget lsb-release 2>/dev/null || true

# 1. Neutralisation TOTALE et DÉFINITIVE de Snap (Bouclier MadOS)
echo -e "    ${WHITE}├─ [SÉCURITÉ] Érection d'un mur anti-Snap (APT Blockade)...${NC}"
# Bloquer toute réinstallation automatique de snapd par APT
if is_dry_run; then
    log_simu "écrirait /etc/apt/preferences.d/nosnap.pref pour bloquer snapd"
else
    sudo tee /etc/apt/preferences.d/nosnap.pref > /dev/null <<EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
fi

# Tuer les processus snapd s'ils tournent encore
run_action "arrêterait snapd.service, snapd.socket, snapd.seeded.service" sudo systemctl stop snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true
run_action "désactiverait snapd.service, snapd.socket, snapd.seeded.service" sudo systemctl disable snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true

# Purge radicale des composants et des montages snap
echo -e "    ${WHITE}├─ [NETTOYAGE] Purge atomique des composants Snap & Cloud-Init...${NC}"
run_action "purgerait cloud-init, multipath-tools, snapd" sudo apt purge -y cloud-init multipath-tools snapd 2>/dev/null || true
run_action "supprimerait /var/cache/snapd/, /var/lib/snapd/, /snap/" sudo rm -rf /var/cache/snapd/ /var/lib/snapd/ /snap/ 2>/dev/null || true
run_action "purgerait les paquets orphelins (apt autoremove --purge)" sudo apt autoremove -y --purge 2>/dev/null || true

# Assurer que NetworkManager prend le relais du réseau
echo -e "    ${GRAY}├─ Basculement réseau vers NetworkManager...${NC}"
run_action "installerait network-manager" sudo apt install -y network-manager 2>/dev/null || true

# La bascule netplan supprimait 50-cloud-init.yaml puis ecrivait un netplan
# "renderer: NetworkManager" SANS jamais verifier que NetworkManager etait bien
# installe (la commande ci-dessus finit par `|| true`). Si l'installation avait
# echoue, on detruisait une configuration reseau fonctionnelle pour la remplacer
# par une configuration sans moteur : perte totale de reseau, sans repli --
# critique en VM ou sur une machine distante. On ne bascule donc que si
# NetworkManager est REELLEMENT present, et on verifie apres coup.
if is_dry_run; then
    log_simu "verifierait la presence de NetworkManager, sauvegarderait /etc/netplan/50-cloud-init.yaml, ecrirait /etc/netplan/01-network-manager-all.yaml, appliquerait (netplan generate/apply) puis controlerait que le reseau repond"
elif ! command -v NetworkManager >/dev/null 2>&1 \
     && ! systemctl list-unit-files 2>/dev/null | grep -q '^NetworkManager\.service'; then
    echo -e "    ${YELLOW}⚠️  NetworkManager absent : bascule réseau ANNULÉE.${NC}"
    echo -e "    ${GRAY}    La configuration réseau actuelle est conservée intacte.${NC}"
else
    NETPLAN_RESTAURE=0
    if [ -f /etc/netplan/50-cloud-init.yaml ]; then
        sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak 2>/dev/null || true
        sudo rm -f /etc/netplan/50-cloud-init.yaml 2>/dev/null || true
        NETPLAN_RESTAURE=1
    fi

    sudo tee /etc/netplan/01-network-manager-all.yaml > /dev/null <<'EOF'
network:
  version: 2
  renderer: NetworkManager
EOF
    sudo chmod 600 /etc/netplan/01-network-manager-all.yaml
    sudo netplan generate 2>/dev/null || true
    sudo netplan apply 2>/dev/null || true
    sudo systemctl enable NetworkManager 2>/dev/null || true
    sudo systemctl restart NetworkManager 2>/dev/null || true
    sleep 5

    # Controle de survie. L'ancienne version testait `ping 8.8.8.8` puis
    # `ping archive.ubuntu.com` avec un &&, donc il fallait que LES DEUX
    # echouent pour restaurer. Or `ping 8.8.8.8` reussit PAR IP, sans DNS : la
    # premiere condition etait fausse et la restauration ne partait jamais.
    # Constate en VM QEMU : apt a produit 2897 lignes "Could not resolve
    # 'archive.ubuntu.com'" pendant que le garde-fou affichait "Reseau
    # operationnel". Ce qu'il faut verifier, c'est ce dont apt a besoin :
    # la RESOLUTION DE NOMS, puis un acces HTTP reel au depot.
    reseau_utilisable() {
        local hote="archive.ubuntu.com"
        # 1. Resolution DNS -- le point qui avait lache.
        getent hosts "$hote" >/dev/null 2>&1 || return 1
        # 2. Acces HTTP reel au depot (ce que fera apt juste apres).
        if command -v curl >/dev/null 2>&1; then
            curl -fsS --max-time 15 -o /dev/null "http://${hote}/ubuntu/" 2>/dev/null && return 0
        elif command -v wget >/dev/null 2>&1; then
            wget -q --timeout=15 --spider "http://${hote}/ubuntu/" 2>/dev/null && return 0
        else
            # Sans client HTTP, la resolution DNS reste le meilleur signal.
            return 0
        fi
        return 1
    }

    # NetworkManager peut avoir ete empeche de demarrer par le policy-rc.d
    # (exit 101) pose par install.sh : on le relance explicitement, ce que
    # policy-rc.d ne bloque pas, puis on laisse le temps au DHCP.
    sudo systemctl start NetworkManager 2>/dev/null || true
    for _essai in 1 2 3 4 5 6; do
        reseau_utilisable && break
        sleep 5
    done

    if ! reseau_utilisable; then
        echo -e "    ${RED}⚠️  DNS ou dépôt injoignable après la bascule : restauration de l'ancienne configuration...${NC}"
        sudo rm -f /etc/netplan/01-network-manager-all.yaml 2>/dev/null || true
        if [ "$NETPLAN_RESTAURE" -eq 1 ] && [ -f /etc/netplan/50-cloud-init.yaml.bak ]; then
            sudo cp /etc/netplan/50-cloud-init.yaml.bak /etc/netplan/50-cloud-init.yaml 2>/dev/null || true
        fi
        sudo netplan apply 2>/dev/null || true
        sudo systemctl restart systemd-resolved 2>/dev/null || true
        sleep 5
        if reseau_utilisable; then
            echo -e "    ${GREEN}├─ Réseau restauré avec l'ancienne configuration.${NC}"
        else
            echo -e "    ${RED}❌ Réseau toujours inutilisable. Les modules suivants ne pourront rien télécharger.${NC}"
            echo -e "    ${GRAY}    Vérifiez : ${GREEN}resolvectl status${NC}${GRAY} et ${GREEN}ip route${NC}"
        fi
    else
        echo -e "    ${GREEN}├─ Réseau opérationnel (DNS et dépôt joignables).${NC}"
    fi
fi

# 2. Ajout de l'Architecture i386 (pour Steam/Wine)
run_action "ajouterait l'architecture i386 (dpkg --add-architecture)" sudo dpkg --add-architecture i386

# 3. Dépôts (XanMod, Google, Spotify, Lutris)
echo -e "    ${WHITE}├─ [DÉPÔTS] Ajout des clés GPG sécurisées en parallèle...${NC}"
run_action "créerait le répertoire /etc/apt/keyrings" sudo mkdir -p /etc/apt/keyrings

if is_dry_run; then
    log_simu "téléchargerait et importerait les clés GPG Google Chrome, Spotify, XanMod et WineHQ dans /etc/apt/keyrings"
else
    # Téléchargement asynchrone des clés pour gagner du temps
    (wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg) &
    (curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify-new.gpg) &
    (curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify-old.gpg) &
    (wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/xanmod-archive-keyring.gpg) &
    (wget -qO - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/winehq-archive-keyring.gpg) &

    # Attendre que tous les téléchargements soient finis
    wait
fi

if is_dry_run; then
    log_simu "écrirait les fichiers de dépôts APT google-chrome.list, spotify.list, xanmod-release.list et winehq.list"
else
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/spotify-new.gpg,/etc/apt/keyrings/spotify-old.gpg arch=amd64] https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null
    echo 'deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/winehq.list > /dev/null
fi

# Lutris & Divers
if ! ls /etc/apt/sources.list.d/lutris-team-ubuntu-lutris-*.list &>/dev/null; then
    run_action "ajouterait le PPA lutris-team/lutris" sudo add-apt-repository ppa:lutris-team/lutris -y --no-update
fi
run_action "activerait le dépôt universe" sudo add-apt-repository universe -y --no-update
run_action "activerait le dépôt multiverse" sudo add-apt-repository multiverse -y --no-update
run_action "activerait le dépôt restricted" sudo add-apt-repository restricted -y --no-update

# 4. Mise à jour globale
echo -e "    ${WHITE}├─ [MAJ] Rafraîchissement APT et mise à niveau...${NC}"
run_action "rafraîchirait les index APT (apt update)" sudo apt update -q
run_action "mettrait à niveau tous les paquets (apt upgrade)" sudo apt upgrade -y -q

# 5. Dépendances de base
echo -e "    ${WHITE}├─ [BASE] Utilitaires fondamentaux...${NC}"
run_action "installerait les utilitaires de base (build-essential, git, cmake, ...)" sudo apt install -y build-essential git cmake pkg-config unzip p7zip-full htop vim nano pipx zsh gamemode ca-certificates gcc g++ make file

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 0 Terminée.${NC}"
