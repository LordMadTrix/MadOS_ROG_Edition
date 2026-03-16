# MadOS ROG - Guide de Récupération & Gestion d'Erreurs

## 🆘 Qu'est-ce qui s'est passé?

L'installation de MadOS a échoué à un module. **Ne vous inquiétez pas!** Le système a enregistré exactement où le problème s'est produit et peut continuer sans danger.

---

## 📊 Comment ça marche?

### Système de Checkpoints
Chaque fois qu'un module se complète **avec succès**, un **checkpoint** est enregistré. Si un module échoue:
1. Une tentative automatique de **retry** (3x par défaut)
2. Un menu apparaît pour que vous décidiez:
   - **Réessayer** → Relancer le module
   - **Ignorer** → Sauter et continuer
   - **Arrêter** → Quitter l'installation

### Fichiers de Suivi
| Fichier | Contenu |
|---------|---------|
| `/var/log/mados/mados_install.log` | Tous les logs complets |
| `/tmp/mados_checkpoint.log` | État des modules (OK/FAILED/SKIPPED) |
| `/var/log/mados/mados_errors.log` | Erreurs détectées |
| `/var/lib/mados_backup/` | Sauvegardes des fichiers modifiés |

---

## 🔧 Commandes de Récupération

### 1️⃣ **Lancer le Mode Récupération**
```bash
sudo bash recovery.sh
```
Menu interactif pour:
- 📖 Voir les logs
- 🔄 Continuer depuis où ça s'est arrêté
- 📦 Voir les fichiers sauvegardés
- 🗑️ Réinitialiser et recommencer

### 2️⃣ **Continuer l'Installation**
```bash
sudo bash install_local.sh
```
Les modules déjà complétés seront **automatiquement sautés**.

### 3️⃣ **Consulter les Logs**
```bash
sudo tail -f /var/log/mados/mados_install.log
```

### 4️⃣ **Voir les Erreurs**
```bash
sudo cat /var/log/mados/mados_errors.log
```

### 5️⃣ **Réinitialiser & Recommencer**
```bash
sudo rm /tmp/mados_checkpoint.log
sudo bash install_local.sh
```

---

## 🔙 Revenir à l'État Initial

Les fichiers importants modifiés ont été **sauvegardés** avant les changements.

### Fichiers Sauvegardés
```bash
ls -la /var/lib/mados_backup/
```

Exemple:
```
/var/lib/mados_backup/sources.list.bak.1234567890
/var/lib/mados_backup/50-cloud-init.yaml.bak.1234567890
```

### Restaurer un Fichier
```bash
# Exemple: restaurer sources.list
sudo cp /var/lib/mados_backup/sources.list.bak.* /etc/apt/sources.list
sudo apt update
```

---

## 🚀 Scénarios Courants

### ❌ Erreur Réseau (apt update échoue)
```bash
# Vérifier la connexion
ping -c 1 archive.ubuntu.com

# Voir les logs réseau
sudo tail -100 /var/log/mados/mados_install.log | grep -E "DNS|network|ping"

# Continuer - la prochaine tentative devrait réussir
sudo bash install_local.sh
```

### ❌ GPU non Détecté
```bash
# Vérifier le hardware détecté
lspci | grep -E "VGA|3D"

# Voir ce que le script a trouvé
grep -i "gpu" /var/log/mados/mados_install.log

# Mode manuel - relancer le détecteur GPU
sudo bash modules/02_pilotes_gpu_auto.sh
```

### ❌ Manque d'Espace Disque
```bash
# Vérifier l'espace disponible
df -h /

# Libérer de l'espace
sudo apt autoremove -y
sudo apt clean
sudo journalctl --vacuum=1w  # Logs vieux d'une semaine

# Continuer
sudo bash install_local.sh
```

### ❌ Module Spécifique Échoue
```bash
# Relancer UNIQUEMENT ce module
sudo bash modules/XX_description.sh

# Ou en mode débogage (affiche les erreurs)
bash -x modules/XX_description.sh 2>&1 | tee debug.log
```

---

## 📈 État d'Avancement

### Voir les modules complétés
```bash
grep "OK:" /tmp/mados_checkpoint.log
```

Exemple:
```
[2026-03-16 10:30:45] OK:00_nettoyage_ubuntu.sh
[2026-03-16 10:35:12] OK:01_noyau_xanmod.sh
[2026-03-16 10:42:08] FAILED:02_pilotes_gpu_auto.sh
```

### Voir le module qui a échoué
```bash
grep "FAILED:" /tmp/mados_checkpoint.log
```

---

## 🛡️ Sauvegarde Complète du Système

Si vous voulez un **vrai point de sauvegarde** avant l'installation:

```bash
# Créer une image du système (avant de lancer MadOS)
sudo timeshift --create --comments "Avant MadOS Installation" --tags D

# Après l'installation, si quelque chose ne va pas:
sudo timeshift --restore
```

---

## 📞 Débogage Avancé

### Activer les logs détaillés
```bash
export DEBUG=1
sudo bash install_local.sh
```

### Exécuter un module en mode debug
```bash
bash -x modules/00_nettoyage_ubuntu.sh 2>&1 | tee debug.log
less debug.log
```

### Vérifier la syntaxe des scripts
```bash
shellcheck modules/*.sh
```

### Voir les dernières 50 lignes de logs
```bash
sudo tail -50 /var/log/mados/mados_install.log
```

---

## 🎯 Flux Normal vs Flux de Récupération

### Flux Normal ✅
```
install.sh → install_local.sh → menu → run_module("00_clean") → SUCCÈS ✓
    ↓
run_module("01_kernel") → SUCCÈS ✓
    ↓
run_module("02_gpu") → SUCCÈS ✓
    ↓
Installation terminée 🎉
```

### Flux d'Erreur & Récupération
```
install_local.sh → run_module("02_gpu") → ERREUR ❌
    ↓
[Tentative 1/3 automatique] → Échoue
[Tentative 2/3 automatique] → Échoue
[Tentative 3/3 automatique] → Échoue
    ↓
Menu: "Réessayer / Ignorer / Arrêter"
    ↓
L'utilisateur choisit → Checkpoint sauvegardé
    ↓
sudo bash recovery.sh → Continuer depuis le checkpoint
    ↓
run_module("02_gpu") → SKIPPED (déjà en erreur avant)
run_module("03_rog") → SUCCÈS ✓
run_module("04_soft") → SUCCÈS ✓
    ↓
Installation terminée avec 1 module ignoré ⚠️
```

---

## ✅ Checklist Post-Installation

Même si MadOS s'est arrêté en cours de route, vérifiez:

```bash
# 1. Système toujours bootable?
sudo reboot

# 2. Pas de paquets cassés?
sudo apt --fix-broken install

# 3. Voir l'état complet
sudo cat /var/log/mados/mados_install.log | tail -50

# 4. Continuer si besoin
sudo bash install_local.sh
```

---

## 📚 Informations Utiles

- **Version MadOS**: 3.0
- **Distribution**: Ubuntu 25.10+
- **Support**: Checkpoints automatiques depuis: `install_local.sh`
- **Rollback Possible**: Oui (via TimeShift)
- **Perte de Données**: Non (tous les fichiers sauvegardés)

---

## 🎓 Astuce Pro

Si vous testez l'installation dans une **VM**, créez un snapshot AVANT:

```bash
# Via VirtualBox
VBoxManage snapshot "UbuntuVM" take "avant-mados"

# Via KVM
virsh snapshot-create-as ubuntu --name "avant-mados"

# En cas de problème, revert:
virsh snapshot-revert ubuntu avant-mados
```

---

**Bonne chance! L'installation MadOS est robuste et récupérable. 🚀**
