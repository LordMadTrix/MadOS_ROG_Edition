#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 21_boot_eclair.sh
# ==============================================================================
# Phase: 21 - Boot Éclair (LZ4 & Silent GRUB)
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 21 Extrémisation du Boot (Démarrage Éclair)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Initramfs ZSTD (Modern & Safe)
echo -e "    ${GRAY}├─ Injection de l'outil de compression ZSTD (Standard Moderne)...${NC}"
run_action "installerait le paquet zstd" sudo apt-get install -y zstd -qq >/dev/null 2>&1 || true

echo -e "    ${GRAY}├─ Optimisation du moteur Initramfs vers ZSTD (Équilibre Vitesse/Fiabilité)...${NC}"
INITRAMFS_CONF="/etc/initramfs-tools/initramfs.conf"
# 3. Mode Secours MadOS dans GRUB
echo -e "    ${WHITE}├─ [RESCUE] Création de l'entrée de Secours ROG dans GRUB...${NC}"
# L'ancienne entree codait en dur `set root='(hd0,1)'`, `root=/dev/sda1` et
# `vmlinuz-xanmod-edge` : faux sur tout portable NVMe, donc non demarrable. Et
# elle ecrivait avec `tee` (pas `tee -a`) dans /etc/grub.d/40_custom, effacant
# les entrees personnelles de l'utilisateur. On derive maintenant l'UUID reel de
# la racine et le noyau reellement installe, dans un fichier DEDIE.
RESCUE_FILE="/etc/grub.d/41_mados_rescue"
ROOT_SRC=$(findmnt -no SOURCE / 2>/dev/null)
ROOT_UUID=$(blkid -s UUID -o value "$ROOT_SRC" 2>/dev/null)
# Parcours par glob plutot que `ls | grep` (SC2010) : robuste aux noms de
# fichiers inhabituels, tout en gardant le tri par VERSION (sort -V), sans
# lequel 6.9 passerait pour plus recent que 6.10.
_dernier_noyau() {
    local k kl motif="${1:-}"
    local candidats=()
    for k in /boot/vmlinuz-*; do
        [ -f "$k" ] || continue
        if [ -n "$motif" ]; then
            kl="${k,,}"
            case "$kl" in *"$motif"*) ;; *) continue ;; esac
        fi
        candidats+=("$k")
    done
    [ "${#candidats[@]}" -eq 0 ] && return 1
    printf '%s
' "${candidats[@]}" | sort -V | tail -1
}
KERNEL_IMG=$(_dernier_noyau xanmod) || KERNEL_IMG=$(_dernier_noyau) || KERNEL_IMG=""
INITRD_IMG=""
if [ -n "$KERNEL_IMG" ]; then
    INITRD_IMG="/boot/initrd.img-$(basename "$KERNEL_IMG" | sed 's/^vmlinuz-//')"
    [ -f "$INITRD_IMG" ] || INITRD_IMG=""
fi

if is_dry_run; then
    log_simu "ecrirait l'entree de secours GRUB dans $RESCUE_FILE (UUID racine et noyau detectes, sans toucher a 40_custom)"
elif [ -z "$ROOT_UUID" ] || [ -z "$KERNEL_IMG" ] || [ -z "$INITRD_IMG" ]; then
    # Mieux vaut aucune entree qu'une entree non demarrable.
    echo -e "    ${YELLOW}⚠️  Racine ou noyau non identifiables : entrée de secours NON créée.${NC}"
else
    sudo tee "$RESCUE_FILE" > /dev/null <<RESCUE_EOF
#!/bin/sh
exec tail -n +3 \$0
menuentry 'MadOS ROG Edition - Mode Secours (Reset Drivers/UI)' --class red --class mados {
	search --no-floppy --fs-uuid --set=root ${ROOT_UUID}
	linux	${KERNEL_IMG} root=UUID=${ROOT_UUID} ro single mados_rescue=1
	initrd	${INITRD_IMG}
}
RESCUE_EOF
    sudo chmod +x "$RESCUE_FILE" || true
    echo -e "    ${GRAY}├─ Entrée de secours : noyau $(basename "$KERNEL_IMG"), racine UUID=${ROOT_UUID}${NC}"
fi

# 4. Activation du Timeout et Masquage partiel
echo -e "    ${WHITE}├─ [CONFIG] Optimisation du Timeout et Thème boot...${NC}"
if is_dry_run; then
    log_simu "reglerait GRUB_TIMEOUT=3 dans /etc/default/grub, lancerait update-grub et passerait COMPRESS=zstd"
else
backup_file "/etc/default/grub"
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub || true
sudo update-grub 2>/dev/null || true
if [ -f "$INITRAMFS_CONF" ]; then
    # Sur une Ubuntu par defaut la ligne est COMMENTEE (#COMPRESS=gzip) : le
    # motif ancre ^COMPRESS= ne matchait donc jamais et ZSTD n'etait jamais
    # applique. On gere les deux cas, et on ajoute la ligne si elle est absente.
    if grep -qE '^[[:space:]]*#?[[:space:]]*COMPRESS=' "$INITRAMFS_CONF"; then
        sudo sed -i 's|^[[:space:]]*#\?[[:space:]]*COMPRESS=.*|COMPRESS=zstd|' "$INITRAMFS_CONF" || true
    else
        echo 'COMPRESS=zstd' | sudo tee -a "$INITRAMFS_CONF" >/dev/null
    fi
fi
fi

# 2. Silent GRUB
echo -e "    ${GRAY}├─ Masquage total des textes BIOS POST sous GRUB pour une esthétique console pure...${NC}"
GRUB_CONF="/etc/default/grub"
if [ -f "$GRUB_CONF" ]; then
    if is_dry_run; then
        log_simu "masquerait le boot GRUB (timeout style, cmdline discret) dans $GRUB_CONF"
    else
    # Masquer le timeout en style Hidden mais garder 2 secondes de survie
    sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' "$GRUB_CONF" || true
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' "$GRUB_CONF" || true
    sudo sed -i '/GRUB_RECORDFAIL_TIMEOUT/d' "$GRUB_CONF" || true
    echo 'GRUB_RECORDFAIL_TIMEOUT=2' | sudo tee -a "$GRUB_CONF" >/dev/null || true

    # Fusion, pas remplacement. L'ancienne version ecrasait TOUTE la ligne :
    # elle supprimait donc les parametres deja presents (resume=UUID=... pour
    # l'hibernation, nvidia-drm.modeset=1, amd_pstate=active...) et annulait au
    # passage les ajouts du module 06 et du pilote QEMU, qui s'executent avant.
    MADOS_PARAMS="quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_priority=3 vt.global_cursor_default=0"
    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" "$GRUB_CONF"; then
        ACTUELS=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "$GRUB_CONF" | head -1 | sed 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"$/\1/')
        FUSION="$ACTUELS"
        for p in $MADOS_PARAMS; do
            cle="${p%%=*}"
            # Deja present (meme cle) : on ne duplique pas.
            case " $FUSION " in
                *" $cle "*|*" $cle="*) continue ;;
            esac
            FUSION="$FUSION $p"
        done
        FUSION=$(echo "$FUSION" | sed 's/^ *//; s/ *$//; s/  */ /g')
        sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${FUSION}\"|" "$GRUB_CONF"
        echo -e "    ${GRAY}├─ Paramètres noyau fusionnés : ${FUSION}${NC}"
    else
        echo "GRUB_CMDLINE_LINUX_DEFAULT=\"${MADOS_PARAMS}\"" | sudo tee -a "$GRUB_CONF" >/dev/null
    fi
    fi
fi

# 3. Application massive avec protection LVM
echo -e "    ${GRAY}├─ Reconstruction brutale de l'initramfs et du grub (${CYAN}Ceci prendra 30s...${GRAY})${NC}"
if is_dry_run; then
    log_simu "reconstruirait l'initramfs (ZSTD avec repli GZIP) et relancerait update-grub"
else
# La redirection etait executee par l utilisateur, pas par sudo (SC2024), et le
# code teste juste apres etait celui de la redirection. On passe par tee et on
# lit le statut de la VRAIE commande.
sudo update-initramfs -u -k all 2>&1 | sudo tee /tmp/initramfs_update.log >/dev/null
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo -e "    ${RED}⚠ Échec du ZSTD. Tentative de repli vers GZIP (Standard)...${NC}"
    sudo sed -i 's/^COMPRESS=zstd/COMPRESS=gzip/' "$INITRAMFS_CONF"
    sudo update-initramfs -u -k all >/dev/null 2>&1
fi
sudo update-grub >/dev/null 2>&1 || true
fi

echo -e "    ${CYAN}✅ [SUCCÈS] Boot sublimé. Au redémarrage, la seule chose que vous verrez sera le Splash Plymouth ROG instantané.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 21 Terminée.${NC}"
