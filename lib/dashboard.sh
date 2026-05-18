#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - lib/dashboard.sh
# Tableau de bord terminal fixe — fenêtre encadrée pendant l'installation
# Technique : tput csr (Change Scroll Region) — aucune dépendance externe
# Structure :
#   Lignes 0–6  : Header fixe (╔═╗ titre ╠═╣ module/progress/stats ╠═╣)
#   Lignes 7–N2 : Zone de scroll (logs d'installation)
#   Ligne  N-1  : Pied fixe (╚═══════════════════════════════════════╝)
# ==============================================================================

DASH_LINES=7    # Lignes réservées pour le header (0–6)
_DASH_T0=0      # Timestamp de démarrage
_DASH_ERRORS=0  # Compteur d'erreurs
_DASH_ACTIVE=false

# Largeur dynamique selon le terminal (min 60, max 120)
_dash_width() {
    local w=$(( $(tput cols 2>/dev/null || echo 80) - 2 ))
    [ "$w" -lt 60 ]  && w=60
    [ "$w" -gt 120 ] && w=120
    echo "$w"
}

# ---- Répéter un caractère N fois ----------------------------------------
_repeat() {
    local char="$1" n="${2:-0}"
    [ "$n" -gt 0 ] && printf "%.0s${char}" $(seq 1 "$n") || true
}

# ---- Temps écoulé HH:MM:SS -----------------------------------------------
_dash_elapsed() {
    local e=$(( $(date +%s) - _DASH_T0 ))
    printf '%02d:%02d:%02d' $(( e/3600 )) $(( (e%3600)/60 )) $(( e%60 ))
}

# ---- Ligne de bordure (╔═══╗ / ╠═══╣ / ╚═══╝) ---------------------------
_dash_border() {
    tput cup "$1" 0
    printf "${RED}%s%s%s${NC}" "$2" "$(_repeat "$3" $DASH_W)" "$4"
}

# ---- Ligne de contenu (║ texte ║) ----------------------------------------
# Pas de codes ANSI dans $raw pour que ${#raw} = largeur visible
_dash_content() {
    local row="$1" raw="$2" color="${3:-$NC}"
    local len=${#raw}
    local pad=$(( DASH_W - len ))
    [ $pad -lt 0 ] && { raw="${raw:0:$DASH_W}"; pad=0; }
    tput cup "$row" 0
    printf "${RED}║${NC}${color}%s${NC}%*s${RED}║${NC}" "$raw" "$pad" ""
}

# ---- Header (lignes 0–6) : ╔ titre ╠ module/progress/stats ╠ ------------
_dash_draw() {
    local DASH_W
    DASH_W=$(_dash_width)

    local cur=${MADOS_MODULE_CURRENT:-0}
    local tot=${MADOS_MODULE_TOTAL:-1}
    [ "$tot" -le 0 ] && tot=1

    # Module en cours
    local desc="${CURRENT_MODULE_DESC:-Initialisation...}"
    local modnum="[$(printf '%02d/%02d' "$cur" "$tot")]"
    local label="  $modnum $desc"
    [ ${#label} -gt $DASH_W ] && label="${label:0:$(( DASH_W - 3 ))}..."

    # Barre de progression
    local bar_w=$(( DASH_W / 3 ))
    [ "$bar_w" -lt 20 ] && bar_w=20
    local filled=$(( cur * bar_w / tot ))
    local empty=$(( bar_w - filled ))
    local pct=$(printf '%3d' $(( cur * 100 / tot )))
    local bar="$(_repeat '█' "$filled")$(_repeat '░' "$empty")"

    # Stats système
    local elapsed=$(_dash_elapsed)
    local ram
    ram=$(awk '/^MemAvailable:/{printf "%.1fG", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "?")
    local disk
    disk=$(df -h / 2>/dev/null | awk 'NR==2{print $5}' || echo "?")

    local title="  [ MadOS ROG Edition 4.0 ]  NTSYNC Edition  —  Deploiement en cours"

    _dash_border  0 '╔' '═' '╗'
    _dash_content 1 "$title" "$WHITE"
    _dash_border  2 '╠' '═' '╣'
    _dash_content 3 "$label" "$CYAN"
    _dash_content 4 "  Progress  [${bar}] ${pct}%" "$GREEN"
    _dash_content 5 "  Temps: ${elapsed}  |  RAM libre: ${ram}  |  Disque: ${disk}  |  Erreurs: ${_DASH_ERRORS}" "$GRAY"
    _dash_border  6 '╠' '═' '╣'   # Séparateur vers zone de scroll
}

# ---- Pied de fenêtre (dernière ligne) : ╚═══╝ ----------------------------
_dash_bottom() {
    local DASH_W
    DASH_W=$(_dash_width)
    tput cup $(( $(tput lines) - 1 )) 0
    printf "${RED}╚%s╝${NC}" "$(_repeat '═' $DASH_W)"
}

# ---- Initialisation (appeler après MADOS_MODULE_TOTAL) -------------------
dashboard_init() {
    [ -t 1 ] || return 0
    tput csr 0 0 &>/dev/null || return 0

    _DASH_T0=$(date +%s)
    _DASH_ERRORS=0
    _DASH_ACTIVE=true

    clear
    _dash_draw
    _dash_bottom

    # Zone de scroll : entre header et pied de fenêtre
    tput csr $DASH_LINES $(( $(tput lines) - 2 ))
    tput cup $DASH_LINES 0

    trap 'dashboard_cleanup' EXIT INT TERM
    trap '_dash_on_resize' WINCH
}

# ---- Recalcul sur resize du terminal -------------------------------------
_dash_on_resize() {
    _dash_draw
    _dash_bottom
    tput csr $DASH_LINES $(( $(tput lines) - 2 ))
    tput cup $(( $(tput lines) - 2 )) 0
}

# ---- Mise à jour du header (avant chaque module) -------------------------
# Réétablit toujours la scroll region car whiptail/clear peuvent la reset
dashboard_update() {
    $_DASH_ACTIVE || return 0
    [ -t 1 ]      || return 0
    _dash_draw
    _dash_bottom
    tput csr $DASH_LINES $(( $(tput lines) - 2 ))
    tput cup $(( $(tput lines) - 2 )) 0
}

# ---- Incrémenter les erreurs ---------------------------------------------
dashboard_error() {
    (( _DASH_ERRORS++ )) || true
    dashboard_update
}

# ---- Statut final (installation terminée) --------------------------------
dashboard_done() {
    $_DASH_ACTIVE || return 0
    [ -t 1 ]      || return 0
    local _save="${CURRENT_MODULE_DESC:-}"
    export CURRENT_MODULE_DESC="Installation terminee avec succes !"
    _dash_draw
    _dash_bottom
    export CURRENT_MODULE_DESC="$_save"
}

# ---- Restaurer le terminal (scroll region plein écran) ------------------
dashboard_cleanup() {
    $_DASH_ACTIVE || return 0
    _DASH_ACTIVE=false
    tput csr 0 $(( $(tput lines) - 1 )) 2>/dev/null || true
    tput cup "$(tput lines)" 0           2>/dev/null || true
    printf '\n'
}
