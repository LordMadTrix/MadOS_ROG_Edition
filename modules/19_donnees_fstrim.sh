#!/bin/bash
# ==========================================
# MadOS ROG V2.6 - 19_donnees_fstrim.sh
# ==========================================
# Phase: 19 - Automaintenance SSD & Logs (Fstrim)
# ==========================================



RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}>>> ${WHITE}[Phase 19] ${BOLD}Déploiement Maintenance SSD & OS (Automatisé)...${NC}"

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

echo -e "    ${CYAN}✅ Votre système se nettoiera tout seul en mode fantôme pour préserver votre SSD.${NC}"
echo -e "    ${WHITE}✅ Phase 19 Terminée.${NC}"
