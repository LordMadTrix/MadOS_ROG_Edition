#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 05_bureau_kde_plasma.sh
# ==============================================================================
# Phase: 5 - KDE Plasma Desktop & Élimination Bloatware
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 5 Déploiement du Bureau KDE Plasma${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# PPA Plasma 6
if ! grep -r "kubuntu-ppa/backports" /etc/apt/sources.list.d/ &>/dev/null; then
    if is_dry_run; then
        log_simu "ajouterait les PPA kubuntu-ppa/backports et backports-extra puis ferait apt update"
    else
        sudo add-apt-repository ppa:kubuntu-ppa/backports -y > /dev/null 2>&1 || true
        sudo add-apt-repository ppa:kubuntu-ppa/backports-extra -y > /dev/null 2>&1 || true
        sudo apt update -q
    fi
fi

if is_dry_run; then
    log_simu "configurerait debconf pour sélectionner sddm comme gestionnaire d'affichage par défaut (sddm et gdm3)"
else
    echo "sddm shared/default-x-display-manager select sddm" | sudo debconf-set-selections
    echo "gdm3 shared/default-x-display-manager select sddm" | sudo debconf-set-selections
fi

# Installation KDE
echo -e "    ${WHITE}├─ [BUREAU] Compilation KDE Plasma Desktop 6...${NC}"
run_action "installerait KDE Plasma Desktop 6 et les applications associées" sudo DEBIAN_FRONTEND=noninteractive apt install -y kubuntu-desktop kde-plasma-desktop plasma-workspace plasma-session-x11 plasma-nm plasma-pa plasma-systemmonitor kde-standard dolphin konsole kate ark gwenview kde-spectacle kcalc partitionmanager dbus-x11 xserver-xorg

echo -e "    ${WHITE}├─ [TRADUCTION] Conversion Locale vers Français...${NC}"
run_action "installerait les paquets de langue française" sudo DEBIAN_FRONTEND=noninteractive apt install -y language-pack-fr language-pack-gnome-fr language-pack-kde-fr hunspell-fr
run_action "changerait la locale système vers fr_FR.UTF-8" sudo update-locale LANG=fr_FR.UTF-8 LC_MESSAGES=fr_FR.UTF-8 2>/dev/null || true

# Config SDDM
echo -e "    ${WHITE}├─ [CONNECT] Serveur de Connexion SDDM...${NC}"
run_action "installerait sddm et le thème breeze" sudo DEBIAN_FRONTEND=noninteractive apt install -y sddm sddm-theme-breeze
run_action "désactiverait gdm3, lightdm et xdm" sudo systemctl disable gdm3 lightdm xdm 2>/dev/null || true
run_action "activerait le service sddm" sudo systemctl enable sddm 2>/dev/null || true

# Détection VM pour forcer X11 (Stabilité VMware)
IS_VM=$(systemd-detect-virt)
SDDM_CONF="/etc/sddm.conf.d/mados-sddm.conf"
run_action "créerait le dossier /etc/sddm.conf.d/" sudo mkdir -p /etc/sddm.conf.d/

if [[ "$IS_VM" == "vmware" || "$IS_VM" == "qemu" || "$IS_VM" == "oracle" ]]; then
    echo -e "    ${YELLOW}⚠️  VM Détectée : Forçage du DisplayServer X11 pour la stabilité...${NC}"
    if is_dry_run; then
        log_simu "écrirait $SDDM_CONF avec DisplayServer=x11 (stabilité VM)"
    else
        # Heredoc NON quote : $REAL_USER doit etre interpole. L'ancienne version
        # ecrivait "User=mados" en dur -- si le compte ne s'appelle pas mados,
        # SDDM tentait un autologin sur un utilisateur inexistant.
        cat <<SDDM_EOF | sudo tee "$SDDM_CONF" >/dev/null
[General]
DisplayServer=x11
InputMethod=

[Theme]
Current=breeze
SDDM_EOF
        # L'autologin n'est ajoute que si le compte existe vraiment.
        if id -u "$REAL_USER" >/dev/null 2>&1; then
            cat <<SDDM_EOF | sudo tee -a "$SDDM_CONF" >/dev/null

[Autologin]
Relogin=false
Session=plasma
User=$REAL_USER
SDDM_EOF
        else
            echo -e "    ${YELLOW}⚠️  Utilisateur '$REAL_USER' introuvable : autologin non configuré.${NC}"
        fi
    fi
else
    if is_dry_run; then
        log_simu "écrirait $SDDM_CONF avec la configuration SDDM standard"
    else
        cat <<'SDDM_EOF' | sudo tee "$SDDM_CONF" >/dev/null
[Theme]
Current=breeze
[Autologin]
Relogin=false
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
[X11]
ServerPath=/usr/bin/X
ServerArguments=-nolisten tcp
EnableHiDPI=true
SDDM_EOF
    fi
fi

# Wayland env (Optionnel : On laisse le système choisir pour éviter les écrans noirs NVIDIA)
run_action "créerait le dossier $USER_HOME/.config" sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config"
# On commente les exports forcés pour la stabilité
# export QT_QPA_PLATFORM=wayland
# export GDK_BACKEND=wayland
# export MOZ_ENABLE_WAYLAND=1

# Nettoyage GNOME / FIrefox Snap
echo -e "\n    ${RED}>>> ${WHITE}[NETTOYAGE] ${BOLD}Désintégration de GNOME, Firefox (Snap) et du Démon Snapd...${NC}"
if is_dry_run; then
    log_simu "purgerait GNOME (ubuntu-desktop, gnome-shell, gnome-control-center, gnome-software, gdm3), Firefox (snap + apt) et snapd, puis nettoierait les paquets orphelins"
else
    sudo apt purge -y ubuntu-desktop gnome-shell gnome-control-center gnome-software gdm3 2>/dev/null || true
    sudo snap remove --purge firefox 2>/dev/null || true
    sudo apt-get purge -y firefox snapd 2>/dev/null || true
    sudo apt-get autoremove -y --purge > /dev/null 2>&1 || true
    sudo apt-get clean > /dev/null 2>&1 || true
fi

# ---- NOUVEAU : Macros-ROG (Raccourcis Clavier MadOS) ----
echo -e "    ${WHITE}├─ [HOTKEYS] Injection des raccourcis clavier MadOS (Macro-ROG)...${NC}"
if is_dry_run; then
    log_simu "injecterait les raccourcis clavier MadOS (Macro-ROG et Rage-Quit) dans kglobalshortcutsrc, créerait $USER_HOME/.local/share/khotkeys et rechargerait kglobalaccel"
else
    # Ce module installe Plasma 6 : kwriteconfig5 et qdbus (Plasma 5) n'existent
    # donc pas sur la machine. Tous les appels ci-dessous echouaient en silence
    # derriere `2>/dev/null || true` -- les raccourcis n'etaient jamais poses.
    KWRITE=""
    for c in kwriteconfig6 kwriteconfig5; do
        if sudo -u "$REAL_USER" command -v "$c" >/dev/null 2>&1; then KWRITE="$c"; break; fi
    done

    if [ -z "$KWRITE" ]; then
        echo -e "    ${YELLOW}⚠️  kwriteconfig introuvable : raccourcis clavier non configurés.${NC}"
    else
        raccourci() {
            sudo -u "$REAL_USER" "$KWRITE" --file "$USER_HOME/.config/kglobalshortcutsrc" \
                --group "$1" --key "$2" "$3" 2>/dev/null || true
        }
        raccourci "khotkeys"     "{mados_game}"    "Meta+Shift+G,none,MadOS Game Mode"
        raccourci "khotkeys"     "{mados_eco}"     "Meta+Shift+E,none,MadOS Eco Mode"
        raccourci "khotkeys"     "{mados_stealth}" "Meta+Shift+S,none,MadOS Stealth Mode"
        # ---- Rage-Quit Force (Kill Game) ----
        raccourci "kglobalaccel" "Kill Window"     "Ctrl+Alt+Backspace,none,Force Kill Current Window"
        echo -e "    ${GRAY}├─ Raccourcis posés via ${KWRITE}.${NC}"
    fi

    # Création du dossier khotkeys si manquant
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.local/share/khotkeys"

    # Prise en compte immediate si une session est active (qdbus6 sous Plasma 6).
    for q in qdbus6 qdbus-qt6 qdbus; do
        if sudo -u "$REAL_USER" command -v "$q" >/dev/null 2>&1; then
            sudo -u "$REAL_USER" "$q" org.kde.kglobalaccel /kglobalaccel reconfigure >/dev/null 2>&1 || true
            break
        fi
    done
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 5 Terminée.${NC}"
