#!/bin/bash
# ==========================================
# MadOS ROG V3 - ISO Builder (Oracular Oriole)
# ==========================================
# ATTENTION: Doit être exécuté sur un OS Linux natif ou VM (Ubuntu 24.04+)
# avec les droits root (sudo).
# L'ISO finale contiendra nativement KDE Plasma 6 et les modules MadOS V3.
# ==========================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo -e "\n\e[31m[Erreur] Ce script d'assemblage d'ISO doit être exécuté en root (sudo).\e[0m"
  exit 1
fi

ISO_URL="https://releases.ubuntu.com/24.10/ubuntu-24.10-desktop-amd64.iso"
ISO_NAME="ubuntu-24.10-desktop-amd64.iso"
WORK_DIR="work"
ISO_EXTRACT="$WORK_DIR/iso"
SQUASHFS_EXTRACT="$WORK_DIR/squashfs"
CHROOT_SCRIPT="chroot_scripts/00_chroot_install.sh"
OUTPUT_ISO="MadOS-ROG-V3-Plasma6-amd64.iso"

echo -e "\e[31m>>> \e[37m[MADOS ISO BUILDER] \e[1mInitialisation de la Forge de l'ISO V3...\e[0m"

# 1. Installer les dépendances système de la machine hôte
echo -e "\n>>> [1/5] Installation des outils de construction ISO sur la machine hôte..."
apt update && DEBIAN_FRONTEND=noninteractive apt install -y squashfs-tools xorriso mtools fdisk wget curl rsync sudo

# 2. Téléchargement de l'ISO Oracular
echo -e "\n>>> [2/5] Récupération de l'image de base Ubuntu 24.10 (pour KDE Plasma 6)..."
if [ ! -f "$ISO_NAME" ]; then
    wget --progress=bar:force:noscroll -O "$ISO_NAME" "$ISO_URL"
else
    echo ">>> L'ISO officielle $ISO_NAME est déjà présente en cache."
fi

# Préparation dossiers
umount "$WORK_DIR/mnt" 2>/dev/null || true
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/mnt" "$ISO_EXTRACT"

# 3. Extraction de l'ISO et du noyau d'installation Squashfs
echo -e "\n>>> [3/5] Extraction du système de fichiers en lecture seule (squashfs)..."
mount -o loop "$ISO_NAME" "$WORK_DIR/mnt"
echo ">>> Copie des fichiers de boot de l'ISO..."
rsync -a "$WORK_DIR/mnt/" "$ISO_EXTRACT/"
umount "$WORK_DIR/mnt"

echo ">>> Démontage de la matrice système (Unsquashfs) - Cette étape prend 1 à 3 minutes..."
unsquashfs -d "$SQUASHFS_EXTRACT" "$ISO_EXTRACT/casper/filesystem.squashfs"

# 4. Injection de MadOS et Exécution du système CHROOT (Matrice Mère)
echo -e "\n>>> [4/5] Injection du Framework MadOS dans l'ISO..."
# Copier le framework complet MadOS (situé dans le répertoire parent)
mkdir -p "$SQUASHFS_EXTRACT/tmp/mados_src"
# Utilisation de rsync pour ignorer MadOS_ISO_Builder afin d'éviter une boucle infinie
rsync -a --exclude="MadOS_ISO_Builder" ../ "$SQUASHFS_EXTRACT/tmp/mados_src/"

# Copier le script d'installation CHROOT spécifique
cp "$CHROOT_SCRIPT" "$SQUASHFS_EXTRACT/tmp/00_chroot_install.sh"
chmod +x "$SQUASHFS_EXTRACT/tmp/00_chroot_install.sh"

echo ">>> Préparation des points de montage critiques virtuels..."
mount --bind /dev "$SQUASHFS_EXTRACT/dev"
mount -t proc /proc "$SQUASHFS_EXTRACT/proc"
mount -t sysfs /sys "$SQUASHFS_EXTRACT/sys"
mount --bind /run "$SQUASHFS_EXTRACT/run"

# Injection du DNS de l'hôte pour avoir internet dans le Chroot
cp /etc/resolv.conf "$SQUASHFS_EXTRACT/etc/resolv.conf"

echo -e "\n\e[32m=============== [ DÉBUT DU CYCLE CHROOT INTERNE ] ===============\e[0m"
# Exécuter l'installation silencieuse à l'intérieur de l'ISO
chroot "$SQUASHFS_EXTRACT" /bin/bash -c "/tmp/00_chroot_install.sh"
echo -e "\e[32m================ [ FIN DU CYCLE CHROOT INTERNE ] ================\e[0m\n"

echo ">>> Nettoyage de l'empreinte de construction (Post-Chroot)..."
rm -f "$SQUASHFS_EXTRACT/etc/resolv.conf"
rm -rf "$SQUASHFS_EXTRACT/tmp/mados_src"
rm -f "$SQUASHFS_EXTRACT/tmp/00_chroot_install.sh"

# Nettoyage des historiques internes
chroot "$SQUASHFS_EXTRACT" /bin/bash -c "apt-get clean && rm -rf /tmp/* /var/tmp/* /var/cache/apt/archives/*"

echo ">>> Démontage sécurisé des liens noyaux virtuels..."
umount "$SQUASHFS_EXTRACT/run"
umount "$SQUASHFS_EXTRACT/sys"
umount "$SQUASHFS_EXTRACT/proc"
umount "$SQUASHFS_EXTRACT/dev"

# 5. Repacking de l'ISO
echo -e "\n>>> [5/5] Re-compression du système (Squashfs) - Soyez patient, cela utilise 100% de votre CPU..."
rm -f "$ISO_EXTRACT/casper/filesystem.squashfs"
mksquashfs "$SQUASHFS_EXTRACT" "$ISO_EXTRACT/casper/filesystem.squashfs" -comp xz -b 1048576 -Xdict-size 100%

# Mise à jour de la taille dans l'ISO (Indispensable pour Ubiquity/Subiquity)
printf $(du -sx --block-size=1 "$SQUASHFS_EXTRACT" | cut -f1) > "$ISO_EXTRACT/casper/filesystem.size"

echo ">>> Génération de l'intégrité (md5sum)..."
cd "$ISO_EXTRACT"
find . -type f -print0 | xargs -0 md5sum > md5sum.txt
cd - > /dev/null

echo -e "\n>>> Forgage de l'image ISO Finale hybride (MBR/EFI) via Xorriso..."
# Extraire les 432 premiers octets (MBR) de l'ISO originale pour que la nôtre boot aussi en mode Legacy BIOS
dd if="$ISO_NAME" bs=1 count=432 of="$WORK_DIR/isohdpfx.bin" 2>/dev/null || true

xorriso -as mkisofs \
  -r -V "MADOS_ROG_V3" \
  -J -l -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  -isohybrid-mbr "$WORK_DIR/isohdpfx.bin" \
  -o "../$OUTPUT_ISO" \
  "$ISO_EXTRACT"

chmod 777 "../$OUTPUT_ISO"
echo -e "\n\e[32m✅ [SUCCÈS RÉSECONSTITUÉ] : L'ISO MadOS V3 a été générée avec succès : $OUTPUT_ISO\e[0m"
echo -e "L'Image fait environ $(du -h "../$OUTPUT_ISO" | cut -f1). Vous pouvez la flasher sur USB via Ventoy ou Rufus."
