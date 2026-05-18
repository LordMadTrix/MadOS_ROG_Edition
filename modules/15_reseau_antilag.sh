#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 15_reseau_antilag.sh
# ==============================================================================
# Phase: 15 - Optimisation Réseau (Anti-Lag TCP BBRv3 & fq_codel)
# ==============================================================================

# Variables de Couleurs
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1m'
NC='\033[0m'

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}Phase 15 : Déploiement Stack Réseau BBRv3 (Low Latency)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

SYSCTL_CONF="/etc/sysctl.d/99-mados-network.conf"

cat <<'EOF' | sudo tee "$SYSCTL_CONF" >/dev/null
# =====================================
# MadOS ROG - Profil Réseau v4.0 BBRv3
# =====================================
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq_codel
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fastopen=3

# High Speed Buffers (Max RTX / NVMe)
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.netdev_max_backlog=10000
EOF

echo -e "    ${GRAY}├─ Injection de la Stack BBRv3 (Kernel 6.14+ Optimization)...${NC}"
sudo sysctl --system >/dev/null 2>&1 || true

# QoS Mad-Priority v2 — persistant via NetworkManager dispatcher
echo -e "    ${GRAY}├─ Activation de Mad-Priority v2 (QoS Gamer, persistant)...${NC}"
sudo mkdir -p /etc/NetworkManager/dispatcher.d
cat <<'NM_EOF' | sudo tee /etc/NetworkManager/dispatcher.d/99-mados-qos >/dev/null
#!/bin/bash
[ "$2" != "up" ] && exit 0
IFACE="$1"
tc qdisc del dev "$IFACE" root 2>/dev/null
tc qdisc add dev "$IFACE" root fq_codel
NM_EOF
sudo chmod +x /etc/NetworkManager/dispatcher.d/99-mados-qos || true

# Appliquer immédiatement sur l'interface active
INTERFACE=$(ip route show default | awk '{print $5}' | head -1)
if [ -n "$INTERFACE" ]; then
    sudo tc qdisc del dev "$INTERFACE" root 2>/dev/null
    sudo tc qdisc add dev "$INTERFACE" root fq_codel 2>/dev/null || true
fi

echo -e "\n${GREEN}✅ PHASE 15 TERMINÉE : Latence réseau réduite au minimum.${NC}\n"
