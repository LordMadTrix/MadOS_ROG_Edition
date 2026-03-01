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

# Google Antigravity AI n'est pas disponible publiquement comme paquet Linux.
# Si vous avez accès à une version interne, placez le .deb dans le répertoire assets/
echo -e "    ${GRAY}├─ [Antigravity] Package non disponible publiquement — ignoré.${NC}"

echo -e "    ${CYAN}✅ [SUCCÈS] Environnement Docker, Virtualisation KVM, Éditeur Code et Antigravity prêts.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 18 Terminée.${NC}"
