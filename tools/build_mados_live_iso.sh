#!/bin/bash
# ==============================================================================
# MadOS - Custom Linux ISO Builder (version lue dans ./VERSION) (debootstrap + XanMod Kernel)
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# ÉLÉVATION — le mot de passe n'est JAMAIS stocké dans ce script.
#
# Avant, on trouvait ici « SUDO_PWD="<mot de passe>" » en clair. Comme
# build_mados_live_iso.sh recopie tout le dépôt vers /opt/mados-rog dans le
# chroot, ce mot de passe partait DANS CHAQUE ISO produite. Vérifié en
# l'extrayant d'une image déjà construite : il y était.
#
# « sudo -v » le demande une fois puis rafraîchit le ticket. La boucle de fond
# le maintient vivant : une construction dure bien plus que les 15 minutes du
# délai sudo par défaut, et sans elle le script s'arrêterait au milieu.
# ------------------------------------------------------------------------------
demander_sudo() {
    [ "$(id -u)" -eq 0 ] && return 0
    if ! sudo -n true 2>/dev/null; then
        echo -e "${CYAN:-}Privilèges administrateur requis pour cette étape.${NC:-}"
        sudo -v || { echo -e "${RED:-}Élévation refusée : arrêt.${NC:-}"; exit 1; }
    fi
    # Maintien du ticket tant que ce script vit.
    ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
}
run_sudo() { sudo "$@"; }
demander_sudo

# Workspace sur le filesystem ext4 WSL (954GB libres) — NTFS incompatible avec debootstrap
# ─────────────────────────────────────────────────────────────────────────────
# VERSION : une seule source de vérité, le fichier VERSION du dépôt.
# Elle était écrite en dur à plus de vingt endroits dans ce seul script. Le
# README de la branche principale annonçait encore 3.5 alors que VERSION disait
# 3.6 — c'est exactement ce que produit une version recopiée à la main.
# ─────────────────────────────────────────────────────────────────────────────
RACINE_DEPOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MADOS_VERSION="$(cat "$RACINE_DEPOT/VERSION" 2>/dev/null | tr -d ' 

')"
if [ -z "$MADOS_VERSION" ]; then
    echo "ERREUR : fichier VERSION introuvable ou vide dans $RACINE_DEPOT" >&2
    exit 1
fi
MADOS_DATE="$(date +%Y%m%d)"
echo -e "${CYAN}Construction de MadOS $MADOS_VERSION${NC}"

WORKDIR="/home/madtrix/mados_build_workspace"
CHROOT_DIR="$WORKDIR/chroot"
JOURNAL_APT="/tmp/mados_apt_update.log"

# ─────────────────────────────────────────────────────────────────────────────
# BASE UBUNTU : une seule variable, et elle doit designer une version SUPPORTEE.
#
# Le script bootstrapait « plucky » (25.04), sortie du support. debootstrap le
# detecte via « ubuntu-distro-info --supported » et bascule alors sur
# old-releases.ubuntu.com avec le trousseau des cles RETIREES -- d'ou l'echec
# « Release signed by unknown key ». Ce n'etait pas un probleme de trousseau
# mais le symptome d'une base morte : plus aucun correctif de securite.
#
# resolute = Ubuntu 26.04 LTS, supportee jusqu'en 2031. XanMod publie pour elle.
# ─────────────────────────────────────────────────────────────────────────────
SUITE_UBUNTU="resolute"

if command -v ubuntu-distro-info >/dev/null 2>&1; then
    if ! ubuntu-distro-info --supported 2>/dev/null | grep -qx "$SUITE_UBUNTU"; then
        echo -e "${RED}✗ La suite « $SUITE_UBUNTU » n'est plus supportee par Ubuntu.${NC}"
        echo -e "${YELLOW}  Construire dessus donnerait un systeme sans correctifs de securite.${NC}"
        echo -e "${YELLOW}  Suites supportees : $(ubuntu-distro-info --supported | tr '
' ' ')${NC}"
        exit 1
    fi
    echo -e "${GREEN}  ✓ Base $SUITE_UBUNTU : supportee${NC}"
fi
IMAGE_DIR="$WORKDIR/image"

echo -e "${CYAN}🚀 Début de la construction de la distribution MadOS...${NC}"

# 1. Installation des dépendances requises
echo -e "${CYAN}[1/7] Installation des dépendances système...${NC}"
# apt-get update N'EST PAS bloquant, et ce n'est pas une facilite.
# La machine de construction a ses propres depots tiers, sans rapport avec MadOS.
# Constate ici : une PPA Lutris absente pour Ubuntu 26.04 et une entree XanMod
# pointant sur une suite « releases » qui n'existe pas -- deux 404 qui tuaient la
# construction avant meme le premier telechargement.
# Ce qui compte n'est pas le code de retour d'update, c'est de savoir si LES
# PAQUETS DONT ON A BESOIN sont installables. On verifie donc le RESULTAT.
#
# grub-efi-amd64-bin est le paquet qui manquait a l'origine : sans les fichiers
# de plateforme EFI, grub-mkrescue produit une image BIOS SANS SE PLAINDRE.
# Verifie sur l'ISO livree : son catalogue El Torito n'annoncait que 0x00 (BIOS),
# donc invisible pour le firmware UEFI d'un ROG.
PAQUETS="debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin grub-common efibootmgr dosfstools mtools binutils systemd-container"

if ! run_sudo apt-get update -qq 2>"$JOURNAL_APT"; then
    echo -e "${YELLOW}  Des depots ont echoue pendant la mise a jour :${NC}"
    grep -E '^(E|W):' "$JOURNAL_APT" 2>/dev/null | head -5 | sed 's/^/      /'
    echo -e "${YELLOW}  Sans importance si les paquets requis restent disponibles. On verifie.${NC}"
fi

run_sudo apt-get install -y $PAQUETS -qq || true

# Le controle porte sur le RESULTAT, jamais sur le code de retour.
MANQUANTS=""
for paq in $PAQUETS; do
    dpkg -s "$paq" >/dev/null 2>&1 || MANQUANTS="$MANQUANTS $paq"
done
if [ -n "$MANQUANTS" ]; then
    echo -e "${RED}✗ Paquets toujours absents apres installation :$MANQUANTS${NC}"
    echo -e "${YELLOW}  Repare les depots de cette machine, puis relance.${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Toutes les dependances sont presentes${NC}"

# Nettoyage des anciennes builds
run_sudo rm -rf "$WORKDIR"
mkdir -p "$CHROOT_DIR" "$IMAGE_DIR/boot/grub"

# 2. Bootstrapping d'une Ubuntu 25.04 Desktop/Base minimale (Plucky Puffin)
echo -e "${CYAN}[2/7] Telechargement et bootstrapping du systeme de base Ubuntu ($SUITE_UBUNTU)...${NC}"
# --no-check-gpg retire : il desactivait la verification des signatures du depot,
# donc le systeme de base etait bati sans garantie d'authenticite. Si le trousseau
# manque, c'est lui qu'il faut installer (paquet ubuntu-keyring), pas la
# verification qu'il faut couper.
run_sudo debootstrap --arch=amd64 "$SUITE_UBUNTU" "$CHROOT_DIR" http://archive.ubuntu.com/ubuntu/

# 3. Personnalisation du système via Chroot
echo -e "${CYAN}[3/7] Configuration du chroot (noyau XanMod, Wayland/labwc, bureau LXQt)...${NC}"

# Copie des scripts MadOS dans le système cible (sans les ISOs/fichiers volumineux)
run_sudo mkdir -p "$CHROOT_DIR/opt/mados-rog"
# Exclure les ISOs, qcow2 et l'ancien workspace pour éviter de gonfler le squashfs
# Ce qui part dans l'ISO est une LISTE BLANCHE, plus une liste noire.
# L'ancienne version copiait tout sauf quelques extensions : les scripts de
# construction partaient donc dans l'image, mot de passe compris. Une liste
# noire oublie toujours quelque chose ; une liste blanche, non.
for f in ./*; do
    fname="$(basename "$f")"
    case "$fname" in
        install.sh|lib|modules|assets|config.conf|VERSION|README.md|LICENSE) ;;
        *) continue ;;
    esac
    run_sudo cp -r "$f" "$CHROOT_DIR/opt/mados-rog/"
done
# tools/ : seulement l'utilitaire destine a l'utilisateur final et l'installateur.
# Surtout PAS build_mados_live_iso.sh, build_kernel.sh ni compile_xanmod_source.sh.
run_sudo mkdir -p "$CHROOT_DIR/opt/mados-rog/tools"
for t in tools/mados.sh tools/mados_completion.sh tools/live_installer.sh; do
    [ -f "$t" ] && run_sudo cp "$t" "$CHROOT_DIR/opt/mados-rog/tools/"
done

# Script de configuration exécuté à l'intérieur du chroot
# Le heredoc ci-dessous est QUOTÉ ('EOF') : rien du script parent n'y est
# substitué, ce qui est voulu (les $ du script interne restent intacts). On
# injecte donc la version en tête du fichier généré, séparément.
cat > "$WORKDIR/chroot_setup.sh" <<ENTETE
#!/bin/bash
MADOS_VERSION="$MADOS_VERSION"
SUITE_UBUNTU="$SUITE_UBUNTU"
ENTETE
cat << 'EOF' >> "$WORKDIR/chroot_setup.sh"
set -e
export DEBIAN_FRONTEND=noninteractive

# Configuration des dépôts apt
cat <<APT > /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu $SUITE_UBUNTU main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $SUITE_UBUNTU-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $SUITE_UBUNTU-security main restricted universe multiverse
APT

apt-get update -qq

# Installation des certificats et de wget pour le dépôt XanMod
apt-get install -y wget gpg ca-certificates --no-install-recommends -y

# Télécharger la clé publique de signature et ajouter le dépôt officiel de XanMod
wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
# Guillemets DOUBLES : entre apostrophes simples, $SUITE_UBUNTU serait ecrit
# litteralement dans le fichier de depot et XanMod ne resoudrait rien.
echo "deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org $SUITE_UBUNTU main" > /etc/apt/sources.list.d/xanmod-kernel.list
apt-get update -qq

# Configuration de la langue et du clavier par défaut (AZERTY)
apt-get install -y locales keyboard-configuration -y
locale-gen fr_FR.UTF-8
update-locale LANG=fr_FR.UTF-8

# Installation du noyau officiel XanMod, de systemd, network-manager, casper et initramfs
# ─────────────────────────────────────────────────────────────────────────────
# LES OUTILS DE L'INSTALLATEUR
#
# Constate en installant pour de vrai dans une machine virtuelle : parted,
# rsync, mkfs.fat, partprobe, grub-install et update-grub etaient ABSENTS de
# l'image. L'installateur ne pouvait ni partitionner, ni formater, ni copier
# quoi que ce soit -- et annoncait pourtant « v Partitions formatees »,
# « v Systeme copie » a chaque etape ratee.
#
# Les paquets GRUB sont installes ICI, dans le live, et non seulement dans le
# chroot : le systeme cible est une COPIE du live, il en herite donc. Les
# installer plus tard depuis le chroot supposerait un reseau, qu'une
# installation hors ligne n'a pas.
# ─────────────────────────────────────────────────────────────────────────────
apt-get install -y linux-xanmod-x64v3 systemd systemd-sysv libpam-systemd seatd network-manager dbus-user-session sudo initramfs-tools casper parted dosfstools rsync grub2-common grub-pc-bin grub-efi-amd64-bin efibootmgr swaybg --no-install-recommends -y

# Générer l'initramfs pour le noyau XanMod
# On prend le noyau XANMOD explicitement, pas « le premier par ordre
# alphabetique ». Avec un seul noyau installe l'ancien code marchait par
# chance ; des qu'un second apparait il embarque le mauvais, en silence.
KERNEL_VER=$(find /boot -maxdepth 1 -name 'vmlinuz-*xanmod*' -printf '%f
' 2>/dev/null              | sed 's/^vmlinuz-//' | sort -V | tail -n1)
if [ -z "$KERNEL_VER" ]; then
    KERNEL_VER=$(find /boot -maxdepth 1 -name 'vmlinuz-*' -printf '%f
' 2>/dev/null                  | sed 's/^vmlinuz-//' | sort -V | tail -n1)
fi
if [ -z "$KERNEL_VER" ]; then
    echo "ERREUR : aucun noyau dans /boot apres installation de linux-xanmod." >&2
    exit 1
fi
echo "Noyau retenu : $KERNEL_VER"
update-initramfs -c -k "$KERNEL_VER"

# ─────────────────────────────────────────────────────────────────────────────
# I-03 : les .deb du noyau sont mis de cote ICI, dans le chroot.
#
# Ils l'etaient auparavant depuis l'exterieur, APRES l'execution de ce script --
# donc apres le « apt-get clean » de la fin, qui avait deja vide
# /var/cache/apt/archives. Verifie sur l'ISO construite : le dossier noyau/ ne
# contenait que la copie brute, aucun paquet. L'installateur se rabattait alors
# sur le noyau du live, sans regenerer d'initrd pour le materiel reel.
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p /opt/mados-rog/noyau
cp /var/cache/apt/archives/linux-*xanmod*.deb /opt/mados-rog/noyau/ 2>/dev/null || true
NB_DEB=$(ls /opt/mados-rog/noyau/*.deb 2>/dev/null | wc -l)
if [ "$NB_DEB" -eq 0 ]; then
    # Le cache peut etre vide si apt a reutilise un paquet deja telecharge.
    # On les retelecharge explicitement plutot que de laisser un trou.
    echo "Cache apt vide : retelechargement des paquets noyau..."
    ( cd /opt/mados-rog/noyau && apt-get download linux-xanmod-x64v3 2>/dev/null || true )
    NB_DEB=$(ls /opt/mados-rog/noyau/*.deb 2>/dev/null | wc -l)
fi
echo "Paquets noyau conserves pour l'installation : $NB_DEB"

# ═══════════════════════════════════════════════════
# LXQt = Razor-Qt (même projet, même équipe, Qt6)
# Suite complète : panel, runner, fm, notif, settings
# ═══════════════════════════════════════════════════
apt-get install -y \
    lxqt-menu-data \
    lxqt-panel \
    lxqt-runner \
    lxqt-session \
    lxqt-notificationd \
    lxqt-policykit \
    lxqt-config \
    lxqt-themes \
    lxqt-about \
    pcmanfm-qt \
    labwc xwayland xterm \
    --no-install-recommends -y

# Le fond d'ecran, a un emplacement standard : /opt/mados-rog n'existe plus
# apres l'installation sur disque, l'autostart y chercherait dans le vide.
mkdir -p /usr/share/backgrounds
cp /opt/mados-rog/assets/wallpapers/MadCarbon.png /usr/share/backgrounds/mados.png 2>/dev/null || true

# Enregistrement de la session Labwc pour LightDM (fallback GUI)
mkdir -p /usr/share/wayland-sessions/
cat <<SESSION > /usr/share/wayland-sessions/labwc.desktop
[Desktop Entry]
Name=Labwc
Comment=Labwc Wayland Compositor
Exec=/usr/bin/labwc
Type=Application
DesktopNames=Labwc
SESSION

# NOTE: PAS de casper.conf — casper crée son user 'ubuntu' interne normalement
# Mais les scripts casper font 'passwd -l ubuntu' APRES squashfs mount
# Il faut donc que ubuntu existe dans notre squashfs
# (l'user ubuntu sera verrouillé et ne pourra JAMAIS se connecter)
useradd -m -s /usr/sbin/nologin -c "Casper Compat (never used)" ubuntu 2>/dev/null || true
passwd -l ubuntu 2>/dev/null || true

# Création de l'utilisateur live "mados"
useradd -m -s /bin/bash mados
echo "mados:mados" | chpasswd
# ─────────────────────────────────────────────────────────────────────────────
# ACCES AUX PERIPHERIQUES D'ENTREE
#
# Sans gestionnaire de siege, un compositeur Wayland affiche l'ecran mais
# n'ouvre AUCUN peripherique d'entree : le bureau apparait, le clavier et la
# souris sont morts. Constate en lancant l'ISO -- le terminal et l'installateur
# s'affichaient parfaitement, et aucune touche n'arrivait.
#
# L'image n'avait ni seatd, ni libpam-systemd. Sans le second, l'autologin par
# agetty n'ouvre pas de session logind, et libseat n'a donc rien a interroger.
# D'ou le contournement « LIBSEAT_BACKEND=noop » : le seul moyen de faire
# demarrer labwc, mais precisement celui qui ne fournit aucune entree.
#
# On installe les deux, et le contournement disparait.
# ─────────────────────────────────────────────────────────────────────────────
usermod -aG sudo,video,audio,render,input,tty mados
# Groupe cree par le paquet seatd ; sans lui, l'acces au siege est refuse.
getent group _seatd >/dev/null 2>&1 && usermod -aG _seatd mados
systemctl enable seatd 2>/dev/null || true
echo "mados ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/mados

# ═══════════════════════════════════════════════════
# BRANDING MADOS — Supprimer TOUT référence à Ubuntu
# ═══════════════════════════════════════════════════

# Nom de la machine
echo "mados-rog" > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
127.0.1.1   mados-rog
::1         localhost ip6-localhost ip6-loopback
HOSTS

# Identification du système d'exploitation
cat > /etc/os-release <<OSREL
NAME="MadOS ROG Edition"
VERSION="$MADOS_VERSION Stable"
ID=mados
ID_LIKE=ubuntu
PRETTY_NAME="MadOS ROG Edition $MADOS_VERSION (XanMod | Wayland | LXQt)"
VERSION_ID="$MADOS_VERSION"
HOME_URL="https://github.com/LordMadTrix/MadOS_ROG_Edition"
SUPPORT_URL="https://github.com/LordMadTrix/MadOS_ROG_Edition"
BUG_REPORT_URL="https://github.com/LordMadTrix/MadOS_ROG_Edition/issues"
OSREL

cat > /etc/lsb-release <<LSBREL
DISTRIB_ID=MadOS
DISTRIB_RELEASE=$MADOS_VERSION
DISTRIB_CODENAME=rog
DISTRIB_DESCRIPTION="MadOS ROG Edition $MADOS_VERSION"
LSBREL

# Banner de connexion (efface "Ubuntu 25.04" du prompt getty)
# ─────────────────────────────────────────────────────────────────────────────
# La banniere de connexion : premiere chose que voit l'utilisateur apres une
# installation. L'ancienne dessinait une boite a largeur FIXE autour d'un
# numero de version VARIABLE : les barres de droite ne tombaient jamais au bon
# endroit, et la boite apparaissait tronquee. Verifie sur une capture d'ecran.
#
# On abandonne la boite. Une banniere ASCII et deux lignes de texte n'ont
# aucune largeur a respecter, donc rien a casser.
# ─────────────────────────────────────────────────────────────────────────────
cat > /etc/issue <<ISSUE

  [1;31m███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗[0m
  [1;31m████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝[0m
  [1;31m██╔████╔██║███████║██║  ██║██║   ██║███████╗[0m
  [1;31m██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║[0m
  [1;31m██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║[0m
  [1;31m╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝[0m

  [0;36mROG Edition $MADOS_VERSION[0m  ·  XanMod 7  ·  Wayland  ·  LXQt
  [0;37m\n \l[0m

ISSUE

cat > /etc/issue.net <<ISSUENET
MadOS ROG Edition $MADOS_VERSION | XanMod | Wayland | LXQt
ISSUENET

# Message du jour (MOTD)
rm -f /etc/motd
cat > /etc/motd <<MOTD

  ██████╗  ██╗   ██╗   ██╗
  ██╔══██╗╚██╗ ██╔╝   ██║
  ██████╔╝ ╚████╔╝    ██║
  ██╔═══╝   ╚██╔╝     ██║
  ██║        ██║  ██╗██████╗
  ╚═╝        ╚═╝  ╚═╝╚═════╝

  ROG Edition $MADOS_VERSION — XanMod • Wayland • LXQt
  Bienvenue dans MadOS !

MOTD

# Supprimer les paquets de branding Ubuntu
apt-get remove -y --purge ubuntu-advantage-tools ubuntu-pro-client ubuntu-pro-client-l10n 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true

# Autologin TTY1 via getty — --skip-login supprime le prompt de connexion
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat <<GETTY > /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin mados --skip-login --noclear %I \$TERM
GETTY

# Script de démarrage Wayland automatique depuis le TTY1
cat <<'PROFILE' > /home/mados/.bash_profile
# ─────────────────────────────────────────────────────────────────────────────
# L'installateur d'abord, sur la console. Le bureau ensuite, si on le demande.
#
# Avant, TTY1 lancait labwc, qui lancait Xwayland, qui lancait un xterm, qui
# lancait l'installateur. Trois couches entre le clavier et un programme en
# mode TEXTE qui n'en reclame aucune. Constate en lancant l'ISO : la liste des
# disques s'affichait parfaitement, et aucune touche n'atteignait le terminal.
#
# Un installateur texte se contente d'une console. On supprime les couches
# plutot que de chercher laquelle avale les touches.
# ─────────────────────────────────────────────────────────────────────────────
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then

    if [ -x /opt/mados-rog/tools/live_installer.sh ] || [ -f /opt/mados-rog/tools/live_installer.sh ]; then
        sudo bash /opt/mados-rog/tools/live_installer.sh
    fi

    echo ""
    read -r -p "Ouvrir le bureau graphique ? (o/N) : " reponse
    if [ "$reponse" = "o" ] || [ "$reponse" = "O" ] || [ "$reponse" = "y" ] || [ "$reponse" = "Y" ]; then
        export WLR_BACKENDS=drm
        export WLR_RENDERER=pixman
        export XDG_RUNTIME_DIR=/run/user/$(id -u)
        export XDG_SESSION_TYPE=wayland
        # Rendu logiciel : indispensable en machine virtuelle, penalisant sur
        # du vrai materiel. La decision se prend ici, pas a la construction.
        if systemd-detect-virt --quiet; then
            export LIBGL_ALWAYS_SOFTWARE=1
            export WLR_NO_HARDWARE_CURSORS=1
        fi
        mkdir -p "$XDG_RUNTIME_DIR"
        chmod 700 "$XDG_RUNTIME_DIR"
        # lxqt-session, et non labwc directement : c'est la session qui
        # applique le style Qt, charge le theme et fournit aux greffons du
        # panneau leur contexte D-Bus. Lance seul, lxqt-panel affichait son
        # apparence d'usine -- fond clair -- et ni le menu ni l'horloge ne se
        # dessinaient. Constate sur trois reconstructions successives.
        #
        # labwc reste le gestionnaire de fenetres : session.conf le designe.
        if command -v lxqt-session >/dev/null 2>&1; then
            exec lxqt-session
        else
            exec labwc
        fi
    fi
fi
PROFILE
chown mados:mados /home/mados/.bash_profile

# Configuration du thème ROG sombre pour xterm
mkdir -p /home/mados/.config/labwc
cat <<XRES > /home/mados/.Xresources
XTerm*background:       #0a0a0a
XTerm*foreground:       #e0e0e0
XTerm*cursorColor:      #cc0000
XTerm*color0:           #0a0a0a
XTerm*color1:           #cc0000
XTerm*color2:           #00cc44
XTerm*color3:           #cc8800
XTerm*color4:           #0088cc
XTerm*color5:           #cc0088
XTerm*color6:           #00cccc
XTerm*color7:           #e0e0e0
XTerm*color8:           #444444
XTerm*color9:           #ff2222
XTerm*color10:          #22ff66
XTerm*color11:          #ffaa00
XTerm*color12:          #22aaff
XTerm*color13:          #ff22aa
XTerm*color14:          #22ffff
XTerm*color15:          #ffffff
XTerm*faceName:         DejaVu Sans Mono
XTerm*faceSize:         11
XTerm*scrollBar:        false
XTerm*borderWidth:      0
XRES
chown mados:mados /home/mados/.Xresources

# Configuration th\u00e8me LXQt ROG sombre
mkdir -p /home/mados/.config/lxqt
cat > /home/mados/.config/lxqt/lxqt.conf <<LXQTCONF
[General]
icon_theme=Papirus-Dark
single_click_activate=false
theme=graphite
LXQTCONF
# ─────────────────────────────────────────────────────────────────────────────
# LA BARRE DES TACHES
#
# Aucun panel.conf n'existait : le panneau tournait sur ses valeurs d'usine.
# D'ou l'aspect generique constate sur capture -- fond clair, elements tronques
# a gauche et a droite, sans rapport avec le theme rouge et noir du reste.
#
# On fixe la taille, la position et surtout l'ORDRE des elements : menu a
# gauche, fenetres au centre, indicateurs et horloge a droite. Les couleurs
# viennent du theme (graphite) plutot que d'etre ecrites ici : LXQt les stocke
# au format binaire de Qt, illisible et fragile a generer a la main.
# ─────────────────────────────────────────────────────────────────────────────
cat > /home/mados/.config/lxqt/panel.conf <<PANELCONF
[General]
__userfile__=true

[panel1]
alignment=-1
animation-duration=0
desktop=0
hidable=false
iconSize=22
lineCount=1
lockPanel=true
opacity=100
panelSize=34
plugins=mainmenu, desktopswitch, taskbar, clock
position=Bottom
reserveSpace=true
width=100
widthPercent=true

[mainmenu]
alignment=Left
type=mainmenu

[desktopswitch]
alignment=Left
type=desktopswitch

[taskbar]
alignment=Left
type=taskbar

[clock]
alignment=Right
type=clock
timeFormat=HH:mm
dateFormat=ddd d MMM
showSeconds=false
PANELCONF

# Configuration de la session LXQt (Labwc comme WM)
cat > /home/mados/.config/lxqt/session.conf <<SESSIONCONF
[General]
__userfile__=true

[Environment]
WLR_NO_HARDWARE_CURSORS=1
LIBGL_ALWAYS_SOFTWARE=1

[LockScreenSettings]
lock_screen=false

[Modules]
lxqt-panel=true
lxqt-runner=true
lxqt-notificationd=true
lxqt-policykit-agent=true

[WindowManager]
window_manager=labwc
SESSIONCONF

# Lancement du panel LXQt (Razor-Qt) et de l'installateur MadOS au boot de Labwc (Wayland)
cat <<LABWC > /home/mados/.config/labwc/autostart
# Les composants LXQt (panneau, notifications, agent PolicyKit, lanceur) ne
# sont plus lances ici : lxqt-session s'en charge, avec le theme applique.
# Les lancer aussi depuis labwc produirait des doublons.
# Rendu logiciel : indispensable en machine virtuelle (aucune acceleration
# disponible), penalisant sur du vrai materiel. systemd-detect-virt tranche
# au demarrage ; la meme image sert donc aux deux usages.
if systemd-detect-virt --quiet; then
    export LIBGL_ALWAYS_SOFTWARE=1
    export WLR_NO_HARDWARE_CURSORS=1
fi

# Fond d'ecran : le bureau affichait un noir uni, alors que le depot embarque
# dix fonds ROG. MadCarbon est le plus leger (54 Ko), ce qui compte dans une
# image live. swaybg le pose nativement sous Wayland ; xsetroot, qui servait
# jusqu'ici, est un outil X11 qui ne sait afficher qu'une couleur.
if command -v swaybg >/dev/null 2>&1 && [ -f /usr/share/backgrounds/mados.png ]; then
    swaybg -i /usr/share/backgrounds/mados.png -m fill &
else
    xsetroot -solid '#0a0a0a' 2>/dev/null &
fi
# Ressources X11 pour xterm, seul rescape graphique de cet autostart.
xrdb -merge /home/mados/.Xresources 2>/dev/null &
# L'installateur ne se lance plus ici : il tourne sur la console, avant labwc.
# Le faire passer par Xwayland puis xterm ajoutait deux couches entre le
# clavier et lui, et les touches n'y arrivaient pas.
xterm -bg '#0a0a0a' -fg '#e0e0e0' -fa 'DejaVu Sans Mono' -fs 11 &
LABWC
chown -R mados:mados /home/mados/.config

# Désactiver LightDM — on utilise getty TTY1 + .bash_profile à la place
systemctl disable lightdm 2>/dev/null || true

# ═══════════════════════════════════════════════════
# DNS PRÉ-CONFIGURÉ POUR QEMU / VM LIVE
# 10.0.2.3 = DNS interne QEMU user network
# ═══════════════════════════════════════════════════
# DNS via NetworkManager (méthode correcte, sans bloquer NM)
# ═══════════════════════════════════════════════════
mkdir -p /etc/NetworkManager/conf.d/
cat > /etc/NetworkManager/conf.d/mados-dns.conf <<NMDNS
[global-dns-domain-*]
servers=10.0.2.3,8.8.8.8,1.1.1.1
NMDNS

# systemd-resolved fallback (sans chattr — laisser NM écrire resolv.conf)
mkdir -p /etc/systemd/resolved.conf.d/
cat > /etc/systemd/resolved.conf.d/mados-dns.conf <<RESOLVED
[Resolve]
DNS=10.0.2.3 8.8.8.8 1.1.1.1
FallbackDNS=8.8.4.4 9.9.9.9
DNSOverTLS=no
LLMNR=no
RESOLVED

# resolv.conf par défaut (sera écrasé par NM au boot, c'est voulu)
cat > /etc/resolv.conf <<RESOLV
nameserver 10.0.2.3
nameserver 8.8.8.8
nameserver 1.1.1.1
RESOLV

# ═══════════════════════════════════════════════════
# /etc/hosts avec IPs directes — bypass DNS si résolution échoue
# ═══════════════════════════════════════════════════
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
127.0.1.1   mados-rog
::1         localhost ip6-localhost ip6-loopback

# Dépôts Ubuntu (IPs Cloudflare CDN)
104.20.28.246   archive.ubuntu.com
172.66.152.176  archive.ubuntu.com
104.20.28.246   security.ubuntu.com
104.20.28.246   fr.archive.ubuntu.com

# XanMod
104.21.40.143   deb.xanmod.org

# Google DNS (fallback)
8.8.8.8         dns.google
HOSTS

# APT : forcer IPv4 et retries pour VM
cat > /etc/apt/apt.conf.d/99mados-vm <<APTCONF
Acquire::ForceIPv4 "true";
Acquire::Retries "5";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
APTCONF

# Nettoyage
# apt-get clean ne vide que /var/cache/apt : les paquets noyau deja copies
# dans /opt/mados-rog/noyau/ ne sont pas concernes.
apt-get clean
rm -f /etc/uuid
EOF

run_sudo chmod +x "$WORKDIR/chroot_setup.sh"
run_sudo mv "$WORKDIR/chroot_setup.sh" "$CHROOT_DIR/chroot_setup.sh"

# Le noyau XanMod est déjà installé via apt dans le chroot, aucun besoin de le copier ou de le compiler manuellement.


# Montage des dossiers de périphériques et systèmes virtuels (requis par apt)
run_sudo mount -t proc /proc "$CHROOT_DIR/proc"
run_sudo mount -t sysfs /sys "$CHROOT_DIR/sys"
run_sudo mount --bind /dev "$CHROOT_DIR/dev"
run_sudo mount --bind /dev/pts "$CHROOT_DIR/dev/pts"

# Exécution du chroot
set +e
run_sudo chroot "$CHROOT_DIR" /bin/bash /chroot_setup.sh
CHROOT_STATUS=$?
set -e

# Démontage propre
run_sudo umount -lf "$CHROOT_DIR/dev/pts" || true
run_sudo umount -lf "$CHROOT_DIR/dev" || true
run_sudo umount -lf "$CHROOT_DIR/sys" || true
run_sudo umount -lf "$CHROOT_DIR/proc" || true

if [ $CHROOT_STATUS -ne 0 ]; then
    echo -e "${RED}✗ Erreur d'installation à l'intérieur du chroot (Code: $CHROOT_STATUS)${NC}"
    exit 1
fi

# 4. Préparation de la structure ISO
echo -e "${CYAN}[4/7] Préparation des fichiers d'amorce et du noyau pour l'ISO...${NC}"
# Extraction du noyau XanMod installé dans le chroot pour l'amorce ISO
# Meme regle que dans le chroot : XanMod d'abord, jamais « le premier de la liste ».
KERNEL_VERSION=$(find "$CHROOT_DIR/boot" -maxdepth 1 -name 'vmlinuz-*xanmod*' -printf '%f
' 2>/dev/null                  | sed 's/^vmlinuz-//' | sort -V | tail -n1)
[ -z "$KERNEL_VERSION" ] && KERNEL_VERSION=$(find "$CHROOT_DIR/boot" -maxdepth 1 -name 'vmlinuz-*' -printf '%f
' 2>/dev/null                  | sed 's/^vmlinuz-//' | sort -V | tail -n1)
if [ -z "$KERNEL_VERSION" ]; then
    echo -e "${RED}Aucun noyau trouve dans le chroot : construction impossible.${NC}"; exit 1
fi
echo -e "${GREEN}  Noyau embarque : $KERNEL_VERSION${NC}"
run_sudo cp "$CHROOT_DIR/boot/vmlinuz-$KERNEL_VERSION" "$IMAGE_DIR/boot/vmlinuz"
run_sudo cp "$CHROOT_DIR/boot/initrd.img-$KERNEL_VERSION" "$IMAGE_DIR/boot/initrd.img"

# ─────────────────────────────────────────────────────────────────────────────
# I-03 : LE NOYAU DOIT SURVIVRE A L'INSTALLATION SUR DISQUE
# mksquashfs exclut /boot (correct : GRUB lit le noyau depuis l'ISO). Mais
# live_installer.sh recopiait ensuite la racine live vers le disque -- avec un
# /boot VIDE. Verifie sur l'image livree : 0 entree sous /boot dans le squashfs.
# Le systeme installe n'avait donc ni vmlinuz ni initrd, et update-grub ecrivait
# un menu sans aucune entree.
# On depose ici les .deb du noyau, que l'installateur reinstallera dans la cible :
# cela repose le noyau ET regenere un initrd pour le VRAI materiel, pas celui du live.
echo -e "${CYAN}  Mise de cote des paquets noyau pour l'installation sur disque...${NC}"
# Les .deb sont deja mis de cote DANS le chroot (voir plus haut, avant le
# apt-get clean qui viderait le cache). Ici on n'ajoute que le repli brut.
run_sudo mkdir -p "$CHROOT_DIR/opt/mados-rog/noyau"
# Filet : si le cache apt a ete vide, on copie le noyau brut. L'installateur
# saura se rabattre dessus.
run_sudo mkdir -p "$CHROOT_DIR/opt/mados-rog/noyau/brut"
run_sudo cp "$CHROOT_DIR/boot/vmlinuz-$KERNEL_VERSION" "$CHROOT_DIR/opt/mados-rog/noyau/brut/" 2>/dev/null || true
run_sudo cp "$CHROOT_DIR/boot/initrd.img-$KERNEL_VERSION" "$CHROOT_DIR/opt/mados-rog/noyau/brut/" 2>/dev/null || true
run_sudo bash -c "echo '$KERNEL_VERSION' > \"$CHROOT_DIR/opt/mados-rog/noyau/version\""

# 5. Configuration de GRUB pour l'ISO
echo -e "${CYAN}[5/7] Configuration du chargeur de démarrage GRUB...${NC}"
cat <<EOF > "$WORKDIR/grub.cfg"
# Le menu doit rester assez longtemps a l'ecran pour qu'on puisse choisir
# l'entree de diagnostic quand le demarrage normal se fige.
# Identite visuelle du menu : sans ces lignes, GRUB affiche du texte blanc sur
# noir en 640x480, identique a n'importe quelle distribution.
# Le mode graphique exige une POLICE : sans loadfont, gfxterm n'a aucun glyphe
# pour les traits de cadre et affiche des blocs vides a la place. Constate sur
# une capture d'ecran -- le cadre du menu etait illisible.
#
# Le « if » n'est pas une precaution de style : si la police manque, GRUB reste
# en mode texte, qui dessine ces memes traits nativement. Mieux vaut un menu
# sobre qu'un menu casse.
if loadfont /boot/grub/fonts/unicode.pf2 ; then
    insmod all_video
    insmod gfxterm
    set gfxmode=auto
    terminal_output gfxterm
fi

set color_normal=light-gray/black
set color_highlight=white/red
set menu_color_normal=light-gray/black
set menu_color_highlight=white/red

set timeout=10
set default=0

menuentry "Demarrer MadOS ROG Edition v$MADOS_VERSION (Live & Install)" {
    linux /boot/vmlinuz boot=casper quiet splash ---
    initrd /boot/initrd.img
}

menuentry "MadOS ROG Edition v$MADOS_VERSION - messages detailles (diagnostic)" {
    # Sans « quiet splash », tous les messages du noyau s'affichent a l'ecran.
    # console=ttyS0 les envoie EN PLUS sur le port serie, que l'hyperviseur sait
    # ecrire dans un fichier : seule facon de lire ce qui s'est passe quand
    # l'ecran se fige. Sans cette entree, on diagnostique un systeme muet.
    linux /boot/vmlinuz boot=casper console=tty0 console=ttyS0,115200n8 ---
    initrd /boot/initrd.img
}
EOF
run_sudo cp "$WORKDIR/grub.cfg" "$IMAGE_DIR/boot/grub/grub.cfg"

# ─────────────────────────────────────────────────────────────────────────────
# I-09 : MARQUEURS D'IDENTIFICATION DU SUPPORT
# L'ISO n'en portait aucun -- verifie : « .disk » apparaissait 0 fois dedans.
# Casper s'en sort souvent sans, mais ce sont ces fichiers qui permettent aux
# outils tiers (Ventoy, graveurs, gestionnaires de demarrage) de reconnaitre
# le support comme un live Ubuntu.
run_sudo mkdir -p "$IMAGE_DIR/.disk"
run_sudo bash -c "echo \"MadOS ROG Edition $MADOS_VERSION - amd64 ($MADOS_DATE)\" > \"$IMAGE_DIR/.disk/info\""
run_sudo bash -c "echo 'https://github.com/LordMadTrix/MadOS_ROG_Edition' > \"$IMAGE_DIR/.disk/release_notes_url\""
run_sudo bash -c "echo 'full_cd/single' > \"$IMAGE_DIR/.disk/cd_type\""

# 6. Création du système de fichiers SquashFS
echo -e "${CYAN}[6/7] Compression du système de fichiers racine en SquashFS (xz)...${NC}"
mkdir -p "$IMAGE_DIR/casper"
# xz : meilleure compression — exclure seulement /boot (déjà copié dans image/boot)
# IMPORTANT: opt/mados-rog doit être dans le squashfs (contient install.sh)
run_sudo mksquashfs "$CHROOT_DIR" "$IMAGE_DIR/casper/filesystem.squashfs" -comp xz -noappend -e boot

# 7. Création de l'ISO bootable finale
echo -e "${CYAN}[7/7] Génération de l'ISO bootable avec grub-mkrescue...${NC}"
# --modules et l'etiquette de volume : grub-mkrescue produit une image hybride
# BIOS + UEFI des lors que les deux plateformes sont installees (voir les
# dependances en haut). -V donne au support un nom, ce qui manquait aussi.
run_sudo grub-mkrescue -o MadOS_ROG_Edition_v4.iso "$IMAGE_DIR"     -- -volid "MADOS_ROG_40"

# ─────────────────────────────────────────────────────────────────────────────
# CONTROLE : l'ISO est-elle REELLEMENT amorcable en UEFI ?
# Sans ce controle, une dependance manquante redonnerait silencieusement une
# image BIOS seule -- exactement le defaut d'origine, invisible jusqu'a ce
# qu'un ROG refuse de demarrer dessus.
echo -e "${CYAN}Verification du catalogue d'amorcage...${NC}"
if command -v xorriso >/dev/null 2>&1; then
    PLATEFORMES=$(xorriso -indev MadOS_ROG_Edition_v4.iso -report_el_torito plain 2>/dev/null                   | grep -ci 'UEFI\|0xef' || true)
    if [ "${PLATEFORMES:-0}" -eq 0 ]; then
        echo -e "${RED}✗ ECHEC : l'ISO n'annonce aucune plateforme UEFI.${NC}"
        echo -e "${YELLOW}  Verifie que grub-efi-amd64-bin et dosfstools sont bien installes.${NC}"
        exit 1
    fi
    echo -e "${GREEN}  ✓ Amorcage UEFI present dans le catalogue${NC}"
fi
if [ ! -s MadOS_ROG_Edition_v4.iso ]; then
    echo -e "${RED}✗ ECHEC : l'ISO est vide ou absente.${NC}"; exit 1
fi

echo -e "${GREEN}✅ Terminé avec succès ! Votre ISO personnalisée 'MadOS_ROG_Edition_v4.iso' est disponible.${NC}"
