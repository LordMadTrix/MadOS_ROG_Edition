# Changelog MadOS ROG Edition

Tous les changements notables seront documentés dans ce fichier.

## [3.1.0] - 2026-03-16

### ✨ Nouveau
- **Détection Hyperviseur Automatique** : QEMU, VMware, VirtualBox, Hyper-V
- **Gestion d'Erreurs Robuste** : Retry automatique 3x + menu utilisateur
- **Système de Checkpoints** : Reprendre depuis le dernier module échoué
- **Logging Complet** : Timestamps, traçabilité totale, séparation info/warning/error
- **Sauvegarde Automatique** : Backup de tous fichiers modifiés
- **Recovery Menu** : `recovery.sh` pour diagnostic et récupération
- **Support Hyperviseur** : Drivers optimisés pour chaque plateforme
  - QEMU/KVM : qemu-guest-agent + SPICE
  - VMware : open-vm-tools complet + SVGA III
  - VirtualBox : guest-additions + DKMS
  - Hyper-V : modules hv_* + optimisation réseau
- **Optimisations Réseau** : GSO/GRO/TSO, I/O scheduler
- **Control Center Electron** : Mise à jour GUI complète

### 🔧 Améliorations
- Meilleur support du mode DRY-RUN pour tester sans modifier
- Validation des prérequis avant installation
- Détection GPU plus robuste (lspci + glxinfo)
- Support XWayland amélioré
- Watchdog système désactivé (VM friendly)

### 🐛 Corrections
- Fix: Retry infini sur erreur APT (maintenant 3x max)
- Fix: Perte de logs en cas de crash (backup + timestamp)
- Fix: Module 02_GPU échouait en VM (drivers hyperviseur maintenant pré-installés)
- Fix: DNS timeout en VM (dnmasq + fallback)
- Fix: DKMS failure VirtualBox résolu (headers automatiques)

### 📖 Documentation
- Ajout RECOVERY_GUIDE.md complet
- Ajout HYPERVISOR_DRIVERS_GUIDE.md
- Ajout ERREUR_RECOVERY_IMPLEMENTATION.md
- Ajout INSTALLATION.md
- Ajout CONTRIBUTING.md
- README.md redessiné + badges

### ⚠️ Notes de Migration (depuis v3.0)
```bash
# Si vous mettez à jour depuis v3.0:
rm /tmp/mados_checkpoint.log  # Réinitialiser checkpoints
sudo bash install_local.sh     # Relancer installation
```

---

## [3.0.5] - 2026-02-28

### 🔧 Améliorations
- Meilleure détection de connexion Internet
- Support Python 3.12
- Meilleure gestion du GRUB
- Amélioration UI menu Whiptail

### 🐛 Corrections
- Fix: Erreur sur disques NVMe sans "sda"
- Fix: apt-listchanges bloquerait parfois l'installation
- Fix: Module 05_KDE échouait sur GNOME préinstallé

---

## [3.0.3] - 2026-02-15

### ✨ Nouveau
- Module 27_creation_maker : Support imprimante 3D + graveur laser
- Module 26_vr_oculus : Intégration Meta Quest 3 + ALVR

### 🐛 Corrections
- Fix: Timeshift échouait sur ext4 (détection automatique btrfs)
- Fix: Module 14_OpenClaw échouait (Node.js + npm fix)

---

## [3.0.0] - 2026-01-30

### 🎉 Major Release

**Première release publique - Framework complet MadOS ROG v3.0**

#### ✨ Fonctionnalités Principales
- 7 modules obligatoires (nettoyage → desktop)
- 21 modules optionnels (gaming, perf, tools)
- Interface Whiptail interactive
- MadOS Control Center (PyQt6)
- Support complet ASUS ROG
- Thème MadOS avec wallpapers animés
- OpenClaw IA local intégré

#### 🎮 Gaming
- Détection GPU NVIDIA/AMD/Intel
- Kernel XanMod EDGE
- Proton + Gamescope
- MangoHud profiling
- Anti-lag réseau

#### 🛡️ Sécurité
- Anti-bloatware (snapd, cloud-init)
- Bouclier anti-pub
- BBR networking
- ZRAM compression
- Diagnostic santé complet

---

## [2.0.0] - 2025-12-01

Ancienne version (avant framework reconstruction)

---

## Convention de Versioning

MadOS utilise [SemVer](https://semver.org/):
- **MAJOR** : Breaking changes ou refactorisation majeure
- **MINOR** : Nouvelles fonctionnalités (backward compatible)
- **PATCH** : Corrections de bugs

Format: `v{MAJOR}.{MINOR}.{PATCH}`

---

## Planification v3.2+

### En Cours
- [ ] Tests CI/CD automatisés (GitHub Actions)
- [ ] Support Arch Linux (en plus d'Ubuntu)
- [ ] Interface Web pour configuration
- [ ] Containerization (Docker image MadOS)

### Prochainement
- [ ] Support macOS (Parallels Desktop)
- [ ] Package manager snap/flatpak
- [ ] Intégration cloud (sync configs)
- [ ] Plugin system pour modules custom

### Futurs
- [ ] Serveur MadOS (headless mode)
- [ ] Mobile app (remote control)
- [ ] Web dashboard
- [ ] Marketplace modules community

---

## Comment Contribuer aux Changements

Voir [CONTRIBUTING.md](CONTRIBUTING.md) pour les détails complets.

```bash
# 1. Fork le repo
# 2. Créer une branche
git checkout -b feature/ma-feature

# 3. Commit avec messages explicites
git commit -m "feat: description courte"

# 4. Push vers votre fork
git push origin feature/ma-feature

# 5. Créer une Pull Request
# (Les changements seront mergés après review)
```

---

## Liens Utiles

- 🐛 [Issues](https://github.com/LordMadTrix/MadOS_ROG_Edition/issues)
- 🚀 [Pull Requests](https://github.com/LordMadTrix/MadOS_ROG_Edition/pulls)
- 📖 [Documentation](https://lordmadtrix.github.io/MadOS_ROG_Edition)
- 💬 [Discussions](https://github.com/LordMadTrix/MadOS_ROG_Edition/discussions)

---

**Merci de contribuer à MadOS ROG! 🌟**
