<div align="center" markdown="1">
  <img src="assets/logo.png" alt="MadOS ROG Logo" width="300" />

  # 🔴 MadOS ROG Edition 3.1+

  **La transformation ultime pour votre ASUS ROG sous Linux**
  
  *Framework d'installation post-boot ultra-robuste avec gestion d'erreurs automatique*

  [![Bash](https://img.shields.io/badge/Script-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
  [![Ubuntu](https://img.shields.io/badge/OS-Ubuntu_25.10-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
  [![KDE Plasma](https://img.shields.io/badge/Desktop-KDE_Plasma_6-1D99F3?style=for-the-badge&logo=kde&logoColor=white)](https://kde.org/)
  [![Python](https://img.shields.io/badge/Python-3.12+-3776ab?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)

  [![Version](https://img.shields.io/badge/Version-3.1+-ff003c?style=for-the-badge)](https://github.com/LordMadTrix/MadOS_ROG_Edition/releases)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
  [![GitHub Stars](https://img.shields.io/github/stars/LordMadTrix/MadOS_ROG_Edition?style=for-the-badge&logo=github)](https://github.com/LordMadTrix/MadOS_ROG_Edition)

  <p align="center">
    <a href="#-fonctionnalités">⚡ Fonctionnalités</a> •
    <a href="#-quick-start">🚀 Quick Start</a> •
    <a href="#-prérequis">📋 Prérequis</a> •
    <a href="#-architecture">🏗️ Architecture</a> •
    <a href="#-documentation">📖 Docs</a> •
    <a href="https://lordmadtrix.github.io/MadOS_ROG_Edition">🌐 Site Web</a>
  </p>
</div>

---

## ⚡ Fonctionnalités Principales

### 🎮 **Gaming Extrême**
- ✅ **GPU Auto-Détection** : NVIDIA (DKMS), AMD (Mesa/RADV), Intel
- ✅ **Noyau XanMod EDGE** : Kernel gaming + AVX2/AVX512
- ✅ **E-Sport Mode** : USB 1000Hz, anti-lag réseau, RAM compressée
- ✅ **Proton + Gamescope** : Jeux Windows natifs sur Linux
- ✅ **VR Ready** : Meta Quest 3, ALVR, SideQuest

### ⚙️ **Hardware ASUS ROG**
- ✅ **asusctl Native** : MUX Switch, RGB, ventilateurs
- ✅ **Thermal Management** : Undervolt CPU, limite 85°C
- ✅ **Power Profile** : auto-cpufreq, batterie extrême
- ✅ **MangoHud ROG** : Monitoring en-jeu

### 🎨 **Interface & UX**
- ✅ **KDE Plasma 6** : Bureau moderne Wayland
- ✅ **MadOS Theme** : Dark ROG immersif
- ✅ **Control Center GUI** : PyQt6 complet
- ✅ **OpenClaw IA** : Assistant IA local

### 🛡️ **Sécurité & Performance**
- ✅ **Anti-Bloatware** : Snapd, Cloud-init supprimés
- ✅ **Bouclier Anti-Pub** : Filtrage hosts global
- ✅ **BBR Networking** : Optimisation TCP/IP
- ✅ **ZRAM Compression** : ZSTD RAM compressée
- ✅ **Diagnostic Santé** : Monitoring complet système

### 🛠️ **Framework Installation**
- ✅ **Gestion d'Erreurs** : Retry automatique 3x + menu
- ✅ **Checkpoints** : Reprendre depuis le dernier échec
- ✅ **Logging Complet** : Traçabilité totale (timestamps)
- ✅ **Auto-Backup** : Tous fichiers modifiés sauvegardés
- ✅ **Hyperviseur Support** : QEMU, VMware, VirtualBox, Hyper-V
- ✅ **28 Modules** : 7 obligatoires + 21 optionnels

---

## 🚀 Quick Start

### Installation 1-2-3

```bash
# 1. Télécharger & Exécuter
wget https://raw.githubusercontent.com/LordMadTrix/MadOS_ROG_Edition/main/install.sh
sudo bash install.sh

# 2. Sélectionner modules via menu interactif
# (Nettoyage, GPU, Kernel, Desktop, etc.)

# 3. Redémarrer
sudo reboot
```

### En Cas d'Erreur

```bash
# Menu de récupération
sudo bash recovery.sh

# Ou continuer depuis le dernier checkpoint
sudo bash install_local.sh
```

### Vérifier Installation

```bash
# Voir les logs
sudo tail -100 /var/log/mados/mados_install.log

# Vérifier l'état
sudo cat /tmp/mados_checkpoint.log

# Relancer module spécifique
sudo bash modules/XX_description.sh
```

---

## 📋 Prérequis

| Composant | Minimum | Recommandé |
|-----------|---------|-----------|
| **OS** | Ubuntu 24.04 LTS | Ubuntu 25.10 |
| **CPU** | 2 cores | 4+ cores (AVX2) |
| **RAM** | 8 GB | 16 GB |
| **Disque** | 40 GB | 100 GB (SSD) |
| **Internet** | 1 Mbps | 10 Mbps |
| **Compte** | Sudo access | Sudo access |

### Environnements Supportés
- ✅ PC Bare Metal (Desktop/Laptop ASUS ROG)
- ✅ QEMU/KVM
- ✅ VMware ESXi/Workstation/Fusion
- ✅ VirtualBox
- ✅ Microsoft Hyper-V
- ✅ Azure/AWS (Linux VMs)

---

## 🏗️ Architecture

### Structure du Projet

```
MadOS_ROG_Edition/
├── install.sh                       # Bootstrap principal
├── install_local.sh                 # Installation interactive
├── recovery.sh                      # Menu récupération
│
├── lib/
│   ├── common.sh                    # Fonctions communes
│   └── config.conf                  # Configuration globale
│
├── modules/                         # 28 modules d'installation
│   ├── 00_nettoyage_ubuntu.sh       # Purification système
│   ├── 01_noyau_xanmod.sh           # Kernel gaming
│   ├── 02_pilotes_gpu_auto.sh       # GPU auto-détection
│   ├── 03_integration_rog.sh        # Hardware ASUS
│   ├── 04_arsenal_logiciel.sh       # Logiciels gaming
│   ├── 05_bureau_kde_plasma.sh      # Desktop KDE 6
│   └── ...21 modules optionnels
│
├── assets/
│   ├── logo.png                     # Logo MadOS
│   ├── mados_cc.py                  # Control Center GUI
│   └── wallpapers/                  # Fonds d'écran animés
│
└── docs/
    ├── RECOVERY_GUIDE.md            # Récupération d'erreurs
    ├── HYPERVISOR_DRIVERS_GUIDE.md  # Drivers hyperviseur
    ├── INSTALLATION.md              # Guide installation
    └── CONTRIBUTING.md              # Contribution
```

### Flux d'Installation

```
┌─────────────────────────────────────┐
│ sudo bash install.sh                │
└────────────┬────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ Vérifications Pré-Installation       │
│ ├─ Root access                       │
│ ├─ Disk space (40GB)                 │
│ ├─ Internet connection               │
│ └─ Hyperviseur detection             │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ Menu Sélection Modules (Whiptail)    │
│ ├─ Modules obligatoires (pré-sélectionnés)  │
│ └─ Modules optionnels (cases à cocher)      │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ Installation Modules (avec Retry)    │
│ ├─ [Tentative 1/3] échoue           │
│ ├─ [Tentative 2/3] échoue           │
│ ├─ [Tentative 3/3] échoue           │
│ └─ Menu utilisateur: Retry/Ignorer/Arrêter │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ ✅ Installation Terminée             │
│ Logs: /var/log/mados/mados_install.log    │
└──────────────────────────────────────┘
```

---

## 📖 Documentation

### Pour Utilisateurs
- **[INSTALLATION.md](INSTALLATION.md)** - Guide installation complet
- **[RECOVERY_GUIDE.md](RECOVERY_GUIDE.md)** - Récupération & Dépannage
- **[HYPERVISOR_DRIVERS_GUIDE.md](HYPERVISOR_DRIVERS_GUIDE.md)** - Drivers hyperviseur
- **[TUTORIEL_INSTALLATION.md](TUTORIEL_INSTALLATION.md)** - Tutoriel pas-à-pas

### Pour Développeurs
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Comment contribuer
- **[ERREUR_RECOVERY_IMPLEMENTATION.md](ERREUR_RECOVERY_IMPLEMENTATION.md)** - Détails gestion erreurs
- **[HYPERVISOR_IMPLEMENTATION.md](HYPERVISOR_IMPLEMENTATION.md)** - Support hyperviseur
- **[lib/common.sh](lib/common.sh)** - Fonctions partagées

### Ressources
- **[docs/architecture_core.html](docs/architecture_core.html)** - Architecture détaillée
- **[README.md](README.md)** - Ce fichier
- **[CHANGELOG.md](CHANGELOG.md)** - Historique versions
- **[LICENSE](LICENSE)** - MIT License

---

## 🐛 Gestion d'Erreurs & Récupération

MadOS est conçu pour **ne jamais planter** le système :

```bash
# En cas d'erreur
└─ [Retry 1/3] automatique
   └─ [Retry 2/3] automatique
      └─ [Retry 3/3] automatique
         └─ Menu utilisateur
            ├─ Réessayer
            ├─ Ignorer & continuer
            └─ Arrêter installation

# Fichiers de suivi
/var/log/mados/mados_install.log     # Logs complets
/var/log/mados/mados_errors.log      # Erreurs seulement
/tmp/mados_checkpoint.log            # État modules
/var/lib/mados_backup/               # Backups fichiers
```

### Récupération Rapide

```bash
# Menu interactif
sudo bash recovery.sh

# Continuer installation
sudo bash install_local.sh

# Voir les erreurs
sudo tail -50 /var/log/mados/mados_errors.log
```

---

## 📊 Modules d'Installation

### 🔵 Obligatoires (Toujours Exécutés)

```
00 → Nettoyage Ubuntu (purge serveur)
01 → Noyau XanMod EDGE (kernel gaming)
02 → Détection GPU Auto (NVIDIA/AMD/Intel)
03 → Intégration ASUS ROG (asusctl)
04 → Arsenal Logiciel (gaming apps)
05 → Bureau KDE Plasma 6 (Wayland)
06 → Esthétique MadOS (thème + wallpapers)
```

### 🟢 Optionnels (À Sélectionner)

```
07 → Snapshots Système (Timeshift BTRFS)
08 → Proton + Gamescope (Gaming Windows)
09 → Montage NTFS (auto-mount disques)
10 → Son Démarrage (ROG sound effect)
11 → Batterie Extrême (auto-cpufreq)
12 → MangoHud ROG (monitoring jeu)
13 → Pack Streamer (OBS + NoiseTorch)
14 → OpenClaw IA (assistant local)
15 → Réseau Anti-Lag (TCP BBR)
16 → ZRAM (compression RAM)
17 → Bouclier Anti-Pub (hosts filter)
18 → Pack Pro Dev (VSCode, Docker)
19 → Auto-Trim NVMe (SSD maintenance)
20 → E-Sport USB (polling 1000Hz)
21 → Fast Boot (initramfs LZ4)
22 → CPU Undervolt (thermal 85°C)
23 → Control Center (GUI MadOS)
24 → Mise à Jour Auto (GitHub)
25 → Diagnostic Santé (monitoring)
26 → VR Suite (Meta Quest, ALVR)
27 → Station Maker (3D print + laser)
```

---

## 🎯 Performance Attendue

Après MadOS + drivers optimisés:

| Métrique | Avant | Après | Gain |
|----------|-------|-------|------|
| Boot time | 40s | 10s | -75% |
| Gaming FPS | +15% | Variable | +15-30% |
| Latence réseau | 50ms | 10ms | -80% |
| GPU perf | Stock | +20% | +20% |
| Batterie | 3h | 5h | +40% |

*Valeurs indicatives selon matériel*

---

## 💬 Support & Contribution

### Reportez un Bug
```bash
# 1. Vérifiez les logs
sudo tail -100 /var/log/mados/mados_install.log

# 2. Créez une issue GitHub avec:
- Output des logs
- Modèle PC (ASUS ROG...)
- Version Ubuntu
- Version MadOS
```

### Contribuez
Voir [CONTRIBUTING.md](CONTRIBUTING.md)

```bash
# Fork → Clone → Branch → Commit → Push → PR
git clone https://github.com/VOTRE_USERNAME/MadOS_ROG_Edition.git
git checkout -b feature/ma-feature
git push origin feature/ma-feature
```

---

## 📜 License

**MIT License** - Utilisation libre & commerciale

Voir [LICENSE](LICENSE)

---

## 🙏 Remerciements

- **ASUS ROG** pour les specs
- **XanMod** pour le kernel optimisé
- **KDE Project** pour Plasma 6
- **OpenClaw** pour l'IA
- **Tous les contributeurs** 🌟

---

## 📞 Contact & Liens

- 🌐 **Site Web** : [lordmadtrix.github.io/MadOS_ROG_Edition](https://lordmadtrix.github.io/MadOS_ROG_Edition)
- 📧 **Email** : [contact@mados-rog.fr](mailto:contact@mados-rog.fr)
- 💬 **Discord** : [Rejoindre le serveur](https://discord.gg/mados-rog)
- 🐦 **Twitter** : [@MadOS_ROG](https://twitter.com/MadOS_ROG)
- 🌟 **GitHub** : [LordMadTrix/MadOS_ROG_Edition](https://github.com/LordMadTrix/MadOS_ROG_Edition)

---

<div align="center">

**Transformez votre ASUS ROG en Machine de Guerre Gaming sous Linux! 🔴🎮**

*Fait avec ❤️ par LordMadTrix*

[⬆ Back to Top](#-mados-rog-edition-31)

</div>
