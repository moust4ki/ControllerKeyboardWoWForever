# Controller Keyboard

Clavier visuel en **roue (daisywheel)** pour écrire dans le chat de **WoW Forever** à la manette, avec
une **prédiction de mots façon smartphone** qui apprend votre façon d'écrire. Tout reste cliquable à la
souris, donc aussi au trackpad du Steam Controller.

Le design reprend les codes de l'interface manette de WoW Forever : roue sombre à 8 pétales, liserés
bronze et or, police Friz Quadrata, icônes de boutons du jeu.

## Installation

1. Téléchargez le dépôt (*Code > Download ZIP*) et extrayez-le.
2. Renommez le dossier en **`ControllerKeyboard`** (nom exact) et placez-le dans
   `World of Warcraft/_classic_beta_/Interface/AddOns/`.
3. **Relancez complètement le jeu** (un `/reload` ne suffit pas pour de nouveaux fichiers de textures).

## Utilisation à la manette

Le clavier s'ouvre tout seul quand le chat s'ouvre.

```
            [a b c d]
   [. , ? !]         [e f g h]
 [y z ' -]     (•)     [i j k l]
   [u v w x]         [m n o p]
            [q r s t]
```

- **Stick gauche** : choisit un pétale.
- **Stick droit** : pichenette vers la lettre à taper (gauche / haut / droite / bas du pétale).
- **Stick gauche au centre** : le stick droit gère les suggestions (← → choisir, ↑ insérer, ↓ effacer).

| Bouton | Action |
|---|---|
| LB | effacer (maintenir pour répéter) |
| RB | espace |
| LT | Maj (1 appui = une majuscule, 2 appuis rapides = verrouillage) |
| RT ou clic stick gauche | chiffres, accents et symboles |
| Croix ← → | suggestion précédente / suivante |
| Croix ↑ ou clic stick droit | insérer la suggestion |
| Croix ↓ | effacer le dernier mot |

**A** (envoyer), **X** (canaux), **Y** (paramètres de l'onglet), **B** (retour), **Start** et **Select**
restent gérés par l'interface manette du jeu : l'addon ne les utilise pas.

## Utilisation à la souris / Steam Controller

Toutes les lettres, suggestions et actions (Maj, 123, Espace, Effacer, Envoyer, X) sont cliquables.
L'interface manette du jeu ferme le chat au premier clic : le clavier reste alors ouvert et garde le
message, « Envoyer » l'envoie sur le canal du chat et « X » ferme le clavier. Pour changer de canal,
choisissez-le dans le chat avant de taper, ou commencez le message par `/p`, `/g`, `/w nom`…

## Prédiction

- **Complétion des mots** : dictionnaire français de 12 000 mots + vocabulaire WoW (lfg, heal,
  donjon, hdv…). Les accents sont ignorés pendant la recherche : `ca` propose « ça », `ete` « été ».
- **Mot suivant, comme sur iPhone** : dès l'ouverture du chat, vos débuts de message habituels ; après
  chaque mot, la suite la plus probable d'après vos enchaînements de 2 et 3 mots et une base
  d'expressions françaises courantes (« je » → suis, vais… ; « bonne » → nuit, soirée… ; « j' » → ai…).
- **Commandes** : un message qui commence par `/` propose `/reload`, `/p`, `/ra`, `/g`, `/w`, puis vos
  commandes les plus utilisées et les commandes courantes (`/r`, `/roll`, `/dance`, `/ck lock`…).
- **Apprentissage** : chaque message envoyé (manette ou clavier) enrichit vos mots, débuts de message,
  enchaînements et commandes. Le contenu des messages après `/w`, `/g`… n'est jamais mémorisé comme
  commande. Tout reste en local dans `WTF/.../SavedVariables/ControllerKeyboard.lua`.

## Options

*Échap > Options > AddOns > Controller Keyboard* :

- verrouiller la position, ouverture automatique, seulement quand la manette est active ;
- taille du clavier, inversion de l'axe vertical des sticks ;
- police (polices Blizzard : Friz Quadrata, Morpheus, Skurri, Arial Narrow, ou celle du chat) ;
- style des boutons (Xbox / PlayStation) et icônes de boutons du jeu ;
- langue des suggestions (français, anglais, les deux), apprentissage ;
- replacer le clavier, oublier les mots appris.

## Commandes

| Commande | Effet |
|---|---|
| `/ck` | ouvrir le clavier |
| `/ck lock` | verrouiller / déverrouiller la position (déverrouiller affiche le clavier pour le placer) |
| `/ck auto` | ouverture automatique avec le chat |
| `/ck pad` | n'ouvrir automatiquement que si la manette est active |
| `/ck learn` | activer / désactiver l'apprentissage |
| `/ck lang fr\|en\|both` | langue des suggestions |
| `/ck scale 0.8` | taille du clavier |
| `/ck invert` | inverser l'axe vertical des sticks |
| `/ck reset` | replacer le clavier |
| `/ck stats` | statistiques |
| `/ck forget confirm` | oublier les mots appris |
| `/ck glyphs` | lister les icônes de boutons manette du jeu |
| `/ck debug` | afficher les boutons et sticks reçus |

Un raccourci **« Ouvrir/fermer le clavier »** est aussi disponible dans *Échap > Raccourcis > AddOns*.

## Notes techniques

- L'interface manette de WoW Forever interdit aux addons de fermer le chat ou d'ouvrir des panneaux
  (erreur `SetPreferredGamepadInteractTarget`, qui peut figer le client). L'addon ne ferme donc jamais le
  chat lui-même, crée ses cadres hors de la surveillance de l'interface manette, et envoie à la souris
  via un bouton de macro sécurisé.
- Les boutons de la manette sont liés temporairement (override bindings) uniquement pendant la saisie.

## Développement

Textures (sources PNG dans `design/textures/`, conversion en TGA pour le jeu) :

```bash
python tools/convert_textures.py
```

Dictionnaires (liste de fréquences [FrequencyWords](https://github.com/hermitdave/FrequencyWords),
OpenSubtitles) :

```bash
python tools/build_dict.py fr
```

Package CurseForge / release (`dist/ControllerKeyboard-<version>.zip`, description dans
`docs/curseforge.md`) :

```bash
python tools/package.py
```

## Licence

Code sous licence MIT (voir `LICENSE`). `Dict_frFR.lua` et `Dict_enUS.lua` sont dérivés de
FrequencyWords (Hermit Dave) et restent sous licence
[CC-BY-SA-4.0](https://creativecommons.org/licenses/by-sa/4.0/).
