#!/bin/bash
# MadOS ROG Edition - Module 19: Suite VR Oculus/Meta Quest

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

REAL_USER=$(logname || echo $SUDO_USER)
USER_HOME=$(eval echo ~$REAL_USER)

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${CYAN}   19. Intégration VR (Meta Quest 3, ALVR, SideQuest)${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "${YELLOW}[!] Ce module configure le support natif pour les casques Meta Quest.${NC}"

# 1. Installation des pré-requis (ADB, fuse, jq)
echo -e "\n${BLUE}[+] Installation des outils Android (ADB) et dépendances...${NC}"
sudo apt-get update
sudo apt-get install -y android-tools-adb curl jq libfuse2 wget xz-utils libnss3

# 2. Règles udev pour Meta Quest (Vendor ID 2833)
echo -e "\n${BLUE}[+] Configuration des règles USB (Udev) pour Oculus/Meta Quest...${NC}"
UDEV_RULE_FILE="/etc/udev/rules.d/51-android.rules"
if ! grep -q "2833" "$UDEV_RULE_FILE" 2>/dev/null; then
    echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="2833", MODE="0666", GROUP="plugdev"' | sudo tee -a "$UDEV_RULE_FILE" >/dev/null
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo -e "    ${GRAY}├─ Règles udev Oculus ajoutées avec succès.${NC}"
else
    echo -e "    ${GRAY}├─ Règles udev Oculus déjà présentes.${NC}"
fi

# Création du dossier /opt/VR si nécessaire
sudo mkdir -p /opt/MadOS_VR
sudo chown -R $REAL_USER:$REAL_USER /opt/MadOS_VR

# 3. Installation de SideQuest
echo -e "\n${BLUE}[+] Installation de SideQuest (Sideloading & Gestion Casque)...${NC}"
SQ_PATH="/opt/MadOS_VR/SideQuest-X11.tar.xz"
echo -e "    ${GRAY}├─ Téléchargement de la dernière version de SideQuest...${NC}"
# On parse directement la page HTML pour éviter la limite d'API GitHub (60 requêtes/heure)
SQ_LATEST_REF=$(curl -sL "https://github.com/SideQuestVR/SideQuest/releases/latest" | grep -Eo 'href="[^"]*SideQuest-[0-9.]*\.tar\.xz"' | head -n 1 | cut -d'"' -f2)
SQ_LATEST_URL="https://github.com${SQ_LATEST_REF}"

if [ -n "$SQ_LATEST_REF" ]; then
    wget -qO "$SQ_PATH" "$SQ_LATEST_URL"
    echo -e "    ${GRAY}├─ Extraction de SideQuest dans /opt/MadOS_VR/SideQuest...${NC}"
    sudo rm -rf /opt/MadOS_VR/SideQuest
    sudo mkdir -p /opt/MadOS_VR/SideQuest
    sudo tar -xf "$SQ_PATH" -C /opt/MadOS_VR/SideQuest --strip-components=1
    sudo rm -f "$SQ_PATH"
    sudo chown -R $REAL_USER:$REAL_USER /opt/MadOS_VR/SideQuest
    
    # Création du raccourci
    echo -e "    ${GRAY}├─ Création du raccourci Bureau pour SideQuest...${NC}"
    cat <<EOF | sudo tee "/usr/share/applications/sidequest.desktop" >/dev/null
[Desktop Entry]
Name=SideQuest
Comment=Sideload apps to Oculus Quest
Exec=/opt/MadOS_VR/SideQuest/sidequest
Terminal=false
Type=Application
Icon=/opt/MadOS_VR/SideQuest/resources/app/icon.png
Categories=Utility;Game;
EOF
else
    echo -e "${RED}[!] Impossible de récupérer le lien de SideQuest.${NC}"
fi

# 4. Installation de ALVR (Air Light VR pour PCVR)
echo -e "\n${BLUE}[+] Installation de ALVR (Streaming PCVR Sans Fils)...${NC}"
ALVR_PATH="/opt/MadOS_VR/ALVR.AppImage"
echo -e "    ${GRAY}├─ Téléchargement de la dernière version de ALVR...${NC}"
ALVR_LATEST_REF=$(curl -sL "https://github.com/alvr-org/ALVR/releases/latest" | grep -Eo 'href="[^"]*ALVR_Launcher-[^-]*-x86_64\.AppImage"' | head -n 1 | cut -d'"' -f2)
ALVR_LATEST_URL="https://github.com${ALVR_LATEST_REF}"

if [ -n "$ALVR_LATEST_REF" ]; then
    wget -qO "$ALVR_PATH" "$ALVR_LATEST_URL"
    sudo chmod +x "$ALVR_PATH"
    sudo chown $REAL_USER:$REAL_USER "$ALVR_PATH"
    
    # Création du raccourci
    echo -e "    ${GRAY}├─ Création du raccourci Bureau pour ALVR Launcher...${NC}"
    cat <<EOF | sudo tee "/usr/share/applications/alvr.desktop" >/dev/null
[Desktop Entry]
Name=ALVR Launcher
Comment=Wireless PCVR for Standalone Headsets
Exec=/opt/MadOS_VR/ALVR.AppImage
Terminal=false
Type=Application
Icon=steam
Categories=Game;VR;
EOF
else
    echo -e "${RED}[!] Impossible de récupérer le lien de ALVR.${NC}"
fi

# Redémarrage propre du serveur ADB pour s'assurer qu'il prenne en compte les règles
sudo -u "$REAL_USER" adb kill-server 2>/dev/null
sudo -u "$REAL_USER" adb start-server 2>/dev/null

echo -e "\n${GREEN}[SUCCÈS] Intégration VR (Meta Quest, ADB, ALVR, SideQuest) terminée.${NC}"
echo -e "${CYAN}Branchez votre Meta Quest 3 au PC via USB et acceptez le message 'Autoriser le débogage USB' à l'intérieur du casque !${NC}"
sleep 4
