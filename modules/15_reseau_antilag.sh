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
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_nodelay=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_abort_on_overflow=1
net.ipv4.tcp_fastopen=3
# High Speed Buffers (Max RTX / NVMe)
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.netdev_max_backlog=10000
EOF

echo -e "    ${GRAY}├─ Injection de la Stack Réseau e-Sport (Bufferbloat Kill)...${NC}"
sudo sysctl --system >/dev/null 2>&1 || true

# ---- NOUVEAU : Script Prioritizer QoS (MadPriority) ----
echo -e "    ${GRAY}├─ Injection de l'Optimiseur de bande passante (Gamer QoS)...${NC}"
cat <<'QOS_EOF' | sudo tee /usr/local/bin/mados-qos-game >/dev/null
#!/bin/bash
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -z "$INTERFACE" ]; then exit 1; fi
# Réinitialisation
sudo tc qdisc del dev $INTERFACE root 2>/dev/null
# Application QoS Priorité UDP (Jeux)
sudo tc qdisc add dev $INTERFACE root handle 1: htb default 11
sudo tc class add dev $INTERFACE parent 1: classid 1:1 htb rate 1000mbit
sudo tc class add dev $INTERFACE parent 1:1 classid 1:10 htb rate 900mbit ceil 1000mbit prio 0
sudo tc filter add dev $INTERFACE protocol ip parent 1:0 prio 1 u32 match ip protocol 17 0xff flowid 1:10
QOS_EOF
sudo chmod +x /usr/local/bin/mados-qos-game || true

echo -e "    ${CYAN}✅ [SUCCÈS] Réseau e-Sport & Prioritizer MadOS installés.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 15 Terminée.${NC}"
