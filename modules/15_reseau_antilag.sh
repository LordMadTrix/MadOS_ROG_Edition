#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 15_reseau_antilag.sh
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

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 15 Déploiement du profil Réseau Anti-Lag (TCP BBR)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

SYSCTL_CONF="/etc/sysctl.d/99-mados-network.conf"

if is_dry_run; then
    log_simu "écrirait le profil réseau eSport BBR+ dans $SYSCTL_CONF"
else
    cat <<'EOF' | sudo tee "$SYSCTL_CONF" >/dev/null
# =====================================
# MadOS ROG - Profil Réseau eSport BBR+
# =====================================
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_congestion_control=bbr
# fq_codel : c'est ce qu'annonce l'en-tete du fichier, et c'est le qdisc
# anti-bufferbloat adapte a un poste client.
net.core.default_qdisc=fq_codel
# Retire : net.ipv4.tcp_low_latency a ete SUPPRIME du noyau Linux.
# Retire : net.ipv4.tcp_nodelay n'existe pas en tant que sysctl -- TCP_NODELAY
# est une option de socket, posee par chaque application.
net.ipv4.tcp_tw_reuse=1
# Retire : tcp_abort_on_overflow=1 fait envoyer un RST quand la file d'accept
# deborde. C'est un reglage serveur, contre-productif sur un poste client.
net.ipv4.tcp_fastopen=3
# High Speed Buffers (Max RTX / NVMe)
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.netdev_max_backlog=10000
EOF
fi

echo -e "    ${GRAY}├─ Injection de la Stack Réseau e-Sport (Bufferbloat Kill)...${NC}"
run_action "appliquerait la configuration sysctl (sysctl --system)" sudo sysctl --system >/dev/null 2>&1 || true

# ---- NOUVEAU : Script Prioritizer QoS (MadPriority) ----
echo -e "    ${GRAY}├─ Injection de l'Optimiseur de bande passante (Gamer QoS)...${NC}"
if is_dry_run; then
    log_simu "installerait le script /usr/local/bin/mados-qos-game (QoS gamer)"
else
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
fi

echo -e "    ${CYAN}✅ [SUCCÈS] Réseau e-Sport & Prioritizer MadOS installés.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 15 Terminée.${NC}"
