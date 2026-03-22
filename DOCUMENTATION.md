# 📖 DOCUMENTATION COMPLÈTE — MadOS ROG Edition v3.0

> **Auteur :** LordMadTrix  
> **Version :** 3.0 (Noble / Ubuntu 24.04)  
> **Cible :** Laptop ASUS ROG — Post-Installation Linux Gaming  
> **Date de génération :** 2026-03-01

---

## 🧩 Vue d'Ensemble du Projet

MadOS ROG Edition est un système de post-installation automatisé pour transformer une installation Ubuntu 24.04 standard en un OS gaming extrême optimisé pour les laptops ASUS ROG. Il repose sur un **menu TUI interactif** (Whiptail) qui orchestre l'exécution de **27 modules shell** indépendants.

```
MadROG poste install/
├── install_local.sh         ← Script principal (lanceur local TUI)
├── install.sh               ← Bootstrap d'installation rapide (wget)
├── modules/
│   ├── 00_nettoyage_ubuntu.sh   ← Phase 0  : Nettoyage & Dépôts
│   ├── 01_noyau_xanmod.sh       ← Phase 1  : Kernel XanMod EDGE
│   ├── 02_pilotes_gpu_auto.sh   ← Phase 2  : Pilotes GPU (NVIDIA/AMD/Intel)
│   ├── 03_integration_rog.sh    ← Phase 3  : Hardware ASUS ROG
│   ├── 04_arsenal_logiciel.sh   ← Phase 4  : Logiciels Gaming
│   ├── 05_bureau_kde_plasma.sh  ← Phase 5  : Bureau KDE Plasma 6
│   ├── 06_thematique_mados.sh   ← Phase 6  : Thème Visuel ROG
│   ├── 07_snapshots_systeme.sh  ← Phase 7  : Sauvegardes Timeshift
│   ├── 08_proton_gamescope.sh   ← Phase 8  : Ultra Gaming Proton-GE
│   ├── 09_montage_ntfs.sh       ← Phase 9  : Disques NTFS Windows
│   ├── 10_son_demarrage.sh      ← Phase 10 : Son de session ROG
│   ├── 11_batterie_extreme.sh   ← Phase 11 : auto-cpufreq
│   ├── 12_mangohud_rog.sh       ← Phase 12 : Profil MangoHud
│   ├── 13_pack_streamer.sh      ← Phase 13 : OBS Studio
│   ├── 14_openclaw_ai.sh        ← Phase 14 : IA OpenClaw + Ollama
│   ├── 15_reseau_antilag.sh     ← Phase 15 : TCP BBR Anti-Lag
│   ├── 16_zram_memoire.sh       ← Phase 16 : ZRAM (Swap compressé)
│   ├── 17_bouclier_antipub.sh   ← Phase 17 : Blocage Pub (Hosts)
│   ├── 18_pack_pro_dev.sh       ← Phase 18 : Docker + VSCodium + QEMU
│   ├── 19_donnees_fstrim.sh     ← Phase 19 : Maintenance SSD
│   ├── 20_esport_usb_1000hz.sh  ← Phase 20 : USB Polling 1000Hz
│   ├── 21_boot_eclair.sh        ← Phase 21 : Boot LZ4 rapide
│   ├── 22_cpu_undervolt.sh      ← Phase 22 : Undervolt CPU
│   ├── 23_control_center.sh     ← Phase 23 : GUI MadOS Control Center
│   ├── 24_mados_update.sh       ← Phase 24 : Mise à jour GitHub
│   ├── 25_sante_systeme.sh      ← Phase 25 : Diagnostic Santé
│   └── 26_vr_oculus_quest.sh    ← Phase 26 : Suite VR Meta Quest
└── assets/
    ├── logo.png                 ← Logo Plymouth personnalisé
    ├── wallpapers/              ← Fonds d'écran MadOS ROG
    └── mados_cc.py              ← Application PyQt6 Control Center
```

---

## 🚀 Script Principal : `install_local.sh`

**Rôle :** Point d'entrée du système local. Affiche le menu TUI et orchestre l'exécution des modules.

### Commandes et leur rôle

```bash
set -uo pipefail
```
Active le mode strict : `-u` = erreur si variable non définie, `-o pipefail` = échec de pipe propagé.  
⚠️ `-e` (exit on error) est volontairement **absent** pour ne pas crasher sur les annulations whiptail.

```bash
command -v whiptail >/dev/null 2>&1
sudo apt-get install -y whiptail dialog
```
Vérifie si `whiptail` est installé (outil TUI Newt), l'installe si absent.

```bash
if [ "$EUID" -ne 0 ]; then ... exit 1; fi
```
Vérifie que le script est lancé en **root** (`EUID=0`). Affiche une erreur whiptail sinon.

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MODULES_DIR="$SCRIPT_DIR/modules"
```
Calcule le chemin absolu du script (fonctionne même avec des chemins relatifs ou des liens symboliques) et définit le répertoire des modules.

```bash
chmod +x "$MODULES_DIR"/*.sh 2>/dev/null || true
```
Rend tous les modules exécutables. Le `|| true` empêche un crash si le dossier est vide.

```bash
exec < /dev/tty
tput reset 2>/dev/null || true
```
**Crucial pour wget/curl pipe** : réattache l'entrée standard au terminal physique.  
`tput reset` efface l'écran et réinitialise le terminal proprement.

```bash
echo 'Defaults env_keep += "DEBIAN_FRONTEND NEEDRESTART_MODE"' | sudo tee /etc/sudoers.d/mados-apt-env > /dev/null
sudo chmod 0440 /etc/sudoers.d/mados-apt-env
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
```
Empêche APT d'afficher des dialogues interactifs pendant l'installation (`noninteractive`).  
`NEEDRESTART_MODE=a` = redémarre automatiquement les services sans demander.  
Le fichier sudoers préserve ces variables même sous sudo.

```bash
export LOG_FILE="/var/log/mados_install.log"
echo "=== Début ===" > "$LOG_FILE"
```
Initialise le fichier de log principal dans `/var/log/`.

```bash
export RED='\033[0;31m'  # Codes ANSI de couleur
export NEWT_COLORS="root=black,black window=white,black ..."
```
Définit les codes de couleur shell et la palette de couleurs de l'interface whiptail.

```bash
run_module() {
    bash "$MODULES_DIR/$SCRIPT" 2>&1 | tee -a "$LOG_FILE"
}
```
**Fonction centrale** : exécute un module shell, redirige `stderr` vers `stdout`, et enregistre tout dans le log via `tee`.  
En cas d'échec, propose un menu whiptail : Réessayer / Ignorer / Arrêter.

```bash
CHOICES=$(whiptail --checklist ... 3>&1 1>&2 2>&3)
```
La redirection `3>&1 1>&2 2>&3` est obligatoire pour capturer la sortie de whiptail dans une variable (whiptail écrit sur stderr par défaut).

```bash
LOG_URL=$(cat "$LOG_FILE" | nc termbin.com 9999 || echo "Échec")
```
Upload le log sur **Termbin** (pastebin en ligne de commande via netcat) et retourne l'URL pour partage.

---

## 📦 Module 00 : `00_nettoyage_ubuntu.sh` — Purification & Dépôts

**Rôle :** Nettoie les bloatwares Ubuntu Server et configure tous les dépôts tiers nécessaires.

```bash
sudo pkill -f apt 2>/dev/null || true
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a
```
Tue les processus apt bloquants et nettoie les **verrous APT/DPKG** (évite les erreurs "dpkg was interrupted").  
`dpkg --configure -a` reprend toute configuration DPKG interrompue.

```bash
sudo apt purge -y cloud-init multipath-tools snapd
sudo apt autoremove -y --purge
sudo rm -rf /etc/cloud/ /var/lib/cloud/
```
Supprime les services **cloud server** inutiles sur un laptop :  
- `cloud-init` : outil de configuration cloud (AWS, Azure)  
- `multipath-tools` : gestion RAID serveur  
- `snapd` : store snap Canonical  

```bash
sudo apt install -y network-manager
sudo rm /etc/netplan/50-cloud-init.yaml
sudo tee /etc/netplan/01-network-manager-all.yaml > /dev/null << 'EOF'
network:
  version: 2
  renderer: NetworkManager
EOF
sudo netplan generate
sudo systemctl enable NetworkManager
```
Transfère la gestion réseau de cloud-init vers **NetworkManager** (plus adapté au desktop).  
`netplan generate` recompile la configuration réseau.

```bash
sudo dpkg --add-architecture i386
```
Active **l'architecture 32 bits** (i386), indispensable pour Steam, Wine, et certains jeux.

```bash
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=...] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
```
Ajoute le **dépôt Google Chrome** avec vérification de signature GPG (méthode moderne via `/etc/apt/keyrings/`).

```bash
curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify-new.gpg
```
Ajoute le **dépôt Spotify** (deux clés GPG : ancienne + nouvelle pour compatibilité).

```bash
wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=...] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
```
Ajoute le **dépôt XanMod** (kernel gaming optimisé).

```bash
sudo add-apt-repository ppa:lutris-team/lutris -y --no-update
sudo add-apt-repository universe -y --no-update
sudo add-apt-repository multiverse -y --no-update
sudo add-apt-repository restricted -y --no-update
```
Active les dépôts Ubuntu étendus :  
- `universe` : logiciels communautaires non-officiels  
- `multiverse` : logiciels propriétaires/restrictifs  
- `restricted` : pilotes propriétaires (NVIDIA)  
- PPA Lutris : launcher de jeux multi-plateformes  

```bash
sudo apt update -q
sudo apt upgrade -y -q
sudo apt install -y build-essential git curl wget cmake pkg-config unzip p7zip-full htop vim nano pipx zsh gamemode ...
```
Mise à jour du système et installation des **utilitaires de base**.  
`build-essential` = compilateurs C/C++, `gamemode` = optimiseur CPU/GPU pour jeux.

---

## ⚡ Module 01 : `01_noyau_xanmod.sh` — Kernel XanMod EDGE

**Rôle :** Installe le kernel Linux XanMod optimisé pour le gaming (réduction de latence, scheduler amélioré).

```bash
detect_cpu_level() {
    flags=$(grep -m1 '^flags' /proc/cpuinfo)
    if echo "$flags" | grep -q 'avx512f'; then echo "x64v4"
    elif echo "$flags" | grep -q 'avx2'; then echo "x64v3"
    elif echo "$flags" | grep -q 'sse4_2'; then echo "x64v2"
    else echo "x64v1"; fi
}
```
Détecte le **niveau d'optimisation SIMD du CPU** :  
- `x64v4` : AVX-512 (Intel Alder Lake+, AMD Zen 4)  
- `x64v3` : AVX2 (ROG cible principale — Intel Haswell+, AMD Zen)  
- `x64v2` : SSE4.2 (CPUs anciens)  
Lit les flags CPU depuis `/proc/cpuinfo`.

```bash
XANMOD_PKG="linux-xanmod-edge-${CPU_LEVEL}"
sudo apt install -y "$XANMOD_PKG"
```
Installe le **kernel XanMod EDGE** ciblé pour l'architecture CPU détectée.  
Fallback sur `linux-xanmod-edge` générique si la version spécifique échoue.

```bash
sudo apt install -y "linux-headers-xanmod-edge-${CPU_LEVEL}"
```
Installe les **en-têtes kernel** nécessaires pour DKMS (Dynamic Kernel Module Support), indispensable pour compiler les pilotes NVIDIA.

```bash
sudo update-grub
```
Met à jour la configuration GRUB pour démarrer sur le nouveau kernel au prochain redémarrage.

---

## 🎮 Module 02 : `02_pilotes_gpu_auto.sh` — Pilotes GPU

**Rôle :** Détecte automatiquement la carte graphique et installe les pilotes appropriés.

```bash
GPU_INFO=$(lspci | grep -i 'vga\|3d\|2d')
```
Liste le matériel PCI et filtre les **contrôleurs graphiques** (VGA, 3D, 2D).

```bash
sudo add-apt-repository ppa:graphics-drivers/ppa -y --no-update
RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep 'recommended' | grep -o 'nvidia-driver-[0-9]*')
```
Ajoute le PPA NVIDIA officiel et utilise `ubuntu-drivers` pour **détecter automatiquement le meilleur pilote NVIDIA** recommandé.

```bash
sudo apt install -y "$RECOMMENDED_DRIVER" dkms nvidia-utils-550
```
Installe le pilote NVIDIA via **DKMS** (se recompile automatiquement à chaque mise à jour du kernel).

```bash
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-modeset.conf
sudo update-initramfs -u
```
Active **NVIDIA DRM Modeset**, obligatoire pour faire fonctionner Wayland avec les pilotes NVIDIA propriétaires.

```bash
sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 libvulkan1 xserver-xorg-video-amdgpu
```
Pour AMD : installe les drivers **Mesa open-source** + Vulkan (RADV) pour les deux architectures (64 et 32 bits).

---

## 🔧 Module 03 : `03_integration_rog.sh` — Hardware ASUS ROG

**Rôle :** Intégration complète du hardware ASUS ROG : WiFi, audio, GPU hybride, asusctl.

```bash
ROG_MODEL=$(sudo dmidecode -s system-product-name)
```
Lit le modèle du laptop depuis le **DMI/BIOS** (ex: "ROG Zephyrus G14 GA402").

```bash
sudo apt install -y linux-firmware firmware-sof-signed wireless-tools iw rfkill wpasupplicant alsa-base alsa-utils pulseaudio pipewire pipewire-pulse wireplumber libspa-0.2-bluetooth blueman bluetooth bluez
```
Installe un stack audio/réseau complet :  
- `linux-firmware`, `firmware-sof-signed` : firmwares WiFi et audio Intel SOF  
- `pipewire` + `wireplumber` : serveur audio moderne (remplace PulseAudio)  
- `bluez`, `blueman` : Bluetooth  

```bash
sudo -u "$REAL_USER" systemctl --user enable pipewire pipewire-pulse wireplumber
```
Active PipeWire en tant que **service utilisateur** (pas système).

```bash
sudo apt remove --purge -y power-profiles-daemon
sudo apt install -y tlp tlp-rdw thermald acpi acpid cpufrequtils
```
Remplace le gestionnaire d'énergie GNOME par **TLP** (optimisé laptops) et **thermald** (protection thermique Intel).

```bash
sudo tee /etc/modules-load.d/asus-rog.conf > /dev/null << 'EOF'
asus_wmi
asus_nb_wmi
asus_ec_sensors
hid_asus
EOF
```
Force le chargement au démarrage des **modules kernel ASUS** :  
- `asus_wmi` : interface WMI (boutons Fn, profils GPU)  
- `asus_nb_wmi` : WMI spécifique laptops  
- `asus_ec_sensors` : capteurs EC (températures, fans)  
- `hid_asus` : clavier ROG (RGB, macros)  

```bash
echo 'options asus_wmi fnlock_default=1' | sudo tee /etc/modprobe.d/asus-wmi.conf
```
**Active par défaut le verrou Fn** (touches F1-F12 = fonctions multimédia).

```bash
sudo tee /etc/tlp.d/99-mados-rog.conf << 'EOF'
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
WIFI_PWR_ON_AC=off
EOF
```
Configure TLP : `performance` sur secteur, `powersave` sur batterie, WiFi toujours actif sur secteur.

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"
```
Installe **Rust** (nécessaire pour compiler asusctl et supergfxctl depuis les sources).

```bash
sudo apt install -y libclang-dev libudev-dev libfontconfig1-dev libseat-dev libinput-dev libdbus-1-dev ...
```
Installe toutes les **bibliothèques de développement** nécessaires pour la compilation Rust des outils ASUS.

```bash
build_tool() {
    git clone --depth=1 "$REPO" "$REPO_DIR"  # Clone superficiel (plus rapide)
    local MAX_JOBS=$(nproc)
    if [ "$MAX_JOBS" -gt 2 ]; then MAX_JOBS=2; fi  # Limite CPU pour éviter kernel panic
    cargo build --release -j"$MAX_JOBS"
    sudo cp "target/release/$NAME" /usr/local/bin/
    sudo systemctl enable "$NAME"
}
build_tool "https://gitlab.com/asus-linux/supergfxctl.git" "supergfxctl"
build_tool "https://gitlab.com/asus-linux/asusctl.git" "asusctl"
```
**Compile et installe depuis les sources GitLab asus-linux** :  
- `supergfxctl` : bascule entre GPU hybride/discret/intégré  
- `asusctl` : contrôle des profils d'énergie ROG, LED, ventilateurs, Aura  
La limitation à 2 jobs évite les freezes système pendant la compilation.

---

## 🛠️ Module 04 : `04_arsenal_logiciel.sh` — Logiciels Gaming

**Rôle :** Installe le stack logiciel gaming complet.

```bash
install_pkg() {
    for pkg in "$@"; do
        if apt-cache show "$pkg" &>/dev/null; then
            sudo apt install -y "$pkg" || true
        fi
    done
}
```
Fonction utilitaire : installe un paquet **seulement s'il existe dans les dépôts** (évite les erreurs sur les paquets indisponibles).

```bash
install_pkg google-chrome-stable    # Navigateur Google Chrome
install_pkg spotify-client           # Streaming musical
install_pkg steam-installer steam-devices lutris   # Gaming PC
```
- `steam-installer` : télécharge et installe Steam  
- `steam-devices` : règles udev pour manettes, casques Steam  
- `lutris` : launcher multi-jeux (GOG, Epic, Battle.net, etc.)  

```bash
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
install_pkg vlc obs-studio stacer mangohud goverlay ttf-mscorefonts-installer pipx
```
- Pre-accepte la EULA des **polices Microsoft** (évite la popup debconf)  
- `mangohud` : overlay de performance en jeu (FPS, GPU, CPU, RAM)  
- `goverlay` : GUI pour configurer MangoHud  
- `stacer` : gestionnaire de tâches/nettoyeur graphique  

```bash
sudo -u "$REAL_USER" pipx install protonup-qt
```
Installe **ProtonUp-Qt** via pipx (gestionnaire Python isolé) : permet d'installer les versions custom de Proton-GE pour Steam.

```bash
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub com.heroicgameslauncher.hgl
sudo flatpak install -y flathub com.steamgriddb.SGDBoop
```
Installe depuis **Flathub** :  
- **Heroic Games Launcher** : client Epic Games Store et GOG natif Linux  
- **SGDBoop** : outil d'art Steam Grid DB (images de jeux)  

---

## 🖥️ Module 05 : `05_bureau_kde_plasma.sh` — KDE Plasma 6

**Rôle :** Installe KDE Plasma 6 en Wayland, configure SDDM, supprime GNOME.

```bash
sudo add-apt-repository ppa:kubuntu-ppa/backports -y
sudo add-apt-repository ppa:kubuntu-ppa/backports-extra -y
sudo apt update
```
Ajoute les PPA **Kubuntu Backports** pour obtenir KDE Plasma 6 sur Ubuntu 24.04.

```bash
echo "sddm shared/default-x-display-manager select sddm" | sudo debconf-set-selections
```
Définit **SDDM** comme gestionnaire de session par défaut via debconf (sans popup).

```bash
sudo apt install -y kubuntu-desktop kde-plasma-desktop plasma-workspace plasma-nm plasma-pa plasma-systemmonitor kde-standard dolphin konsole kate ark gwenview kde-spectacle kcalc partitionmanager
```
Installe KDE Plasma 6 avec les applications essentielles :  
- `plasma-nm` : gestionnaire réseau KDE  
- `plasma-pa` : volume audio KDE  
- `dolphin` : gestionnaire de fichiers  
- `konsole` : terminal  
- `kate` : éditeur de texte  
- `kde-spectacle` : capture d'écran  

```bash
sudo apt install -y language-pack-fr language-pack-kde-fr hunspell-fr
sudo update-locale LANG=fr_FR.UTF-8 LC_MESSAGES=fr_FR.UTF-8
```
Configure le système entier en **français** (interface, correcteur orthographique).

```bash
sudo tee /etc/sddm.conf.d/mados-sddm.conf << 'SDDM_EOF'
[Theme]
Current=breeze
[Autologin]
Relogin=false
SDDM_EOF
```
Configure SDDM avec le thème Breeze (qui sera remplacé par le wallpaper ROG).

```bash
cat << 'ENV_EOF' | sudo -u "$REAL_USER" tee -a "$USER_HOME/.profile"
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland
export MOZ_ENABLE_WAYLAND=1
ENV_EOF
```
Force les applications à utiliser le **backend Wayland** plutôt que XWayland.

```bash
sudo apt purge -y ubuntu-desktop gnome-shell gnome-control-center gnome-software gdm3
sudo snap remove --purge firefox
sudo apt-get purge -y firefox snapd
```
**Désinstalle GNOME, GDM3, Firefox Snap et Snapd** complètement pour libérer de l'espace et éviter les conflits.

---

## 🎨 Module 06 : `06_thematique_mados.sh` — Thème Visuel ROG

**Rôle :** Applique l'identité visuelle MadOS ROG complète (OS, GRUB, KDE, Plymouth).

```bash
cat > /etc/os-release << 'OSRELEASE'
NAME="MadOS ROG Edition"
VERSION="2.6 (Noble)"
ID=ubuntu
PRETTY_NAME="MadOS ROG Edition 2.6"
HOME_URL="https://github.com/mados-rog"
OSRELEASE
```
Rebrande l'OS : **remplace l'identité Ubuntu** par MadOS ROG. Visible dans `neofetch`, `lsb_release`, etc.

```bash
echo "mados-rog" > /etc/hostname
hostname mados-rog
```
Change le **nom d'hôte** du système.

```bash
chsh -s /bin/zsh "$REAL_USER"
sudo -u "$REAL_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo -u "$REAL_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
```
- Change le shell par défaut vers **ZSH**  
- Installe **Oh My ZSH** (framework ZSH)  
- Installe **Powerlevel10k** (thème ZSH ultra-rapide avec icônes)  

```bash
cat > "$USER_HOME/.zshrc" << 'ZSHRC'
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git sudo history command-not-found)
alias rog-boost='asusctl profile -P Performance'  # Raccourci profil perf
alias rog-gpu='supergfxctl -g'                     # Info GPU actif
ZSHRC
```
Configure `.zshrc` avec le thème P10K et des **alias ROG** pratiques.

```bash
sudo cp -r "$ASSETS_DIR/wallpapers/"* "$WALLPAPER_DIR/"
cat << 'THEME_EOF' | sudo tee /usr/share/sddm/themes/breeze/theme.conf.user
[General]
background=/usr/share/wallpapers/MadOS/MadRog1.jpg
THEME_EOF
```
Déploie les **wallpapers ROG** et configure SDDM pour afficher le fond d'écran ROG sur l'écran de connexion.

```bash
cat << 'EOF' | sudo -u "$REAL_USER" tee "$USER_HOME/.config/autostart/set-wallpaper.desktop"
Exec=sh -c "sleep 4 && plasma-apply-wallpaperimage /usr/share/wallpapers/MadOS/MadRog1.jpg && rm -f ~/.config/autostart/set-wallpaper.desktop"
EOF
```
Applique automatiquement le wallpaper KDE **au premier démarrage** (via autostart), puis se supprime.

```bash
git clone --depth=1 https://github.com/AdisonCavani/distro-grub-themes.git "$GRUB_THEME_DIR"
sudo cp -r "$GRUB_THEME_DIR/customize/cyberpunk" /boot/grub/themes/mados-rog
sed -i 's/^#GRUB_THEME=.*/GRUB_THEME="\/boot\/grub\/themes\/mados-rog\/theme.txt"/' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub
update-grub
```
Installe un **thème GRUB Cyberpunk** (rouge/noir, cohérent avec l'esthétique ROG) et configure GRUB.

```bash
sudo apt install -y papirus-icon-theme
wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/install.sh | sh
sudo papirus-folders -C red --theme Papirus-Dark
```
Installe les **icônes Papirus-Dark** et les colore en rouge (couleur ROG).

```bash
cat << 'KDEGLOBALS' | sudo -u "$REAL_USER" tee "$USER_HOME/.config/kdeglobals"
[Colors:Selection]
BackgroundNormal=255,0,0   # Sélection en rouge ROG
[Icons]
Theme=Papirus-Dark
KDEGLOBALS
```
Configure KDE avec la **couleur d'accentuation rouge** signature ROG.

```bash
sudo convert "$ASSETS_DIR/logo.png" -resize 250x250 "$PLY_DIR/logo.png"
sudo convert -size 600x100 xc:transparent -fill "#FFFFFF" -gravity center -pointsize 38 -annotate +0+0 "MadOS ROG Edition" "$PLY_DIR/text.png"
```
Utilise **ImageMagick** pour redimensionner le logo et créer une image texte pour Plymouth.

```bash
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth .../mados-rog.plymouth 100
sudo update-alternatives --set default.plymouth .../mados-rog.plymouth
sudo update-initramfs -u
```
Configure **Plymouth** (splash screen de démarrage) avec le thème MadOS ROG personnalisé et recompile l'initramfs.

---

## 💾 Module 07 : `07_snapshots_systeme.sh` — Timeshift

```bash
sudo apt install -y timeshift
ROOT_FSTYPE=$(df -T / | awk 'NR==2 {print $2}')
if [ "$ROOT_FSTYPE" == "btrfs" ]; then
    sudo timeshift --btrfs --create --comments "Sauvegarde MadOS Initiale"
fi
```
Installe **Timeshift** et crée un snapshot initial si le système de fichiers est **BTRFS** (instantané ultra-rapide).  
En mode `--rsync` (ext4), le snapshot est trop long, il est laissé manuel.

---

## 🎯 Module 08 : `08_proton_gamescope.sh` — Ultra Gaming

```bash
sudo apt install -y gamemode
```
Installe **Feral GameMode** : optimise automatiquement les performances CPU/GPU quand un jeu est lancé.

```bash
sudo -u "$REAL_USER" pipx install protonup
STEAM_COMPAT_DIR="/home/$REAL_USER/.steam/root/compatibilitytools.d"
sudo -u "$REAL_USER" protonup -d "$STEAM_COMPAT_DIR" -y
```
Installe **ProtonUp CLI** et télécharge automatiquement la dernière version de **Proton-GE** (GloriousEggroll) dans le dossier compatibilité tools de Steam.  
Proton-GE améliore la compatibilité et les performances de jeux Windows sur Linux.

---

## 💿 Module 09 : `09_montage_ntfs.sh` — Disques NTFS

```bash
exec < /dev/tty 2>/dev/null || true
NTFS_DRIVES=$(sudo blkid | grep -i ntfs || true)
```
Scanne les partitions avec `blkid` pour trouver les **disques NTFS** (Windows).

```bash
UUID=$(sudo blkid -s UUID -o value "$TARGET_DRIVE")
sudo apt install -y ntfs-3g
echo "UUID=$UUID /mnt/Jeux_Windows ntfs-3g uid=$USER_UID,gid=$USER_GID,rw,user,exec,umask=000,utf8 0 0" | sudo tee -a /etc/fstab
sudo mount -a
```
Monte le disque Windows en **lecture/écriture** avec les permissions utilisateur. Les options `umask=000,utf8` assurent l'accès complet aux fichiers du jeu Steam sur Windows.

---

## 🔊 Module 10 : `10_son_demarrage.sh` — Son ROG

```bash
sudo apt install -y sox libsox-fmt-all sound-theme-freedesktop
cat << 'EOF' | sudo -u "$REAL_USER" tee "$AUTOSTART_DIR/mados-login-sound.desktop"
Exec=sh -c "paplay /usr/share/sounds/freedesktop/stereo/desktop-login.oga"
X-KDE-AutostartScript=true
EOF
```
Installe les outils audio et crée un **fichier .desktop d'autostart** KDE qui joue un son lors de chaque connexion via `paplay` (PulseAudio player).

---

## 🔋 Module 11 : `11_batterie_extreme.sh` — auto-cpufreq

```bash
git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git "$TEMP_DIR"
cd "$TEMP_DIR"
sudo ./auto-cpufreq-installer --install
sudo systemctl enable auto-cpufreq
```
Clone et installe **auto-cpufreq** depuis les sources : ajuste dynamiquement la fréquence CPU et le gouverneur (performance/powersave) selon l'utilisation réelle et l'état de la batterie.

---

## 📊 Module 12 : `12_mangohud_rog.sh` — MangoHud ROG

```bash
sudo apt install -y goverlay
cat << 'EOF' | sudo -u "$REAL_USER" tee "$MANGO_DIR/MangoHud.conf"
gpu_color=FF0000       # GPU en rouge ROG
cpu_color=FF4500       # CPU en orange-rouge
background_alpha=0.6   # Fond semi-transparent
toggle_hud=Shift_R+F12 # Raccourci d'affichage
fps
frametime
cpu_temp
gpu_temp
EOF
```
Configure MangoHud avec un profil **couleurs ROG** (rouge/noir) affichant FPS, latence, températures CPU/GPU.  
Activable/désactivable avec `Shift+F12`.

---

## 📡 Module 13 : `13_pack_streamer.sh` — OBS Studio

```bash
sudo add-apt-repository ppa:obsproject/obs-studio -y
sudo apt update
sudo apt install -y obs-studio
```
Installe **OBS Studio** depuis le PPA officiel (version la plus récente pour le support Wayland).

---

## 🤖 Module 14 : `14_openclaw_ai.sh` — IA OpenClaw + Ollama

**Rôle :** Déploie un assistant IA local (Ollama + OpenClaw) avec accès terminal.

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```
Installe **Node.js 22** depuis le dépôt officiel NodeSource.

```bash
curl -fsSL https://ollama.com/install.sh | sudo -E bash -
sudo systemctl enable --now ollama
```
Installe **Ollama** : moteur d'exécution d'IA locale (modèles LLM comme LLaMA, Mistral, etc.).

```bash
sudo -u "$REAL_USER" git clone --depth=1 https://github.com/openclaw/openclaw.git "$OC_DIR"
cat << ENV_EOF | sudo -u "$REAL_USER" tee "$OC_DIR/.env"
ALLOW_LOCAL_SHELL=true
gateway.mode=local
gateway.models.local=ollama
DEFAULT_SYSTEM_PROMPT="Vous êtes OpenClaw, IA de MadOS ROG..."
ENV_EOF
```
Clone OpenClaw et configure le **prompt système** qui définit le personnage de l'IA.

```bash
sudo npm install -g pnpm
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && pnpm install"
sudo -u "$REAL_USER" bash -c "cd '$OC_DIR' && pnpm run build"
```
Installe **pnpm** (gestionnaire de paquets Node rapide) et compile OpenClaw.

```bash
cat << 'SRV_EOF' | tee "$USER_HOME/.config/systemd/user/openclaw.service"
[Service]
ExecStartPre=/bin/sleep 10
ExecStart=$OC_DIR/start-gateway.sh
Restart=on-failure
SRV_EOF
sudo loginctl enable-linger "$REAL_USER"
sudo -u "$REAL_USER" ln -sf ".../openclaw.service" ".../default.target.wants/openclaw.service"
```
Crée un **service systemd utilisateur** qui démarre OpenClaw à la connexion (avec 10s de délai pour attendre le réseau).  
`loginctl enable-linger` permet au service de tourner sans session active.

---

## 🌐 Module 15 : `15_reseau_antilag.sh` — TCP BBR Anti-Lag

```bash
cat << 'EOF' | sudo tee /etc/sysctl.d/99-mados-network.conf
net.core.default_qdisc=fq_codel           # Queue discipline (élimine le bufferbloat)
net.ipv4.tcp_congestion_control=bbr       # TCP BBR Google (réduit la latence multijoueur)
net.core.rmem_max=16777216                # Buffer réception max (16 MB)
net.core.wmem_max=16777216                # Buffer envoi max (16 MB)
net.ipv4.tcp_syncookies=1                 # Protection SYN Flood
EOF
sudo sysctl --system
```
Configure le kernel Linux pour le **gaming réseau** :  
- **BBR** (Bottleneck Bandwidth and RTT) : algorithme TCP Google qui réduit le ping  
- **fq_codel** : élimine le bufferbloat (cause principale des pics de latence)  
- Buffers élargis pour connexions haut débit  

---

## 💾 Module 16 : `16_zram_memoire.sh` — ZRAM Compressé

```bash
sudo apt-get install -y zram-tools
cat << 'EOF' | sudo tee /etc/default/zramswap
ALGO=zstd    # Algorithme de compression ultra-rapide
PERCENT=50   # 50% de la RAM allouée au ZRAM
PRIORITY=100 # Priorité haute (utilisé avant le swap disque)
EOF
cat << 'EOF' | sudo tee /etc/sysctl.d/99-mados-zram.conf
vm.swappiness=150       # Favorise fortement le ZRAM sur le disque
vm.page-cluster=0       # Réduit la lecture anticipée → moins de latence
EOF
sudo systemctl restart zramsetup
```
ZRAM crée un **espace de swap en RAM compressée** :  
- Plus rapide que le swap sur disque (même NVMe)  
- `zstd` : meilleur ratio vitesse/compression (≈3:1)  
- `swappiness=150` : le kernel swap activement dans ZRAM avant le disque  

---

## 🛡️ Module 17 : `17_bouclier_antipub.sh` — Anti-Pub Hosts

```bash
HOSTS_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
curl -sSL "$HOSTS_URL" -o "$TEMP_HOSTS"
sudo sed -i '/# === MADOS ROG AUTOGENERATED HOSTS ===/,/# === END MADOS ROG ===/d' /etc/hosts
grep "^0.0.0.0" "$TEMP_HOSTS" | sudo tee -a /etc/hosts
```
Télécharge la liste **StevenBlack** (100 000+ domaines publicitaires/malware) et les injecte dans `/etc/hosts` en redirectant vers `0.0.0.0` (blocage au niveau réseau, sans application).  
La section est délimitée pour éviter les doublons lors des re-runs.

---

## 💻 Module 18 : `18_pack_pro_dev.sh` — Dev & Virtualisation

```bash
sudo apt-get install -y docker.io docker-compose-v2 git-lfs
sudo usermod -aG docker "$REAL_USER"
sudo systemctl enable --now docker
```
Installe **Docker** et ajoute l'utilisateur au groupe docker (pour utiliser Docker sans sudo).

```bash
sudo apt-get install -y qemu-kvm qemu-system qemu-utils libvirt-clients libvirt-daemon-system bridge-utils virtinst virt-manager
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt "$REAL_USER"
sudo usermod -aG kvm "$REAL_USER"
```
Installe **QEMU/KVM** (virtualisation matérielle Linux) et **Virt-Manager** (GUI).  
L'utilisateur est ajouté aux groupes `libvirt` et `kvm` pour accès sans root.

```bash
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=... ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
sudo apt-get install -y codium
```
Installe **VSCodium** (VS Code sans télémétrie Microsoft) depuis le dépôt officiel.

---

## 🔧 Module 19 : `19_donnees_fstrim.sh` — Maintenance SSD

```bash
sudo systemctl enable --now fstrim.timer
```
Active le **trim hebdomadaire SSD** via systemd timer (libère les cellules NAND effacées = maintient les performances NVMe).

```bash
sudo sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=500M/' /etc/systemd/journald.conf
sudo sed -i 's/^#SystemMaxFileSize=.*/SystemMaxFileSize=100M/' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
```
Limite les **logs systemd** à 500 MB (par défaut : illimité → peut saturer le disque).

```bash
sudo apt-get autoremove -y
sudo apt-get clean
sudo journalctl --vacuum-time=3d
sudo fstrim -av
```
Nettoyage immédiat : paquets orphelins, cache APT, vieux logs (>3j), trim SSD forcé.

---

## ⚡ Module 20 : `20_esport_usb_1000hz.sh` — USB Polling Rate

```bash
cat << 'EOF' | sudo tee /etc/udev/rules.d/99-usb-latency.rules
ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="usb", TEST=="power/autosuspend", ATTR{power/autosuspend}="-1"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger
```
Règles **udev** qui désactivent l'autosuspend USB au branchement de tout périphérique.  
Évite les micro-coupures et latences des souris/claviers gaming dues à la mise en veille USB.

```bash
echo 'options usbhid mousepoll=1' | sudo tee /etc/modprobe.d/usbhid.conf
sudo update-initramfs -u -k all
```
- `mousepoll=1` : force le **polling rate** du module HID à 1000 Hz (1ms de latence vs 8ms par défaut)  
- Recompile l'initramfs pour inclure ce paramètre kernel dès le boot  

---

## 🏎️ Module 21 : `21_boot_eclair.sh` — Boot Ultrarapide

```bash
sudo sed -i 's/^COMPRESS=.*/COMPRESS=lz4/' /etc/initramfs-tools/initramfs.conf
```
Change l'algorithme de **compression de l'initramfs** vers LZ4 (décompression 5x plus rapide que gzip, -20% de taille).

```bash
sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_priority=3 vt.global_cursor_default=0"
```
- `GRUB_TIMEOUT=0` + `hidden` : **supprime l'écran de démarrage GRUB** (boot direct)  
- `quiet splash` : supprime les messages kernel, affiche Plymouth  
- `loglevel=3` : filtre les messages kernel (seulement erreurs)  
- `vt.global_cursor_default=0` : masque le curseur clignotant au boot  

```bash
sudo update-initramfs -u -k all
sudo update-grub
```
Recompile l'initramfs LZ4 pour tous les kernels installés et regénère GRUB.

---

## 🌡️ Module 22 : `22_cpu_undervolt.sh` — Undervolt CPU

**Rôle :** Applique le profil thermique selon `$MADOS_TDP_PROFILE` (SILENCE/EQUILIBRE/EXTREME).

```bash
CPU_VENDOR=$(lscpu | awk '/Vendor ID/ || /Fournisseur/ {print $3}' | head -n1)
```
Détecte l'architecture CPU : `AuthenticAMD` ou `GenuineIntel`.

```bash
# === AMD (RyzenAdj) ===
sudo git clone --depth=1 https://github.com/FlyGoat/RyzenAdj.git /opt/RyzenAdj
cd /opt/RyzenAdj && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make
sudo cp ryzenadj /usr/local/bin/ryzenadj
```
Compile **RyzenAdj** (outil de contrôle TDP pour processeurs AMD Ryzen).

```bash
case "${MADOS_TDP_PROFILE}" in
    "SILENCE") AMD_ARGS="--tctl-temp=70 --stapm-limit=25000 --fast-limit=25000"   # 25W max
    "EXTREME") AMD_ARGS="--tctl-temp=95 --stapm-limit=65000 --fast-limit=65000"   # 65W débridé
    *) AMD_ARGS="--tctl-temp=85"                                                    # 45W stock
esac
```
- `--tctl-temp` : limite la température CPU (en °C)  
- `--stapm-limit` : TDP soutenu (Slow TDP, en mW)  
- `--fast-limit` : TDP boost court terme (en mW)  

```bash
cat << EOF | sudo tee /etc/systemd/system/mados-amd-thermal.service
[Service]
ExecStart=/usr/local/bin/ryzenadj $AMD_ARGS
After=sleep.target   # Réappliqué après chaque réveil de veille
EOF
sudo systemctl enable --now mados-amd-thermal.service
```
Crée un **service systemd** qui réapplique les limites TDP au démarrage ET après chaque réveil.

```bash
# === Intel (intel-undervolt) ===
sudo apt install -y intel-undervolt
sudo sed -i "s/undervolt 0. CPU CORE 0/undervolt 0. CPU CORE $CORE_UV/" /etc/intel-undervolt.conf
sudo intel-undervolt apply
sudo systemctl enable intel-undervolt.service
```
Configure **intel-undervolt** pour réduire la tension CPU (économie d'énergie, réduction thermique sans perte de perf).

---

## 🖥️ Module 23 : `23_control_center.sh` — GUI Control Center

```bash
sudo apt install -y python3-pyqt6 python3-psutil
sudo mkdir -p /opt/mados-control-center
sudo cp "assets/mados_cc.py" /opt/mados-control-center/mados_cc.py
```
Installe **PyQt6** (interface graphique Python) et copie l'application Control Center.

```bash
cat << EOF | sudo tee "$USER_HOME/Desktop/MadOS_Control_Center.desktop"
[Desktop Entry]
Exec=python3 /opt/mados-control-center/mados_cc.py
Icon=/opt/mados-control-center/icon.png
Categories=System;Settings;
EOF
sudo chmod +x "$USER_HOME/Desktop/MadOS_Control_Center.desktop"
sudo cp ... "$USER_HOME/Bureau/"   # Copie aussi pour bureau français
```
Crée un **raccourci .desktop** sur le Bureau (version anglaise `Desktop` et française `Bureau`).

---

## 🔄 Module 24 : `24_mados_update.sh` — Mise à Jour GitHub

```bash
REPO_URL="https://github.com/LordMadTrix/MadOS_ROG_Edition.git"
ping -c 1 github.com &>/dev/null
sudo git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
```
Vérifie la connexion internet et clone la **dernière version depuis GitHub**.

```bash
NEW_VER=$(cat "$INSTALL_DIR/VERSION")
CUR_VER=$(cat /opt/mados/VERSION)
if [ "$NEW_VER" = "$CUR_VER" ]; then echo "Déjà à jour"; exit 0; fi
```
Compare les fichiers `VERSION` pour **détecter si une mise à jour est nécessaire**.

```bash
CHOICE=$(whiptail --menu "Quelle mise à jour ?" ... 3>&1 1>&2 2>&3)
sudo apt update && sudo apt upgrade -y
sudo npm update -g pnpm
```
Propose un menu de mise à jour : totale, sélective, ou paquets uniquement.

---

## 🩺 Module 25 : `25_sante_systeme.sh` — Diagnostic Santé

**Rôle :** Génère un rapport de santé complet du système MadOS.

```bash
check_ok()   { ((SCORE++)); ((TOTAL++)); echo "[ OK ] $1" >> "$REPORT_FILE"; }
check_warn() { ((TOTAL++)); WARNINGS+="  - $1\n"; }
check_fail() { ((TOTAL++)); WARNINGS+="  - ✗ $1\n"; }
```
Système de **scoring** : chaque vérification ajoute 1 au total, et 1 au score si OK.

```bash
KERNEL=$(uname -r)
if echo "$KERNEL" | grep -qi "xanmod"; then check_ok "Kernel XanMod"
```
Vérifie que le **kernel XanMod** est actif via `uname -r`.

```bash
PLASMA_VER=$(plasmashell --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+')
```
Détecte la version de KDE Plasma avec **expression régulière** `\d+\.\d+\.\d+`.

```bash
nvidia-smi --query-gpu=driver_version --format=csv,noheader
glxinfo | grep -qi "AMD\|Radeon\|RADV"
```
Détecte les pilotes GPU actifs (NVIDIA via `nvidia-smi`, AMD via `glxinfo`).

```bash
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" systemctl --user is-active --quiet openclaw.service
```
Vérifie l'état du **service OpenClaw** dans la session utilisateur (nécessite `XDG_RUNTIME_DIR`).

```bash
PERCENT=$(( SCORE * 100 / TOTAL ))
whiptail --title "🏥 MadOS Health Check" \
    --yesno "Score de Santé : $SCORE/$TOTAL ($PERCENT%)" 10 55 && \
    whiptail --scrolltext --textbox "$REPORT_FILE" 30 80
```
Calcule un **pourcentage de santé** et propose d'afficher le rapport complet dans whiptail.

---

## 🥽 Module 26 : `26_vr_oculus_quest.sh` — Suite VR Meta Quest

```bash
sudo apt-get install -y android-tools-adb curl jq libfuse2 wget xz-utils libnss3
```
Installe **ADB** (Android Debug Bridge) pour communiquer avec les casques Meta Quest.

```bash
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="2833", MODE="0666", GROUP="plugdev"' | sudo tee -a /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules
```
Règle **udev** pour le Vendor ID `0x2833` (Oculus/Meta) : donne accès USB sans root.

```bash
SQ_LATEST_TAG=$(curl -sS -o /dev/null -w "%{url_effective}" -I -L https://github.com/SideQuestVR/SideQuest/releases/latest | awk -F'/' '{print $NF}')
SQ_NUM_VERSION=${SQ_LATEST_TAG#v}
SQ_LATEST_URL="https://github.com/SideQuestVR/SideQuest/releases/download/${SQ_LATEST_TAG}/SideQuest-${SQ_NUM_VERSION}.tar.xz"
wget -qO "$SQ_PATH" "$SQ_LATEST_URL"
sudo tar -xf "$SQ_PATH" -C /opt/MadOS_VR/SideQuest --strip-components=1
```
Récupère **dynamiquement la dernière version** de SideQuest via le redirect GitHub `releases/latest`.  
`--strip-components=1` extrait sans le dossier parent.

```bash
ALVR_LATEST_TAG=$(curl ... https://github.com/alvr-org/ALVR/releases/latest ...)
sudo mv "/opt/MadOS_VR/ALVR/ALVR Launcher" "/opt/MadOS_VR/ALVR/alvr_launcher"
```
Installe **ALVR** (Air Light VR) pour le streaming PCVR sans fil.  
Renomme l'exécutable (espace dans le nom original = problème de compatibilité shell).

```bash
sudo -u "$REAL_USER" adb kill-server
sudo -u "$REAL_USER" adb start-server
```
Redémarre le **daemon ADB** pour prendre en compte les nouvelles règles udev.

---

## 📊 Synthèse des Technologies Utilisées

| Technologie | Usage | Modules |
|---|---|---|
| **APT/DPKG** | Gestion paquets Debian | Tous |
| **Systemd** | Services, timers, journald | 03, 10, 11, 14, 16, 19, 22 |
| **GPG/Keyrings** | Vérification signatures dépôts | 00, 18 |
| **Whiptail/Newt** | Interface TUI | Menu, 14, 24, 25 |
| **GRUB** | Bootloader | 06, 21 |
| **Plymouth** | Boot splash screen | 06 |
| **Sysctl** | Paramètres kernel runtime | 15, 16 |
| **Udev** | Règles périphériques USB/HID | 20, 26 |
| **Modprobe** | Modules kernel | 03, 02, 20 |
| **Fstab** | Montage automatique disques | 09 |
| **Cargo/Rust** | Compilation asusctl, supergfxctl | 03 |
| **Node.js/PNPM** | Build OpenClaw AI | 14 |
| **CMake/Make** | Compilation RyzenAdj | 22 |
| **Git** | Clonage dépôts sources | 03, 06, 11, 14, 22 |
| **ImageMagick** | Traitement images Plymouth | 06 |
| **Flatpak** | Applications sandbox | 04 |
| **Netcat (nc)** | Upload logs Termbin | Menu |
| **ADB** | Communication Meta Quest | 26 |
| **Pipx** | Installation Python isolée | 04, 08 |
| **PyQt6** | GUI Control Center | 23 |

---

*Documentation générée automatiquement — MadOS ROG Edition v3.0 — LordMadTrix*
