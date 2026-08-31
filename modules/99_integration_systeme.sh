#!/bin/bash
# ==============================================================================
# MadOS ROG Edition 3.6 - 99_integration_systeme.sh
# ==============================================================================
# Phase: 99 - Finalisation & Intégration Permanente
# Rend l'installateur disponible via commande globale et nettoie l'OOBE.
# ==============================================================================

# ==============================================================================
# Variables de Couleurs
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'

[ -f "$PROJECT_ROOT/lib/common.sh" ] && source "$PROJECT_ROOT/lib/common.sh"

echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC} 🔧 ${WHITE}${BOLD}Phase 99 Intégration Permanente au Système${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# 1. Création d'une commande globale 'mados-install'
# Note : le raccourci ci-dessous utilisait "gnome-terminal", absent sur KDE --
# c'est-a-dire sur le bureau que MadOS installe lui-meme. x-terminal-emulator
# est l'alternative Debian/Ubuntu qui pointe vers le terminal reellement present.
echo -e "    ${WHITE}├─ [CLI] Création de la commande 'mados-install'...${NC}"
if is_dry_run; then
    log_simu "écrirait le lanceur /usr/local/bin/mados-install et le rendrait exécutable"
else
    cat <<EOF | sudo tee /usr/local/bin/mados-install > /dev/null
#!/bin/bash
# Lanceur universel MadOS
curl -sL https://raw.githubusercontent.com/LordMadTrix/MadOS_ROG_Edition/main/install.sh | sudo bash
EOF
    sudo chmod +x /usr/local/bin/mados-install
fi

# 2. Création d'un raccourci sur le Bureau
echo -e "    ${WHITE}├─ [GUI] Création du raccourci sur le Bureau...${NC}"
if is_dry_run; then
    log_simu "créerait le raccourci MadOS-Installer.desktop dans $USER_HOME/Desktop et $USER_HOME/Bureau"
else
    mkdir -p "$USER_HOME/Bureau" "$USER_HOME/Desktop" 2>/dev/null || true

    cat <<EOF > "$USER_HOME/Desktop/MadOS-Installer.desktop"
[Desktop Entry]
Type=Application
Name=MadOS Installer
Comment=Relancer l'installateur MadOS
Exec=x-terminal-emulator -e mados-install
Icon=utilities-terminal
Terminal=false
Categories=System;
EOF

    cp "$USER_HOME/Desktop/MadOS-Installer.desktop" "$USER_HOME/Bureau/MadOS-Installer.desktop" 2>/dev/null || true
    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/Desktop" "$USER_HOME/Bureau" 2>/dev/null || true
    chmod +x "$USER_HOME/Desktop/MadOS-Installer.desktop" "$USER_HOME/Bureau/MadOS-Installer.desktop" 2>/dev/null || true
fi

# 3. Nettoyage de l'OOBE (Autostart & Terminal)
echo -e "    ${WHITE}├─ [SYSTEM] Nettoyage des mécanismes d'auto-run post-install...${NC}"
if is_dry_run; then
    log_simu "supprimerait /etc/xdg/autostart/mados.desktop et /usr/local/bin/mados-oobe"
else

# ==============================================================================
# 4. Bascule du réseau vers NetworkManager (DÉPLACÉE DEPUIS LE MODULE 00)
# ==============================================================================
# Elle s'exécutait au tout début de l'installation et cassait le DNS pendant que
# les 38 modules suivants essayaient de télécharger. Mesuré en VM QEMU sur une
# Ubuntu 24.04 propre, à charge apt identique :
#     bascule au début : 2362 "Could not resolve", 6391 Ign:, ~4 paquets posés
#     sans la bascule  :    0 "Could not resolve",    0 Ign:,  95 paquets posés
# Ici, en toute fin de parcours, plus rien n'a besoin du réseau : si la bascule
# se passe mal, le contrôle ci-dessous restaure l'ancienne configuration, et de
# toute façon l'utilisateur redémarre juste après.
# Assurer que NetworkManager prend le relais du réseau
echo -e "    ${GRAY}├─ Basculement réseau vers NetworkManager...${NC}"
run_action "installerait network-manager" sudo apt install -y network-manager 2>/dev/null || true

# La bascule netplan supprimait 50-cloud-init.yaml puis ecrivait un netplan
# "renderer: NetworkManager" SANS jamais verifier que NetworkManager etait bien
# installe (la commande ci-dessus finit par `|| true`). Si l'installation avait
# echoue, on detruisait une configuration reseau fonctionnelle pour la remplacer
# par une configuration sans moteur : perte totale de reseau, sans repli --
# critique en VM ou sur une machine distante. On ne bascule donc que si
# NetworkManager est REELLEMENT present, et on verifie apres coup.
if is_dry_run; then
    log_simu "verifierait la presence de NetworkManager, sauvegarderait /etc/netplan/50-cloud-init.yaml, ecrirait /etc/netplan/01-network-manager-all.yaml, appliquerait (netplan generate/apply) puis controlerait que le reseau repond"
elif ! command -v NetworkManager >/dev/null 2>&1 \
     && ! systemctl list-unit-files 2>/dev/null | grep -q '^NetworkManager\.service'; then
    echo -e "    ${YELLOW}⚠️  NetworkManager absent : bascule réseau ANNULÉE.${NC}"
    echo -e "    ${GRAY}    La configuration réseau actuelle est conservée intacte.${NC}"
else
    NETPLAN_RESTAURE=0
    if [ -f /etc/netplan/50-cloud-init.yaml ]; then
        sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak 2>/dev/null || true
        sudo rm -f /etc/netplan/50-cloud-init.yaml 2>/dev/null || true
        NETPLAN_RESTAURE=1
    fi

    sudo tee /etc/netplan/01-network-manager-all.yaml > /dev/null <<'EOF'
network:
  version: 2
  renderer: NetworkManager
EOF
    sudo chmod 600 /etc/netplan/01-network-manager-all.yaml
    sudo netplan generate 2>/dev/null || true
    sudo netplan apply 2>/dev/null || true
    activer_service "gestionnaire réseau" enable NetworkManager
    activer_service "gestionnaire réseau" restart NetworkManager
    sleep 5

    # Controle de survie. L'ancienne version testait `ping 8.8.8.8` puis
    # `ping archive.ubuntu.com` avec un &&, donc il fallait que LES DEUX
    # echouent pour restaurer. Or `ping 8.8.8.8` reussit PAR IP, sans DNS : la
    # premiere condition etait fausse et la restauration ne partait jamais.
    # Constate en VM QEMU : apt a produit 2897 lignes "Could not resolve
    # 'archive.ubuntu.com'" pendant que le garde-fou affichait "Reseau
    # operationnel". Ce qu'il faut verifier, c'est ce dont apt a besoin :
    # la RESOLUTION DE NOMS, puis un acces HTTP reel au depot.
    reseau_utilisable() {
        local hote="archive.ubuntu.com"
        # 1. Resolution DNS -- le point qui avait lache.
        getent hosts "$hote" >/dev/null 2>&1 || return 1
        # 2. Acces HTTP reel au depot (ce que fera apt juste apres).
        if command -v curl >/dev/null 2>&1; then
            curl -fsS --max-time 15 -o /dev/null "http://${hote}/ubuntu/" 2>/dev/null && return 0
        elif command -v wget >/dev/null 2>&1; then
            wget -q --timeout=15 --spider "http://${hote}/ubuntu/" 2>/dev/null && return 0
        else
            # Sans client HTTP, la resolution DNS reste le meilleur signal.
            return 0
        fi
        return 1
    }

    # NetworkManager peut avoir ete empeche de demarrer par le policy-rc.d
    # (exit 101) pose par install.sh : on le relance explicitement, ce que
    # policy-rc.d ne bloque pas, puis on laisse le temps au DHCP.
    activer_service "gestionnaire réseau" start NetworkManager
    for _essai in 1 2 3 4 5 6; do
        reseau_utilisable && break
        sleep 5
    done

    if ! reseau_utilisable; then
        echo -e "    ${RED}⚠️  DNS ou dépôt injoignable après la bascule : restauration de l'ancienne configuration...${NC}"
        sudo rm -f /etc/netplan/01-network-manager-all.yaml 2>/dev/null || true
        if [ "$NETPLAN_RESTAURE" -eq 1 ] && [ -f /etc/netplan/50-cloud-init.yaml.bak ]; then
            sudo cp /etc/netplan/50-cloud-init.yaml.bak /etc/netplan/50-cloud-init.yaml 2>/dev/null || true
        fi
        sudo netplan apply 2>/dev/null || true
        activer_service "résolution DNS" restart systemd-resolved
        sleep 5
        if reseau_utilisable; then
            echo -e "    ${GREEN}├─ Réseau restauré avec l'ancienne configuration.${NC}"
        else
            echo -e "    ${RED}❌ Réseau toujours inutilisable. Les modules suivants ne pourront rien télécharger.${NC}"
            echo -e "    ${GRAY}    Vérifiez : ${GREEN}resolvectl status${NC}${GRAY} et ${GREEN}ip route${NC}"
        fi
    else
        echo -e "    ${GREEN}├─ Réseau opérationnel (DNS et dépôt joignables).${NC}"
    fi
fi
    sudo rm -f /etc/xdg/autostart/mados.desktop 2>/dev/null || true
    sudo rm -f /usr/local/bin/mados-oobe 2>/dev/null || true
fi

echo -e "    ${WHITE}✅ [SUCCÈS] Phase 99 Terminée.${NC}"
