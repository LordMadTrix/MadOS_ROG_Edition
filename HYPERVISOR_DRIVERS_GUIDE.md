# 🖥️ Guide des Drivers Hyperviseur - MadOS ROG v3.0

## 📋 Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Hyperviseurs Supportés](#hyperviseurs-supportés)
3. [Détection Automatique](#détection-automatique)
4. [Installation Manuelle](#installation-manuelle)
5. [Optimisations Spécifiques](#optimisations-spécifiques)
6. [Dépannage](#dépannage)

---

## 🎯 Vue d'ensemble

MadOS ROG détecte **automatiquement** votre hyperviseur (QEMU, VMware, VirtualBox, Hyper-V) et installe les drivers et outils appropriés pour **optimiser les performances**.

### ✨ Avantages

✅ Détection automatique - pas de configuration manuelle  
✅ Drivers optimisés pour chaque hyperviseur  
✅ Support complet du copier-coller et du drag-and-drop  
✅ Performance réseau améliorée  
✅ Support graphique natif (Wayland/X11)  
✅ Agents invités fonctionnels  

---

## 🔧 Hyperviseurs Supportés

### 1️⃣ **QEMU/KVM** 🟦

#### Drivers Installés
```bash
qemu-guest-agent        # Agent invité principal
spice-vdagent          # Support copier-coller, souris, clipboard
acpid                  # Gestion ACPI (arrêt gracieux)
open-vm-tools          # Support cross-hyperviseur
```

#### Performance
- Accélération matérielle: ✅ KVM (libvirt)
- Réseau optimisé: Désactivation GSO/GRO
- Support 3D: Avec SPICE

#### Détection
```bash
# Le système détecte automatiquement:
- "QEMU" dans /proc/cpuinfo
- Périphériques QEMU via lspci
```

---

### 2️⃣ **VMware** 🟥

#### Drivers Installés
```bash
open-vm-tools          # Outils VMware principal
open-vm-tools-desktop  # Support graphique (X11/Wayland)
open-vm-tools-devel    # Headers pour compilation
vmware-gfx.conf        # Configuration SVGA III (si disponible)
```

#### Performance
- Accélération graphique: ✅ SVGA III
- Réseau: ✅ Optimisé (vmxnet3)
- Support complet: Copier-coller, drag-drop, partage fichiers

#### Détection
```bash
# Le système détecte automatiquement:
- DMI: "VMware"
- /sys/class/dmi/id/sys_vendor
- Périphériques VMware via lspci
```

#### Configuration Graphique
Si détecté SVGA III:
```bash
/etc/modprobe.d/vmware-gfx.conf:
options vmwgfx enable_fbdev=1
```

---

### 3️⃣ **VirtualBox** 🟩

#### Drivers Installés
```bash
virtualbox-guest-utils      # Utilitaires invité
virtualbox-guest-x11        # Support X11 (résolution automatique)
virtualbox-guest-dkms       # Module noyau dynamique
linux-headers-generic       # Headers pour compilation
```

#### Performance
- Résolution automatique: ✅ Redimensionnement de fenêtre
- Accélération 3D: ✅ (avec extension pack)
- Copier-coller: ✅ Bidirectionnel

#### DKMS
Les modules sont recompilés automatiquement lors de mises à jour du noyau:
```bash
sudo dkms autoinstall
```

#### Détection
```bash
# Le système détecte automatiquement:
- /sys/devices/virtual/dmi/id/product_name contient "VirtualBox"
- Périphériques VirtualBox via lspci
```

---

### 4️⃣ **Hyper-V** 🟪

#### Drivers Installés
```bash
linux-image-generic     # Noyau avec support Hyper-V
linux-tools-generic     # Outils de diagnostic
Modules Hyper-V:        # Déjà intégrés dans le noyau Linux
  - hv_vmbus
  - hv_storvsc
  - hv_netvsc
```

#### Performance
- Réseau: ✅ NetVSC (haute performance)
- Stockage: ✅ StorVSC
- Intégration système: ✅ Complète

#### Configuration
Les modules sont activés et rendus persistants:
```bash
/etc/modules:
hv_vmbus
hv_storvsc
hv_netvsc
```

#### Détection
```bash
# Le système détecte automatiquement:
- systemd-detect-virt = hyperv
- /sys/hypervisor/properties/identity contient "Hyper-V"
```

---

## 🔍 Détection Automatique

### Processus

L'installation MadOS effectue:

```
┌─────────────────────────────────────┐
│ 1. Vérification DMI (BIOS)          │
│    ├─ QEMU / VMware / VirtualBox   │
│    └─ Hyper-V                      │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ 2. Vérification /proc/cpuinfo       │
│    └─ "QEMU" détecté?              │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ 3. Scan PCI (lspci)                 │
│    ├─ QEMU / VMware / VirtualBox    │
│    └─ Autres périphériques          │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ 4. Installation drivers optimisés   │
└─────────────────────────────────────┘
```

### Vérifier la Détection

```bash
# Voir quel hyperviseur a été détecté
grep "hypervisor" /var/log/mados/mados_install.log

# Afficher le résultat de detection_hypervisor()
sudo bash -c 'source /opt/mados/lib/common.sh; detect_hypervisor'
```

---

## 🛠️ Installation Manuelle

### Forcer la Réinstallation d'Hyperviseur Spécifique

```bash
# Charger les fonctions
source /opt/mados/lib/common.sh

# Installer spécifiquement
sudo bash -c 'install_qemu_drivers'      # QEMU/KVM
sudo bash -c 'install_vmware_drivers'    # VMware
sudo bash -c 'install_virtualbox_drivers' # VirtualBox
sudo bash -c 'install_hyperv_drivers'    # Hyper-V
```

### Module Dédié

```bash
# Exécuter le module de drivers hyperviseur
sudo bash /opt/mados/modules/hyperviseur_drivers.sh
```

---

## ⚙️ Optimisations Spécifiques

### Réseau

Tous les hyperviseurs bénéficient de:

```bash
# Désactivation des offloads réseau (améliore la latence)
ethtool -K eth0 gso off gro off tso off

# Interfaces reconnues:
# - eth0, ens0 (Hyper-V)
# - ens33, ens160 (VMware)
# - enp0s3 (VirtualBox)
```

### I/O Scheduler

Pour les VMs, le scheduler est optimisé:

```bash
# Changé automatiquement à:
echo "noop" > /sys/block/sda/queue/scheduler    # Idéal pour SSD
# ou
echo "deadline" > /sys/block/sda/queue/scheduler # Alternative
```

### Watchdog

Le watchdog est désactivé (peut causer des ralentissements):

```bash
# /etc/default/grub:
GRUB_CMDLINE_LINUX_DEFAULT="... nowatchdog"
```

---

## 📊 Vérification Post-Installation

### QEMU/KVM

```bash
# Vérifier l'agent invité
systemctl status qemu-guest-agent
sudo systemctl enable qemu-guest-agent

# Vérifier SPICE
ps aux | grep spice-vdagent
```

### VMware

```bash
# Vérifier VMware Tools
systemctl status vmtoolsd
sudo systemctl enable vmtoolsd

# Vérifier les modules
lsmod | grep vmw
```

### VirtualBox

```bash
# Vérifier le service invité
systemctl status vboxadd-service
sudo systemctl enable vboxadd-service

# Vérifier DKMS
dkms status | grep virtualbox
```

### Hyper-V

```bash
# Vérifier les modules
lsmod | grep hv_

# Devrait afficher:
# hv_vmbus
# hv_storvsc
# hv_netvsc
```

---

## 🐛 Dépannage

### QEMU/KVM

#### Problème: Guest Agent ne démarre pas

```bash
# Solution
sudo systemctl status qemu-guest-agent
sudo systemctl restart qemu-guest-agent
journalctl -u qemu-guest-agent -n 20

# Si non installé
sudo apt install qemu-guest-agent
```

#### Problème: Copier-coller ne fonctionne pas

```bash
# Vérifier spice-vdagent
ps aux | grep spice

# Relancer
killall spice-vdagent
spice-vdagent &

# Ou via systemd (si disponible)
sudo systemctl restart spice-vdagent
```

---

### VMware

#### Problème: Résolution écran incorrecte

```bash
# Vérifier SVGA III
lspci | grep -i svga

# Vérifier les modules
lsmod | grep vmw

# Configuration
cat /etc/modprobe.d/vmware-gfx.conf
```

#### Problème: Copier-coller ne fonctionne pas

```bash
# Redémarrer VMware Tools
sudo systemctl restart vmtoolsd

# Vérifier le service
sudo vmware-toolbox-cmd stat balloon
```

---

### VirtualBox

#### Problème: Résolution ne change pas en redimensionnant

```bash
# Vérifier le service X11
sudo systemctl status vboxadd-x11

# Relancer manuellement
sudo /opt/VBoxGuestAdditions-*/bin/VBoxClient --display
```

#### Problème: DKMS échoue

```bash
# Reconstruire les modules
sudo dkms autoinstall -k $(uname -r)

# Vérifier les erreurs
dkms status | grep -i error
```

---

### Hyper-V

#### Problème: Pas de connectivité réseau

```bash
# Vérifier les modules
lsmod | grep hv_netvsc

# Charger manuellement
sudo modprobe hv_vmbus
sudo modprobe hv_netvsc

# Vérifier l'interface
ip link show
```

---

## 📚 Fichiers & Logs

### Fichiers de Configuration

```bash
/etc/modprobe.d/vmware-gfx.conf      # Config graphique VMware
/etc/default/grub                     # Watchdog désactivé
/etc/modules                          # Modules persistants Hyper-V
```

### Logs

```bash
/var/log/mados/mados_install.log      # Logs complets installation
/var/log/mados/mados_errors.log       # Erreurs seulement
journalctl -u qemu-guest-agent        # Logs QEMU
journalctl -u vmtoolsd                # Logs VMware
journalctl -u vboxadd-service         # Logs VirtualBox
```

---

## 🎓 Cas d'Usage

### Cas 1: Développement Local (QEMU)

```bash
# Installation MadOS détecte QEMU
# ├─ Installe qemu-guest-agent
# ├─ Installe spice-vdagent
# └─ Optimise réseau

# Résultat: VM responsive, copier-coller, bonne performance
```

### Cas 2: Serveur d'Entreprise (VMware)

```bash
# Installation MadOS détecte VMware
# ├─ Installe open-vm-tools complet
# ├─ Configure SVGA III si disponible
# └─ Active partage fichiers

# Résultat: Intégration maximale, performance réseau optimale
```

### Cas 3: Labos & Tests (VirtualBox)

```bash
# Installation MadOS détecte VirtualBox
# ├─ Installe guest additions
# ├─ Compile modules DKMS
# └─ Active résolution adaptative

# Résultat: Travail fluide, redimensionnement automatique
```

### Cas 4: Cloud Azure/Windows (Hyper-V)

```bash
# Installation MadOS détecte Hyper-V
# ├─ Charge modules hv_*
# ├─ Optimise réseau NetVSC
# └─ Configure stockage StorVSC

# Résultat: Performance cloud maximale, latence basse
```

---

## 🚀 Performance Attendue

| Hyperviseur | CPU | RAM | Réseau | Disque |
|-------------|-----|-----|--------|--------|
| QEMU/KVM | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| VMware | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| VirtualBox | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Hyper-V | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

*Après installation MadOS avec drivers optimisés*

---

## 📞 Support

- Consulter les logs: `sudo tail -100 /var/log/mados/mados_install.log`
- Vérifier la détection: `grep hypervisor /var/log/mados/mados_install.log`
- Relancer les drivers: `sudo bash /opt/mados/modules/hyperviseur_drivers.sh`

---

**MadOS ROG - Drivers Hyperviseur Optimisés 🚀**
