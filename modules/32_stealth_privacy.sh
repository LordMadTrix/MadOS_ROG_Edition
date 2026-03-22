#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 32_stealth_privacy.sh
# ==============================================================================
# Phase: 32 - Stealth-Mode (Anti-Telemetry & Hardened Privacy)
# ==============================================================================

export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🛡️ ${WHITE}${BOLD}Phase 32 Activation du Mode Discrétion (Stealth-Mode Privacy)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Neutralisation du traçage Ubuntu
echo -e "    ${WHITE}├─ [TRACAGE] Désactivation du rapport d'erreurs (Apport)...${NC}"
sudo sed -i 's/enabled=1/enabled=0/g' /etc/default/apport 2>/dev/null || true
sudo systemctl stop apport 2>/dev/null || true
sudo systemctl disable apport 2>/dev/null || true

echo -e "    ${WHITE}├─ [TRACAGE] Suppression de Popularity-Contest (Envoi données d'usage)...${NC}"
sudo apt purge -y popularity-contest 2>/dev/null || true

# 2. Sécurisation DNS (DNS-over-TLS)
echo -e "    ${WHITE}├─ [DNS] Configuration Quad9 (Privacy) avec DNS-over-TLS...${NC}"
cat <<'EOF' | sudo tee /etc/systemd/resolved.conf >/dev/null
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net
DNSOverTLS=yes
DNSSEC=yes
Domains=~.
EOF
sudo systemctl restart systemd-resolved 2>/dev/null || true

# 3. Firewall Gaming Hardened
echo -e "    ${WHITE}├─ [PAR-FEU] Activation du Firewall UFW (Profil Gaming)...${NC}"
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Ports Steam/Gaming
sudo ufw allow 27000:27100/udp 2>/dev/null || true
sudo ufw --force enable 2>/dev/null || true

# 4. Nettoyage Télémétrie GDM
echo -e "    ${WHITE}├─ [UI] Désactivation des services de localisation et d'usage GDM...${NC}"
sudo -u "${SUDO_USER:-$USER}" dbus-launch gsettings set org.gnome.system.location enabled false 2>/dev/null || true
sudo -u "${SUDO_USER:-$USER}" dbus-launch gsettings set org.gnome.desktop.privacy report-technical-problems false 2>/dev/null || true

echo -e "    ${CYAN}✅ [SUCCÈS] Stealth-Mode actif. Votre MadOS est désormais une forteresse numérique de discrétion.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 32 Terminée.${NC}"
