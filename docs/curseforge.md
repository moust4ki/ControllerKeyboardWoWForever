# Controller Keyboard

**Type in WoW Forever's chat with a gamepad, no keyboard needed.**
*Écrivez dans le chat de WoW Forever à la manette. (Français plus bas)*

Controller Keyboard adds a wheel keyboard that opens with the chat. The left stick picks a petal, the
right stick types the letter: two gestures per letter, no grid to navigate. Smartphone-style
prediction suggests words and the rest of your sentences, and learns the way you write.

The look matches WoW Forever's gamepad UI: dark wheel with bronze and gold rims, Friz Quadrata font,
the game's own button icons.

## Features

- **Two input methods**, switchable in the options:
  - **Daisywheel**: 8 petals of 4 characters; left stick = petal, right stick = letter.
  - **One-stick keyboard**: a full AZERTY / QWERTY keyboard; the left stick's tilt places the
    cursor, RT types the highlighted key.
- Numbers / accents / symbols layer in both.
- **iPhone-style prediction**
  - word completion: English and French dictionaries (12,000 words each, client language by default)
    plus WoW slang: lfg, heal…;
  - accents ignored while searching;
  - next word from your habits and common phrases;
  - suggestions as soon as the chat opens.
- **Chat channel row**: `/s`, `/y`, `/p`, `/ra`, `/g`, `/1`, `/w`, `/r`, switched with the D-pad or by hovering
  with the mouse, without losing the chat focus.
- **Slash command autocomplete**: `/` suggests `/reload`, `/p`, `/ra`, `/g`, `/w`, then your most used
  commands.
- **Learning**: your words, message starters and word sequences are remembered, locally.
- **Mouse and Steam Controller**: everything is clickable; the message is kept even when the game
  closes the chat.
- **Works with the game's gamepad UI**: B goes back, X opens channels, as usual.
- **Options panel**: lock position, size, optional mouse buttons row, Blizzard font, Xbox / PlayStation glyphs, suggestion
  language (French, English, both)…

## Gamepad controls (daisywheel)

| Button | Action |
|---|---|
| Left stick | pick a petal |
| Right stick | type the aimed letter |
| Right stick (left stick centered) | ← → move in the active row, ↑ insert the suggestion, ↓ delete |
| LB / RB | delete / space |
| LT | shift (double tap: caps lock) |
| RT | numbers, accents, symbols |
| D-pad ↓ / ↑ | channel row (under the wheel) / suggestions row |
| D-pad ← → | move in the active row (suggestion or channel) |
| A | send the message |
| B | empty the message (with an empty message: the game's back, closes the chat) |
| X, Y | handled by the game: channels, tab |

## Gamepad controls (one-stick keyboard)

| Button | Action |
|---|---|
| Left stick | move the cursor on the keyboard (absolute position) |
| RT | type the highlighted key |
| LT / RB | delete / space |
| LB | shift (double tap: caps lock) |
| Left stick click | numbers, accents, symbols |
| Right stick | ← → move in the active row, ↑ insert, ↓ delete |
| D-pad, A, B | same as the daisywheel |

## Installation

Install with the CurseForge app, or extract the zip into
`World of Warcraft/_classic_beta_/Interface/AddOns/`. **Fully restart the game** after installing (a
`/reload` does not load new textures).

## Commands

- `/ck`: open the keyboard
- `/ck lock`: lock / unlock the position
- `/ck glyphs`: list the game's gamepad button icons
- `/ck help`: all commands
- Options: *Escape > Options > AddOns > Controller Keyboard*

## Compatibility

Made for **WoW Forever** and its gamepad UI. The keyboard is disabled in combat (the game blocks too
many actions there) and comes back after combat. Source code and issues:
[GitHub](https://github.com/moust4ki/ControllerKeyboardWoWForever).

---

# Controller Keyboard (Français)

**Écrivez dans le chat de WoW Forever à la manette, sans clavier.**

Controller Keyboard ajoute un clavier en roue qui s'ouvre avec le chat. Le stick gauche choisit un
pétale, le stick droit tape la lettre : deux gestes par lettre, sans naviguer dans une grille. Une
prédiction façon smartphone propose les mots et la suite de vos phrases, et apprend votre façon
d'écrire.

Le design reprend l'interface manette de WoW Forever : roue sombre à liserés bronze et or, police
Friz Quadrata, icônes de boutons du jeu.

## Fonctionnalités

- **Deux méthodes de saisie**, au choix dans les options :
  - **Daisywheel** : 8 pétales de 4 caractères ; stick gauche = pétale, stick droit = lettre.
  - **Clavier 1 stick** : un clavier AZERTY / QWERTY complet ; l'inclinaison du stick gauche place le
    curseur, RT tape la touche en surbrillance.
- Couche chiffres / accents / symboles dans les deux.
- **Prédiction façon iPhone**
  - complétion des mots : dictionnaires français et anglais (12 000 mots chacun, langue du client par
    défaut) + vocabulaire WoW : lfg, heal, donjon, hdv… ;
  - accents ignorés : `ca` propose « ça », `ete` propose « été » ;
  - mot suivant d'après vos habitudes et des expressions courantes (« je » → suis, vais… ; « bonne » →
    nuit, soirée…) ;
  - propositions dès l'ouverture du chat, avant même de taper.
- **Rangée de canaux** : `/s`, `/y`, `/p`, `/ra`, `/g`, `/1`, `/w`, `/r`, à la croix ou au survol de la souris,
  sans perdre le focus du chat.
- **Autocomplétion des commandes** : `/` propose `/reload`, `/p`, `/ra`, `/g`, `/w`, puis vos commandes
  les plus utilisées.
- **Apprentissage** : vos mots, vos débuts de message et vos enchaînements sont retenus, en local.
- **Souris et Steam Controller** : tout est cliquable ; le message est conservé même si le jeu ferme le chat.
- **Intégré à l'interface manette du jeu** : B revient, X ouvre les canaux, comme d'habitude.
- **Panneau d'options** : verrouillage de la position, taille, boutons souris optionnels, police Blizzard, style Xbox / PlayStation,
  langue des suggestions (français, anglais, les deux)…

## Commandes à la manette (daisywheel)

| Bouton | Action |
|---|---|
| Stick gauche | choisir un pétale |
| Stick droit | taper la lettre visée |
| Stick droit (stick gauche au centre) | ← → se déplacer dans la rangée active, ↑ insérer, ↓ effacer |
| LB / RB | effacer / espace |
| LT | majuscule (deux appuis : verrouillage) |
| RT | chiffres, accents, symboles |
| Croix ↓ / ↑ | rangée des canaux (sous la roue) / rangée des suggestions |
| Croix ← → | se déplacer dans la rangée active (suggestion ou canal) |
| A | envoyer le message |
| B | vider le message (message vide : retour du jeu, ferme le chat) |
| X, Y | gérés par le jeu : canaux, onglet |

## Commandes à la manette (clavier 1 stick)

| Bouton | Action |
|---|---|
| Stick gauche | déplacer le curseur sur le clavier (position absolue) |
| RT | taper la touche en surbrillance |
| LT / RB | effacer / espace |
| LB | majuscule (deux appuis : verrouillage) |
| Clic stick gauche | chiffres, accents, symboles |
| Stick droit | ← → se déplacer dans la rangée active, ↑ insérer, ↓ effacer |
| Croix, A, B | comme la daisywheel |

## Installation

Installez via l'application CurseForge, ou extrayez le zip dans
`World of Warcraft/_classic_beta_/Interface/AddOns/`. **Relancez complètement le jeu** après
l'installation (un `/reload` ne suffit pas pour charger les textures).

## Commandes

- `/ck` : ouvrir le clavier
- `/ck lock` : verrouiller / déverrouiller la position
- `/ck glyphs` : lister les icônes de boutons manette du jeu
- `/ck help` : toutes les commandes
- Options : *Échap > Options > AddOns > Controller Keyboard*

## Compatibilité

Conçu pour **WoW Forever** et son interface manette. Le clavier est désactivé en combat (le jeu y
bloque trop d'actions) et revient après le combat. Code source et suivi des problèmes :
[GitHub](https://github.com/moust4ki/ControllerKeyboardWoWForever).

*Dictionaries derived from FrequencyWords by Hermit Dave (CC-BY-SA-4.0). Code under the MIT license.*

---

## AI disclosure

This addon was built with the help of AI: the code was written with Claude Code (Anthropic) and the
visual design created with Claude Design, directed by the author, who defined the features and tested
the addon in game.

*Cet addon a été développé avec l'aide de l'intelligence artificielle : le code a été écrit avec
Claude Code (Anthropic) et le design visuel créé avec Claude Design, sous la direction de l'auteur, qui
a défini les fonctionnalités et testé l'addon en jeu.*
