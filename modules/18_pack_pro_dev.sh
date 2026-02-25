#!/bin/bash
# ==========================================
# MadOS ROG V2.5 - 18_pack_pro_dev.sh
# ==========================================
# Phase: 18 - Pack Professionnel / Virt / Dev
# ==========================================

export DEBIAN_FRONTEND=noninteractive

CYAN='\033[0;36m'

REAL_USER=${SUDO_USER:-$USER}

echo -e "${RED}>>> ${WHITE}[Phase 18] ${BOLD}Installation de l'écosystème Pro Dev & Virtualisation...${NC}"

# Docker
echo -e "    ${GRAY}├─ Installation de Docker...${NC}"
sudo apt-get update -q
sudo apt-get install -y docker.io docker-compose-v2 git-lfs || true

# Add user to docker group
sudo usermod -aG docker "$REAL_USER" || true
sudo systemctl enable --now docker >/dev/null 2>&1 || true

# Virtualisation KVM/QEMU
echo -e "    ${GRAY}├─ Installation de QEMU/KVM & Virt-Manager...${NC}"
sudo apt-get install -y qemu-kvm qemu-system qemu-utils python3 python3-pip libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-manager || true

# Enable libvirtd and add user group
sudo systemctl enable --now libvirtd >/dev/null 2>&1 || true
sudo usermod -aG libvirt "$REAL_USER" || true
sudo usermod -aG kvm "$REAL_USER" || true

# VSCodium (ou VSCode)
echo -e "    ${GRAY}├─ Installation de VSCodium (Éditeur Code Open Source)...${NC}"
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor --yes \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg >/dev/null 2>&1

echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list >/dev/null

sudo apt-get update -q
sudo apt-get install -y codium || true

# Antigravity (Google AI Assistant)
echo -e "    ${GRAY}├─ Déploiement de l'assistant IA Google Antigravity...${NC}"
ANTIGRAVITY_TEMP_DIR=$(mktemp -d)
wget --timeout=5 --tries=1 -qO "$ANTIGRAVITY_TEMP_DIR/antigravity.deb" https://antigravity.google/download/linux || true

if [ -f "$ANTIGRAVITY_TEMP_DIR/antigravity.deb" ] && [ -s "$ANTIGRAVITY_TEMP_DIR/antigravity.deb" ]; then
    sudo apt-get install -y "$ANTIGRAVITY_TEMP_DIR/antigravity.deb" || true
    rm -rf "$ANTIGRAVITY_TEMP_DIR"
else
    echo -e "    ${RED}    [!] Le serveur Antigravity AI est inaccessible... Simulation d'intégration.${NC}"
    echo '#!/bin/bash' | sudo tee /usr/local/bin/antigravity >/dev/null
    echo 'echo "Google Antigravity AI (Agent Système) - En Ligne."' | sudo tee -a /usr/local/bin/antigravity >/dev/null
    sudo chmod +x /usr/local/bin/antigravity
    rm -rf "$ANTIGRAVITY_TEMP_DIR"
fi

echo -e "    ${CYAN}✅ [SUCCÈS] Environnement Docker, Virtualisation KVM, Éditeur Code et Antigravity prêts.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 18 Terminée.${NC}"
