<div align="center">
  <img src="assets/logo.png" alt="MadOS ROG Logo" width="300" />

  # MadOS ROG Edition — Framework Post-Install
  
  **La transformation ultime pour votre ASUS ROG sous Linux.**

  [![Bash](https://img.shields.io/badge/Script-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
  [![Ubuntu](https://img.shields.io/badge/OS-Ubuntu_24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
  [![KDE Plasma](https://img.shields.io/badge/Desktop-KDE_Plasma_6-1D99F3?style=for-the-badge&logo=kde&logoColor=white)](https://kde.org/)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

  <p align="center">
    <a href="#fonctionnalités">Points Clés</a> •
    <a href="#prérequis">Prérequis</a> •
    <a href="#installation">Déploiement</a> •
    <a href="#architecture-des-modules">Modules</a> •
    <a href="#contribution">Contribution</a>
  </p>
</div>

---

## ⚡ Fonctionnalités

**MadOS ROG Edition** n'est pas qu'un simple script, c'est une matrice d'installation interactive conçue pour transformer une base Ubuntu Server ou Desktop (24.04 LTS) en une station de combat orientée Gaming, optimisée spécifiquement pour les PC portables **ASUS Republic of Gamers**.

- 🧠 **Détection Intelligente GPU** : Scan matériel automatique (`lspci`) pour déployer les pilotes NVIDIA (DKMS), AMD (Mesa/RADV) ou Intel sans la moindre configuration manuelle.
- 💻 **Noyau XanMod EDGE** : Compilation automatique du kernel orienté gaming avec support des instructions AVX2 / AVX512 (selon votre CPU).
- ⚙️ **Contrôle Hardware ASUS** : Intégration CLI native de `asusctl` et `supergfxctl` (compilés via Rust) pour la gestion du MUX Switch, des ventilateurs et du clavier RGB.
- 🎨 **Esthétique ROG Immersive** : Thème sombre, accents rouges, SDDM Wallpaper animé, Neofetch exclusif, et terminal ZSH (Powerlevel10k).
- 🤖 **Assistant IA ([OpenClaw](https://openclaw.ai/))** : (Optionnel) Installation intégrée d'un agent IA local directement utilisable sur votre bureau.
- 🧹 **Purge Anti-Bloatware** : Suppression radicale de Snapd, GNOME, et de la télémétrie Ubuntu.

---

## 🛠 Prérequis

1. Un PC (idéalement **ASUS ROG**) avec une connexion internet active.
2. Une installation fraîche d'**Ubuntu 24.04 LTS (Noble Numbat)**, version **Serveur** de préférence (pour partir d'une base légère), ou Desktop (le script désinstallera GNOME).
3. L'utilisateur courant doit faire partie du groupe `sudo`.

---

## 🚀 Installation

Il suffit de cloner (ou télécharger) ce dépôt sur votre nouvelle machine, et de lancer le menu interactif (surnommé *La Matrice*).

```bash
# 1. Cloner ce dépôt
git clone https://github.com/LordMadTrix/MadOS_ROG_Edition.git
cd MadOS_ROG_Edition

# 2. Rendre le script exécutable (facultatif si déjà fait via Git)
chmod +x Menu_Installation_ROG.sh modules/*.sh

# 3. Lancer la Matrice
sudo bash Menu_Installation_ROG.sh
```

Une fois le script lancé, une interface "BIOS" graphique (Whiptail) apparaîtra. Vous aurez le choix entre :
- `[1] Déploiement Total` : Un sous-menu interactif vous permettra de cocher/décocher les modules bonus.
- `[2] Déploiement Personnalisé` : Sélectionnez précisément les modules voulus avec la barre [ESPACE].
- `[3] Mode Destruction 🔥` : Purge le système de Canonical (Snap, etc.).

> **Note :** Il est déconseillé d'interrompre le script une fois lancé (notamment pendant la compilation du noyau ou l'installation des dépendances Rust).

---

## 📦 Architecture des Modules

Le déploiement est découpé logiquement. Chaque script dans le dossier `modules/` réalise une tâche atomique :

| Module | Description Focus |
| :--- | :--- |
| `00_nettoyage_ubuntu.sh` | Purge de `cloud-init`, `snapd`, et mise en place des dépôts officiels. |
| `01_noyau_xanmod.sh`     | Ciblage automatique CPU et injection du profil Kernel XanMod. |
| `02_pilotes_gpu_auto.sh` | Analyse PCI, téléchargement DKMS/Mesa, forçage algorithmique Wayland HDR. |
| `03_integration_rog.sh`  | Détection du modèle via `dmidecode`, compilation de contrôle de carte mère. |
| `04_arsenal_logiciel.sh` | Steam, Chrome, Lutris, MangoHud, et l'injecteur IA OpenClaw. |
| `05_bureau_kde_plasma.sh`| Interface graphique KDE Plasma 6 via Backports. |
| `06_thematique_mados.sh` | Paramétrage Visuel: GRUB interactif, Splash Plymouth. |
| `07_snapshots_systeme.sh`| 🛡️ Configuration de sauvegardes systèmes fiables via Timeshift. |
| `08_proton_gamescope.sh` | 🎮 Compilation de Proton-GE (Steam) et GameScope pour l'upscaling. |
| `09_montage_ntfs.sh`     | 💾 Détection et ajout (fstab) de vos disques de jeu Windows (NTFS). |
| `10_son_demarrage.sh`    | 🔊 Injection du son au démarrage KDE (Ambiance ROG). |
| `11_batterie_extreme.sh` | 🔋 Déploiement de `auto-cpufreq` pour doubler l'autonomie sur batterie. |
| `12_mangohud_rog.sh`     | 📊 Création d'un profil agressif Rouge/Noir pour surveiller vos FPS en jeu. |
| `13_pack_streamer.sh`    | 🎥 Installation massive d'OBS, `obs-vkcapture` (Wayland), et IA `NoiseTorch`. |

---

## 🤝 Contribution

Ce projet a été imaginé et propulsé par amour du matériel ASUS et de l'univers Linux. Toute aide est bienvenue !

1. **Forkez** le projet.
2. **Créez** une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`).
3. **Committez** vos changements (`git commit -m 'Ajout exceptionnel'`).
4. **Poussez** vers la branche (`git push origin feature/AmazingFeature`).
5. **Ouvrez** une Pull Request.

---

## 📄 Licence

Distribué sous la licence **MIT**. Voir `LICENSE` pour plus d'informations.

<div align="center">
  <i>Conçu pour les joueurs. Codé avec passion. 🩸</i>
</div>
