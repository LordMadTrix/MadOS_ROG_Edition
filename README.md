<div align="center" markdown="1">
  <img src="assets/logo.png" alt="MadOS ROG Logo" width="300" />

  # 🔴 MadOS ROG Edition 3.5 Ultimate Stable

  ### La branche Linux de [MadTweak](https://github.com/LordMadTrix/madtweak)

  **La transformation ultime pour votre ASUS ROG sous Kubuntu 24.04 LTS**
  
  *Framework d'installation post-boot ultra-robuste optimisé pour la stabilité et la performance.*

  [![Kubuntu](https://img.shields.io/badge/OS-Kubuntu_24.04_LTS-007ACC?style=for-the-badge&logo=kubuntu&logoColor=white)](https://kubuntu.org/)
  [![NVIDIA](https://img.shields.io/badge/GPU-NVIDIA_DKMS-76B900?style=for-the-badge&logo=nvidia&logoColor=white)](https://www.nvidia.com/)
  [![Version](https://img.shields.io/badge/Version-3.5_Ultimate-ff003c?style=for-the-badge)](https://github.com/LordMadTrix/MadOS_ROG_Edition)
</div>

---

## ⚡ Fonctionnalités Principales

### 🎮 **Gaming Extrême**
- ✅ **GPU Auto-Détection** : NVIDIA (DKMS), AMD (Mesa/RADV), Intel.
- ✅ **Noyau XanMod EDGE** : Kernel gaming haute performance.
- ✅ **E-Sport Mode** : Réseau anti-lag (TCP BBR+), RAM compressée (ZRAM).
- ✅ **Proton-GE** : Support des jeux Windows optimisé.

### ⚙️ **Hardware ASUS ROG**
- ✅ **asusctl & supergfxctl** : Gestion native du MUX Switch, RGB et ventilation.
- ✅ **Thermal Guard** : Limite thermique à 85°C pour protéger les composants.
- ✅ **Power Tuning** : Profils de puissance dynamiques (Silence/Equilibre/Extreme).

### 🎨 **Interface & UX**
- ✅ **KDE Plasma 5/6** : Bureau moderne optimisé ROG.
- ✅ **MadOS Theme** : Thème sombre immersif avec icônes Papirus Red.
- ✅ **Windows-Style Transformation** : Barre des tâches centrée et menu intuitif.

---

## 🚀 Installation

```bash
# 1. Télécharger & Exécuter le script
git clone https://github.com/LordMadTrix/MadOS_ROG_Edition.git
cd MadOS_ROG_Edition
sudo bash install.sh
```

---

## 🏗️ Structure du Projet

```
MadOS_ROG_Edition/
├── install.sh           # Script d'installation principal (Robuste)
├── lib/                 # Fonctions communes et configuration
├── modules/             # 28 modules d'optimisation (GPU, CPU, Thème...)
├── assets/              # Logo, fonds d'écran et thèmes
└── docs/                # Guide d'utilisation et aide
```

---

## 🛡️ Sécurité & réversibilité

Trois garde-fous, repris de son pendant Windows [MadTweak](https://github.com/LordMadTrix/madtweak) :

```bash
sudo bash install.sh --dry-run        # SIMULATION : montre tout, n'écrit rien
sudo bash install.sh --list-backups   # ce qui a été sauvegardé, donc restaurable
sudo bash install.sh --restore        # remet les fichiers dans leur état d'origine
```

- **Mode simulation** — toute action passant par `run_action` affiche ce qu'elle *ferait* au lieu de le faire. À lancer au moins une fois avant une vraie installation.
- **Manifeste de sauvegarde** — chaque fichier sauvegardé est indexé (`original → sauvegarde → date`) dans `manifeste.tsv`. Sans cet index, un backup horodaté ne dit plus de quel fichier il provient : c'est lui qui rend la restauration possible.
- **Un module refuse de nuire** — plutôt que d'appliquer un réglage néfaste sur *cette* machine-ci, il appelle `refuser_reglage "raison"` et explique pourquoi. Un refus n'est pas un échec.

---

## 🪟 Sur Windows ? Voir **MadTweak**

MadOS a un petit frère pour l'autre moitié du dual-boot : **[MadTweak](https://github.com/LordMadTrix/madtweak)** optimise Windows 10 / 11 avec 155 tweaks réversibles, un audit complet et une annulation exacte — même philosophie, même identité ROG.

| | MadOS ROG Edition | [MadTweak](https://github.com/LordMadTrix/madtweak) |
|---|---|---|
| **Système** | Kubuntu 24.04 LTS | Windows 10 / 11 |
| **Rôle** | **Installe et transforme** un système neuf | **Ajuste et nettoie** un système existant |

---

## 💛 Remerciements

MadOS est développé sur mon temps libre et restera gratuit. Merci à celles et ceux qui
le soutiennent via [GitHub Sponsors](https://github.com/sponsors/LordMadTrix) — les
sponsors qui le souhaitent sont crédités ici.

<!-- SPONSORS:DEBUT -->
*Aucun sponsor pour l'instant — cette section attend son premier nom.*
<!-- SPONSORS:FIN -->

Merci aussi à celles et ceux qui signalent un bug ou testent sur une configuration
différente de la mienne : c'est ce qui permet à un script qui touche au noyau et aux
pilotes de rester sûr sur des machines que je ne possède pas.

## 📜 License
**MIT License** - Libre et Open Source. Fait avec ❤️ par LordMadTrix.
