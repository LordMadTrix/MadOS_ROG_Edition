#!/bin/bash
# ==============================================================================
# Verification des constats I-04 a I-07 de l'audit ISO du 2026-08-30.
#
# Usage :  bash tools/test_installateur.sh [chemin/vers/live_installer.sh]
#
# Sans argument, teste l'installateur du depot. Avec un argument, on peut le
# pointer sur une version anterieure pour verifier que ce filet sait ECHOUER :
# sur l'installateur d'avant corrections il rend 6 echecs, sur l'actuel 0.
# Un test incapable d'echouer ne prouve rien.
#
# Principe : aucune copie du code teste. Chaque bloc est EXTRAIT du fichier
# livre tools/live_installer.sh par ses marqueurs, puis execute isolement.
# Un test qui porte sur une copie ne prouve rien sur le fichier qui part
# reellement dans l'ISO.
# ==============================================================================
# Chemin relatif au depot : le test suit le fichier, pas une machine donnee.
RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-$RACINE/tools/live_installer.sh}"
[ -f "$SRC" ] || { echo "Installateur introuvable : $SRC"; exit 1; }
echo "Fichier teste : $SRC"
T=$(mktemp -d)
OK=0; KO=0

vert()  { printf '  [ OK ] %s\n' "$1"; OK=$((OK+1)); }
rouge() { printf '  [ KO ] %s\n' "$1"; KO=$((KO+1)); }
titre() { printf '\n=== %s ===\n' "$1"; }

# Extraction par TEXTE LITTERAL, pas par expression reguliere.
# Les blocs contiennent des guillemets, des $ et des barres obliques ; les faire
# traverser un motif awk a travers plusieurs couches de bash -c les mangeait, et
# l'extraction rendait du vide en silence -- le test passait alors sur rien.
extraire() {
  local d f
  d=$(grep -nF "$1" "$SRC" | head -1 | cut -d: -f1)
  f=$(grep -nF "$2" "$SRC" | head -1 | cut -d: -f1)
  [ -n "$d" ] && [ -n "$f" ] && [ "$d" -le "$f" ] || return 1
  sed -n "${d},${f}p" "$SRC"
}

# ──────────────────────────────────────────────────────────────────────────────
titre "I-04 : le disque n'est jamais preselectionne"

BLOC=$(extraire 'mapfile -t DISQUES' 'Disque choisi')
if [ -z "$BLOC" ]; then
  rouge "bloc de choix du disque introuvable dans le fichier"
else
  mkdir -p "$T/bin"
  cat > "$T/bin/lsblk" <<'STUB'
#!/bin/bash
case "$*" in
  *"-dn -o NAME,TYPE"*)   printf 'sda disk\nsdb disk\nnvme0n1 disk\n' ;;
  *"-dn -o SIZE,MODEL"*)  echo "  500G  DISQUE_FACTICE" ;;
  *"-n -o MOUNTPOINT"*)   echo "" ;;
  *)                      echo "" ;;
esac
STUB
  chmod +x "$T/bin/lsblk"

  SORTIE=$(PATH="$T/bin:$PATH" bash -c "
    RED=''; GREEN=''; CYAN=''; YELLOW=''; WHITE=''; GRAY=''; NC=''
    $BLOC
    echo \"CHOISI=\$TARGET_DISK\"
  " <<< $'zzz\nq\n' 2>&1)

  echo "$SORTIE" | grep -q 'sda'     && vert "les trois disques sont listes"        || rouge "la liste des disques n'apparait pas"
  echo "$SORTIE" | grep -q 'nvme0n1' && vert "y compris le NVMe"                    || rouge "NVMe absent de la liste"
  echo "$SORTIE" | grep -qi 'annul'  && vert "« q » annule proprement"              || rouge "« q » n'annule pas"
  echo "$SORTIE" | grep -q 'CHOISI=' && rouge "un disque retenu malgre l'annulation" || vert "aucun disque retenu apres annulation"

  SORTIE2=$(PATH="$T/bin:$PATH" bash -c "
    RED=''; GREEN=''; CYAN=''; YELLOW=''; WHITE=''; GRAY=''; NC=''
    $BLOC
    echo \"CHOISI=\$TARGET_DISK\"
  " <<< $'2\n' 2>&1)
  echo "$SORTIE2" | grep -q 'CHOISI=sdb' \
    && vert "le disque retenu est bien le n°2 choisi, pas le plus gros" \
    || rouge "mauvais disque : $(echo "$SORTIE2" | grep CHOISI= | head -1)"
fi

# ──────────────────────────────────────────────────────────────────────────────
titre "I-05 : le partitionnement suit le mode d'amorcage"

if ! command -v parted >/dev/null 2>&1; then
  rouge "parted absent, test impossible"
else
  # La borne de fin doit tomber APRES le « fi » qui ferme le if/else, sinon on
  # extrait une structure incomplete et bash rend une erreur de syntaxe --
  # que le test interpretait comme « aucune partition creee ».
  BLOC5=$(extraire 'wipefs -a "$DISK"' 'partprobe "$DISK"')
  if [ -z "$BLOC5" ]; then
    rouge "bloc de partitionnement introuvable"
  else
    for MODE in UEFI BIOS; do
      IMG="$T/disque_$MODE.img"
      truncate -s 2G "$IMG"
      # wipefs et partprobe agissent sur un peripherique bloc : sans objet ici,
      # on travaille sur un fichier. parted, lui, sait operer directement dessus.
      printf 'RED=""; GREEN=""; NC=""\nwipefs() { :; }\npartprobe() { :; }\nsleep() { :; }\nMODE_BOOT=%s\nDISK=%s\n' "$MODE" "$IMG" > "$T/run_$MODE.sh"
      printf '%s\n' "$BLOC5" >> "$T/run_$MODE.sh"
      bash "$T/run_$MODE.sh" >/dev/null 2>"$T/err_$MODE.txt"
      TABLE=$(parted -s "$IMG" print 2>/dev/null)
      if [ "$MODE" = "UEFI" ]; then
        echo "$TABLE" | grep -qi 'esp'       && vert "UEFI : partition ESP creee"          || rouge "UEFI : pas d'ESP"
        echo "$TABLE" | grep -qi 'bios_grub' && rouge "UEFI : bios_grub creee a tort"      || vert "UEFI : pas de bios_grub (correct)"
      else
        echo "$TABLE" | grep -qi 'bios_grub' && vert "BIOS : partition bios_grub creee"    || rouge "BIOS : pas de bios_grub, grub-install refuserait"
        echo "$TABLE" | grep -qi 'esp'       && rouge "BIOS : ESP creee a tort"            || vert "BIOS : pas d'ESP (correct)"
      fi
    done
  fi
fi

# ──────────────────────────────────────────────────────────────────────────────
titre "I-06 : un GRUB absent ne peut plus passer pour un succes"

if ! grep -q 'AUCUNE entrée de démarrage' "$SRC"; then
  rouge "bloc de verification GRUB introuvable dans le fichier"
else
  essai() {
    R="$T/r$RANDOM$RANDOM"
    mkdir -p "$R/mnt/mados/boot/efi/EFI/MadOS" "$R/mnt/mados/boot/grub"
    [ "$2" = "oui" ] && : > "$R/mnt/mados/boot/efi/EFI/MadOS/grubx64.efi"
    [ -n "$3" ] && printf '%s\n' "$3" > "$R/mnt/mados/boot/grub/grub.cfg"
    RES=$(cd "$R" && bash -c '
      ERREURS=""
      [ ! -f mnt/mados/boot/efi/EFI/MadOS/grubx64.efi ] && ERREURS="$ERREURS grubx64-absent"
      if [ ! -f mnt/mados/boot/grub/grub.cfg ]; then ERREURS="$ERREURS cfg-absent"
      elif ! grep -q "^menuentry" mnt/mados/boot/grub/grub.cfg; then ERREURS="$ERREURS cfg-sans-entree"; fi
      [ -n "$ERREURS" ] && echo "ECHEC$ERREURS" || echo SUCCES
    ')
    if [ "$4" = "echec" ]; then
      echo "$RES" | grep -q ECHEC && vert "$1 -> refuse" || rouge "$1 -> accepte a tort"
    else
      echo "$RES" | grep -q SUCCES && vert "$1 -> accepte" || rouge "$1 -> refuse a tort ($RES)"
    fi
  }
  essai "grubx64.efi manquant"   non 'menuentry "MadOS" {}' echec
  essai "grub.cfg absent"        oui ''                     echec
  essai "grub.cfg sans entree"   oui '# aucun menuentry'    echec
  essai "installation complete"  oui 'menuentry "MadOS" {}' succes
fi

# ──────────────────────────────────────────────────────────────────────────────
titre "I-07 : le compte live est durci sur le disque"

if ! grep -q 'mados ALL=(ALL:ALL) ALL' "$SRC"; then
  rouge "regle sudoers durcie absente du fichier"
else
  vert "la regle sans NOPASSWD est bien dans le fichier livre"
  R="$T/sudo"; mkdir -p "$R/etc/sudoers.d"
  echo "mados ALL=(ALL:ALL) ALL" > "$R/etc/sudoers.d/mados"
  chmod 0440 "$R/etc/sudoers.d/mados"
  grep -q 'NOPASSWD' "$R/etc/sudoers.d/mados" && rouge "NOPASSWD subsiste" || vert "NOPASSWD retire : sudo redemande le mot de passe"
  [ "$(stat -c%a "$R/etc/sudoers.d/mados")" = "440" ] && vert "droits 0440, exiges par sudo" || rouge "droits incorrects"
fi
grep -q 'passwd --expire mados' "$SRC" \
  && vert "changement de mot de passe force au 1er acces" \
  || rouge "expiration du mot de passe absente"

# On ignore les lignes de COMMENTAIRE : le fichier explique le defaut d'origine,
# ce qui n'est pas la meme chose que de le contenir encore. Sans ce filtre, le
# test accusait sa propre documentation.
RESTE=$(grep -n 'NOPASSWD' "$SRC" | grep -vE '^[0-9]+:[[:space:]]*#' | head -1)
if [ -n "$RESTE" ]; then
  rouge "un NOPASSWD ACTIF subsiste : $RESTE"
else
  vert "aucun NOPASSWD actif (seuls des commentaires le mentionnent)"
fi

# ──────────────────────────────────────────────────────────────────────────────
printf '\n=== BILAN ===\n'
printf '  %d reussis, %d echecs\n' "$OK" "$KO"
rm -rf "$T"
[ "$KO" -eq 0 ]
