#!/bin/bash
# ==========================================
# MadOS ROG V3 - Chroot Injector
# ==========================================
# Exécuté à l'intérieur du système de fichiers de l'ISO extractée.
# AUCUNE INTERACTION UTILISATEUR PERMISE (Non-Interactive).
# ==========================================

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

echo ">>> [CHROOT] Initialisation de l'environnement..."
apt-get update

echo ">>> [CHROOT] Purge des Bloatwares Ubuntu (Snapd, Télémétrie)..."
apt-get purge -y snapd ubuntu-report popularity-contest apparmor 2>/dev/null || true
apt-get autoremove -y --purge

echo ">>> [CHROOT] Installation du Noyau XanMod EDGE..."
wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -vo /usr/share/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list
apt-get update
apt-get install -y linux-xanmod-edge-x64v3

echo ">>> [CHROOT] Pré-installation de KDE Plasma 6 et Applications..."
# Ubuntu 24.10 intègre Plasma 6 nativement, on assure juste l'installation du desktop
apt-get install -y kubuntu-desktop kde-plasma-desktop sddm sddm-theme-breeze
# Désactiver GDM au profit de SDDM
systemctl disable gdm || true
systemctl enable sddm || true

echo ">>> [CHROOT] Installation des Outils Gaming (Steam, Lutris, MangoHud)..."
dpkg --add-architecture i386
apt-get update
apt-get install -y steam-installer lutris mangohud gamemode governlay

echo ">>> [CHROOT] Compilation asusctl / supergfxctl..."
apt-get install -y curl git build-essential cmake pkg-config libdbus-1-dev libudev-dev libsystemd-dev
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
cd /tmp
git clone --depth=1 https://gitlab.com/asus-linux/asusctl.git
cd asusctl && make && make install
systemctl enable asusd
cd /tmp
git clone --depth=1 https://gitlab.com/asus-linux/supergfxctl.git
cd supergfxctl && make && make install
systemctl enable supergfxd
cd /

echo ">>> [CHROOT] Installation OpenClaw IA (Base)..."
apt-get install -y nodejs npm
# On clone l'application dans /opt pour qu'elle soit globale sur l'ISO
cd /opt
git clone --depth=1 https://github.com/LordMadTrix/OpenClaw.git
cd OpenClaw
npm install
npm run build
# Création d'un service systemd global
cat <<EOF > /etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw AI Assistant
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/OpenClaw
ExecStart=/usr/bin/npm start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable openclaw.service
cd /

echo ">>> [CHROOT] Injection du MadOS Control Center V3..."
# Le dossier mados_src a été copié par le builder à la racine /tmp
mkdir -p /opt/mados-control-center
cp /tmp/mados_src/assets/mados_cc.py /opt/mados-control-center/
chmod +x /opt/mados-control-center/mados_cc.py
apt-get install -y python3-pyqt6 inxi hwinfo
cat <<EOF > /usr/share/applications/mados-control-center.desktop
[Desktop Entry]
Name=MadOS Control Center
Comment=Centre de commandement ROG V3
Exec=python3 /opt/mados-control-center/mados_cc.py
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=System;Settings;
EOF

echo ">>> [CHROOT] Nettoyage massif pour réduire la taille de l'ISO..."
rm -rf /root/.cargo /root/.rustup
apt-get clean
rm -rf /tmp/* /var/tmp/* /var/cache/apt/archives/*

echo ">>> [CHROOT] Injection terminée. Retour au Builder principal."
exit 0
