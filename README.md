# 🚀 VM Overlay Manager

> 🧠 Gestion intelligente des overlays QCOW2 pour Libvirt / KVM\
> ⚡ Switch instantané • 🔄 Reset automatique • 🛡 Snapshots sécurisés •
> 🆙 Mise à jour automatique

------------------------------------------------------------------------

## ✨ Pourquoi ce projet existe

Gérer manuellement des overlays QCOW2 dans Libvirt peut être risqué,
lent et source d'erreurs.

**VM Overlay Manager** fournit une méthode propre, sécurisée et rapide
pour gérer vos overlays comme un professionnel.

------------------------------------------------------------------------

## 🔥 Fonctionnalités

### 🖥 Support Multi-VM

Gérez plusieurs machines virtuelles indépendamment avec des
configurations dédiées.

### 🔄 Switch d'Overlay Instantané

Changez d'overlay en quelques secondes sans modifier manuellement les
fichiers XML.

### 🛡 Snapshots Automatiques

Avant tout changement d'overlay : - Un snapshot est créé
automatiquement\
- Un retour arrière reste possible

### 🗑 Suppression Intégrée

Supprimez les overlays inutilisés directement depuis l'interface.\
🛑 L'overlay actif est protégé contre toute suppression accidentelle.

### 🧹 Reset Automatique à l'Arrêt

Grâce au hook Libvirt : - La VM revient automatiquement sur l'overlay
`Default` à chaque extinction\
- L'environnement de production reste propre et stable

### 🆙 Mise à Jour Automatique

À chaque lancement : - Le script vérifie sa version sur GitHub\
- Détecte si une nouvelle version est disponible\
- Propose une mise à jour automatique en place

### 🧠 Détection Intelligente

-   Détection automatique des VM Libvirt\
-   Liste dynamique des images QCOW2 disponibles\
-   Vérification de la structure des overlays avant switch

------------------------------------------------------------------------

## 🧩 Structure des Overlays

Base.qcow2 (Backing File propre)\
│\
├── Default.qcow2 🟢 Production\
├── Dev.qcow2 🧪 Tests\
├── Sandbox.qcow2 🔬 Expérimentations\
└── Temp.qcow2 ⚠ Tests risqués

------------------------------------------------------------------------

## 🛠 Installation

``` bash
git clone https://github.com/LordZatchi/vm-overlay-manager.git
cd vm-overlay-manager
chmod +x vm-overlay.sh
```

Lancement :

``` bash
./vm-overlay.sh
```

Suivez l'assistant interactif.

------------------------------------------------------------------------

## 🎮 Utilisation

``` bash
./vm-overlay.sh
```

Actions disponibles :

-   📂 Lister & changer d'overlay\
-   ➕ Créer un nouvel overlay\
-   🗑 Supprimer un overlay en sécurité\
-   🔄 Forcer le retour à Default\
-   📜 Consulter les logs\
-   🆙 Vérifier les mises à jour

------------------------------------------------------------------------

## 🎯 Cas d'utilisation

-   🧪 Tests logiciels\
-   🛠 VM de réparation Windows\
-   🖥 Environnements WinApps\
-   🔬 Lab sandbox\
-   🧱 États jetables pour expérimentation

------------------------------------------------------------------------

## 📦 Prérequis

-   Linux\
-   QEMU / KVM\
-   Libvirt\
-   Bash\
-   Images disque QCOW2\
-   Connexion Internet (pour la mise à jour automatique)

------------------------------------------------------------------------

## 🗺 Roadmap

-   [ ] Visualisation des différences entre overlays\
-   [ ] Navigateur de snapshots\
-   [ ] Mode CLI rapide\
-   [ ] Interface web optionnelle

------------------------------------------------------------------------

## ⚖ Licence

Licence MIT\
Voir le fichier `LICENSE` pour plus de détails.

------------------------------------------------------------------------

Projet créé par **LordZatchi** ⚙️\
Gestion professionnelle des overlays pour environnements VM avancés.
