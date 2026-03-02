# 📖 LE GUIDE D'INSTALLATION ULTIME : MadOS ROG Edition v3.0

> **Sujet :** Installer Ubuntu Server (Base Minimale) + Le Script MadOS ROG Edition  
> **Cible :** PC Fixe ou PC Portable (Spécialement ASUS ROG)  
> **Modes :** Standalone (Seul sur le disque) ou Dual Boot (À côté de Windows 11/10)  
> **Objectif :** Obtenir un système Linux Gaming extrême, pur, et optimisé E-Sport, sans les bloatwares d'Ubuntu Desktop.

---

## 🛑 PRÉREQUIS AVANT LE DÉCOLLAGE

Avant de commencer, vous aurez besoin de :
1. **Une clé USB** de 4 Go minimum (elle sera formatée).
2. **Rufus** (sur Windows) ou **BalenaEtcher** pour flasher la clé USB.
3. L'image ISO d'**Ubuntu Server 24.04 (Noble Numbat)** téléchargée depuis le site officiel d'Ubuntu. Pourquoi la version *Server* ? Car elle est totalement vide : pas d'environnement de bureau, pas de navigateur, pas de flatpak inutiles. C'est la toile blanche parfaite pour MadOS.

---

## 🛠️ PHASE 1 : PRÉPARATION DU TERRAIN (Sur Windows)

### 🔹 Cas A : Installation Seul (Standalone)
Si vous voulez écraser Windows et utiliser uniquement MadOS : **passez directement à la Phase 2.** (Aucune préparation logicielle requise).

### 🔹 Cas B : Installation Dual Boot (À côté de Windows)
Si vous voulez garder Windows pour le travail et MadOS pour le Gaming :
1. Sur Windows, faites un clic droit sur le bouton Démarrer > **Gestion des disques**.
2. Repérez votre partition `C:` (ou le disque où vous voulez installer MadOS).
3. Faites un clic droit > **Réduire le volume**.
4. Entrez la quantité d'espace à allouer pour MadOS en Mégaoctets (ex: `100 000` pour environ 100 Go). **Minimum recommandé : 60 Go.**
5. Cliquez sur **Réduire**. L'espace deviendra "Non alloué" (en noir). *Ne créez pas de volume dessus*, laissez-le tel quel.

### 🔌 Désactiver la sécurité BIOS
Il est *crucial* de configurer le BIOS (touche `Suppr` ou `F2` au démarrage) :
- **Secure Boot :** Désactivé (Disabled) -> Indispensable pour l'installation des drivers NVIDIA (DKMS) et du module kernel ASUS.
- **Fast Boot :** Désactivé (Disabled) -> Assure que le matériel est bien détecté au démarrage à froid.
- **SATA Mode :** AHCI (Ne pas utiliser RAID/RST).

---

## 💾 PHASE 2 : CRÉATION DE LA CLÉ BOOTABLE

1. Branchez votre clé USB sur votre PC.
2. Lancez **Rufus**.
3. Dans *Périphérique*, sélectionnez votre clé USB.
4. Dans *Sélection*, choisissez le fichier ISO **Ubuntu Server 24.04**.
5. Schéma de partition : **GPT** | Système de destination : **UEFI (non-CSM)**.
6. Cliquez sur **DÉMARRER**.

---

## 🐧 PHASE 3 : INSTALLATION D'UBUNTU SERVER (LA BASE)

1. Branchez la clé USB sur votre PC éteint.
2. Allumez et tapotez la touche du Boot Menu (souvent `F8`, `F12` ou `Echap` chez ASUS).
3. Sélectionnez votre clé USB en mode `[UEFI]`. L'installateur d'Ubuntu Server démarre.

### 📜 Déroulement de l'installateur :
- **Langue & Clavier :** Choisissez *Français*.
- **Ubuntu Server (minimisé) ou standard ?** Prenez la version "Ubuntu Server" standard (pas la version "minimized").
- **Réseau :** L'installateur détectera votre connexion Ethernet (DHCP). Si vous êtes en Wi-Fi, choisissez votre réseau et entrez le mot de passe.
- **Proxy / Miroir :** Laissez les paramètres par défaut (faites `Done`).

### 💿 Partitionnement du stockage :
C'est ici que votre choix prend tout son sens.

> **Pour le Standalone (Seul l'OS d'Ubuntu est voulu)** :
> Choisissez *"Use an entire disk"* (Utiliser le disque entier). Sélectionnez votre SSD primaire.

> **Pour le Dual Boot (À côté de Windows)** :
> Choisissez *"Custom storage layout"* (Partitionnement manuel).
> 1. Cherchez votre espace "Free Space" (celui que vous avez réduit sur Windows).
> 2. Sélectionnez cet espace > *Add GPT Partition*.
> 3. Size : Laissez le maximum / Format : `Ext4` ou `BTRFS` / Mount point (Point de montage) : `/` (Racine).
> 4. Ubuntu créera automatiquement la partition EFI si nécessaire, ou utilisera celle de Windows (en dual boot).

### 👤 Création du compte et Services :
- **Nom du PC et d'utilisateur :** Mettez des noms simples (ex: Utilisateur `mados`, Mot de passe `root`). Entrez "mados-rog" comme nom de serveur.
- **Ubuntu Pro :** Skip for now (Ignorer).
- **SSH Setup :** Vous pouvez cocher "Install OpenSSH Server" si vous comptez administrer la machine à distance via le réseau, sinon ignorez.
- **Featured Server Snaps :** *TRÈS IMPORTANT*. Ne cochez **ABSOLUMENT RIEN**. Laute de votre PC doit rester une toile vierge totale.
- Lancez l'installation et patientez. Quand "Reboot Now" s'affiche, retirez la clé USB et redémarrez.

---

## ⚡ PHASE 4 : DÉPLOIEMENT DE L'EXPÉRIENCE MADOS ROG (LE SCRIPT)

Votre PC redémarre. Vous devriez arriver (si Dual Boot) sur un menu "GRUB" noir et blanc. Choisissez "Ubuntu".
L'écran va défiler avec du texte blanc sur fond noir, puis vous demandera de vous connecter (*login*).
1. Tapez votre nom d'utilisateur et faites `Entrée`.
2. Tapez votre mot de passe (les caractères ne s'affichent pas, c'est normal sous Linux) et faites `Entrée`.

Vous êtes maintenant face au terminal brut. Voici la magie :

> ⚠️ **ASTUCE ANTI-BEUG (Machine Virtuelle / Connexion instable) :**
> Si vous être sur une VM (VirtualBox/VMware), le réseau coupe souvent (`Erreur temporaire de résolution de ubuntu.com`). C'est dû à l'IPv6. Forcez l'IPv4 en tapant cette commande **avant** l'étape 1 :
> ```bash
> echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
> ```

**Étape 1 : Mettre à jour la base de données APT et installer git :**
```bash
sudo apt update && sudo apt install -y git
```
> Il vous sera demandé votre mot de passe pour confirmer l'action *sudo* (droits administrateur).

**Étape 2 : Télécharger (Cloner) le Cœur Matriciel MadOS ROG Edition depuis GitHub :**
```bash
git clone https://github.com/LordMadTrix/MadOS_ROG_Edition.git
```

**Étape 3 : Entrer dans le répertoire de l'outil et lancer l'installation :**
```bash
cd "MadOS_ROG_Edition/MadROG poste install"
chmod +x Menu_Installation_ROG.sh
sudo ./Menu_Installation_ROG.sh
```

---

## 🎮 PHASE 5 : LA MATRICE PREND LE CONTRÔLE (TUI WHIPTAIL)

Le menu **MadOS ROG Edition (v3.0)** va apparaître dans votre terminal physique avec ses couleurs Rouge/Blanc cybernétiques.

1. **Choix du déploiement :**
   - Prenez  `1 - Déploiement Total (Expérience E-Sport)` si vous voulez l'OS de base complet + l'IA + le Gaming optimisé au maximum.
   - Prenez `2 - Déploiement Custom` si vous souhaitez cocher spécifiquement (avec la touche Espace) ce que le script installera.
2. Appuyez sur **OK** ou faites la touche `<Entrée>`.
3. Le script, grâce aux 27 modules indépendants, va se charger de tout pendant une durée de 15 à 30 minutes :
   - Installation du noyau XanMod Edge ultra rapide.
   - Compilation locale d'Asusctl (contrôle Hardware ROG, Ventilateurs, LED).
   - Déploiement de l'environnement Plasma 6 Wayland (ultra léger sans GNOME).
   - Modification réseau TCP BBR (zéro latence réseau).
   - Outils E-Sport (Polling rate 1000Hz USB, ZRAM DDR4/DDR5 compression rapide).
   - Installation E-Sport Proton, MangoHud ROG et Steam.

✨ **UNE FOIS TERMINÉ :**
L'écran affichera le succès final. Vous n'avez qu'à redémarrer la machine avec la commande :
```bash
sudo reboot
```

## 🎇 LE RÉSULTAT FINAL
En redémarrant, adieu l'écran violet terne d'Ubuntu.  
Le BIOS laissera place au menu GRUB "Cyberpunk", suivi du boot screen "MadOS ROG Edition" (Plymouth).  
Le gestionnaire de session SDDM vous accueillera, et vous entrerez dans un **KDE Plasma 6 personnalisé au grain de rouge Republic of Gamers**, tournant à la perfection avec les drivers NVIDIA DKMS pré-compilés et l'Hardware ASUS prêt au combat. Vous avez un contrôle TLP sur votre batterie et des logiciels gaming pré-installés avec un kernel temps-réel E-Sport.

*Bon jeu.*
