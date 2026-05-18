#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 05_bureau_kde_plasma.sh
# ==============================================================================
# Phase: 5 - Environnement Bureau KDE Plasma 6 (Wayland Native)
# ==============================================================================

# Variables de Couleurs
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}Phase 5 : Déploiement KDE Plasma 6 Ultimate (Wayland)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. INSTALLATION CORE
echo -e "    ${WHITE}├─ [REPOS] Vérification et mise à jour du cache APT...${NC}"

# EOL check standalone (au cas où le module est lancé seul)
_CODENAME=$(. /etc/os-release 2>/dev/null && echo "${VERSION_CODENAME:-}")
if [ -n "$_CODENAME" ] && [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
    if grep -q "archive\.ubuntu\.com" /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null; then
        if ! curl -sf --max-time 8 "https://archive.ubuntu.com/ubuntu/dists/$_CODENAME/Release" >/dev/null 2>&1; then
            echo -e "    ${YELLOW}⚠️  EOL détecté ($_CODENAME) — bascule old-releases...${NC}"
            sudo sed -i \
                -e 's|http://archive\.ubuntu\.com/ubuntu|http://old-releases.ubuntu.com/ubuntu|g' \
                -e 's|http://security\.ubuntu\.com/ubuntu|http://old-releases.ubuntu.com/ubuntu|g' \
                /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true
        fi
    fi
fi
# Activer universe/multiverse
sudo sed -i 's/^Components: main restricted$/Components: main restricted universe multiverse/' \
    /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true
sudo sed -i 's/^Components: main restricted universe$/Components: main restricted universe multiverse/' \
    /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true

_APT_OUT=$(sudo apt-get update -o Acquire::Retries=3 2>&1)
echo "$_APT_OUT" | grep -E "^Err|^W:" | head -8 || true

echo -e "    ${WHITE}├─ [DIAG] Recherche des paquets KDE disponibles...${NC}"
echo -e "    ${GRAY}    Miroir actif : $(grep -m1 'URIs:' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || echo 'inconnu')${NC}"

# Détection dynamique du bon paquet KDE pour cette version Ubuntu
_KDE_PKG=""
for _try in kubuntu-desktop kde-plasma-desktop plasma-workspace plasma-desktop; do
    if apt-cache show "$_try" &>/dev/null 2>&1; then
        _KDE_PKG="$_try"
        echo -e "    ${GREEN}    Package KDE trouvé : ${WHITE}$_try${NC}"
        break
    fi
done

if [ -z "$_KDE_PKG" ]; then
    echo -e "    ${RED}    Aucun package KDE trouvé !${NC}"
    echo -e "    ${GRAY}    Sources configurées :${NC}"
    grep -h "^URIs:\|^Components:\|^deb " /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list 2>/dev/null | head -8
    echo -e "    ${GRAY}    Packages plasma disponibles :${NC}"
    apt-cache search plasma 2>/dev/null | grep -i "desktop\|workspace\|kde" | head -8 || echo "    (aucun — apt-get update a probablement échoué)"
    echo -e "    ${YELLOW}    Sortie apt-get update (dernières lignes) :${NC}"
    echo "$_APT_OUT" | tail -15
fi

echo -e "    ${WHITE}├─ [INSTALL] Installation de KDE Plasma 6...${NC}"
if [ -n "$_KDE_PKG" ]; then
    sudo apt-get install -y "$_KDE_PKG" 2>&1 | tail -3; true
else
    echo -e "    ${RED}    ÉCHEC : impossible d'installer KDE (repos inaccessibles).${NC}"
    echo -e "    ${YELLOW}    Packages disponibles (plasma*) :${NC}"
    apt-cache search plasma 2>/dev/null | grep -i "desktop\|workspace" | head -8 || echo "    (aucun)"
fi

# Extras Wayland et apps KDE
sudo apt-get install -y xwayland sddm 2>/dev/null | tail -1 || true
for _pkg in qt6-wayland plasma-nm plasma-pa plasma-systemmonitor dolphin konsole kate ark gwenview kcalc; do
    apt-cache show "$_pkg" &>/dev/null 2>&1 && sudo apt-get install -y "$_pkg" >/dev/null 2>&1 || true
done

# 2. CONFIGURATION SDDM (WAYLAND NATIVE)
echo -e "    ${WHITE}├─ [SDDM] Activation du démarrage Wayland natif...${NC}"
sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/mados.conf >/dev/null
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland

[Theme]
Current=breeze
EOF

# 3. TRADUCTION & LOCALISATION
echo -e "    ${WHITE}├─ [LOCAL] Application de la langue française...${NC}"
sudo apt install -y language-pack-fr language-pack-kde-fr >/dev/null 2>&1 || true
sudo update-locale LANG=fr_FR.UTF-8 || true

# 4. RACCOURCIS CLAVIER (MAD-MACROS v4)
echo -e "    ${WHITE}├─ [HOTKEYS] Injection des raccourcis ROG (Plasma 6 Ready)...${NC}"
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config"
KWIN_RC="$USER_HOME/.config/kwinrc"
GLOBAL_RC="$USER_HOME/.config/kglobalshortcutsrc"

# Optimisations KWin (VRR / HDR / Tearing) — kwriteconfig6 disponible seulement si KDE installé
if command -v kwriteconfig6 &>/dev/null; then
    sudo -u "$REAL_USER" kwriteconfig6 --file "$KWIN_RC" --group "Compositing" --key "AllowTearing" "true"
    sudo -u "$REAL_USER" kwriteconfig6 --file "$KWIN_RC" --group "Compositing" --key "MaxFPS" "360"
    sudo -u "$REAL_USER" kwriteconfig6 --file "$GLOBAL_RC" --group "khotkeys" --key "{mados_game}" "Meta+Shift+G,none,MadOS Game Mode"
    sudo -u "$REAL_USER" kwriteconfig6 --file "$GLOBAL_RC" --group "kglobalaccel" --key "Kill Window" "Ctrl+Alt+Backspace,none,Force Kill Current Window"
else
    # Fallback : écrire directement dans les fichiers de config KDE
    sudo -u "$REAL_USER" mkdir -p "$(dirname "$KWIN_RC")"
    cat >> "$KWIN_RC" <<'KWINEOF'
[Compositing]
AllowTearing=true
MaxFPS=360
KWINEOF
    echo -e "    ${GRAY}    (kwriteconfig6 absent — config écrite directement)${NC}"
fi

# 5. NETTOYAGE BLOATWARE
echo -e "    ${RED}├─ [CLEAN] Suppression de GNOME et Snapd (Firefox Dev version)...${NC}"
sudo apt purge -y ubuntu-desktop gnome-shell snapd >/dev/null 2>&1 || true
# Installation Firefox via PPA (Debian package) pour éviter Snap
sudo add-apt-repository ppa:mozillateam/ppa -y >/dev/null 2>&1 || true
sudo apt install -y firefox >/dev/null 2>&1 || true

echo -e "\n${GREEN}✅ PHASE 5 TERMINÉE : Bureau Plasma 6 configuré.${NC}\n"
