# Controller Keyboard

Clavier visuel en **roue (daisywheel)** pour écrire dans le chat de **WoW Forever** à la manette, avec
prédiction de mots qui apprend de votre façon d'écrire. Tout reste cliquable à la souris, donc aussi
au trackpad du Steam Controller.

## Fonctionnement

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

A (envoyer), X (canaux), Y (paramètres de l'onglet), B (retour), Start et Select restent gérés par
l'interface manette du jeu : l'addon ne les utilise pas.

Le clavier s'ouvre tout seul quand la zone de saisie du chat prend le focus (`/ck auto` pour désactiver,
`/ck pad` pour ne l'ouvrir que si la manette est l'entrée active). Un raccourci **« Ouvrir/fermer le
clavier »** est aussi disponible dans *Échap > Raccourcis > AddOns*. Faites glisser la barre de texte
(icône de déplacement) ou le centre de la roue pour déplacer le clavier ; la position est mémorisée.

### Souris et Steam Controller

L'interface manette du jeu ferme le chat dès qu'on clique à la souris. Quand un clic sur le clavier ferme
le chat, le clavier reste ouvert et garde le message : on continue à taper (souris ou manette), puis
« Envoyer » (ou A) l'envoie sur le canal choisi, et « X » (ou B) ferme le clavier. Si le chat est rouvert,
le message y est recopié.

### Envoi et fermeture du chat

L'interface manette de WoW Forever interdit aux addons de fermer le chat ou d'envoyer le texte
eux-mêmes (erreur `SetPreferredGamepadInteractTarget`). À la manette, c'est le A natif du jeu qui
envoie ; à la souris, le bouton « Envoyer » est un bouton de macro sécurisé qui envoie `/s texte`
(ou `/p`, `/g`, `/w nom`…).

## Prédiction

- Un dictionnaire français, plus un vocabulaire WoW (lfg, heal, donjon, hdv…).
- Les accents sont ignorés pendant la recherche : `ca` propose « ça », `ete` propose « été ».
- **Prédiction du mot suivant** (comme sur iPhone) : dès l'ouverture du chat, l'addon propose vos
  débuts de message habituels ; après chaque mot, il propose la suite la plus probable en combinant
  vos enchaînements de 2 et 3 mots et une base d'expressions françaises courantes
  (« je » -> suis, vais… ; « bonne » -> nuit, soirée… ; « j' » -> ai, arrive…).
- **Apprentissage** : chaque message que vous envoyez (manette ou clavier) augmente la fréquence de
  vos mots, de vos débuts de message et de vos enchaînements de mots.
- Les données sont stockées localement dans `WTF/.../SavedVariables/ControllerKeyboard.lua`.

## Commandes

| Commande | Effet |
|---|---|
| `/ck` | ouvrir / fermer le clavier |
| `/ck auto` | ouverture automatique avec le chat |
| `/ck pad` | n'ouvrir automatiquement que si la manette est active |
| `/ck learn` | activer / désactiver l'apprentissage |
| `/ck lang fr\|en\|both` | dictionnaires utilisés |
| `/ck scale 0.8` | taille du clavier |
| `/ck invert` | inverser l'axe vertical du stick |
| `/ck lock` | verrouiller / déverrouiller la position (déverrouiller affiche le clavier pour le placer) |
| `/ck reset` | replacer le clavier |
| `/ck stats` | statistiques |
| `/ck forget confirm` | oublier les mots appris |
| `/ck debug` | afficher les boutons et sticks reçus |

## Installation

Copier le dossier dans `Interface/AddOns/ControllerKeyboard` (le dossier doit porter ce nom exact).

## Générer un dictionnaire plus grand

```bash
python tools/build_dict.py fr
python tools/build_dict.py en
```

Le script télécharge la liste de fréquences [FrequencyWords](https://github.com/hermitdave/FrequencyWords)
(OpenSubtitles, CC-BY-SA-4.0) et génère `Dict_frFR.lua` / `Dict_enUS.lua` (12 000 mots chacun).
L'anglais est chargé mais désactivé par défaut : `/ck lang both` pour l'activer.

## Licence

Code sous licence MIT (voir `LICENSE`). Les fichiers `Dict_frFR.lua` et `Dict_enUS.lua` sont dérivés de
FrequencyWords (Hermit Dave) et restent sous licence
[CC-BY-SA-4.0](https://creativecommons.org/licenses/by-sa/4.0/).
