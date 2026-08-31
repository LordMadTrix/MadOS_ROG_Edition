#!/bin/bash
# ==============================================================================
# MadOS ROG Edition — Live Installer
# Installe MadOS depuis le Live CD vers un disque dur
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[0;33m'; WHITE='\033[1;37m'; GRAY='\033[0;37m'
NC='\033[0m'

# Version lue depuis le dépôt embarqué dans l'ISO, jamais recopiée à la main.
MADOS_VERSION="$(cat /opt/mados-rog/VERSION 2>/dev/null | tr -d ' 
')"
[ -z "$MADOS_VERSION" ] && MADOS_VERSION="?"

clear
echo -e "${RED}"
cat << 'LOGO'
  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗
  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝
  ██╔████╔██║███████║██║  ██║██║   ██║███████╗
  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║
  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║
  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝
LOGO
echo -e "${NC}"
echo -e "${RED}  ╔══════════════════════════════════════════╗${NC}"
echo -e "${RED}  ║   INSTALLATEUR MadOS ROG Edition $MADOS_VERSION     ║${NC}"
echo -e "${RED}  ║   XanMod 7 | Wayland | LXQt (Razor-Qt)  ║${NC}"
echo -e "${RED}  ╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Détection des disques disponibles ─────────────────────────────────────────
echo -e "${CYAN}Disques disponibles :${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
lsblk -nd -o NAME,SIZE,TYPE,MODEL 2>/dev/null | grep -v "loop\|sr\|rom" | while read line; do
    echo -e "  ${WHITE}$line${NC}"
done
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# CHOIX EXPLICITE DU DISQUE — jamais de présélection automatique.
#
# Avant, la cible était le disque LE PLUS GROS, choisi tout seul, et la seule
# question posée était oui/non. Sur une machine avec un SSD système et un gros
# disque de données, c'est le disque de données qui était visé — puis effacé
# par wipefs + parted mklabel. La taille est précisément le critère qui désigne
# le plus souvent le mauvais disque.
# ─────────────────────────────────────────────────────────────────────────────
# ─────────────────────────────────────────────────────────────────────────────
# Tous les « disk » de lsblk ne sont pas des cibles valides.
#
# Constaté en lançant l'ISO sous QEMU : la machine n'avait aucun disque dur, et
# le lecteur de disquette que QEMU crée par défaut était proposé comme cible —
# « fd0  4K disk ». lsblk le classe bien comme « disk », et rien ne l'écartait.
# Sur du vrai matériel, un lecteur de cartes vide produit le même effet.
#
# Le seuil n'est pas arbitraire : le partitionnement réclame 512 Mo d'ESP et
# 2 Go de swap avant la moindre donnée. En dessous de 3 Go, parted échouerait
# de toute façon — autant le dire avant plutôt que de planter au milieu.
# ─────────────────────────────────────────────────────────────────────────────
MIN_OCTETS=$((3 * 1024 * 1024 * 1024))
CONFORT_OCTETS=$((16 * 1024 * 1024 * 1024))

mapfile -t TOUS < <(lsblk -dn -o NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}')

DISQUES=()
ECARTES=()
for d in "${TOUS[@]}"; do
    case "$d" in
        fd*|sr*|loop*|ram*|zram*)
            ECARTES+=("$d|support non installable"); continue ;;
    esac
    OCTETS=$(lsblk -dnb -o SIZE "/dev/$d" 2>/dev/null | head -1)
    [ -z "$OCTETS" ] && OCTETS=0
    if [ "$OCTETS" -lt "$MIN_OCTETS" ]; then
        ECARTES+=("$d|trop petit pour accueillir le système")
        continue
    fi
    DISQUES+=("$d")
done

if [ ${#ECARTES[@]} -gt 0 ]; then
    LISTE=""
    for e in "${ECARTES[@]}"; do LISTE="$LISTE /dev/${e%%|*} (${e#*|})"; done
    echo -e "${GRAY}Écartés :$LISTE${NC}"
    echo ""
fi

if [ ${#DISQUES[@]} -eq 0 ]; then
    echo -e "${RED}[ERREUR] Aucun disque utilisable sur cette machine.${NC}"
    if [ ${#ECARTES[@]} -gt 0 ]; then
        echo -e "${GRAY}  Écartés :${NC}"
        for e in "${ECARTES[@]}"; do
            echo -e "${GRAY}    /dev/${e%%|*} — ${e#*|}${NC}"
        done
    fi
    echo -e "${YELLOW}  Il faut un disque d'au moins 3 Go (ESP 512 Mo + swap 2 Go + racine).${NC}"
    exit 1
fi

echo -e "${CYAN}Sur quel disque installer MadOS ?${NC}"
echo ""
i=1
for d in "${DISQUES[@]}"; do
    INFO=$(lsblk -dn -o SIZE,MODEL "/dev/$d" 2>/dev/null | head -1)
    OCTETS=$(lsblk -dnb -o SIZE "/dev/$d" 2>/dev/null | head -1)
    JUSTE=""
    if [ -n "$OCTETS" ] && [ "$OCTETS" -lt "$CONFORT_OCTETS" ]; then
        JUSTE=" ${YELLOW}(très juste pour un système complet)${NC}"
    fi
    MONTE=$(lsblk -n -o MOUNTPOINT "/dev/$d" 2>/dev/null | grep -c '/' || true)
    MARQUE=""
    [ "$MONTE" -gt 0 ] && MARQUE=" ${YELLOW}(contient des partitions montées)${NC}"
    echo -e "  ${WHITE}$i)${NC} /dev/$d   $INFO$MARQUE$JUSTE"
    i=$((i+1))
done
echo -e "  ${WHITE}q)${NC} Annuler"
echo ""

TARGET_DISK=""
while [ -z "$TARGET_DISK" ]; do
    read -p "$(echo -e "${WHITE}Numéro du disque : ${NC}")" CHOIX
    case "$CHOIX" in
        q|Q) echo -e "${YELLOW}Installation annulée.${NC}"; exit 0 ;;
        ''|*[!0-9]*) echo -e "${RED}  Entre un numéro de la liste.${NC}" ;;
        *)
            if [ "$CHOIX" -ge 1 ] && [ "$CHOIX" -le ${#DISQUES[@]} ]; then
                TARGET_DISK="${DISQUES[$((CHOIX-1))]}"
            else
                echo -e "${RED}  Numéro hors liste.${NC}"
            fi ;;
    esac
done

echo ""
echo -e "${YELLOW}Disque choisi : ${WHITE}/dev/$TARGET_DISK${NC}"
lsblk "/dev/$TARGET_DISK" 2>/dev/null | sed 's/^/    /'
echo ""
echo ""
echo -e "${RED}⚠️  ATTENTION : TOUTES LES DONNÉES sur /dev/$TARGET_DISK seront EFFACÉES !${NC}"
echo ""
read -p "$(echo -e "${WHITE}Confirmer l'installation sur /dev/$TARGET_DISK ? [oui/NON] : ${NC}")" CONFIRM

if [ "$CONFIRM" != "oui" ]; then
    echo -e "${YELLOW}Installation annulée.${NC}"
    exit 0
fi

DISK="/dev/$TARGET_DISK"

# ─────────────────────────────────────────────────────────────────────────────
# MODE D'AMORÇAGE RÉEL — on installe comme la machine a démarré.
#
# Avant, l'installateur créait toujours une table GPT avec ESP et lançait
# grub-install --target=x86_64-efi. Or l'ISO n'était amorçable qu'en BIOS :
# /sys/firmware/efi n'existait donc pas, et l'installation EFI était au mieux
# fragile, au pire silencieusement inopérante. Les deux moitiés du système ne
# visaient pas le même mode.
# ─────────────────────────────────────────────────────────────────────────────
if [ -d /sys/firmware/efi ]; then
    MODE_BOOT="UEFI"
else
    MODE_BOOT="BIOS"
fi
echo -e "${CYAN}Mode d'amorçage détecté : ${WHITE}$MODE_BOOT${NC}"

# ── Détection type de disque (nvme ou sata) ────────────────────────────────────
if echo "$TARGET_DISK" | grep -q "nvme"; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi

EFI_PART="${PART_PREFIX}1"
SWAP_PART="${PART_PREFIX}2"
ROOT_PART="${PART_PREFIX}3"

# ── Partitionnement GPT ────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[1/6] Partitionnement de $DISK (GPT)...${NC}"
wipefs -a "$DISK" 2>/dev/null || true
if [ "$MODE_BOOT" = "UEFI" ]; then
    parted -s "$DISK"         mklabel gpt         mkpart ESP fat32 1MiB 513MiB         set 1 esp on         mkpart swap linux-swap 513MiB 2561MiB         mkpart root ext4 2561MiB 100%
    echo -e "${GREEN}  ✓ GPT/UEFI : ESP 512 Mo | Swap 2 Go | Root reste${NC}"
else
    # En BIOS sur une table GPT, GRUB exige une partition « bios_grub » où loger
    # son core.img. Sans elle, grub-install refuse net. 2 Mo suffisent largement :
    # elle n'est pas formatée et ne contient qu'un amorceur.
    parted -s "$DISK"         mklabel gpt         mkpart biosboot 1MiB 3MiB         set 1 bios_grub on         mkpart swap linux-swap 3MiB 2051MiB         mkpart root ext4 2051MiB 100%
    echo -e "${GREEN}  ✓ GPT/BIOS : bios_grub 2 Mo | Swap 2 Go | Root reste${NC}"
fi
sleep 1
partprobe "$DISK" 2>/dev/null || true
sleep 2

# ── Formatage ─────────────────────────────────────────────────────────────────
echo -e "${CYAN}[2/6] Formatage des partitions...${NC}"
if [ "$MODE_BOOT" = "UEFI" ]; then
    mkfs.fat -F32 -n "MADOS_EFI" "$EFI_PART"
fi
mkswap -L "mados-swap" "$SWAP_PART"
mkfs.ext4 -L "MadOS_ROOT" -F "$ROOT_PART"
echo -e "${GREEN}  ✓ Partitions formatées${NC}"

# ── Montage ───────────────────────────────────────────────────────────────────
echo -e "${CYAN}[3/6] Montage des partitions...${NC}"
mkdir -p /mnt/mados
mount "$ROOT_PART" /mnt/mados
if [ "$MODE_BOOT" = "UEFI" ]; then
    mkdir -p /mnt/mados/boot/efi
    mount "$EFI_PART" /mnt/mados/boot/efi
fi
swapon "$SWAP_PART" 2>/dev/null || true
echo -e "${GREEN}  ✓ Partitions montées dans /mnt/mados${NC}"

# ── Copie du système depuis le squashfs live ───────────────────────────────────
echo -e "${CYAN}[4/6] Copie du système MadOS (peut prendre 5-10 min)...${NC}"
echo -e "${GRAY}  Copie depuis / (live squashfs) → /mnt/mados...${NC}"

rsync -aAX \
    --exclude=/proc \
    --exclude=/sys \
    --exclude=/dev \
    --exclude=/run \
    --exclude=/mnt \
    --exclude=/tmp \
    --exclude=/media \
    --exclude=/lost+found \
    --exclude=/cdrom \
    --exclude=/casper \
    / /mnt/mados/

echo -e "${GREEN}  ✓ Système copié${NC}"

# ── Reconfiguration du système installé ───────────────────────────────────────
echo -e "${CYAN}[5/6] Configuration du système installé...${NC}"

# Créer les points de montage spéciaux
mkdir -p /mnt/mados/{proc,sys,dev,run,tmp,media,cdrom}

# Bind mount pour chroot
mount -t proc /proc /mnt/mados/proc
mount -t sysfs /sys /mnt/mados/sys
mount --bind /dev /mnt/mados/dev
mount --bind /run /mnt/mados/run

# fstab
ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
SWAP_UUID=$(blkid -s UUID -o value "$SWAP_PART")

cat > /mnt/mados/etc/fstab <<FSTAB
# MadOS ROG Edition — /etc/fstab
UUID=$ROOT_UUID  /          ext4  errors=remount-ro  0 1
UUID=$SWAP_UUID  none       swap  sw                 0 0
tmpfs            /tmp       tmpfs defaults            0 0
FSTAB

# La ligne EFI n'a de sens qu'en UEFI : en BIOS il n'y a pas d'ESP, et une
# entree fstab pointant sur une partition inexistante bloque le demarrage
# suivant sur une invite de secours.
if [ "$MODE_BOOT" = "UEFI" ]; then
    EFI_UUID=$(blkid -s UUID -o value "$EFI_PART")
    echo "UUID=$EFI_UUID   /boot/efi  vfat  umask=0077         0 1" >> /mnt/mados/etc/fstab
fi

# Hostname sur le système installé
echo "mados-rog" > /mnt/mados/etc/hostname

# Supprimer l'autologin (sur HDD l'user entrera son mot de passe ou choisit)
rm -f /mnt/mados/etc/systemd/system/getty@tty1.service.d/autologin.conf 2>/dev/null || true

# Supprimer l'autostart live (install.sh live)
rm -f /mnt/mados/home/mados/.config/labwc/autostart 2>/dev/null || true

# Créer un autostart propre (sans l'installateur live)
mkdir -p /mnt/mados/home/mados/.config/labwc/
cat > /mnt/mados/home/mados/.config/labwc/autostart <<AUTOSTART
# Le systeme installe tourne sur du VRAI materiel : ni contournement de siege
# (seatd et logind y sont presents), ni rendu logiciel force. Ces trois lignes
# etaient recopiees telles quelles depuis le live, ou elles n'avaient de sens
# que faute des paquets adequats.
if systemd-detect-virt --quiet; then
    export LIBGL_ALWAYS_SOFTWARE=1
    export WLR_NO_HARDWARE_CURSORS=1
fi
xsetroot -solid '#0a0a0a' 2>/dev/null &
lxqt-notificationd &
lxqt-policykit-agent &
lxqt-panel &
AUTOSTART

# ─────────────────────────────────────────────────────────────────────────────
# I-03 : REPOSER LE NOYAU
#
# Le squashfs live est bâti avec « mksquashfs -e boot » : correct pour le live,
# puisque GRUB lit le noyau depuis l'ISO. Mais le rsync ci-dessus a donc copié
# un /boot VIDE sur le disque. Vérifié sur l'image livrée : 0 entrée sous /boot
# dans le squashfs. Sans ce bloc, update-grub ne trouve aucun noyau et écrit un
# menu vide — la machine installée ne démarre jamais.
#
# On réinstalle les .deb mis de côté par le constructeur : cela repose le noyau
# ET régénère un initrd pour le matériel RÉEL, pas celui de la VM live.
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${CYAN}  Réinstallation du noyau sur le système cible...${NC}"
NOYAU_OK=0
if ls /opt/mados-rog/noyau/*.deb >/dev/null 2>&1; then
    mkdir -p /mnt/mados/tmp/noyau
    cp /opt/mados-rog/noyau/*.deb /mnt/mados/tmp/noyau/
    if chroot /mnt/mados /bin/bash -c "DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/noyau/*.deb"; then
        NOYAU_OK=1
    fi
    rm -rf /mnt/mados/tmp/noyau
fi

# Repli : si les paquets manquent, on repose le noyau brut mis de côté.
if [ "$NOYAU_OK" -eq 0 ] && [ -d /opt/mados-rog/noyau/brut ]; then
    echo -e "${YELLOW}  Paquets noyau indisponibles : repli sur la copie brute.${NC}"
    cp /opt/mados-rog/noyau/brut/vmlinuz-* /mnt/mados/boot/ 2>/dev/null || true
    cp /opt/mados-rog/noyau/brut/initrd.img-* /mnt/mados/boot/ 2>/dev/null || true
fi

# Dernier repli : le noyau du support live lui-même.
if ! ls /mnt/mados/boot/vmlinuz-* >/dev/null 2>&1; then
    for src in /cdrom/boot /run/live/medium/boot /lib/live/mount/medium/boot; do
        if [ -f "$src/vmlinuz" ]; then
            echo -e "${YELLOW}  Repli ultime : noyau repris depuis le support ($src).${NC}"
            cp "$src/vmlinuz"    /mnt/mados/boot/vmlinuz-live    2>/dev/null || true
            cp "$src/initrd.img" /mnt/mados/boot/initrd.img-live 2>/dev/null || true
            break
        fi
    done
fi

# CONTRÔLE BLOQUANT : sans noyau, inutile d'aller plus loin.
if ! ls /mnt/mados/boot/vmlinuz-* >/dev/null 2>&1; then
    echo -e "${RED}✗ ÉCHEC : aucun noyau sur le système cible.${NC}"
    echo -e "${YELLOW}  Le système ne démarrerait pas. Arrêt avant GRUB.${NC}"
    umount /mnt/mados/proc /mnt/mados/sys /mnt/mados/dev /mnt/mados/run 2>/dev/null || true
    umount /mnt/mados/boot/efi 2>/dev/null || true
    umount /mnt/mados 2>/dev/null || true
    exit 1
fi
echo -e "${GREEN}  ✓ Noyau présent sur la cible${NC}"

# ─────────────────────────────────────────────────────────────────────────────
# I-07 : le compte live ne doit pas rester tel quel sur le disque
#
# Le compte « mados » a le mot de passe « mados » et un sudoers NOPASSWD:ALL.
# Normal pour un live éphémère ; pas sur une machine installée. L'ancien code
# ne retirait que l'autologin.
# ─────────────────────────────────────────────────────────────────────────────
rm -f /mnt/mados/etc/sudoers.d/mados
echo "mados ALL=(ALL:ALL) ALL" > /mnt/mados/etc/sudoers.d/mados
chmod 0440 /mnt/mados/etc/sudoers.d/mados
chroot /mnt/mados /usr/bin/passwd --expire mados >/dev/null 2>&1 || true
echo -e "${GREEN}  ✓ Compte mados : sudo avec mot de passe, changement forcé au 1er accès${NC}"

# ─────────────────────────────────────────────────────────────────────────────
# I-06 : GRUB, et on VÉRIFIE qu'il est réellement posé
#
# L'ancien bloc finissait par « 2>/dev/null || true » et chaque commande portait
# déjà son propre « || true » : aucun code de retour n'était lu. Le script
# annonçait « installé avec succès » même quand GRUB avait totalement échoué.
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${GRAY}  Installation de GRUB ($MODE_BOOT)...${NC}"
if [ "$MODE_BOOT" = "UEFI" ]; then
    chroot /mnt/mados /bin/bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y grub-efi-amd64 efibootmgr --no-install-recommends -q || true
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=MadOS --recheck ||
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=MadOS --no-nvram --recheck
        update-grub
    "
    GRUB_STATUS=$?
else
    chroot /mnt/mados /bin/bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y grub-pc --no-install-recommends -q || true
        grub-install --target=i386-pc --recheck $DISK
        update-grub
    "
    GRUB_STATUS=$?
fi

# Le vrai contrôle n'est pas le code de sortie, c'est le RÉSULTAT sur le disque.
ERREURS=""
if [ "$MODE_BOOT" = "UEFI" ] && [ ! -f /mnt/mados/boot/efi/EFI/MadOS/grubx64.efi ]; then
    ERREURS="$ERREURS  - grubx64.efi absent de la partition EFI"
fi
if [ ! -f /mnt/mados/boot/grub/grub.cfg ]; then
    ERREURS="$ERREURS  - /boot/grub/grub.cfg n'a pas été généré"
elif ! grep -q "^menuentry" /mnt/mados/boot/grub/grub.cfg; then
    ERREURS="$ERREURS  - grub.cfg ne contient AUCUNE entrée de démarrage"
fi

if [ -n "$ERREURS" ]; then
    echo -e "${RED}✗ ÉCHEC de l'installation du chargeur de démarrage :${NC}"
    echo -e "${YELLOW}$ERREURS${NC}"
    echo -e "${YELLOW}  (code de sortie GRUB : $GRUB_STATUS)${NC}"
    echo -e "${RED}  La machine ne démarrerait pas. Rien n'est annoncé comme réussi.${NC}"
    umount /mnt/mados/proc /mnt/mados/sys /mnt/mados/dev /mnt/mados/run 2>/dev/null || true
    umount /mnt/mados/boot/efi 2>/dev/null || true
    umount /mnt/mados 2>/dev/null || true
    swapoff "$SWAP_PART" 2>/dev/null || true
    exit 1
fi
echo -e "${GREEN}  ✓ GRUB posé, $(grep -c '^menuentry' /mnt/mados/boot/grub/grub.cfg) entrée(s) de démarrage${NC}"

# Démontage
umount /mnt/mados/proc /mnt/mados/sys /mnt/mados/dev /mnt/mados/run 2>/dev/null || true
umount /mnt/mados/boot/efi 2>/dev/null || true
umount /mnt/mados 2>/dev/null || true
swapoff "$SWAP_PART" 2>/dev/null || true

# ── Résumé ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}✅ MadOS ROG Edition installé sur $DISK !${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}Prochaines étapes :${NC}"
echo -e "  ${WHITE}1.${NC} Retirez l'ISO/clé USB"
echo -e "  ${WHITE}2.${NC} Redémarrez : ${CYAN}sudo reboot${NC}"
echo -e "  ${WHITE}3.${NC} MadOS démarre depuis $DISK"
echo -e "  ${WHITE}4.${NC} Pour optimiser : ${CYAN}cd /opt/mados-rog && sudo bash install.sh${NC}"
echo ""
echo -e "${YELLOW}Appuyez sur ENTRÉE pour revenir au bureau live...${NC}"
read
