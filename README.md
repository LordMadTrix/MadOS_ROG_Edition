<div align="center" markdown="1">
  <img src="assets/logo.png" alt="MadOS ROG Logo" width="300" />

  # 🔴 MadOS ROG Edition 4.0 "NTSYNC Edition"
  
  **La transformation ultime pour votre ASUS ROG sous Ubuntu 25.04 "Plucky Puffin"**
  
  *Framework d'optimisation gaming haute-performance intégrant les dernières technologies de synchronisation noyau.*

  [![Ubuntu](https://img.shields.io/badge/OS-Ubuntu_25.04-007ACC?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
  [![NTSYNC](https://img.shields.io/badge/Sync-NTSYNC_Native-ff003c?style=for-the-badge)](https://github.com/LordMadTrix/MadOS_ROG_Edition)
  [![Version](https://img.shields.io/badge/Version-4.0_Stable-ff003c?style=for-the-badge)](https://github.com/LordMadTrix/MadOS_ROG_Edition)
</div>

---

## ⚡ Nouveautés v4.0

### 🚀 **Gaming de Prochaine Génération**
- ✅ **NTSYNC Natif** : Synchronisation noyau pour éliminer les micro-stutters dans les jeux Windows.
- ✅ **NVIDIA 565+ Open Kernel** : Intégration parfaite avec Wayland et Plasma 6.
- ✅ **Mesa 26.x** : Ray Tracing accéléré sur AMD RDNA 3/4.
- ✅ **TCP BBRv3** : Optimisation réseau e-sport pour une latence minimale.

### ⚙️ **Optimisation ASUS ROG (2026)**
- ✅ **asusctl + supergfxctl** : Contrôle complet du matériel ROG (profils, GPU, RGB).
- ✅ **Power-Profiles-Daemon** : Gestion dynamique de l'énergie parfaitement couplée à KDE Plasma 6.
- ✅ **Thermal Guard** : Surveillance thermique avec RGB réactif (vert/jaune/rouge selon la temp).

### 🎨 **Expérience Plasma 6**
- ✅ **KDE Plasma 6 (Wayland)** : HDR et VRR activés par défaut pour une fluidité absolue.
- ✅ **Mad-Macros v4** : Raccourcis clavier ROG optimisés (Meta+Shift+G pour le mode Jeu).

---

## 🚀 Installation

> **Prérequis** : Ubuntu 25.04 Desktop ("Plucky Puffin") — ASUS ROG ou PC gaming compatible.
> Ne pas installer sur Ubuntu Server (modules GUI incompatibles).

```bash
git clone https://github.com/LordMadTrix/MadOS_ROG_Edition.git
cd MadOS_ROG_Edition
sudo bash install.sh
```

---

## 🏗️ Structure du Projet

```
MadOS_ROG_Edition/
├── install.sh           # Script d'installation principal (Robuste v4.0)
├── lib/                 # Fonctions communes (retry APT, logging, couleurs)
├── modules/             # 38 modules d'optimisation (NTSYNC, GPU, KDE6...)
├── tools/               # CLI mados, completion bash, VM de test
├── assets/              # Logo, fonds d'écran et thèmes ROG
└── docs/                # Guide d'utilisation et aide
```

---

## 🖥️ CLI `mados`

Après installation, un outil CLI est disponible :

```bash
mados status              # Vue d'ensemble (kernel, GPU, batterie, temp)
mados doctor              # Diagnostic de tous les composants ✓/✗
mados shift game          # Mode PERFORMANCE (RTX + RGB rouge)
mados shift eco           # Mode SILENCE (GPU intégré + RGB off)
mados aura static -c ff003c  # RGB couleur fixe
mados batt 80             # Limite charge batterie à 80%
mados logs --errors       # Affiche uniquement les erreurs d'install
mados uninstall           # Désinstallation propre de MadOS
```

---

## 🧪 Test en VM

> **Ubuntu Desktop recommandé** — MadOS est conçu pour un environnement graphique (KDE Plasma, GPU, RGB...).
> Ubuntu Server fonctionne mais skippe automatiquement les modules GUI (Chrome, Steam, OBS, etc.)
> L'ISO Desktop sera téléchargée automatiquement par le script.

**1. Lancer la VM** (depuis ton PC) :
```bash
bash tools/test_vm_mados.sh
```

**2. Se connecter en SSH depuis ton PC** (plus pratique pour copier-coller) :
```bash
ssh -p 2222 user@localhost
```

> Si tu vois une erreur `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED` (nouvelle VM) :
> ```bash
> ssh-keygen -f '/home/madtrix/.ssh/known_hosts' -R '[localhost]:2222'
> ssh -p 2222 user@localhost
> ```

**3. Monter le dossier partagé** :
```bash
sudo mkdir -p /mnt/mados
sudo mount -t 9p -o trans=virtio,version=9p2000.L mados_share /mnt/mados
```

**4. Lancer l'installation** :
```bash
cd /mnt/mados
sudo bash install.sh
```

**4. Après reboot de la VM** (sans ISO pour éviter la réinstallation Ubuntu) :
```bash
bash tools/test_vm_mados.sh --keep
```

---

## 📜 License
**MIT License** - Libre et Open Source. Fait avec ❤️ par LordMadTrix.
