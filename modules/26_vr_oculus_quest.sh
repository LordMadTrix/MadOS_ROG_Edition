#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.5 - 26_vr_oculus_quest.sh
# ==============================================================================
# Couleurs
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
BLUE='\033[0;34m'

# Thème Whiptail MadOS
export NEWT_COLORS='
  root=black,black
  window=white,black
  border=red,black
  shadow=black,black
  title=white,red
  button=white,black
  actbutton=white,red
  compactbutton=white,black
  textbox=white,black
  listbox=white,black
  actlistbox=white,red
  sellistbox=white,black
  actsellistbox=white,red
  checkbox=white,black
  actcheckbox=white,red
'

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${CYAN}   19. Intégration VR (Meta Quest 3, ALVR, SideQuest)${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "${YELLOW}[!] Ce module configure le support natif pour les casques Meta Quest.${NC}"

# 1. Installation des pré-requis (ADB, fuse, jq)
echo -e "\n${BLUE}[+] Installation des outils Android (ADB) et dépendances...${NC}"
run_action "mettrait à jour les index apt" sudo apt-get update || true
run_action "installerait android-tools-adb curl jq libfuse2 wget xz-utils libnss3" sudo apt-get install -y android-tools-adb curl jq libfuse2 wget xz-utils libnss3 || true

# 2. Règles udev pour Meta Quest (Vendor ID 2833)
echo -e "\n${BLUE}[+] Configuration des règles USB (Udev) pour Oculus/Meta Quest...${NC}"
UDEV_RULE_FILE="/etc/udev/rules.d/51-android.rules"
if ! grep -q "2833" "$UDEV_RULE_FILE" 2>/dev/null; then
    if is_dry_run; then
        log_simu "ajouterait la règle udev Oculus/Meta Quest (Vendor ID 2833) dans $UDEV_RULE_FILE et rechargerait udev"
    else
        echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="2833", MODE="0666", GROUP="plugdev"' | sudo tee -a "$UDEV_RULE_FILE" >/dev/null
        sudo udevadm control --reload-rules || true
        sudo udevadm trigger || true
        echo -e "    ${GRAY}├─ Règles udev Oculus ajoutées avec succès.${NC}"
    fi
else
    echo -e "    ${GRAY}├─ Règles udev Oculus déjà présentes.${NC}"
fi

# Création du dossier /opt/VR si nécessaire
run_action "créerait /opt/MadOS_VR" sudo mkdir -p /opt/MadOS_VR
run_action "changerait le propriétaire de /opt/MadOS_VR pour $REAL_USER" sudo chown -R $REAL_USER:$REAL_USER /opt/MadOS_VR

# 3. Installation de SideQuest
echo -e "\n${BLUE}[+] Installation de SideQuest (Sideloading & Gestion Casque)...${NC}"
SQ_PATH="/opt/MadOS_VR/SideQuest-X11.tar.xz"
echo -e "    ${GRAY}├─ Téléchargement de la dernière version de SideQuest...${NC}"
# Méthode robuste: on demande le lien de redirection de la page "latest" (pas de limite d'API)
SQ_LATEST_TAG=$(curl -sS -o /dev/null -w "%{url_effective}" -I -L https://github.com/SideQuestVR/SideQuest/releases/latest | awk -F'/' '{print $NF}')
SQ_NUM_VERSION=${SQ_LATEST_TAG#v}
SQ_LATEST_URL="https://github.com/SideQuestVR/SideQuest/releases/download/${SQ_LATEST_TAG}/SideQuest-${SQ_NUM_VERSION}.tar.xz"

if [ -n "$SQ_LATEST_TAG" ]; then
    if is_dry_run; then
        log_simu "téléchargerait SideQuest ($SQ_LATEST_URL), l'installerait dans /opt/MadOS_VR/SideQuest et créerait le raccourci /usr/share/applications/sidequest.desktop"
    else
        if wget -qO "$SQ_PATH" "$SQ_LATEST_URL"; then
            echo -e "    ${GRAY}├─ Extraction de SideQuest dans /opt/MadOS_VR/SideQuest...${NC}"
            sudo rm -rf /opt/MadOS_VR/SideQuest
            sudo mkdir -p /opt/MadOS_VR/SideQuest
            if sudo tar -xf "$SQ_PATH" -C /opt/MadOS_VR/SideQuest --strip-components=1 2>/dev/null; then
                sudo rm -f "$SQ_PATH" || true
                sudo chown -R $REAL_USER:$REAL_USER /opt/MadOS_VR/SideQuest || true

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
                echo -e "${RED}    [!] Fichier SideQuest corrompu ou invalide.${NC}"
            fi
        else
            echo -e "${RED}    [!] Echec du téléchargement (Erreur réseau/Github).${NC}"
        fi
    fi
else
    echo -e "${RED}[!] Impossible de récupérer le lien de SideQuest.${NC}"
fi

# 4. Installation de ALVR (Air Light VR pour PCVR)
echo -e "\n${BLUE}[+] Installation de ALVR (Streaming PCVR Sans Fils)...${NC}"
ALVR_PATH="/opt/MadOS_VR/alvr_launcher_linux.tar.gz"
echo -e "    ${GRAY}├─ Téléchargement de la dernière version de ALVR...${NC}"
ALVR_LATEST_TAG=$(curl -sS -o /dev/null -w "%{url_effective}" -I -L https://github.com/alvr-org/ALVR/releases/latest | awk -F'/' '{print $NF}')
ALVR_LATEST_URL="https://github.com/alvr-org/ALVR/releases/download/${ALVR_LATEST_TAG}/alvr_launcher_linux.tar.gz"

if [ -n "$ALVR_LATEST_TAG" ]; then
    if is_dry_run; then
        log_simu "téléchargerait ALVR ($ALVR_LATEST_URL), l'installerait dans /opt/MadOS_VR/ALVR et créerait le raccourci /usr/share/applications/alvr.desktop"
    else
        if wget -qO "$ALVR_PATH" "$ALVR_LATEST_URL"; then
            echo -e "    ${GRAY}├─ Extraction de ALVR dans /opt/MadOS_VR/ALVR...${NC}"
            sudo rm -rf /opt/MadOS_VR/ALVR
            sudo mkdir -p /opt/MadOS_VR/ALVR
            if sudo tar -xf "$ALVR_PATH" -C /opt/MadOS_VR/ALVR --strip-components=1 2>/dev/null; then
                sudo rm -f "$ALVR_PATH"

                # Renommer l'exécutable qui contient un espace chiant "ALVR Launcher"
                if [ -f "/opt/MadOS_VR/ALVR/ALVR Launcher" ]; then
                    sudo mv "/opt/MadOS_VR/ALVR/ALVR Launcher" "/opt/MadOS_VR/ALVR/alvr_launcher"
                fi
                sudo chown -R $REAL_USER:$REAL_USER /opt/MadOS_VR/ALVR

                # Création du raccourci
                echo -e "    ${GRAY}├─ Création du raccourci Bureau pour ALVR Launcher...${NC}"
                cat <<EOF | sudo tee "/usr/share/applications/alvr.desktop" >/dev/null
[Desktop Entry]
Name=ALVR Launcher
Comment=Wireless PCVR for Standalone Headsets
Exec=/opt/MadOS_VR/ALVR/alvr_launcher
Terminal=false
Type=Application
Icon=steam
Categories=Game;VR;
EOF
            else
                echo -e "${RED}    [!] Fichier ALVR corrompu ou invalide.${NC}"
            fi
        else
            echo -e "${RED}    [!] Echec du téléchargement (Erreur réseau/Github).${NC}"
        fi
    fi
else
    echo -e "${RED}[!] Impossible de récupérer le lien de ALVR.${NC}"
fi

# Redémarrage propre du serveur ADB pour s'assurer qu'il prenne en compte les règles
if is_dry_run; then
    log_simu "redémarrerait le serveur ADB (kill-server puis start-server)"
else
    sudo -u "$REAL_USER" adb kill-server 2>/dev/null
    sudo -u "$REAL_USER" adb start-server 2>/dev/null
fi

echo -e "\n${GREEN}[SUCCÈS] Intégration VR (Meta Quest, ADB, ALVR, SideQuest) terminée.${NC}"
echo -e "${CYAN}Branchez votre Meta Quest 3 au PC via USB et acceptez le message 'Autoriser le débogage USB' à l'intérieur du casque !${NC}"
sleep 4
