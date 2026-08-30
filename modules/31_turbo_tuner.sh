#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 31_turbo_tuner.sh
# ==============================================================================
# Phase: 31 - Turbo-Tuner (Auto-Tune Hardware & Performance Scanner)
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🏁 ${WHITE}${BOLD}Phase 31 Déploiement du Turbo-Tuner (Auto-Performance Scan)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Calcul des Hugepages (Optimisé pour 32Go+ de RAM)
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ "$TOTAL_RAM_KB" -gt 16000000 ]; then
    echo -e "    ${WHITE}├─ [TUNE] Allocation de 2Go en Hugepages (Stabilité FPS)...${NC}"
    # Allocation de 2Go en Hugepages pour réduire les TLB misses
    if is_dry_run; then
        log_simu "allouerait 1024 hugepages (echo > /proc/sys/vm/nr_hugepages) et écrirait /etc/sysctl.d/99-mados-hugepages.conf"
    else
        echo 1024 | sudo tee /proc/sys/vm/nr_hugepages > /dev/null
        cat <<'THP_EOF' | sudo tee /etc/sysctl.d/99-mados-hugepages.conf >/dev/null
vm.nr_hugepages=1024
kernel.numa_balancing=0
THP_EOF
    fi
fi

# 1.5 Activation du PCI-e Overdrive (Verrouillage Performance)
echo -e "    ${WHITE}├─ [TUNE] Injection du PCI-e Overdrive (Liaison GPU/SSD)...${NC}"
run_action "installerait pciutils" sudo apt install -y pciutils >/dev/null 2>&1 || true
# Force le latency_timer au maximum pour éviter les pauses de transmission
run_action "forcerait le latency_timer PCI-e à 40 (setpci)" sudo setpci -v -d '*:*' latency_timer=40 2>/dev/null || true
# Retire : `setpci -s "$GPU_PCI" 4.w=0x0000:0x0002`.
# Cette ecriture visait le registre Command PCI et mettait a 0 le bit du masque
# 0x0002, c'est-a-dire "Memory Space Enable" du GPU -- elle DESACTIVAIT le
# decodage memoire de la carte graphique au lieu d'activer quoi que ce soit.
# Il n'existe pas de "mode Performance PCI-e" a cet offset : la ligne est
# supprimee, pas corrigee.

# 2. Scanner de Latence et Latency Monitor
echo -e "    ${WHITE}├─ [SCAN] Calibrage des priorités d'interruption (IRQ)...${NC}"
run_action "installerait irqbalance" sudo apt install -y irqbalance || true
run_action "activerait irqbalance" sudo systemctl enable irqbalance || true
run_action "démarrerait irqbalance" sudo systemctl start irqbalance || true

# 3. Optimisation I/O Scheduler (BFQ pour les SSD)
echo -e "    ${WHITE}├─ [TUNE] Forcer l'ordonnanceur BFQ (Low-Latency I/O)...${NC}"
if is_dry_run; then
    log_simu "écrirait la règle udev /etc/udev/rules.d/60-mados-scheduler.rules (ordonnanceur BFQ)"
else
    cat <<'EOF' | sudo tee /etc/udev/rules.d/60-mados-scheduler.rules >/dev/null
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]*", ATTR{queue/scheduler}="bfq"
EOF
fi

# 5. MadOS Auto-Boost (Daemon Intelligent)
echo -e "    ${WHITE}├─ [BOOST] Injection du Daemon MadOS Auto-Boost (Détection Procès)...${NC}"
if is_dry_run; then
    log_simu "installerait /usr/local/bin/mados-auto-boost, le service systemd mados-auto-boost.service, puis l'activerait et le démarrerait"
else
    cat <<'BOOST_EOF' | sudo tee /usr/local/bin/mados-auto-boost >/dev/null
#!/bin/bash
# MadOS Intelligent Game Detection
#
# `pgrep -x "steam|heroic|..."` ne fonctionnait pas : -x impose une
# correspondance EXACTE du nom de processus et desactive l'interpretation du
# motif. Aucun processus ne s'appelle litteralement "steam|heroic|...".
# On utilise -f avec une expression reguliere etendue sur la ligne de commande.
JEUX='steam|heroic|lutris|gamescope|wine-preloader|proton|cs2|valorant|dota2'
MADOS_BIN="/usr/local/bin/mados"

# Sans l'utilitaire 'mados', ce demon tournerait en boucle toutes les 15 s pour
# appeler un binaire inexistant. On sort proprement plutot que de brasser du vent.
if [ ! -x "$MADOS_BIN" ]; then
    echo "mados-auto-boost : $MADOS_BIN absent, rien a piloter. Arret." >&2
    exit 0
fi

LAST_MODE="balance"
while true; do
  if pgrep -f -- "$JEUX" >/dev/null 2>&1; then
    if [ "$LAST_MODE" != "game" ]; then
      "$MADOS_BIN" shift game >/dev/null 2>&1
      LAST_MODE="game"
    fi
  else
    if [ "$LAST_MODE" = "game" ]; then
      "$MADOS_BIN" shift balance >/dev/null 2>&1
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
ConditionPathIsExecutable=/usr/local/bin/mados

[Service]
ExecStart=/usr/local/bin/mados-auto-boost
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
SVC_EOF

    sudo systemctl daemon-reload || true
    # N'activer le service que si l'utilitaire qu'il pilote existe reellement.
    if [ -x /usr/local/bin/mados ]; then
        sudo systemctl enable mados-auto-boost.service 2>/dev/null || true
        sudo systemctl start mados-auto-boost.service 2>/dev/null || true
    else
        echo -e "    ${GRAY}├─ Utilitaire 'mados' absent : Auto-Boost installé mais non activé.${NC}"
    fi
fi

echo -e "    ${CYAN}✅ [SUCCÈS] Turbo-Tuner & Auto-Boost activés. MadOS veille sur vos FPS !${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 31 Terminée.${NC}"
