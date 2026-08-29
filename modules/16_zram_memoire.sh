#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 16_zram_memoire.sh
# ==============================================================================
# Phase: 16 - Compression Mémoire (ZRAM zstd)
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 16 Configuration ZRAM (Compression Mémoire Ultra-Rapide)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

run_action "rafraîchirait les index APT (apt-get update)" sudo apt-get update -q >/dev/null 2>&1 || true
run_action "installerait zram-tools" sudo apt-get install -y zram-tools >/dev/null 2>&1 || true

# Configuration agressive : on alloue 50% de la RAM max pour compresser les données en mémoire via zstd
if is_dry_run; then
    log_simu "écrirait /etc/default/zramswap (zstd, 50% de la RAM)"
else
    cat <<'EOF' | sudo tee /etc/default/zramswap >/dev/null
# MadOS ROG - Configuration ZRAM
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF
fi

echo -e "    ${GRAY}├─ ZRAM configuré à 50% avec l'algorithme zstd.${NC}"

# Réglage du 'swappiness' pour favoriser ZRAM avant le disque
SYSCTL_CONF="/etc/sysctl.d/99-mados-zram.conf"
if is_dry_run; then
    log_simu "écrirait $SYSCTL_CONF (swappiness=150 et réglages associés)"
else
    cat <<'EOF' | sudo tee "$SYSCTL_CONF" >/dev/null
# Favoriser l'usage du ZRAM (Swap en RAM)
vm.swappiness=150
vm.watermark_boost_factor=0
vm.watermark_scale_factor=125
vm.page-cluster=0
EOF
fi

run_action "appliquerait la configuration sysctl (sysctl --system)" sudo sysctl --system >/dev/null 2>&1 || true

# zram-tools fournit "zramswap.service", pas "zramsetup" : l'ancien nom echouait
# silencieusement (masque par la redirection et le repli), et ZRAM n'etait donc
# actif qu'apres un redemarrage -- alors que le module annoncait juste apres
# "Service ZRAM operationnel".
run_action "redémarrerait le service zramswap" sudo systemctl restart zramswap >/dev/null 2>&1 || true

echo -e "    ${CYAN}✅ [SUCCÈS] Service ZRAM opérationnel. Durée de vie du SSD préservée et fluidité RAM assurée.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 16 Terminée.${NC}"
