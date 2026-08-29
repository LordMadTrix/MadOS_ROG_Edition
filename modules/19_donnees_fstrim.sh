#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 19_donnees_fstrim.sh
# ==============================================================================
# Phase: 19 - Automaintenance SSD & Logs (Fstrim)
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
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 19 Déploiement Maintenance SSD & OS (Automatisé)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Activation de la purge SSD hebdomadaire
echo -e "    ${GRAY}├─ Activation du TRIM SSD (fstrim.timer systemd)...${NC}"
run_action "activerait et démarrerait fstrim.timer" sudo systemctl enable --now fstrim.timer >/dev/null 2>&1 || true

# 2. Configuration pour limiter la taille des logs `journalctl`
echo -e "    ${GRAY}├─ Limitation de la taille énorme des logs Systemd à 500Mo max...${NC}"
if [ -f /etc/systemd/journald.conf ]; then
    if is_dry_run; then
        log_simu "limiterait la taille des logs journald (SystemMaxUse=500M, SystemMaxFileSize=100M) dans /etc/systemd/journald.conf et redémarrerait systemd-journald"
    else
        backup_file "/etc/systemd/journald.conf"
        sudo sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=500M/' /etc/systemd/journald.conf || true
        sudo sed -i 's/^#SystemMaxFileSize=.*/SystemMaxFileSize=100M/' /etc/systemd/journald.conf || true
        sudo systemctl restart systemd-journald >/dev/null 2>&1 || true
    fi
fi

# 3. Purge immédiate pour faire de l'espace post-installation
echo -e "    ${GRAY}├─ Nettoyage massif de l'installation actuelle...${NC}"
run_action "supprimerait les paquets orphelins (apt-get autoremove)" sudo apt-get autoremove -y >/dev/null 2>&1 || true
run_action "nettoierait le cache APT (apt-get clean)" sudo apt-get clean >/dev/null 2>&1 || true
run_action "purgerait les logs journald de plus de 3 jours" sudo journalctl --vacuum-time=3d >/dev/null 2>&1 || true
run_action "exécuterait le TRIM sur tous les disques (fstrim -av)" sudo fstrim -av >/dev/null 2>&1 || true

echo -e "    ${CYAN}✅ [SUCCÈS] Votre système se nettoiera tout seul en mode fantôme pour préserver votre SSD.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 19 Terminée.${NC}"
