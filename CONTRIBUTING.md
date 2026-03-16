# 🤝 Guide de Contribution - MadOS ROG Edition

Merci de votre intérêt pour contribuer à MadOS ROG! Ce guide vous expliquera comment contribuer efficacement.

## 📋 Table des Matières

1. [Code de Conduite](#code-de-conduite)
2. [Comment Commencer](#comment-commencer)
3. [Types de Contributions](#types-de-contributions)
4. [Workflow Git](#workflow-git)
5. [Standards de Code](#standards-de-code)
6. [Soumettre une PR](#soumettre-une-pr)
7. [Questions?](#questions)

---

## 📜 Code de Conduite

Nous nous engageons à fournir un environnement accueillant et inclusif.

**Les comportements inacceptables comprennent:**
- Harcèlement ou discrimination
- Commentaires offensants
- Attaques personnelles
- Spam ou promotion commerciale

**Signaler une violation:** [report@mados-rog.fr](mailto:report@mados-rog.fr)

---

## 🚀 Comment Commencer

### 1. Fork le Repository

```bash
# Allez sur GitHub et cliquez "Fork"
https://github.com/LordMadTrix/MadOS_ROG_Edition
```

### 2. Clonez Votre Fork

```bash
git clone https://github.com/VOTRE_USERNAME/MadOS_ROG_Edition.git
cd MadOS_ROG_Edition
git remote add upstream https://github.com/LordMadTrix/MadOS_ROG_Edition.git
```

### 3. Créez une Branche

```bash
# Mise à jour depuis le repo principal
git fetch upstream
git rebase upstream/main

# Créer votre branche feature/bugfix
git checkout -b feature/ma-feature
# ou
git checkout -b fix/mon-bug
```

---

## 📝 Types de Contributions

### 🐛 Signaler un Bug

**Avant de signaler:**
- Vérifiez que le bug n'est pas déjà reporté
- Testez avec la dernière version
- Vérifiez les logs: `sudo tail -100 /var/log/mados/mados_install.log`

**Format du rapport:**
```markdown
### Titre du Bug
Décrivez le comportement inattendu

### Étapes pour Reproduire
1. ...
2. ...
3. ...

### Comportement Attendu
Ce qui devrait se passer

### Logs & Environment
- OS: Ubuntu 25.10
- Modèle: ASUS ROG Strix G16
- Version MadOS: 3.1.0
- Logs: [voir attachment ou gist]

### Informations Supplémentaires
...
```

### ✨ Proposer une Fonctionnalité

**Format de la feature request:**
```markdown
### Décrivez la Fonctionnalité
Explication claire et concise

### Contexte
Pourquoi cette feature est utile?

### Solution Proposée
Comment la mettre en œuvre?

### Alternatives Considérées
Autres approches possibles?

### Contexte Supplémentaire
Screenshots, liens, etc.
```

### 📖 Améliorer la Documentation

- Corrections typos
- Exemples plus clairs
- Meilleure organisation
- Traductions

---

## 🔧 Workflow Git

### Commits

```bash
# Messages clairs et descriptifs
git commit -m "type(scope): description courte"

# Types acceptés:
# feat:  nouvelle fonctionnalité
# fix:   correction de bug
# docs:  documentation
# style: formatage, sans changement logique
# refactor: restructuration sans feature/fix
# test:  ajout ou modification tests
# chore: maintenance, dépendances
```

**Exemples:**
```bash
git commit -m "feat(recovery): ajouter menu interactif recovery.sh"
git commit -m "fix(hypervisor): corriger détection VMware sur Hyper-V"
git commit -m "docs(readme): ajouter section architecture"
git commit -m "refactor(lib/common.sh): simplifier fonction apt_install_safe"
```

### Push et Pull Request

```bash
# Push votre branche
git push origin feature/ma-feature

# Créez une PR sur GitHub
# - Titre clair et descriptif
# - Description détaillée
# - Lien vers issue reliée
# - Screenshots/logs si pertinent
```

---

## 💻 Standards de Code

### Bash Scripts

```bash
#!/bin/bash
# ==============================================================================
# Script Description
# ==============================================================================
# Explication détaillée

# Utiliser set -uo pipefail pour error handling
set -uo pipefail

# Charger les fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

setup_error_traps

main() {
    export CURRENT_MODULE="mon_module.sh"
    
    log_info "Début du module"
    
    # Utiliser les fonctions de logging
    log_info "Message d'info"
    log_warning "Attention"
    log_error "Erreur"
    log_success "Succès!"
    
    # Utiliser apt_install_safe pour APT
    apt_install_safe "paquet1 paquet2" "Description" || return 1
    
    # Utiliser run_command_retry pour commandes importantes
    run_command_retry "sudo commande" "Description" 3 || return 1
    
    log_success "Module complété"
    return 0
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
```

**Règles Bash:**
- ✅ Indentation: 4 espaces (pas de tabs)
- ✅ Noms variables: UPPERCASE pour globales, lowercase pour locales
- ✅ Commentaires pour logique complexe
- ✅ Gestion d'erreurs systématique
- ✅ Logging via fonctions communes
- ✅ Pas de commandes hardcodées (utiliser variables)

### Python Scripts

```python
#!/usr/bin/env python3
"""
Module description.

This module handles...
"""

import sys
import logging

# Configure logging
logger = logging.getLogger(__name__)

class MadOSComponent:
    """Class description."""
    
    def __init__(self):
        """Initialize component."""
        self.name = "MadOS"
    
    def run(self):
        """Execute component logic."""
        logger.info("Starting component")
        return 0

if __name__ == "__main__":
    sys.exit(MadOSComponent().run())
```

**Règles Python:**
- ✅ PEP 8 compliant
- ✅ Type hints quand possible
- ✅ Docstrings pour fonctions publiques
- ✅ Logging au lieu de print()
- ✅ Tests unitaires

### Documentation Markdown

```markdown
# Titre Principal

Paragraphe d'introduction.

## Sous-titre

- Point 1
- Point 2
- Point 3

### Sous-sous-titre

Code block:
\`\`\`bash
# Exemple de code
sudo bash install.sh
\`\`\`

**Gras** pour mots-clés importants
*Italique* pour emphase légère
`code` pour petits snippets
```

---

## 🔄 Soumettre une PR

### Checklist Avant PR

- [ ] Code testé localement
- [ ] Messages de commit clairs
- [ ] Documentation mise à jour
- [ ] Pas de fichiers temporaires
- [ ] Logs/outputs clean
- [ ] Branche à jour avec `main`

```bash
# Vérifier que votre branche est à jour
git fetch upstream
git rebase upstream/main

# Vérifier les changements
git log --oneline upstream/main..HEAD
git diff upstream/main
```

### Soumettre la PR

1. **Allez sur GitHub**
   - Click "Compare & pull request"
   - Ou créez une PR manuellement

2. **Remplissez la Description**

```markdown
## Description
Brève description des changements

## Type de Changement
- [ ] Bug fix
- [ ] Nouvelle fonctionnalité
- [ ] Breaking change
- [ ] Documentation

## Teste Sur
- [ ] Ubuntu 24.04 LTS
- [ ] Ubuntu 25.10
- [ ] QEMU VM
- [ ] VMware VM
- [ ] VirtualBox VM

## Issues Liées
Fixes #XXX
Relates to #YYY

## Checklist
- [ ] Code formaté correctement
- [ ] Tests ajoutés/modifiés
- [ ] Documentation mise à jour
- [ ] Pas de breaking changes
- [ ] Logs testés
```

3. **Attendez la Review**
   - Mainteneurs vont commenter/suggérer
   - Faites les changements demandés
   - Re-push sur la même branche

```bash
# Après modifications
git add .
git commit -m "fix: adresse le feedback de review"
git push origin feature/ma-feature
# La PR sera automatiquement mise à jour
```

---

## 🧪 Testing Local

### Tester un Module

```bash
# Test syntaxe
bash -n modules/mon_module.sh

# Test complet
sudo bash modules/mon_module.sh

# Avec debug
bash -x modules/mon_module.sh 2>&1 | tee debug.log
```

### Tester en VM

```bash
# Créer VM Ubuntu 25.10
# Booter depuis live USB/ISO

# Cloner votre fork
git clone https://github.com/VOTRE_USERNAME/MadOS_ROG_Edition.git
cd MadOS_ROG_Edition

# Tester avant merge
sudo bash install.sh
```

### Valider Syntax

```bash
# Bash
shellcheck modules/*.sh lib/*.sh

# Python
pylint assets/mados_cc.py
flake8 assets/mados_cc.py
```

---

## 📚 Ressources Utiles

- [Guide Git](https://git-scm.com/book)
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide)
- [PEP 8 Python](https://pep8.org/)
- [Markdown Guide](https://www.markdownguide.org/)
- [ShellCheck](https://www.shellcheck.net/)

---

## 💬 Questions?

- 📧 **Email:** [dev@mados-rog.fr](mailto:dev@mados-rog.fr)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/LordMadTrix/MadOS_ROG_Edition/discussions)
- 🐦 **Twitter:** [@MadOS_ROG](https://twitter.com/MadOS_ROG)

---

## 🎉 Merci!

Votre contribution aide à rendre MadOS ROG meilleur pour tous! 🌟

**Les contributions de tous types sont bienvenues:**
- Code
- Documentation
- Bug reports
- Traductions
- Idées

**Bienvenue dans la communauté MadOS ROG!**
