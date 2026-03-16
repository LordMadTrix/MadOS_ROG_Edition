# 🛡️ MadOS ROG - Système de Gestion d'Erreurs et Récupération

## 📋 Résumé des Améliorations Implémentées

Ce document décrit les améliorations de **robustesse**, **logging** et **récupération** ajoutées à MadOS ROG Edition 3.0.

---

## 🎯 Objectif Principal

**Les scripts continueront sans planter le système**, avec possibilité de:
- ✅ Continuer automatiquement après une erreur
- ✅ Relancer les modules échoués
- ✅ Sauvegarder les fichiers avant modification
- ✅ Revenir en arrière si besoin

---

## 📂 Fichiers Ajoutés/Modifiés

### Fichiers Créés ✨

| Fichier | Rôle |
|---------|------|
| **`lib/common.sh`** | Fonctions communes: logging, retry, checkpoints |
| **`lib/config.conf`** | Configuration centralisée (paramètres globaux) |
| **`recovery.sh`** | Menu interactif pour récupération après erreur |
| **`RECOVERY_GUIDE.md`** | Guide complet de récupération (utilisateur) |
| **`modules/00_nettoyage_ubuntu_exemple.sh`** | Exemple de module utilisant les nouvelles fonctions |

### Fichiers Modifiés 🔧

| Fichier | Changement |
|---------|-----------|
| **`install_local.sh`** | Intégration de `lib/common.sh` + gestion d'erreurs + checkpoints |

---

## 🔧 Comment Ça Marche?

### 1️⃣ **Initialisation (au démarrage)**

```bash
# install_local.sh charge:
source "$SCRIPT_DIR/lib/common.sh"
setup_error_traps              # Active la gestion des erreurs
init_mados_logging             # Crée les dossiers logs/backups
```

### 2️⃣ **Vérifications Pré-Installation**

```bash
check_sudo_access              # ✓ Privilèges root
check_disk_space 40            # ✓ 40GB disponibles
check_internet_connection      # ✓ Connexion réseau
```

### 3️⃣ **Exécution d'un Module**

```bash
run_module "00_nettoyage_ubuntu.sh" "Description"

# Ce que ça fait automatiquement:
├─ Vérifier si déjà complété → SKIP si oui
├─ Tentative 1/3 → Échoue? Retry automatique
├─ Tentative 2/3 → Échoue? Retry automatique
├─ Tentative 3/3 → Échoue? Menu utilisateur
└─ Succès? Sauvegarder checkpoint
```

### 4️⃣ **Menu en Cas d'Erreur**

Si un module échoue après 3 tentatives, l'utilisateur choisit:
```
1. Réessayer encore une fois
2. Ignorer l'erreur et continuer
3. Arrêter l'installation
```

### 5️⃣ **Checkpoints Sauvegardés**

```
/tmp/mados_checkpoint.log:

[2026-03-16 10:30:45] OK:00_nettoyage_ubuntu.sh
[2026-03-16 10:35:12] OK:01_noyau_xanmod.sh
[2026-03-16 10:42:08] FAILED:02_pilotes_gpu_auto.sh
[2026-03-16 10:45:00] SKIPPED_ERROR:02_pilotes_gpu_auto.sh
[2026-03-16 10:45:30] OK:03_integration_rog.sh
```

### 6️⃣ **Récupération Après Erreur**

```bash
# Continuer depuis où ça s'est arrêté
sudo bash install_local.sh

# Les modules OK sont sautés automatiquement
# Les modules FAILED/SKIPPED ne sont pas relancés
# L'installation continue à partir du module suivant
```

---

## 🛠️ Fonctions Disponibles pour les Modules

### Logging

```bash
log_info "Ceci est un message d'info"
log_error "Ceci est une erreur"
log_warning "Ceci est un avertissement"
log_success "Succès!"
```

### Exécution Sécurisée

```bash
# Retry automatique (3x par défaut)
run_command_retry \
    "sudo apt-get install -y paquet" \
    "Installation du paquet" \
    3  # nombre de tentatives

# APT spécialisé
apt_update_safe              # apt update avec retry
apt_install_safe "pkg1 pkg2" "Description"
```

### Checkpoints

```bash
skip_if_completed "module_name"  # Retourne 0 si déjà fait
save_checkpoint "module_name" "OK"  # Enregistrer un checkpoint
```

### Sauvegarde/Restauration

```bash
backup_file "/etc/config.conf"  # Sauvegarder avant modification
restore_file "/etc/config.conf" "/var/lib/mados_backup/config.conf.bak"
```

### Vérifications

```bash
check_disk_space 40     # Vérifier 40GB libres
check_internet_connection
check_sudo_access
```

---

## 📊 Structure des Logs

```
/var/log/mados/
├── mados_install.log       # Tous les logs (STDOUT + STDERR)
└── mados_errors.log        # Seulement les erreurs

/var/lib/mados_backup/
├── sources.list.bak.1234567890
├── resolv.conf.bak.1234567890
└── ...autres fichiers sauvegardés

/tmp/
└── mados_checkpoint.log    # État des modules
```

---

## 🚀 Guide Utilisateur

### Scénario 1: Installation Réussie

```bash
sudo bash install.sh
# Tout fonctionne → Installation terminée ✅
```

### Scénario 2: Erreur Réseau au Module 5

```bash
sudo bash install.sh
# Modules 1-4 OK ✅
# Module 5 (pilotes GPU) échoue ❌
# [Tentative 1/3] échoue
# [Tentative 2/3] échoue
# [Tentative 3/3] échoue
# 
# Menu: "Réessayer / Ignorer / Arrêter"
# Utilisateur choisit "Ignorer"
# Module 6+ continuent
```

### Scénario 3: Relancer l'Installation

```bash
# Après une première tentative échouée:
sudo bash recovery.sh       # Voir l'état
# ou
sudo bash install_local.sh  # Continuer directement
# Les modules OK sont sautés automatiquement
```

### Scénario 4: Recommencer de Zéro

```bash
sudo rm /tmp/mados_checkpoint.log
sudo bash install_local.sh
# Tous les modules seront relancés
```

---

## 🔙 Revenir à l'État Initial

Si quelque chose casse gravement:

```bash
# Option 1: Restaurer un fichier spécifique
sudo ls /var/lib/mados_backup/
sudo cp /var/lib/mados_backup/sources.list.bak.* /etc/apt/sources.list
sudo apt update

# Option 2: Restaurer depuis TimeShift (si snapshot créé)
sudo timeshift --list
sudo timeshift --restore

# Option 3: Réinstaller Ubuntu complètement
# (Dernier recours)
```

---

## 📈 Améliorations par Rapport à Avant

| Aspect | Avant ❌ | Après ✅ |
|--------|----------|----------|
| **Erreur APT** | Script s'arrête → Système cassé | Retry 3x + Menu utilisateur |
| **Logs** | Console uniquement | Fichiers logs + timestamps + syslog |
| **Récupération** | Pas possible | Checkpoints + resume depuis point d'erreur |
| **Sauvegarde** | Aucune | Backup auto de fichiers modifiés |
| **Rollback** | Manuel | Automatique avec restore_file() |
| **Modules redondants** | Relancés à chaque fois | Sautés s'ils sont OK |
| **Débogage** | Difficile | Logs détaillés + trap d'erreur |

---

## 🎓 Pour les Développeurs

### Adapter un Module Existant

```bash
#!/bin/bash
# MON_MODULE.sh

# 1. Charger les fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
setup_error_traps

main() {
    export CURRENT_MODULE="mon_module.sh"
    
    log_info "Mon module démarre"
    
    # 2. Utiliser les fonctions sécurisées
    apt_install_safe "paquet" "Installation du paquet" || return 1
    
    # 3. Sauvegarder avant modification
    backup_file "/etc/config.conf"
    
    # 4. Faire le travail
    sudo tee /etc/config.conf <<EOF
ma config
EOF
    
    log_success "Mon module réussi"
    return 0
}

# Exécuter si appelé directement
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
```

### Charger la Configuration

```bash
# Dans un module, pour accéder aux variables globales:
source "$SCRIPT_DIR/lib/config.conf"

echo "Python version: $PYTHON_VERSION"
echo "TDP: $TDP_PROFILE_EQUILIBRE"
```

---

## 🐛 Débogage

### Voir les logs en direct

```bash
sudo tail -f /var/log/mados/mados_install.log
```

### Voir les erreurs seulement

```bash
sudo tail -f /var/log/mados/mados_errors.log
```

### Exécuter un module en mode debug

```bash
bash -x modules/00_nettoyage_ubuntu.sh 2>&1 | tee debug.log
```

### Vérifier la syntaxe

```bash
shellcheck modules/*.sh
```

---

## 📞 Support & Troubleshooting

Pour les problèmes:

1. **Consulter les logs**: `sudo tail -100 /var/log/mados/mados_install.log`
2. **Voir les erreurs**: `sudo cat /var/log/mados/mados_errors.log`
3. **Voir l'état**: `sudo cat /tmp/mados_checkpoint.log`
4. **Lancer recovery**: `sudo bash recovery.sh`
5. **Continuer**: `sudo bash install_local.sh`

---

## 📝 Checklist de Test

- [ ] Installation complète réussit (sans erreur)
- [ ] Erreur APT → 3 retries automatiques
- [ ] Menu utilisateur apparaît après 3 retries
- [ ] "Continuer" saute les modules OK
- [ ] "Relancer" recommence le module échoué
- [ ] recovery.sh fonctionne
- [ ] Logs sont créés dans /var/log/mados/
- [ ] Backups sont créés dans /var/lib/mados_backup/
- [ ] Checkpoints sauvegardés dans /tmp/mados_checkpoint.log

---

## 🎉 Prochaines Étapes

Pour utiliser ce système:

1. **Tester sur une VM Ubuntu 25.10**:
   ```bash
   sudo bash install.sh
   ```

2. **Injecter les nouvelles fonctions dans tous les modules**:
   ```bash
   # Chaque module devrait avoir:
   source "$SCRIPT_DIR/lib/common.sh"
   setup_error_traps
   ```

3. **Documenter les changements**:
   - Voir [RECOVERY_GUIDE.md](./RECOVERY_GUIDE.md) pour l'utilisateur
   - Voir ce fichier pour les développeurs

4. **Tester la récupération**:
   ```bash
   # Arrêter l'installation à mi-chemin
   # Relancer: sudo bash install_local.sh
   # Vérifier que ça continue correctement
   ```

---

## 📚 Fichiers Associés

- **[RECOVERY_GUIDE.md](./RECOVERY_GUIDE.md)** - Guide complet pour l'utilisateur
- **[lib/common.sh](./lib/common.sh)** - Fonctions communes
- **[lib/config.conf](./lib/config.conf)** - Configuration globale
- **[recovery.sh](./recovery.sh)** - Menu interactif de récupération
- **[modules/00_nettoyage_ubuntu_exemple.sh](./modules/00_nettoyage_ubuntu_exemple.sh)** - Exemple d'intégration

---

**Système MadOS ROG 3.0 - Robuste, Récupérable, Fiable! 🚀**
