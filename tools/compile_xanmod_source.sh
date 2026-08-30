#!/bin/bash
# ==============================================================================
# MadOS 4.0 - XanMod Kernel Source Compiler
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

KERNEL_DIR="/tmp/xanmod_kernel_source"
BRANCH="6.11"

echo -e "${CYAN}🚀 [1/4] Installation des dependances de compilation du noyau...${NC}"
run_sudo apt-get update -qq
run_sudo apt-get install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev bc git wget rsync -qq

echo -e "${CYAN}🚀 [2/4] Clonage rapide des sources XanMod (${BRANCH})...${NC}"
run_sudo rm -rf "$KERNEL_DIR"
run_sudo mkdir -p "$KERNEL_DIR"
run_sudo chown -R $USER:$USER "$KERNEL_DIR"

git clone --depth 1 -b "$BRANCH" https://github.com/xanmod/linux.git "$KERNEL_DIR"

cd "$KERNEL_DIR"

echo -e "${CYAN}🚀 [3/4] Initialisation de la configuration par defaut...${NC}"
# Utilise la configuration standard du noyau Linux optimisée
make defconfig

# Désactivation des warnings traités comme erreurs
sed -i 's/CONFIG_WERROR=y/CONFIG_WERROR=n/g' .config
echo "CONFIG_WERROR=n" >> .config

# Configuration requise pour le démarrage Live (OverlayFS et SquashFS avec support XZ)
echo "CONFIG_OVERLAY_FS=y" >> .config
echo "CONFIG_SQUASHFS=y" >> .config
echo "CONFIG_SQUASHFS_XZ=y" >> .config
echo "CONFIG_SQUASHFS_ZLIB=y" >> .config
make olddefconfig

# Patch drivers/firmware/efi/libstub/Makefile pour ajouter -std=gnu11 pour compatibilité GCC 15 (C23)
sed -i 's|KBUILD_CFLAGS\t\t\t:=|KBUILD_CFLAGS\t\t\t:= -std=gnu11 |g' drivers/firmware/efi/libstub/Makefile

# Patch arch/x86/boot Makefiles pour ajouter -std=gnu11 pour compatibilité GCC 15 (C23)
sed -i 's|KBUILD_CFLAGS := -m|KBUILD_CFLAGS := -std=gnu11 -m|g' arch/x86/boot/compressed/Makefile
sed -i 's|KBUILD_CFLAGS\t:= $(REALMODE_CFLAGS)|KBUILD_CFLAGS\t:= -std=gnu11 $(REALMODE_CFLAGS)|g' arch/x86/boot/Makefile


# Configuration du niveau d'optimisation XanMod dans la config
# (On s'assure d'activer l'ordonnanceur BORE ou d'autres configurations si nécessaires)
echo "CONFIG_LOCALVERSION=\"-mados-xanmod\"" >> .config

echo -e "${CYAN}🚀 [4/4] Lancement de la compilation du noyau (bzImage)...${NC}"
echo -e "${YELLOW}Cette etape peut prendre entre 10 et 30 minutes selon votre processeur...${NC}"

make -j$(nproc) WERROR=0 bzImage

if [ -f "arch/x86/boot/bzImage" ]; then
    echo -e "${GREEN}✅ Noyau XanMod compile avec succes !${NC}"
    echo -e "${GREEN}L'image noyau est disponible ici : $KERNEL_DIR/arch/x86/boot/bzImage${NC}"
else
    echo -e "${RED}✗ La compilation a echoue, le fichier binaire bzImage n'a pas ete genere.${NC}"
    exit 1
fi
