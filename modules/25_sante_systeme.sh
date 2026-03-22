#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 25_sante_systeme.sh
# ==============================================================================
# Phase: 25 - Diagnostic Santé Système MadOS
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
BLUE='\033[0;34m'

# Thème Whiptail MadOS
export NEWT_COLORS='
  root=black,black
  window=white,black
  border=red,black
  shadow=black,black
  title=white,red
  button=white,black
  actbutton=white,red
  compactbutton=white,black
  textbox=white,black
  listbox=white,black
  actlistbox=white,red
  sellistbox=white,black
  actsellistbox=white,red
  checkbox=white,black
  actcheckbox=white,red
'

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 25 Diagnostic Santé du Système MadOS${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

REPORT_FILE="/tmp/mados_health_$(date +%Y%m%d_%H%M%S).txt"
SCORE=0
TOTAL=0
WARNINGS=""

check_ok()   { echo -e "    ${GREEN}✓ $1${NC}"; ((SCORE++)); ((TOTAL++)); echo "[ OK ] $1" >> "$REPORT_FILE"; }
check_warn() { echo -e "    ${YELLOW}⚠ $1${NC}"; ((TOTAL++)); WARNINGS+="  - $1\n"; echo "[WARN] $1" >> "$REPORT_FILE"; }
check_fail() { echo -e "    ${RED}✗ $1${NC}"; ((TOTAL++)); WARNINGS+="  - ✗ $1\n"; echo "[FAIL] $1" >> "$REPORT_FILE"; }

# En-tête du rapport
cat > "$REPORT_FILE" << HEADER
=======================================================
  MadOS ROG Edition — Rapport de Santé Système
  Date : $(date '+%d/%m/%Y %H:%M')
  Machine : $(hostname) | Utilisateur : $REAL_USER
=======================================================
HEADER

echo -e "\n    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${CYAN}[1/6] Kernel XanMod${NC}"
echo -e "    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
KERNEL=$(uname -r)
echo "Kernel : $KERNEL" >> "$REPORT_FILE"
if echo "$KERNEL" | grep -qi "xanmod"; then
    check_ok "Kernel XanMod détecté : $KERNEL"
else
    check_warn "Kernel standard Ubuntu actif ($KERNEL) — XanMod non détecté"
fi

echo -e "\n    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${CYAN}[2/6] Interface Graphique${NC}"
echo -e "    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if command -v plasmashell &>/dev/null; then
    PLASMA_VER=$(plasmashell --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    echo "Plasma : $PLASMA_VER" >> "$REPORT_FILE"
    check_ok "KDE Plasma détecté (v$PLASMA_VER)"
elif command -v gnome-shell &>/dev/null; then
    GNOME_VER=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    echo "GNOME : $GNOME_VER" >> "$REPORT_FILE"
    check_ok "GNOME MadOS Edition détecté (v$GNOME_VER)"
else
    check_fail "Aucun environnement graphique (KDE/GNOME) détecté"
fi

echo -e "\n    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${CYAN}[3/6] Pilotes GPU${NC}"
echo -e "    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if command -v nvidia-smi &>/dev/null; then
    NV_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
    check_ok "Pilotes NVIDIA actifs (v$NV_VER)"
    echo "GPU NVIDIA : $NV_VER" >> "$REPORT_FILE"
elif glxinfo 2>/dev/null | grep -qi "AMD\|Radeon\|RADV"; then
    check_ok "Pilotes AMD/Mesa actifs"
    echo "GPU AMD/Mesa détecté" >> "$REPORT_FILE"
elif command -v vainfo &>/dev/null; then
    check_warn "GPU Intel détecté (vérification manuelle conseillée)"
else
    check_fail "Aucun pilote GPU identifiable"
fi

echo -e "\n    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${CYAN}[4/6] OpenClaw IA${NC}"
echo -e "    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
OC_DIR="$(getent passwd "$REAL_USER" | cut -d: -f6)/OpenClaw"
if [ -d "$OC_DIR" ]; then
    check_ok "Dossier OpenClaw présent ($OC_DIR)"
    if sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" systemctl --user is-active --quiet openclaw.service 2>/dev/null; then
        check_ok "Service OpenClaw actif en arrière-plan"
    else
        check_warn "Service OpenClaw installé mais inactif (lancez-le via le panneau de contrôle)"
    fi
else
    check_fail "OpenClaw non installé"
fi

echo -e "\n    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${CYAN}[5/6] Steam & Gaming Stack${NC}"
echo -e "    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
command -v steam &>/dev/null && check_ok "Steam installé" || check_warn "Steam absent"
command -v lutris &>/dev/null && check_ok "Lutris installé" || check_warn "Lutris absent"
command -v mangohud &>/dev/null && check_ok "MangoHud installé" || check_warn "MangoHud absent"
command -v gamemoded &>/dev/null && check_ok "GameMode installé" || check_warn "GameMode absent"

echo -e "\n    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${CYAN}[6/6] Services Système${NC}"
echo -e "    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
systemctl is-active --quiet sddm && check_ok "SDDM actif" || check_warn "SDDM inactif"
systemctl is-active --quiet NetworkManager && check_ok "NetworkManager actif" || check_warn "NetworkManager inactif"
command -v asusctl &>/dev/null && check_ok "asusctl ROG installé" || check_warn "asusctl non installé (non-ROG ou manquant)"

# Résumé final
echo "" >> "$REPORT_FILE"
echo "Score : $SCORE / $TOTAL" >> "$REPORT_FILE"
[ -n "$WARNINGS" ] && echo -e "\nAvertissements :\n$WARNINGS" >> "$REPORT_FILE"

PERCENT=$(( SCORE * 100 / TOTAL ))

echo ""
echo -e "    ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ "$PERCENT" -ge 80 ]; then
    echo -e "    ${GREEN}★ SCORE DE SANTÉ : ${SCORE}/${TOTAL} (${PERCENT}%) — Système en excellente condition !${NC}"
elif [ "$PERCENT" -ge 60 ]; then
    echo -e "    ${YELLOW}★ SCORE DE SANTÉ : ${SCORE}/${TOTAL} (${PERCENT}%) — Quelques points à corriger.${NC}"
else
    echo -e "    ${RED}★ SCORE DE SANTÉ : ${SCORE}/${TOTAL} (${PERCENT}%) — Installation incomplète détectée.${NC}"
fi

if [ -n "$WARNINGS" ]; then
    echo -e "\n    ${YELLOW}Points à corriger :${NC}"
    echo -e "$WARNINGS" | while IFS= read -r line; do echo -e "    $line"; done
fi

echo -e "\n    ${GRAY}Rapport complet sauvegardé dans : ${WHITE}$REPORT_FILE${NC}"

# Proposer d'afficher le rapport complet
whiptail --title "MadOS 3.0 - 🏥 Health Check" \
    --yesno "Score de Santé : $SCORE/$TOTAL ($PERCENT%)\n\nVoulez-vous consulter le rapport complet ?" 10 55 && \
    whiptail --title "MadOS 3.0 - Rapport complet" --scrolltext --textbox "$REPORT_FILE" 30 80 2>/dev/null || true

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 25 Terminée.${NC}"
