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
- **X / Y / B / A** : tape la lettre placée à gauche / en haut / à droite / en bas du pétale.
- **Stick au centre** : X = effacer (maintenir pour répéter), Y = espace, A = insérer la suggestion, B = fermer.

| Bouton | Action |
|---|---|
| LB / RB (ou croix ← →) | suggestion précédente / suivante |
| Croix ↑ ou clic stick droit | insérer la suggestion |
| Croix ↓ | effacer le dernier mot |
| LT | Maj (1 appui = une majuscule, 2 appuis rapides = verrouillage) |
| RT ou clic stick gauche | chiffres, accents et symboles |
| Start | envoyer |
| Select | changer de canal (Dire, Groupe, Raid, Guilde, Crier) |

Le clavier s'ouvre tout seul quand la zone de saisie du chat s'active et que la manette est active. Un
raccourci **« Ouvrir/fermer le clavier »** est aussi disponible dans *Échap > Raccourcis > AddOns*.

## Prédiction

- Un dictionnaire français, plus un vocabulaire WoW (lfg, heal, donjon, hdv…).
- Les accents sont ignorés pendant la recherche : `ca` propose « ça », `ete` propose « été ».
- **Apprentissage** : chaque message que vous envoyez (manette ou clavier) augmente la fréquence de
  vos mots et mémorise les enchaînements de mots. Après un espace, l'addon propose le mot qui suit
  habituellement.
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
(OpenSubtitles, CC-BY-SA-4.0) et génère `Dict_frFR.lua` / `Dict_enUS.lua`. Pour activer l'anglais,
ajouter `Dict_enUS.lua` dans `ControllerKeyboard.toc`.
