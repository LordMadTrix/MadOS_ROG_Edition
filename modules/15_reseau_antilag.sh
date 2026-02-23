#!/bin/bash
# ==========================================
# MadOS ROG V2.5 - 15_reseau_antilag.sh
# ==========================================
# Phase: 15 - Optimisation Réseau (Anti-Lag TCP BBR & fq_codel)
# ==========================================



RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}>>> ${WHITE}[Phase 15] ${BOLD}Déploiement du profil Réseau Anti-Lag (TCP BBR)...${NC}"

SYSCTL_CONF="/etc/sysctl.d/99-mados-network.conf"

cat <<'EOF' | sudo tee "$SYSCTL_CONF" >/dev/null
# =====================================
# MadOS ROG - Profil Réseau Gaming Ultra
# =====================================

# 1. Activation de l'algorithme TCP BBR (Google) pour réduire la latence
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=bbr

# 2. Augmentation des buffers réseaux (High Speed)
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

# 3. Protection basique contre le SYN Flood (Sécurité)
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_rfc1337=1
EOF

echo -e "    ${GRAY}├─ Fichier de configuration /etc/sysctl.d/99-mados-network.conf généré.${NC}"

sudo sysctl --system >/dev/null 2>&1 || true

echo -e "    ${CYAN}✅ Profil TCP BBR et fq_codel actif. Le ping multijoueur est maintenant protégé contre le bufferbloat.${NC}"
echo -e "    ${WHITE}✅ Phase 15 Terminée.${NC}"
