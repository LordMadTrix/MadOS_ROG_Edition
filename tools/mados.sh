#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - mados
# ==============================================================================
# Utilitaire en ligne de commande unifié.
# Installé vers /usr/local/bin/mados par modules/28_mados_cli.sh.
#
# Le démon mados-auto-boost (modules/31_turbo_tuner.sh) appelle
# « mados shift game » et « mados shift balance » : ces deux sous-commandes font
# partie du contrat, ne pas les renommer sans corriger le module 31.
# ==============================================================================

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; GRAY='\033[0;37m'; YELLOW='\033[0;33m'
BOLD='\033[1m'; NC='\033[0m'

# Racine du cache installé par le module 28 (modules/, lib/, assets/).
MADOS_HOME="/opt/mados-rog"
export PROJECT_ROOT="$MADOS_HOME"

_erreur() { echo -e "${RED}[mados]${NC} $*" >&2; }
_info()   { echo -e "${CYAN}[mados]${NC} $*"; }
_ok()     { echo -e "${GREEN}[mados]${NC} $*"; }

_besoin_root() {
    if [ "$(id -u)" -ne 0 ]; then
        _erreur "Cette commande demande les privilèges root : sudo mados $*"
        exit 1
    fi
}

_version() {
    local f
    for f in "$MADOS_HOME/VERSION" /opt/mados/VERSION; do
        if [ -f "$f" ]; then
            cat "$f"
            return 0
        fi
    done
    echo "inconnue"
}

# ------------------------------------------------------------------ shift ----
# Bascule le profil de performance. Chaque levier est optionnel : on applique ce
# qui est réellement présent sur la machine, sans échouer sur le reste.
_appliquer_gouverneur() {
    local gouv="$1"
    local applique=0
    local c dispo
    for c in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -w "$c" ] || continue
        # Ne pas écrire un gouverneur que le pilote ne propose pas.
        dispo="${c%scaling_governor}scaling_available_governors"
        if [ -r "$dispo" ] && ! grep -qw -- "$gouv" "$dispo"; then
            continue
        fi
        echo "$gouv" > "$c" 2>/dev/null && applique=1
    done
    [ "$applique" -eq 1 ]
}

_appliquer_asusctl() {
    local profil="$1"
    command -v asusctl >/dev/null 2>&1 || return 1
    asusctl profile -P "$profil" >/dev/null 2>&1 && return 0
    asusctl profile --profile-set "$profil" >/dev/null 2>&1 && return 0
    return 1
}

cmd_shift() {
    local mode="${1:-}"
    local profil gouv
    case "$mode" in
        game|jeu)          profil="Performance"; gouv="performance" ;;
        balance|equilibre) profil="Balanced";    gouv="schedutil" ;;
        eco|silence)       profil="Quiet";       gouv="powersave" ;;
        *)
            _erreur "Profil inconnu : ${mode:-aucun}. Attendu : game | balance | eco"
            exit 1
            ;;
    esac
    _besoin_root shift "$mode"

    local fait=""
    _appliquer_asusctl "$profil"  && fait="${fait} asusctl(${profil})"
    _appliquer_gouverneur "$gouv" && fait="${fait} gouverneur(${gouv})"

    # schedutil n existe pas sur tous les pilotes : repli pour le mode balance.
    if [ "$gouv" = "schedutil" ] && [ -z "$fait" ]; then
        _appliquer_gouverneur "powersave" && fait="${fait} gouverneur(powersave)"
    fi

    if [ -z "$fait" ]; then
        _erreur "Aucun levier disponible : ni asusctl, ni cpufreq accessible en écriture."
        exit 1
    fi
    _ok "Profil ${BOLD}${mode}${NC} appliqué :${fait}"
}

# ----------------------------------------------------------------- status ----
cmd_status() {
    echo ""
    echo -e "${RED}${BOLD}  MadOS ROG Edition $(_version)${NC}"
    echo -e "${GRAY}  --------------------------------------------${NC}"
    printf "  %-22s %s\n" "Noyau"  "$(uname -r)"
    printf "  %-22s %s\n" "Bureau" "${XDG_CURRENT_DESKTOP:-inconnu}"

    local gouv="n/a"
    if [ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        gouv=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    fi
    printf "  %-22s %s\n" "Gouverneur CPU" "$gouv"

    if command -v asusctl >/dev/null 2>&1; then
        local pa
        pa=$(asusctl profile -p 2>/dev/null | tail -1)
        printf "  %-22s %s\n" "Profil ASUS" "${pa:-n/a}"
    fi

    echo -e "${GRAY}  --------------------------------------------${NC}"
    local svc
    for svc in mados-auto-boost mados-rgb auto-cpufreq ollama sddm; do
        if systemctl list-unit-files 2>/dev/null | grep -q "^${svc}\.service"; then
            if systemctl is-active --quiet "$svc" 2>/dev/null; then
                printf "  %-22s ${GREEN}actif${NC}\n" "$svc"
            else
                printf "  %-22s ${GRAY}inactif${NC}\n" "$svc"
            fi
        fi
    done
    echo ""
}

# ------------------------------------------------- modules mis en cache ------
_lancer_module() {
    local module="$1"
    local libelle="$2"
    local chemin="$MADOS_HOME/modules/$module"
    if [ ! -f "$chemin" ]; then
        _erreur "Module absent : $chemin"
        _erreur "Relancez le module 28 pour recréer le cache /opt/mados-rog."
        exit 1
    fi
    _besoin_root
    _info "$libelle"
    bash "$chemin"
}

cmd_health() { _lancer_module "25_sante_systeme.sh" "Diagnostic de santé du système..."; }
cmd_update() { _lancer_module "24_mados_update.sh"  "Recherche de mise à jour MadOS..."; }

# ------------------------------------------------------------------ night ----
cmd_night() {
    local etat="${1:-}"
    case "$etat" in
        on|off) ;;
        *) _erreur "Usage : mados night on|off"; exit 1 ;;
    esac
    if [ ! -x /usr/local/bin/mados-night-mode ]; then
        _erreur "Mode nocturne non installé (module 32_stealth_privacy.sh)."
        exit 1
    fi
    /usr/local/bin/mados-night-mode "$etat"
}

# ------------------------------------------------------------------ boost ----
cmd_boost() {
    local etat="${1:-}"
    _besoin_root boost "$etat"
    case "$etat" in
        on)
            if systemctl enable --now mados-auto-boost.service >/dev/null 2>&1; then
                _ok "Auto-Boost activé."
            else
                _erreur "Service mados-auto-boost indisponible (module 31)."
            fi
            ;;
        off)
            if systemctl disable --now mados-auto-boost.service >/dev/null 2>&1; then
                _ok "Auto-Boost désactivé."
            else
                _erreur "Service mados-auto-boost indisponible (module 31)."
            fi
            ;;
        *)
            _erreur "Usage : mados boost on|off"
            exit 1
            ;;
    esac
}

# ------------------------------------------------- sauvegardes / restore -----
_charger_common() {
    if [ -f "$MADOS_HOME/lib/common.sh" ]; then
        # shellcheck source=/dev/null
        source "$MADOS_HOME/lib/common.sh"
        return 0
    fi
    _erreur "lib/common.sh introuvable dans $MADOS_HOME."
    exit 1
}

cmd_backups() {
    _besoin_root
    _charger_common
    list_backups
}

cmd_restore() {
    _besoin_root
    _charger_common
    echo -e "${YELLOW}Cette commande remet les fichiers système sauvegardés dans leur état d'origine.${NC}"
    local reponse
    read -r -p "Confirmer la restauration ? (o/N) : " reponse
    case "$reponse" in
        [oOyY]) restore_all ;;
        *) _info "Restauration annulée." ;;
    esac
}

# ------------------------------------------------------------------- help ----
cmd_help() {
    echo ""
    echo -e "  ${BOLD}MadOS ROG Edition $(_version)${NC} - utilitaire ${BOLD}mados${NC}"
    echo ""
    echo -e "  ${WHITE}Performance${NC}"
    echo "    mados shift game        Profil jeu (asusctl Performance + gouverneur performance)"
    echo "    mados shift balance     Profil équilibré"
    echo "    mados shift eco         Profil silencieux / batterie"
    echo "    mados boost on|off      Bascule automatique du profil selon les jeux détectés"
    echo ""
    echo -e "  ${WHITE}Système${NC}"
    echo "    mados status            État MadOS : noyau, gouverneur, profil ASUS, services"
    echo "    mados health            Diagnostic complet (module 25)"
    echo "    mados update            Mise à jour depuis GitHub (module 24)"
    echo "    mados night on|off      Mode nocturne (filtre bleu + RGB éteint)"
    echo ""
    echo -e "  ${WHITE}Sauvegardes${NC}"
    echo "    mados backups           Liste les fichiers système sauvegardés"
    echo "    mados restore           Restaure les fichiers dans leur état d'origine"
    echo ""
    echo -e "  ${WHITE}Divers${NC}"
    echo "    mados version           Version installée"
    echo "    mados help              Cette aide"
    echo ""
}

# ------------------------------------------------------------------- main ----
_commande="${1:-help}"
[ $# -gt 0 ] && shift

case "$_commande" in
    shift)                cmd_shift   "${1:-}" ;;
    status)               cmd_status ;;
    health|sante)         cmd_health ;;
    update)               cmd_update ;;
    night)                cmd_night   "${1:-}" ;;
    boost)                cmd_boost   "${1:-}" ;;
    backups|sauvegardes)  cmd_backups ;;
    restore)              cmd_restore ;;
    version|--version|-v) _version ;;
    help|--help|-h)       cmd_help ;;
    *)
        _erreur "Commande inconnue : $_commande"
        cmd_help
        exit 1
        ;;
esac
