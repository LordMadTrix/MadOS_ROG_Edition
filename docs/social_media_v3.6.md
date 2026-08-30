# 🛠️ Lancement de MadOS ROG Edition 3.6 — Reliability Edition

Posts prêts à copier-coller pour annoncer la 3.6.

**Angle choisi :** la 3.6 n'ajoute pas de fonctionnalités spectaculaires, elle rend
MadOS réellement installable et le prouve avec des chiffres. C'est un argument plus
solide qu'une liste de features — et personne ne pourra le contredire en testant.

---

## 📘 Pour Facebook

🛠️ **MadOS ROG Edition 3.6 est là — et cette fois, j'ai TOUT vérifié.** 🛠️

Salut l'équipe ! Cette version n'est pas une course aux nouvelles fonctionnalités. C'est autre chose, et honnêtement je pense que c'est plus important : **j'ai repris l'installateur ligne par ligne, et je l'ai testé en vrai.**

Pas « ça devrait marcher ». Pas « ça compile ». **Testé** : deux installations complètes de bout en bout, dans une machine virtuelle Ubuntu 24.04 toute neuve.

**Ce que ça a donné, chiffres à l'appui :**
👉 **30 modules exécutés**, **1 690 paquets installés**, **0 erreur réseau**
👉 Le **noyau XanMod 7.2** s'installe enfin vraiment (le dépôt pointait vers une adresse morte)
👉 **0 paquet cassé, 0 mise à jour en attente** après installation
👉 Le mode simulation `--dry-run` vérifié : il n'écrit **rien** sur votre système

**Ce que j'ai corrigé au passage :**
👉 **La commande d'installation elle-même** ne récupérait pas tous les fichiers. Elle va maintenant chercher ce qu'il lui manque toute seule.
👉 **La sauvegarde/restauration** ne sauvegardait rien. Maintenant si, et `sudo bash install.sh --restore` remet vraiment vos fichiers d'origine.
👉 **Plus rien n'est envoyé sans votre accord.** Le journal d'installation partait automatiquement sur un site public : c'est fini, on vous demande.

**Et une nouveauté quand même :** la commande `mados` 🖥️
`mados shift game` pour passer en mode jeu, `mados status`, `mados health`, `mados night on`… avec auto-complétion.

Le tout est libre, gratuit, et l'intégration continue bloque désormais la moindre erreur avant qu'elle ne vous atteigne.

👇 Tout est là :
https://lordmadtrix.github.io/MadOS_ROG_Edition/

Si vous l'installez, dites-moi ce que ça donne sur votre machine — c'est ce genre de retour qui fait avancer le projet. ❤️🖤

#MadOS #LinuxGaming #ASUSROG #OpenSource #Ubuntu #KDEPlasma #XanMod

---

## 🐦 Pour X (Twitter)

🛠️ **MadOS ROG Edition 3.6 — Reliability Edition**

Cette fois je n'annonce pas des features. J'annonce des chiffres vérifiés en VM :

✅ 30 modules, 1 690 paquets, 0 erreur réseau
✅ Noyau XanMod 7.2 qui s'installe vraiment
✅ 0 paquet cassé après installation
✅ `--dry-run` qui n'écrit rien, prouvé
✅ Nouvelle commande `mados`

Libre & gratuit 👇

#LinuxGaming #ASUSROG #MadOS #OpenSource #XanMod

---

## 💬 Version courte (commentaire, Discord, story)

MadOS ROG Edition 3.6 est sortie 🛠️
Version fiabilité : installateur audité ligne par ligne et testé en vrai.
30 modules, 1 690 paquets, 0 erreur. Le noyau XanMod s'installe enfin.
Nouvelle commande `mados` pour piloter la machine.
👉 https://lordmadtrix.github.io/MadOS_ROG_Edition/

---

## ⚠️ À savoir avant de publier

- **Tous les chiffres cités sont mesurés**, pas estimés : 30 modules, 1 690 paquets,
  0 erreur DNS, 0 paquet cassé, 0 upgradable. Ils viennent de deux installations
  réelles en VM QEMU sur Ubuntu 24.04.
- **Le test n'a pas eu lieu sur du matériel ASUS réel.** Les modules qui touchent au
  GPU NVIDIA et au matériel ROG (asusctl, RGB, undervolt) n'ont donc pas pu être
  validés en conditions réelles. Ne rien promettre de spécifique là-dessus tant que
  ce n'est pas testé sur le G533ZX.
- Si quelqu'un demande le détail de ce qui a changé, l'historique du dépôt contient
  la mesure derrière chaque correction.
