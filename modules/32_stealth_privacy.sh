#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 32_stealth_privacy.sh
# ==============================================================================
# Phase: 32 - Stealth-Mode (Anti-Telemetry & Hardened Privacy)
# ==============================================================================

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

export DEBIAN_FRONTEND=noninteractive

echo -e "\n${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC} 🛡️ ${WHITE}${BOLD}Phase 32 Activation du Mode Discrétion (Stealth-Mode Privacy)${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Neutralisation du traçage Ubuntu
echo -e "    ${WHITE}├─ [TRACAGE] Désactivation du rapport d'erreurs (Apport)...${NC}"
if is_dry_run; then
    log_simu "désactiverait apport (sed sur /etc/default/apport, stop + disable du service)"
else
    backup_file "/etc/default/apport"
    sudo sed -i 's/enabled=1/enabled=0/g' /etc/default/apport 2>/dev/null || true
    sudo systemctl stop apport 2>/dev/null || true
    sudo systemctl disable apport 2>/dev/null || true
fi

echo -e "    ${WHITE}├─ [TRACAGE] Suppression de Popularity-Contest (Envoi données d'usage)...${NC}"
run_action "purgerait le paquet popularity-contest" sudo apt purge -y popularity-contest 2>/dev/null || true

# 2. Sécurisation DNS (DNS-over-TLS)
echo -e "    ${WHITE}├─ [DNS] Configuration Quad9 (Privacy) avec DNS-over-TLS...${NC}"
# On depose un drop-in au lieu d'ecraser /etc/systemd/resolved.conf : l'ancienne
# version detruisait le fichier de la distribution (et ses commentaires), ainsi
# que le drop-in mados-dns.conf pose par install.sh.
if is_dry_run; then
    log_simu "ecrirait /etc/systemd/resolved.conf.d/99-mados-stealth.conf (Quad9 + DNS-over-TLS) et redemarrerait systemd-resolved"
else
    sudo mkdir -p /etc/systemd/resolved.conf.d
    # Le drop-in DNS de secours d'install.sh (Google, en clair) ferait doublon
    # avec Quad9 : on le retire, sinon les deux serveurs cohabitent.
    sudo rm -f /etc/systemd/resolved.conf.d/mados-dns.conf 2>/dev/null || true

    cat <<'EOF' | sudo tee /etc/systemd/resolved.conf.d/99-mados-stealth.conf >/dev/null
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net
DNSOverTLS=yes
DNSSEC=yes
Domains=~.
EOF

    # Sans ce lien symbolique, la resolution ne passe pas par systemd-resolved
    # et toute la configuration ci-dessus est ignoree : le DNS-over-TLS annonce
    # n'aurait aucun effet reel.
    if [ ! -L /etc/resolv.conf ] && [ -e /run/systemd/resolve/stub-resolv.conf ]; then
        sudo cp /etc/resolv.conf /etc/resolv.conf.avant-stealth 2>/dev/null || true
        sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    fi

    activer_service "résolution DNS" restart systemd-resolved

    # Verification : on annonce du DoT, on verifie que c'est bien actif.
    if command -v resolvectl >/dev/null 2>&1; then
        if resolvectl status 2>/dev/null | grep -qi "DNSOverTLS.*yes\|+DNSOverTLS"; then
            echo -e "    ${GREEN}├─ DNS-over-TLS actif (Quad9).${NC}"
        else
            echo -e "    ${YELLOW}⚠️  DNS-over-TLS configuré mais non confirmé par resolvectl.${NC}"
        fi
    fi
fi

# 3. Firewall Gaming Hardened
echo -e "    ${WHITE}├─ [PAR-FEU] Activation du Firewall UFW (Profil Gaming)...${NC}"
if is_dry_run; then
    log_simu "installerait ufw, refuserait l'entrant, autoriserait le sortant et les ports Steam, puis l'activerait (port SSH ouvert uniquement si un serveur SSH est installe)"
else
    installer_paquets "pare-feu UFW" ufw
    sudo ufw default deny incoming || true
    sudo ufw default allow outgoing || true

    # Le port 22 n'etait ouvert "au cas ou" : sur un poste de jeu sans serveur
    # SSH, cela expose un port pour rien. On ne l'ouvre que si sshd existe
    # vraiment -- et on previent l'utilisateur quand c'est le cas.
    if systemctl list-unit-files 2>/dev/null | grep -qE '^(ssh|sshd)\.service' || command -v sshd >/dev/null 2>&1; then
        sudo ufw allow 22/tcp 2>/dev/null || true
        echo -e "    ${YELLOW}⚠️  Serveur SSH détecté : port 22 ouvert dans le pare-feu.${NC}"
        echo -e "    ${GRAY}    Pour le refermer : ${GREEN}sudo ufw delete allow 22/tcp${NC}"
    else
        echo -e "    ${GRAY}├─ Aucun serveur SSH : port 22 laissé fermé.${NC}"
    fi

    sudo ufw allow 27000:27100/udp 2>/dev/null || true
    sudo ufw --force enable 2>/dev/null || true
fi

# 4. Nettoyage Télémétrie GDM
echo -e "    ${WHITE}├─ [UI] Désactivation des services de localisation et d'usage GDM...${NC}"
if is_dry_run; then
    log_simu "désactiverait via gsettings la localisation système et l'envoi de rapports de bugs GNOME"
else
    sudo -u "${SUDO_USER:-$USER}" dbus-launch gsettings set org.gnome.system.location enabled false 2>/dev/null || true
    sudo -u "${SUDO_USER:-$USER}" dbus-launch gsettings set org.gnome.desktop.privacy report-technical-problems false 2>/dev/null || true
fi

# 5. MadOS Night-Rider (Automatisme Nocturne)
echo -e "    ${WHITE}├─ [CONFORT] Injection du Script de Confort Nocturne (Night-Rider)...${NC}"
if is_dry_run; then
    log_simu "écrirait le script /usr/local/bin/mados-night-mode et le rendrait exécutable"
else
    cat <<'NIGHT_EOF' | sudo tee /usr/local/bin/mados-night-mode >/dev/null
#!/bin/bash
# MadOS Night-Rider Logic (KDE Plasma)
#
# Corrections par rapport a la version precedente :
#  - kwriteconfig5 n'existe pas sous Plasma 6 (installe par le module 05) :
#    on detecte kwriteconfig6, avec repli sur kwriteconfig5.
#  - le `sudo -u "$SUDO_USER"` imbrique etait faux ET inutile : ce script est
#    lance par l'utilisateur, et $HOME etait de toute facon developpe par le
#    shell appelant avant le sudo, donc pointait vers /root.
#  - `asusctl led-mode` est la syntaxe asusctl v4 ; v6 utilise `asusctl aura`.

KWRITE=""
for c in kwriteconfig6 kwriteconfig5; do
    command -v "$c" >/dev/null 2>&1 && { KWRITE="$c"; break; }
done

aura() {
    # $1 = couleur hexadecimale
    if command -v asusctl >/dev/null 2>&1; then
        asusctl aura static -c "$1" >/dev/null 2>&1 \
            || asusctl led-mode static -c "$1" >/dev/null 2>&1 \
            || true
    fi
}

nightcolor() {
    # $1 = true|false
    [ -n "$KWRITE" ] || { echo "kwriteconfig introuvable : Night Color non modifie." >&2; return 0; }
    "$KWRITE" --file "$HOME/.config/kwinrc" --group NightColor --key Active "$1" 2>/dev/null || true
    # Recharger KWin pour appliquer sans deconnexion.
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 \
        || qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 \
        || true
}

case "${1:-}" in
    on)
        echo "Activation Mode Night-Rider..."
        nightcolor true
        aura 000000
        ;;
    off)
        echo "Désactivation Mode Night-Rider..."
        nightcolor false
        aura ff0000
        ;;
    *)
        echo "Usage : mados-night-mode {on|off}" >&2
        exit 1
        ;;
esac
NIGHT_EOF
    sudo chmod +x /usr/local/bin/mados-night-mode || true
fi

echo -e "    ${CYAN}✅ [SUCCÈS] Mode Stealth et Night-Rider MadOS configurés.${NC}"
echo -e "    ${WHITE}✅ [SUCCÈS] Phase 32 Terminée.${NC}"
