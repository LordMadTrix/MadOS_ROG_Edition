#!/bin/bash
# ==============================================================================
# Chaque reglage de lib/config.conf doit PILOTER quelque chose.
#
# Usage :  bash tools/test_config.sh [chemin/vers/config.conf]
#
# Pourquoi ce test existe : le fichier declarait 58 reglages dont 48 que
# personne ne lisait. Changer DNS_PRIMARY, XANMOD_FLAVOR ou REQUIRED_RAM
# n'avait aucun effet, et rien ne le signalait. Un bouton qui ne fait rien est
# pire qu'un bouton absent : on croit s'en etre servi.
#
# Ce filet echoue des qu'un reglage cesse d'etre lu -- que ce soit parce qu'on
# vient d'en ajouter un « pour plus tard », ou parce qu'un refactoring a
# supprime le seul endroit qui s'en servait.
#
# Pour verifier qu'il sait echouer, pointez-le sur une version anterieure :
#   git show <ancien-commit>:lib/config.conf > /tmp/vieux.conf
#   bash tools/test_config.sh /tmp/vieux.conf
# ==============================================================================
set -uo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF="${1:-$RACINE/lib/config.conf}"

if [ ! -f "$CONF" ]; then
    echo "Fichier de configuration introuvable : $CONF" >&2
    exit 1
fi

echo "Fichier verifie : $CONF"
echo ""

# Ou chercher les lectures. On exclut le fichier de config lui-meme : une
# variable qui ne sert qu'a en definir une autre reste inerte pour l'utilisateur.
consommateurs() {
    find "$RACINE" -maxdepth 2 -name '*.sh' \
        -not -path '*/.git/*' \
        -not -name 'test_config.sh' 2>/dev/null
}

INERTES=()
ACTIFS=0

while IFS= read -r nom; do
    [ -n "$nom" ] || continue
    if consommateurs | xargs grep -l -- "\$$nom\|\${$nom" 2>/dev/null | head -1 | grep -q .; then
        ACTIFS=$((ACTIFS + 1))
    else
        INERTES+=("$nom")
    fi
done < <(grep -oE '^[A-Z_]+' "$CONF" | sort -u)

echo "  reglages actifs  : $ACTIFS"
echo "  reglages inertes : ${#INERTES[@]}"
echo ""

if [ "${#INERTES[@]}" -gt 0 ]; then
    echo "ECHEC : ces reglages ne pilotent rien."
    echo ""
    for v in "${INERTES[@]}"; do
        ligne=$(grep -nE "^$v=" "$CONF" | head -1 | cut -d: -f1)
        printf '  ligne %-5s %s\n' "${ligne:-?}" "$v"
    done
    echo ""
    echo "Deux issues, jamais une troisieme :"
    echo "  - le cabler la ou il devrait agir ;"
    echo "  - le retirer, et expliquer en commentaire ce qui est fige et pourquoi."
    echo ""
    echo "Le laisser « pour plus tard » est ce qui a produit 48 boutons morts."
    exit 1
fi

echo "OK : les $ACTIFS reglages declares sont tous lus par le code."
exit 0
