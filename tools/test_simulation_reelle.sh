#!/bin/bash
# =============================================================================
# Test de simulation REELLE : on execute les 40 modules et on mesure ce qu'ils
# ecrivent, au lieu de relire leur code.
#
# POURQUOI CET OUTIL EXISTE
# -------------------------
# tools/test_simulation.sh analyse le code sans l'executer. Il est utile mais
# il a un angle mort par construction : il ne voit que les motifs qu'on lui a
# appris. Il a longtemps annonce « 0 module fautif » alors que
# hyperviseur_drivers.sh ecrivait pour de vrai dans /etc/default/grub en mode
# --dry-run, via « sudo bash -c '...' » -- une forme qu'il ne surveillait pas.
#
# Ce test-ci ne peut pas avoir cet angle mort : il execute et il constate.
#
# COMMENT L'EXECUTION RESTE SANS DANGER
# -------------------------------------
# Les modules tournent dans un espace de noms de montage prive ou /etc, /usr,
# /var... sont recouverts d'un overlayfs. Ils croient ecrire sur le systeme ;
# tout atterrit dans une couche jetable. Cette couche est aussi LA MESURE :
# ce qu'elle contient est exactement ce que la simulation a ecrit.
#
# DEUX PIEGES, DEJA PAYES
# -----------------------
#  - overlayfs recopie un fichier des qu'il est OUVERT en ecriture, meme sans
#    modification. Sans comparaison de contenu, une ouverture sans effet
#    passerait pour une ecriture. D'ou le bind de reference pose AVANT.
#  - la couche ne survit pas a la fermeture de l'espace de noms. Le rapport est
#    donc rendu DEDANS.
#
# LIMITE ASSUMEE : /sys, /proc et /dev ne supportent pas overlayfs et ne sont
# donc pas mesures. Le total rendu est un MINORANT. L'analyseur statique reste
# necessaire pour ces cas-la : les deux outils se completent, aucun ne remplace
# l'autre.
#
# Usage :  sudo bash tools/test_simulation_reelle.sh
# =============================================================================
set -u

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="/tmp/mados_simu_reelle"
ORIG="/tmp/mados_simu_orig"
CIBLES="etc usr opt var boot srv root home"

# ---- Conditions d'execution -------------------------------------------------
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "IGNORE : ce test doit tourner en root (l'isolation exige des montages)."
    echo "         Relancez :  sudo bash tools/test_simulation_reelle.sh"
    exit 0
fi
if ! grep -qw overlay /proc/filesystems; then
    echo "IGNORE : ce noyau ne fournit pas overlayfs, l'isolation est impossible."
    exit 0
fi
if ! command -v unshare >/dev/null 2>&1; then
    echo "IGNORE : « unshare » absent (paquet util-linux)."
    exit 0
fi

# ---- On se relance a l'interieur d'un espace de noms prive ------------------
if [ "${MADOS_DANS_ESPACE:-non}" != "oui" ]; then
    export MADOS_DANS_ESPACE=oui
    exec unshare --mount --pid --fork --mount-proc bash "${BASH_SOURCE[0]}" "$@"
fi

# =============================================================================
# A partir d'ici, on est isole : les montages ne sortent pas d'ici.
# =============================================================================
rm -rf "$BASE"; mkdir -p "$BASE" "$ORIG"
mount --make-rprivate / 2>/dev/null
mount --bind / "$ORIG" 2>/dev/null

for d in $CIBLES; do
    [ -d "/$d" ] || continue
    mkdir -p "$BASE/$d/up" "$BASE/$d/wk"
    if ! mount -t overlay "ovl_$d" \
         -o "lowerdir=/$d,upperdir=$BASE/$d/up,workdir=$BASE/$d/wk" "/$d" 2>"$BASE/err_$d"; then
        # Un montage refuse dit que L'ENVIRONNEMENT ne convient pas, pas que le
        # code est fautif. Confondre les deux ferait echouer l'integration
        # continue pour une mauvaise raison. On s'abstient, bruyamment : le
        # mot IGNORE est repere par le workflow, qui emet un avertissement.
        echo "IGNORE : overlayfs refuse de recouvrir /$d dans cet environnement."
        cat "$BASE/err_$d"
        exit 0
    fi
done

ecritures() {
    for d in $CIBLES; do
        [ -d "$BASE/$d/up" ] || continue
        find "$BASE/$d/up" -mindepth 1 -type f 2>/dev/null | sed "s|$BASE/$d/up|/$d|"
    done
}

# ---- Le harnais se valide AVANT de rendre le moindre verdict ---------------
# Un « rien n'a ete ecrit » venant d'une mesure aveugle ne vaut rien : il
# signifierait seulement que la mesure ne mesure pas.
TEMOIN="/etc/mados_temoin_$$.txt"
echo temoin > "$TEMOIN"
if [ ! -f "$TEMOIN" ] || ! ecritures | grep -q "mados_temoin_$$" || [ -f "$ORIG$TEMOIN" ]; then
    echo "ECHEC : le harnais ne mesure pas correctement. Aucun verdict rendu."
    exit 2
fi
rm -f "$TEMOIN"
echo "Harnais valide (ecriture captee, original intact)."
echo ""

# ---- Execution --------------------------------------------------------------
export DRY_RUN=yes
export DEBIAN_FRONTEND=noninteractive
export PROJECT_ROOT="$RACINE"
export MADOS_LOG_DIR="$BASE/logs"; mkdir -p "$BASE/logs"

# whiptail attendrait une touche indefiniment.
mkdir -p "$BASE/bin"
printf '#!/bin/bash\nexit 1\n' > "$BASE/bin/whiptail"
chmod +x "$BASE/bin/whiptail"
export PATH="$BASE/bin:$PATH"

OK=0; ECHEC=0; EXPIRE=0
printf '  %-36s %-9s %-7s %s\n' "MODULE" "SORTIE" "DUREE" "TOUCHES"
printf '  %s\n' "----------------------------------------------------------------"

for m in "$RACINE"/modules/*.sh; do
    [ -e "$m" ] || continue
    nom=$(basename "$m")
    avant=$(ecritures | wc -l)
    debut=$(date +%s)
    timeout 90 bash "$m" </dev/null >"$BASE/logs/$nom.out" 2>&1
    code=$?
    duree=$(( $(date +%s) - debut ))
    delta=$(( $(ecritures | wc -l) - avant ))

    if   [ "$code" -eq 124 ]; then etat="EXPIRE";     EXPIRE=$((EXPIRE+1))
    elif [ "$code" -eq 0 ];   then etat="ok";         OK=$((OK+1))
    else                           etat="code $code"; ECHEC=$((ECHEC+1)); fi

    [ "$delta" -gt 0 ] && marque="$delta" || marque="-"
    printf '  %-36s %-9s %-7s %s\n' "$nom" "$etat" "${duree}s" "$marque"
done

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# install.sh lui-meme, lance SEUL et en simulation.
#
# Les modules ci-dessus ne couvrent pas install.sh, et l'analyse statique ne
# peut pas le couvrir non plus : elle modelise des scripts lineaires, pas un
# gros script a fonctions ou un « exit 0 » dans une garde serait pris pour une
# sortie de fichier et masquerait tout le reste.
#
# Ce cas-ci comble le trou. Lance sans lib/ ni modules/, install.sh declenche
# son amorcage : avant correction, il effacait recursivement /opt/mados_src,
# installait git et clonait le depot -- POUR DE VRAI, malgre --dry-run.
# ─────────────────────────────────────────────────────────────────────────────
avant_install=$(ecritures | wc -l)
mkdir -p "$BASE/seul"
cp "$RACINE/install.sh" "$BASE/seul/" 2>/dev/null
if [ -f "$BASE/seul/install.sh" ]; then
    ( cd "$BASE/seul" && timeout 60 bash install.sh --dry-run </dev/null )         > "$BASE/logs/install_seul.out" 2>&1
    code_install=$?
    delta_install=$(( $(ecritures | wc -l) - avant_install ))
    printf '  %-36s %-9s %-7s %s
' "install.sh (lance seul)"            "$([ "$code_install" -eq 0 ] && echo ok || echo "code $code_install")"            "-" "$([ "$delta_install" -gt 0 ] && echo "$delta_install" || echo "-")"
    if [ "$delta_install" -gt 0 ]; then
        ECHEC=$((ECHEC + 1))
    fi
else
    echo "  install.sh introuvable, cas non execute"
fi
echo ""

echo "  modules reussis  : $OK"
echo "  modules en echec : $ECHEC"
echo "  modules expires  : $EXPIRE"
echo ""

# ---- Verdict ----------------------------------------------------------------
reels=0; recopies=0; journaux=0; caches=0
echo "  Fichiers captes, contenu compare a l'original :"
while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
        */log/*|*.log|*/logs/*) journaux=$((journaux+1)); printf '    [journal] %s\n' "$f"; continue ;;
        /var/cache/apt/*)
            # APT reconstruit pkgcache.bin et srcpkgcache.bin des qu une commande
            # LIT les listes de paquets, sans rien installer. Ce n est pas une
            # modification du systeme : c est un cache derive, reconstructible.
            #
            # Constate sur un serveur d integration continue, dont le cache etait
            # perime. La machine de developpement, cache a jour, ne montrait rien :
            # le test passait chez moi et echouait ailleurs, pour du bruit.
            #
            # L exclusion s arrete la. /var/lib/apt/lists/ n est PAS exclu : ces
            # fichiers ne changent que sur « apt-get update », une vraie action
            # reseau, qui doit rester bloquante.
            caches=$((caches+1))
            printf '    [cache  ] %s (regenere par apt en lecture)
' "$f"
            continue ;;
    esac
    if [ -f "$ORIG$f" ] && cmp -s "$f" "$ORIG$f"; then
        recopies=$((recopies+1)); printf '    [recopie] %s (contenu inchange)\n' "$f"
    else
        reels=$((reels+1));       printf '    [MODIFIE] %s\n' "$f"
    fi
done <<< "$(ecritures)"
[ "$journaux" -eq 0 ] && [ "$recopies" -eq 0 ] && [ "$reels" -eq 0 ] && [ "$caches" -eq 0 ] && echo "    (aucun)"

echo ""
echo "  journaux (attendus)   : $journaux"
echo "  caches apt regeneres  : $caches"
echo "  recopies sans effet   : $recopies"
echo "  MODIFICATIONS REELLES : $reels"
echo ""
echo "  (non mesures : /sys, /proc, /dev -- overlayfs ne s'y applique pas)"
echo ""

if [ "$reels" -gt 0 ] || [ "$ECHEC" -gt 0 ] || [ "$EXPIRE" -gt 0 ]; then
    echo "ECHEC : la simulation ne tient pas sa promesse, ou un module a echoue."
    exit 1
fi
echo "OK : les $OK modules s'executent en simulation sans modifier le systeme."
exit 0
