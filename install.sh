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
rm -rf "$INSTALL_DIR" 2>/dev/null || true
git clone https://github.com/LordMadTrix/MadOS_ROG_Edition.git "$INSTALL_DIR"

cd "$INSTALL_DIR"

echo "Application des permissions d'exécution..."
chmod +x Menu_Installation_ROG.sh modules/*.sh

echo "Lancement de la Matrice..."
sudo bash Menu_Installation_ROG.sh
