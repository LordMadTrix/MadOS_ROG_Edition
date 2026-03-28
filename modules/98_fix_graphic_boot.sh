#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.0 - 98_fix_graphic_boot.sh
# ==============================================================================
# Phase: 98 - Réparation du Boot Graphique et Correctifs CLI
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}🛠️  MadOS - RÉPARATION DU DÉMARRAGE GRAPHIQUE...${NC}"

# 1. Installer X11 et forcer SDDM (KDE Login)
echo -e "    ├─ Mise a jour des depots et installation X11 (Plasma 6)..."
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y sddm xserver-xorg plasma-session-x11 --no-install-recommends

echo -e "    ├─ Activation de SDDM comme gestionnaire par defaut..."
echo "/usr/bin/sddm" | sudo tee /etc/X11/default-display-manager
sudo systemctl enable sddm

# 2. Forcer la configuration GLOBALE de SDDM pour X11
echo -e "    ├─ Force SDDM DisplayServer = x11..."
sudo mkdir -p /etc/sddm.conf.d
sudo bash -c "cat <<EOF > /etc/sddm.conf.d/mados.conf
[General]
DisplayServer=x11
InputMethod=

[Autologin]
Session=plasma
User=mados

[Theme]
Current=breeze
EOF"

# 3. Forcer la session X11 via AccountsService
echo -e "    ├─ Configuration de la session X11 via AccountsService..."
sudo mkdir -p /var/lib/AccountsService/users
sudo bash -c "cat <<EOF > /var/lib/AccountsService/users/mados
[User]
Session=plasma
SystemAccount=false
EOF"

# 2. Forcer le mode graphique
echo -e "    ├─ Configuration du boot en mode TARGET GRAPHICAL..."
sudo systemctl set-default graphical.target

# 3. Correctif Module 28 (mados-cli)
echo -e "    ├─ Application du correctif mados-cli..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
if [ -f "$PROJECT_ROOT/tools/mados.sh" ]; then
    sudo cp "$PROJECT_ROOT/tools/mados.sh" /usr/local/bin/mados
    sudo chmod +x /usr/local/bin/mados
    echo -e "    ✅ [SUCCÈS] Utilitaire 'mados' réparé."
else
    echo -e "    ⚠️  Source mados.sh introuvable sur le support local."
fi

echo -e "\n${GREEN}🚀 RÉPARATION TERMINÉE !${NC}"
echo -e "Appuyez sur une touche pour redémarrer la VM."
read -n 1
sudo reboot
