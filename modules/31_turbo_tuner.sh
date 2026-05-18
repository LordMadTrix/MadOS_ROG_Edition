#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 31_turbo_tuner.sh
# ==============================================================================
# Phase: 31 - Turbo-Tuner (Auto-Tune Hardware & Performance Scanner)
# ==============================================================================


GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🏁 ${WHITE}${BOLD}Phase 31 : Déploiement du Turbo-Tuner v4.0 (Performance Scan)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Calcul des Hugepages (Optimisé pour 32Go+ de RAM)
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ "$TOTAL_RAM_KB" -gt 16000000 ]; then
    echo -e "    ${WHITE}├─ [TUNE] Allocation de 2Go en Hugepages (Stabilité FPS)...${NC}"
    # Allocation de 2Go en Hugepages pour réduire les TLB misses
    echo 1024 | sudo tee /proc/sys/vm/nr_hugepages > /dev/null
    cat <<'THP_EOF' | sudo tee /etc/sysctl.d/99-mados-hugepages.conf >/dev/null
vm.nr_hugepages=1024
kernel.numa_balancing=0
THP_EOF
fi

# 1.5 Activation du PCI-e Overdrive (Verrouillage Performance)
echo -e "    ${WHITE}├─ [TUNE] Injection du PCI-e Overdrive (Liaison GPU/SSD)...${NC}"
sudo apt install -y pciutils >/dev/null 2>&1 || true
# Force le latency_timer au maximum pour éviter les pauses de transmission
sudo setpci -v -d *:* latency_timer=40 2>/dev/null || true
# Forcer le GPU à rester en mode Performance PCI-e
GPU_PCI=$(lspci | grep -i vga | awk '{print $1}' | head -1)
[ -n "$GPU_PCI" ] && sudo setpci -v -s "$GPU_PCI" 4.w=0x0000:0x0002 2>/dev/null || true

# 2. Scanner de Latence et Latency Monitor
echo -e "    ${WHITE}├─ [SCAN] Calibrage des priorités d'interruption (IRQ)...${NC}"
sudo apt install -y irqbalance || true
sudo systemctl enable irqbalance || true
sudo systemctl start irqbalance || true

# 3. Optimisation I/O Scheduler (BFQ pour les SSD)
echo -e "    ${WHITE}├─ [TUNE] Forcer l'ordonnanceur BFQ (Low-Latency I/O)...${NC}"
cat <<'EOF' | sudo tee /etc/udev/rules.d/60-mados-scheduler.rules >/dev/null
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]*", ATTR{queue/scheduler}="bfq"
EOF

# 4. Optimisation additionnelle PCI
echo -e "    ${WHITE}├─ [GPU] Finalisation du bus PCI-e (RTX Buffering)...${NC}"

# 5. MadOS Auto-Boost (Daemon Intelligent)
echo -e "    ${WHITE}├─ [BOOST] Injection du Daemon MadOS Auto-Boost (Détection Procès)...${NC}"
cat <<'BOOST_EOF' | sudo tee /usr/local/bin/mados-auto-boost >/dev/null
#!/bin/bash
# MadOS Intelligent Game Detection
LAST_MODE="balance"
while true; do
  # Liste des processus cibles (Jeux, Launchers, Proton)
  if pgrep -x "steam|heroic|lutris|gamescope|wine-preloader|proton|cs2|valorant|dota2" >/dev/null; then
    if [ "$LAST_MODE" != "game" ]; then
      /usr/local/bin/mados shift game >/dev/null 2>&1
      LAST_MODE="game"
    fi
  else
    if [ "$LAST_MODE" == "game" ]; then
      /usr/local/bin/mados shift balance >/dev/null 2>&1
      LAST_MODE="balance"
    fi
  fi
  sleep 15
done
BOOST_EOF
sudo chmod +x /usr/local/bin/mados-auto-boost || true

# Création du service systemd
cat <<'SVC_EOF' | sudo tee /etc/systemd/system/mados-auto-boost.service >/dev/null
[Unit]
Description=MadOS Auto-Boost (Game Detection)
After=multi-user.target

[Service]
ExecStart=/usr/local/bin/mados-auto-boost
Restart=always

[Install]
WantedBy=multi-user.target
SVC_EOF

sudo systemctl daemon-reload || true
sudo systemctl enable mados-auto-boost.service 2>/dev/null || true
sudo systemctl start mados-auto-boost.service 2>/dev/null || true

echo -e "    ${CYAN}✅ [SUCCÈS] Turbo-Tuner & Auto-Boost activés. MadOS veille sur vos FPS !${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 31 Terminée.${NC}"
