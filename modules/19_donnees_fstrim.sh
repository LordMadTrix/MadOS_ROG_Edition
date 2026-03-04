#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 19_donnees_fstrim.sh
# ==============================================================================
# Phase: 19 - Automaintenance SSD & Logs (Fstrim)
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'


echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 19 Déploiement Maintenance SSD & OS (Automatisé)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Activation de la purge SSD hebdomadaire
echo -e "    ${GRAY}├─ Activation du TRIM SSD (fstrim.timer systemd)...${NC}"
sudo systemctl enable --now fstrim.timer >/dev/null 2>&1 || true

# 2. Configuration pour limiter la taille des logs `journalctl`
echo -e "    ${GRAY}├─ Limitation de la taille énorme des logs Systemd à 500Mo max...${NC}"
if [ -f /etc/systemd/journald.conf ]; then
    sudo sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=500M/' /etc/systemd/journald.conf
    sudo sed -i 's/^#SystemMaxFileSize=.*/SystemMaxFileSize=100M/' /etc/systemd/journald.conf
    sudo systemctl restart systemd-journald >/dev/null 2>&1 || true
fi

# 3. Purge immédiate pour faire de l'espace post-installation
echo -e "    ${GRAY}├─ Nettoyage massif de l'installation actuelle...${NC}"
sudo apt-get autoremove -y >/dev/null 2>&1
sudo apt-get clean >/dev/null 2>&1
sudo journalctl --vacuum-time=3d >/dev/null 2>&1 || true
sudo fstrim -av >/dev/null 2>&1 || true

echo -e "    ${CYAN}✅ [SUCCÈS] Votre système se nettoiera tout seul en mode fantôme pour préserver votre SSD.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 19 Terminée.${NC}"
