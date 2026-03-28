# 🔴 MadOS ROG Edition 3.5 — Questing Edition

![MadOS ROG Edition](assets/installer/logo.png)

> **MadOS ROG Edition** est l'évolution ultime des distributions Linux Gaming (basée sur **Ubuntu 25.10**), optimisée pour **l'i9, la RTX et l'écosystème ASUS ROG**.
> MadOS 3.5 apporte le support natif de **Plasma 6**, du noyau **XanMod 6.19+** et une installation "Zéro-Contact".

---

## 🚀 Nouveautés de la Version 3.5

### 🎮 Interface & Moteurs
* **KDE Plasma 6 (Wayland/X11)** : Passage à la version 6 pour une fluidité absolue. Support X11 automatique sur VMware pour éviter les écrans noirs.
* **MadOS Control Center Premium** : Nouvelle interface "Cyber-ROG" en PyQt6 pour piloter vos profils de puissance, l'IA et les LEDs.
* **XanMod 6.19+ Edge** : Le noyau le plus rapide du moment, optimisé pour les processeurs hybrides (P-Cores/E-Cores).

### ⚙️ Optimisations Hardcore
* **RTX Direct-Buffer** : Latence réduite sur les GPU NVIDIA série 40 via les derniers pilotes 560+.
* **Turbo-Tuner 3.5** : Profils de puissance agressifs jusqu'à 125W pour les processeurs ROG Strix/Scar.
* **MadChat IA Locale** : Copilote IA fonctionnant 100% sur vos Tensor Cores (Mistral/Llama).

---

## 🛠️ Comment créer votre ISO MadOS

### Method A : L'ISO "Auto-Pilot" (Recommandée) 💿
Crée une ISO propre basée sur l'image officielle Ubuntu, en y injectant vos scripts MadOS.
```bash
sudo bash scripts/05_build_autoinstall_iso.sh
```

### Method B : L'ISO "Snapshot" (Eggs)
Clonage complet de votre système actuel.
```bash
sudo bash scripts/05_build_iso.sh
```

---

## 🛡️ Installation Rapide (Script-Only)

```bash
wget -qO- mados.sh | sudo bash
```

---
*Power To The Mad Players !*
