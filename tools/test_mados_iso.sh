#!/bin/bash
# ==============================================================================
# MadOS 4.0 - Test de l'ISO personnalisée sous QEMU
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

ISO_PATH="MadOS_ROG_Edition_v4.iso"

if [ ! -f "$ISO_PATH" ]; then
    echo -e "${RED}✗ L'ISO $ISO_PATH n'existe pas. Veuillez lancer 'tools/build_mados_live_iso.sh' d'abord.${NC}"
    exit 1
fi

# Détection dynamique de l'accélération matérielle KVM
QEMU_ARGS=""
if [ -w /dev/kvm ]; then
    echo -e "${CYAN}ℹ Accélération matérielle KVM activée.${NC}"
    QEMU_ARGS="-enable-kvm -cpu host"
else
    echo -e "${YELLOW}⚠ Droits KVM manquants sur /dev/kvm. Utilisation de l'émulation logicielle (plus lente)...${NC}"
    QEMU_ARGS="-cpu qemu64"
fi

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# NETTOYAGE AUTOMATIQUE
#
# Chaque essai laissait derriere lui sa machine QEMU. A force de relancer, on
# se retrouvait avec plusieurs machines vivantes en meme temps, se disputant le
# meme disque de test et mangeant 4 Go de memoire chacune.
#
# On cible par NOM EXACT de processus (pgrep -x), jamais par ligne de commande
# (pgrep -f). Un motif comme « MadOS_ROG_Edition_v4.iso » correspond aussi a la
# ligne de commande du shell qui l'invoque : le script se tuait alors lui-meme.
# Deja constate en pratique, pas une precaution theorique.
# ------------------------------------------------------------------------------
nettoyer_qemu() {
    local restants
    restants=$(pgrep -x qemu-system-x86_64 2>/dev/null | tr '
' ' ')
    [ -z "$restants" ] && return 0
    echo -e "${YELLOW}Arret des machines QEMU encore en vie : $restants${NC}"
    pkill -x qemu-system-x86_64 2>/dev/null || true
    sleep 1
    # Celles qui resistent au signal poli.
    pkill -9 -x qemu-system-x86_64 2>/dev/null || true
}

# Au demarrage : on part d'une machine propre.
nettoyer_qemu

# A la sortie : on ne laisse rien derriere, y compris apres un Ctrl+C.
trap nettoyer_qemu EXIT INT TERM

# ------------------------------------------------------------------------------
# DISQUE VIERGE
#
# Le disque de test garde ses partitions d'un essai a l'autre : c'est voulu, il
# faut pouvoir redemarrer sur un systeme fraichement installe pour verifier
# qu'il demarre. Repartir de zero se demande donc explicitement -- effacer par
# defaut ferait perdre le seul resultat qui compte apres une installation.
#
#   DISQUE_NEUF=oui bash tools/test_mados_iso.sh
# ------------------------------------------------------------------------------
if [ "${DISQUE_NEUF:-non}" = "oui" ]; then
    if [ -f "${DISQUE_TEST:-mados_test_disk.qcow2}" ]; then
        echo -e "${YELLOW}Disque de test remis a neuf (contenu precedent perdu).${NC}"
        rm -f "${DISQUE_TEST:-mados_test_disk.qcow2}"
    fi
fi

# DISQUE CIBLE
#
# Sans disque dur virtuel, la machine n'exposait que le lecteur de disquette que
# QEMU cree par defaut. lsblk le classe comme « disk », et l'installateur le
# proposait donc comme cible : « fd0  4K disk ». On ne pouvait pas tester
# l'installation du tout -- constate en lancant l'ISO pour de vrai, pas en
# relisant le script.
#
# Le fichier qcow2 est creux : il n'occupe sur le disque que ce qui y est
# reellement ecrit, quelle que soit la taille annoncee.
# ------------------------------------------------------------------------------
DISQUE_TEST="${DISQUE_TEST:-mados_test_disk.qcow2}"
TAILLE_DISQUE="${TAILLE_DISQUE:-40G}"

if [ ! -f "$DISQUE_TEST" ]; then
    echo -e "${CYAN}Creation du disque de test ($TAILLE_DISQUE, fichier creux)...${NC}"
    if ! qemu-img create -f qcow2 "$DISQUE_TEST" "$TAILLE_DISQUE" >/dev/null; then
        echo -e "${YELLOW}Disque impossible a creer : la machine demarrera sans cible.${NC}"
        DISQUE_TEST=""
    fi
fi

QEMU_DISQUE=""
if [ -n "$DISQUE_TEST" ] && [ -f "$DISQUE_TEST" ]; then
    QEMU_DISQUE="-drive file=$DISQUE_TEST,format=qcow2,if=virtio"
    TAILLE=$(qemu-img info "$DISQUE_TEST" 2>/dev/null | grep "virtual size" | cut -d: -f2 | xargs)
    echo -e "${CYAN}Disque cible : $DISQUE_TEST ($TAILLE)${NC}"
fi

echo -e "${GREEN}🚀 Lancement de MadOS ROG Edition (ISO) sous QEMU...${NC}"
# shellcheck disable=SC2086
qemu-system-x86_64 \
    $QEMU_ARGS \
    -m 4096 \
    -smp 2 \
    -cdrom "$ISO_PATH" \
    $QEMU_DISQUE \
    -boot d \
    -vga std \
    -display gtk \
    -device intel-hda \
    -device hda-duplex \
    -usb \
    -device usb-tablet
