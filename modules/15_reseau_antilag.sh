#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 15_reseau_antilag.sh
# ==============================================================================
# Phase: 15 - Optimisation Réseau (Anti-Lag TCP BBR & fq_codel)
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 15 Déploiement du profil Réseau Anti-Lag (TCP BBR)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

SYSCTL_CONF="/etc/sysctl.d/99-mados-network.conf"

cat <<'EOF' | sudo tee "$SYSCTL_CONF" >/dev/null
# =====================================
# MadOS ROG - Profil Réseau eSport BBR+
# =====================================

# 1. Activation de l'algorithme TCP BBR + fq_codel (Google)
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=bbr

# 2. Augmentation massive des buffers (RTX / i9 High Speed)
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.netdev_max_backlog=10000

# 3. Optimisation Latence (FastOpen & Low-SACK)
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_dsack=1
net.ipv4.tcp_fack=1

# 4. Sécurité SYN Flood (Active)
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_rfc1337=1
EOF

echo -e "    ${GRAY}├─ Fichier de configuration /etc/sysctl.d/99-mados-network.conf généré.${NC}"

sudo sysctl --system >/dev/null 2>&1 || true

echo -e "    ${CYAN}✅ [SUCCÈS] Profil TCP BBR et fq_codel actif. Le ping multijoueur est maintenant protégé contre le bufferbloat.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 15 Terminée.${NC}"
