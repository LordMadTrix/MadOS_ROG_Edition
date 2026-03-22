#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 31_turbo_tuner.sh
# ==============================================================================
# Phase: 31 - Turbo-Tuner (Auto-Tune Hardware & Performance Scanner)
# ==============================================================================

export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🏁 ${WHITE}${BOLD}Phase 31 Déploiement du Turbo-Tuner (Auto-Performance Scan)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Calcul des Hugepages (Optimisé pour 32Go+ de RAM)
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ "$TOTAL_RAM_KB" -gt 16000000 ]; then
    echo -e "    ${WHITE}├─ [TUNE] Configuration des Hugepages (Gaming Haute Performance)...${NC}"
    # Allocation de 2Go en Hugepages pour les jeux
    echo 1024 | sudo tee /proc/sys/vm/nr_hugepages > /dev/null
    echo "vm.nr_hugepages=1024" | sudo tee -a /etc/sysctl.d/99-mados-performance.conf > /dev/null
fi

# 2. Scanner de Latence et Latency Monitor
echo -e "    ${WHITE}├─ [SCAN] Calibrage des priorités d'interruption (IRQ)...${NC}"
sudo apt install -y irqbalance
sudo systemctl enable irqbalance
sudo systemctl start irqbalance

# 3. Optimisation I/O Scheduler (BFQ pour les SSD)
echo -e "    ${WHITE}├─ [TUNE] Forcer l'ordonnanceur BFQ (Low-Latency I/O)...${NC}"
cat <<'EOF' | sudo tee /etc/udev/rules.d/60-mados-scheduler.rules >/dev/null
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]*", ATTR{queue/scheduler}="bfq"
EOF

# 4. Activation du PCI Latency Timer (pour la RTX)
echo -e "    ${WHITE}├─ [GPU] Optimisation du PCI Latency Timer (RTX Buffering)...${NC}"
sudo setpci -v -d *:* latency_timer=40 2>/dev/null || true

sudo sysctl --system >/dev/null 2>&1

echo -e "    ${CYAN}✅ [SUCCÈS] Turbo-Tuner actif. Votre i9 et votre RTX sont désormais synchronisés pour la performance brute.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 31 Terminée.${NC}"
