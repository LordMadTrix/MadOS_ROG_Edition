#!/bin/bash
# ==============================================================================
# Le mode simulation ne doit RIEN ecrire, dans aucun module.
#
# Usage :  bash tools/test_simulation.sh [dossier/des/modules]
#
# install.sh --dry-run promet d'afficher ce qui serait fait sans y toucher.
# Cette promesse repose sur une discipline : toute action qui modifie la machine
# passe par run_action(), ou vit dans la branche « reelle » d'un garde
# is_dry_run. Rien ne verifiait cette discipline.
#
# Ce que ce filet cherche : un sudo qui MODIFIE la machine et qu'aucun garde ne
# protege. Les sudo de LECTURE (dmidecode, command -v, cat) sont ignores : ils
# sont sans effet en simulation.
#
# ------------------------------------------------------------------------------
# QUATRE PIEGES, appris en se trompant quatre fois sur ce meme fichier :
#
#   1. Imbrication. Empiler seulement sur « if is_dry_run » mais depiler sur
#      n'importe quel « fi » desynchronise tout des le premier if interne.
#      -> on suit TOUTES les structures if/fi.
#
#   2. « elif » apres un garde. Dans
#         if is_dry_run; then log_simu; elif command -v x; then <action>
#      l'action est PROTEGEE : on n'atteint le elif que si la simulation est
#      inactive. La traiter comme non gardee inventait des dizaines de faux cas.
#
#   3. Garde porte par un « elif ». Dans
#         if [ -z "$X" ]; then ...; elif is_dry_run; then log_simu; else <action>
#      le garde n'est pas sur la ligne « if ». Il faut le detecter la aussi.
#
#   4. Commentaires, alias et messages. « echo "lance sudo apt ..." » n'execute
#      rien. Les compter donnait des alertes sur de la documentation.
#
# L'analyseur est VALIDE sur des cas temoins avant chaque execution : s'il ne
# sait plus distinguer un cas protege d'un cas nu, il s'arrete au lieu de rendre
# un verdict auquel on ne peut pas se fier.
# ==============================================================================
set -uo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOSSIER="${1:-$RACINE/modules}"

MODIFIE='(apt|apt-get|dpkg|snap|systemctl|rm|cp|mv|mkdir|tee|ln|chmod|chown|update-initramfs|update-grub|grub-install|make|install|usermod|useradd|modprobe|swapon|mkswap|mkfs|parted|wipefs|timeshift|add-apt-repository|dracut|sysctl|nmcli|ufw|gsettings|killall|pkill|convert|magick)'

analyser() {
    awk -v modifie="$MODIFIE" '
    {
        d = $0
        sub(/^[ \t]+/, "", d)

        if (d ~ /^if[ \t]/ || d == "if") {
            prof++; garde[prof] = (d ~ /is_dry_run/) ? 1 : 0; reelle[prof] = 0
        } else if (d ~ /^elif[ \t]/ && prof > 0) {
            if (garde[prof]) {
                reelle[prof] = 1
            } else if (d ~ /is_dry_run/) {
                garde[prof] = 1; reelle[prof] = 0
            }
        } else if (d == "else" && prof > 0) {
            if (garde[prof]) reelle[prof] = 1
        } else if (d == "fi" && prof > 0) {
            # Piege 5 : sortie anticipee. Un garde is_dry_run qui se termine par
            # exit rend TOUT le reste du fichier inatteignable en simulation.
            # Sans ce cas, le module de mise a jour etait signale pour 4 actions
            # devenues hors de portee. (Pas d apostrophe dans ce bloc : il vit
            # dans une chaine awk entre apostrophes simples, une seule la fermerait.)
            if (garde[prof] && sortie[prof]) sorti_tot = 1
            prof--; next
        }

        if (prof > 0 && garde[prof] && !reelle[prof] && d ~ /^(exit|return)([ \t]|$)/)
            sortie[prof] = 1

        if (sorti_tot) next

        if (d ~ /^#/) next
        if (d ~ /^alias[ \t]/) next
        if (d ~ /echo[ \t]+-?e?[ \t]*"[^"]*sudo/) next
        if (d ~ /run_action|run_command_retry/) next

        protege = 0
        for (k = 1; k <= prof; k++) if (garde[k] && reelle[k]) protege = 1
        if (protege) next

        if (d ~ ("sudo[ \t]+(-u[ \t]+[^ \t]+[ \t]+)?" modifie "([ \t]|$)"))
            printf "%d|%s\n", NR, substr(d, 1, 72)
    }' "$1"
}

# ---- Validation de l'analyseur, AVANT tout verdict -------------------------
T=$(mktemp -d)
printf 'if is_dry_run; then\n    log_simu "x"\nelif command -v a; then\n    sudo systemctl enable a\nfi\n' > "$T/protege.sh"
printf 'echo hop\nsudo systemctl enable a\n' > "$T/nu.sh"
printf 'if is_dry_run; then\n    log_simu "x"\nelse\n    if command -v a; then\n        sudo rm /tmp/x\n    fi\nfi\n' > "$T/imbrique.sh"
printf 'if [ -z "$X" ]; then\n    echo vide\nelif is_dry_run; then\n    log_simu "x"\nelse\n    sudo cp a b\nfi\n' > "$T/garde_elif.sh"
printf 'if is_dry_run; then\n    log_simu "x"\n    exit 0\nfi\nsudo rm -rf /tmp/truc\nsudo chmod +x /tmp/machin\n' > "$T/sortie.sh"

v_protege=$(analyser "$T/protege.sh"    | wc -l)
v_nu=$(analyser      "$T/nu.sh"         | wc -l)
v_imbrique=$(analyser "$T/imbrique.sh"  | wc -l)
v_elif=$(analyser    "$T/garde_elif.sh" | wc -l)
v_sortie=$(analyser  "$T/sortie.sh"     | wc -l)
rm -rf "$T"

if [ "$v_protege" -ne 0 ] || [ "$v_nu" -ne 1 ] || [ "$v_imbrique" -ne 0 ] || \
   [ "$v_elif" -ne 0 ] || [ "$v_sortie" -ne 0 ]; then
    echo "ECHEC : l'analyseur ne distingue plus protege et nu."
    echo "  temoin protege  : $v_protege (attendu 0)"
    echo "  temoin nu       : $v_nu (attendu 1)"
    echo "  temoin imbrique : $v_imbrique (attendu 0)"
    echo "  garde sur elif  : $v_elif (attendu 0)"
    echo "  sortie anticipee: $v_sortie (attendu 0)"
    echo ""
    echo "Aucun verdict n'est rendu : un analyseur faux vaut moins que pas d'analyse."
    exit 2
fi
echo "Analyseur valide sur 5 cas temoins."
echo ""

# ---- Verdict ---------------------------------------------------------------
TOTAL=0
FAUTIFS=0
for m in "$DOSSIER"/*.sh; do
    [ -f "$m" ] || continue
    TOTAL=$((TOTAL + 1))
    res=$(analyser "$m")
    [ -n "$res" ] || continue
    FAUTIFS=$((FAUTIFS + 1))
    echo "  $(basename "$m")"
    echo "$res" | while IFS='|' read -r ligne texte; do
        printf '      L%-5s %s\n' "$ligne" "$texte"
    done
done

echo ""
echo "  modules analyses : $TOTAL"
echo "  modules fautifs  : $FAUTIFS"
echo ""

if [ "$FAUTIFS" -gt 0 ]; then
    echo "ECHEC : ces actions modifient la machine meme en mode simulation."
    echo ""
    echo "Deux facons de corriger :"
    echo "  - passer par run_action \"ce que ca ferait\" <commande> ;"
    echo "  - ou placer l'action dans la branche reelle d'un « if is_dry_run »."
    echo ""
    echo "C'est la meme faute qui, dans MadTweak, effacait Windows.old pendant"
    echo "une simulation : trois lignes annoncees au conditionnel, et une qui"
    echo "detruisait pour de vrai."
    exit 1
fi

echo "OK : les $TOTAL modules respectent le mode simulation."
exit 0
