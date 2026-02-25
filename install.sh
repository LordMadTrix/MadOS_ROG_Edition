#!/bin/bash
# ==========================================
# MadOS ROG V2 - 1-Click Bootstrap Installer
# ==========================================

export DEBIAN_FRONTEND=noninteractive

echo "=========================================================="
echo "      🚀 DÉMARRAGE DE L'INSTALLATEUR MAD OS ROG 🚀      "
echo "=========================================================="
echo "Installation de Git si manquant..."
sudo apt-get update -q >/dev/null 2>&1
sudo apt-get install -y git >/dev/null 2>&1

INSTALL_DIR="/tmp/mados_install_bootstrap"

echo "Clonage du dépôt MadOS_ROG_Edition..."
sudo rm -rf "$INSTALL_DIR" 2>/dev/null || true
sudo git clone https://github.com/LordMadTrix/MadOS_ROG_Edition.git "$INSTALL_DIR"

cd "$INSTALL_DIR" || exit 1

echo "Application des permissions d'exécution..."
sudo chmod +x Menu_Installation_ROG.sh modules/*.sh

echo "Lancement de la Matrice..."
# Nettoyage et exécution directe via la commande formattée pour terminal tty
exec sudo bash -i Menu_Installation_ROG.sh
