#!/bin/bash
# ==========================================
# MadOS ROG V2.5 - 16_zram_memoire.sh
# ==========================================
# Phase: 16 - Compression Mémoire (ZRAM zstd)
# ==========================================

set -u
export DEBIAN_FRONTEND=noninteractive

RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}>>> ${WHITE}[Phase 16] ${BOLD}Configuration ZRAM (Compression Mémoire Ultra-Rapide)...${NC}"

sudo apt-get update -q >/dev/null 2>&1
sudo apt-get install -y zram-tools >/dev/null 2>&1 || true

# Configuration agressive : on alloue 50% de la RAM max pour compresser les données en mémoire via zstd
cat <<'EOF' | sudo tee /etc/default/zramswap >/dev/null
# MadOS ROG - Configuration ZRAM
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF

echo -e "    ${GRAY}├─ ZRAM configuré à 50% avec l'algorithme zstd.${NC}"

# Réglage du 'swappiness' pour favoriser ZRAM avant le disque
SYSCTL_CONF="/etc/sysctl.d/99-mados-zram.conf"
cat <<'EOF' | sudo tee "$SYSCTL_CONF" >/dev/null
# Favoriser l'usage du ZRAM (Swap en RAM)
vm.swappiness=150
vm.watermark_boost_factor=0
vm.watermark_scale_factor=125
vm.page-cluster=0
EOF

sudo sysctl --system >/dev/null 2>&1 || true

sudo systemctl restart zramsetup >/dev/null 2>&1 || true

echo -e "    ${CYAN}✅ Service ZRAM opérationnel. Durée de vie du SSD préservée et fluidité RAM assurée.${NC}"
echo -e "    ${WHITE}✅ Phase 16 Terminée.${NC}"
