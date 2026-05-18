#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 4.0 - 20_esport_usb_1000hz.sh
# ==============================================================================
# Phase: 20 - E-Sport Zero Latency (USB Udev Rules)
# ==============================================================================

# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🚀 ${WHITE}${BOLD}Phase 20 : Tuning E-Sport v4.0 (Zéro Latence USB)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

UDEV_RULES_FILE="/etc/udev/rules.d/99-usb-latency.rules"

echo -e "    ${GRAY}├─ Désactivation de l'autosuspend USB (pour les souris/claviers Gamer)...${NC}"

# Création d'une règle UDEV pour empêcher le noyau de clignoter / mettre en veille les ports USB au bout de X secondes (supprime les micro-freezes).
cat <<'EOF' | sudo tee "$UDEV_RULES_FILE" >/dev/null
# Désactiver le "USB autosuspend" pour éviter les pertes de connexion/latence
ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
# Certains kernels require "on" to force always-on.
ACTION=="add", SUBSYSTEM=="usb", TEST=="power/autosuspend", ATTR{power/autosuspend}="-1"
EOF

sudo udevadm control --reload-rules || true
sudo udevadm trigger || true

echo -e "    ${GRAY}├─ Injection d'un polling rate Kernel forcé...${NC}"
# Optionnel : Sous certains OS/Kernel, le polling default est 125hz (souris standard).
# Bien que XanMod gère bien, on peut forcer le refreshrate de l'USBHID (Polling Rate).
MODPROBE_FILE="/etc/modprobe.d/usbhid.conf"
echo 'options usbhid mousepoll=1' | sudo tee "$MODPROBE_FILE" >/dev/null

# Rebuild l'initramfs pour inclure ce paramètre usbhid kernel
echo -e "    ${GRAY}├─ Régénération des accès HID (${CYAN}Ceci prendra 15s...${GRAY})${NC}"
sudo update-initramfs -u -k all >/dev/null 2>&1 || true

echo -e "    ${CYAN}✅ [SUCCÈS] Autosuspend désactivé, vos périphériques ne seront jamais bridés électriquement.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 20 Terminée.${NC}"
