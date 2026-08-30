#!/bin/bash
# ==============================================================================
# MadOS Hobby OS - Script de compilation et lancement (QEMU/KVM)
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
# Avant, ce fichier contenait « echo "<mot de passe>" | sudo -S » en clair, à
# deux endroits. Le même mot de passe se trouvait dans trois autres scripts, et
# de là DANS CHAQUE ISO produite : build_mados_live_iso.sh recopie tout le dépôt
# dans le chroot. Vérifié en l'extrayant d'une image déjà construite.
#
# « sudo -v » le demande une fois puis rafraîchit le ticket. La boucle de fond le
# maintient vivant : une compilation dure plus que les 15 minutes du délai sudo
# par défaut, et sans elle le script s'arrêterait au milieu.
# ------------------------------------------------------------------------------
demander_sudo() {
    [ "$(id -u)" -eq 0 ] && return 0
    if ! sudo -n true 2>/dev/null; then
        echo -e "${CYAN:-}Privilèges administrateur requis pour cette étape.${NC:-}"
        sudo -v || { echo -e "${RED:-}Élévation refusée : arrêt.${NC:-}"; exit 1; }
    fi
    ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
}
run_sudo() { sudo "$@"; }

echo -e "${CYAN}🔍 [1/4] Vérification et installation des dépendances...${NC}"

# Liste des paquets requis et de leurs commandes associées
declare -A DEPS=(
    ["nasm"]="nasm"
    ["gcc"]="gcc"
    ["ld"]="binutils"
    ["grub-mkrescue"]="grub-common"
    ["xorriso"]="xorriso"
    ["qemu-system-x86_64"]="qemu-system-x86"
)

MISSING_PACKAGES=""

# 1. Vérification des commandes système de base
for cmd in "${!DEPS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "    ${RED}✗ Outil manquant : ${cmd}${NC}"
        MISSING_PACKAGES+="${DEPS[$cmd]} "
    fi
done

# 1.5. Vérification des fichiers cibles BIOS pour GRUB (nécessaires pour générer une ISO bootable)
if [ ! -d "/usr/lib/grub/i386-pc" ]; then
    echo -e "    ${RED}✗ Cibles BIOS de GRUB (i386-pc) manquantes${NC}"
    MISSING_PACKAGES+="grub-pc-bin "
else
    echo -e "    ${GREEN}✓ Cibles BIOS de GRUB présentes${NC}"
fi

# 2. Vérification spécifique du support de compilation 32 bits (multilib)
if command -v gcc &>/dev/null; then
    if ! gcc -m32 -v &>/dev/null; then
        echo -e "    ${RED}✗ Support de compilation 32-bit (multilib) manquant pour GCC${NC}"
        MISSING_PACKAGES+="gcc-multilib libc6-dev-i386 "
    else
        echo -e "    ${GREEN}✓ Support de compilation 32-bit GCC opérationnel${NC}"
    fi
fi

# 3. Installation des paquets manquants
if [ -n "$MISSING_PACKAGES" ]; then
    echo -e "\n${YELLOW}⚠ Dépendances manquantes détectées : $MISSING_PACKAGES${NC}"
    echo -e "${CYAN}📥 Installation des paquets requis via apt...${NC}"
    demander_sudo
    run_sudo apt-get update -qq
    run_sudo apt-get install -y $MISSING_PACKAGES
    
    # Re-vérification de validation finale
    echo -e "\n${CYAN}🔄 Double vérification post-installation...${NC}"
    for cmd in "${!DEPS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "    ${RED}✗ Erreur critique : $cmd est toujours manquant après l'installation.${NC}"
            exit 1
        fi
    done
    echo -e "    ${GREEN}✓ Toutes les dépendances sont maintenant installées et prêtes !${NC}\n"
else
    echo -e "    ${GREEN}✓ Toutes les dépendances sont validées. Prêt à compiler.${NC}\n"
fi

echo -e "${CYAN}🔨 [2/4] Compilation du noyau et de l'assembleur...${NC}"
# Compilation de boot.asm en ELF 32 bits
nasm -f elf32 src/boot.asm -o src/boot.o

# Compilation des pilotes en ELF 32 bits freestanding (sans bibliothèque standard)
gcc -m32 -c src/kernel.c -o src/kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/gdt.c -o src/gdt.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/idt.c -o src/idt.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra -mgeneral-regs-only
gcc -m32 -c src/msr.c -o src/msr.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/asus_ec.c -o src/asus_ec.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/mem.c -o src/mem.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/pit.c -o src/pit.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/pci.c -o src/pci.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/rtc.c -o src/rtc.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/task.c -o src/task.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/vfs.c -o src/vfs.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/sound.c -o src/sound.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/gui.c -o src/gui.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/mouse.c -o src/mouse.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

# Édition de liens du noyau complet
ld -m elf_i386 -T src/linker.ld -o iso/boot/mados_kernel.bin src/boot.o src/kernel.o src/gdt.o src/idt.o src/msr.o src/asus_ec.o src/mem.o src/pit.o src/pci.o src/rtc.o src/task.o src/vfs.o src/sound.o src/gui.o src/mouse.o

# Vérifier si le fichier binaire est compatible Multiboot
if grub-file --is-x86-multiboot iso/boot/mados_kernel.bin; then
    echo -e "    ${GREEN}✓ Fichier binaire compatible Multiboot confirmé !${NC}"
else
    echo -e "    ${RED}✗ Erreur : Le fichier binaire n'est pas conforme à la norme Multiboot.${NC}"
    exit 1
fi

echo -e "${CYAN}🔨 [3/4] Création de l'image ISO bootable (MadOS.iso)...${NC}"
mkdir -p iso/boot/grub
grub-mkrescue -o MadOS.iso iso

echo -e "${GREEN}✅ ISO générée avec succès : MadOS.iso${NC}"

# Demande ou exécution de QEMU
echo -e "${CYAN}🚀 [4/4] Lancement de MadOS dans QEMU...${NC}"
if command -v qemu-system-x86_64 &>/dev/null; then
    qemu-system-x86_64 -cdrom MadOS.iso -m 256 -rtc base=localtime -device intel-hda -device hda-duplex
else
    echo -e "    ${YELLOW}QEMU non trouvé. Vous pouvez tester l'ISO 'MadOS.iso' sur votre émulateur préféré.${NC}"
fi
