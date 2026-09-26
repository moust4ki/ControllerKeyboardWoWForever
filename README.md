# Controller Keyboard

A **daisywheel keyboard** to type in **WoW Forever**'s chat with a gamepad, with **smartphone-style
word prediction** that learns the way you write. Everything is also clickable with the mouse, so it
works with the Steam Controller trackpad too.

The look follows WoW Forever's gamepad UI: dark 8-petal wheel, bronze and gold rims, Friz Quadrata
font, the game's own button icons.

## Installation

1. Download the repository (*Code > Download ZIP*) and extract it, or grab the zip from CurseForge.
2. Rename the folder to **`ControllerKeyboard`** (exact name) and put it in
   `World of Warcraft/_classic_beta_/Interface/AddOns/`.
3. **Fully restart the game** (`/reload` does not load new texture files).

## Gamepad

The keyboard opens by itself with the chat. It is disabled in combat (the game blocks too many
actions there, "Not possible in combat") and comes back after combat if the chat is still open.

```
            [a b c d]
   [. , ? !]         [e f g h]
 [y z ' -]     (•)     [i j k l]
   [u v w x]         [m n o p]
            [q r s t]
```

- **Left stick**: pick a petal.
- **Right stick**: flick toward the letter to type (left / top / right / bottom of the petal).
- **Left stick centered**: the right stick drives the suggestions (← → pick, ↑ insert, ↓ delete).

| Button | Action |
|---|---|
| LB | delete (hold to repeat) |
| RB | space |
| LT | shift (tap = one capital, double tap = caps lock) |
| RT or left stick click | numbers, accents and symbols |
| D-pad ← → | previous / next suggestion |
| D-pad ↑ or right stick click | insert the suggestion |
| D-pad ↓ | delete the last word |

**A** (send), **X** (channels), **Y** (tab settings), **B** (back), **Start** and **Select** stay with
the game's gamepad UI: the addon does not use them.

## Mouse / Steam Controller

Every letter, suggestion and action (Shift, 123, Space, Delete, Send, X) is clickable. The game's
gamepad UI closes the chat on the first click: the keyboard then stays open and keeps the message,
"Send" sends it to the chat channel and "X" closes the keyboard. To change channel, pick it in the chat
before typing, or start the message with `/p`, `/g`, `/w name`…

## Prediction

- **Word completion**: English and French dictionaries of 12,000 words each, plus WoW slang (lfg,
  heal, dungeon…). Defaults to the client's language, changeable in the options. Accents are ignored
  while searching: `ca` suggests "ça", `ete` suggests "été".
- **Next word, iPhone style**: your usual message starters as soon as the chat opens; after each word,
  the most likely next word from your own 2 and 3 word sequences, plus built-in common French phrases.
- **Slash commands**: a message starting with `/` suggests `/reload`, `/p`, `/ra`, `/g`, `/w`, then your
  most used commands and common ones (`/r`, `/roll`, `/dance`, `/ck lock`…).
- **Learning**: every message you send (gamepad or keyboard) feeds your words, message starters, word
  sequences and commands. The text after `/w`, `/g`… is never stored as a command. Everything stays
  local, in `WTF/.../SavedVariables/ControllerKeyboard.lua`.

## Options

*Escape > Options > AddOns > Controller Keyboard*:

- lock position, open automatically, only when the gamepad is active;
- keyboard size, invert the sticks vertical axis;
- font (Blizzard fonts: Friz Quadrata, Morpheus, Skurri, Arial Narrow, or the chat font);
- button style (Xbox / PlayStation) and the game's button icons;
- suggestion language (French, English, both), learning;
- reset position, forget learned words.

## Commands

| Command | Effect |
|---|---|
| `/ck` | open the keyboard |
| `/ck lock` | lock / unlock the position (unlocking shows the keyboard to place it) |
| `/ck auto` | open automatically with the chat |
| `/ck pad` | only open automatically when the gamepad is active |
| `/ck learn` | turn learning on / off |
| `/ck lang fr\|en\|both` | suggestion language |
| `/ck scale 0.8` | keyboard size |
| `/ck invert` | invert the sticks vertical axis |
| `/ck reset` | reset the keyboard position |
| `/ck stats` | statistics |
| `/ck forget confirm` | forget learned words |
| `/ck glyphs` | list the game's gamepad button icons |
| `/ck debug` | print received buttons and sticks |

A **"Toggle keyboard"** key binding is also available in *Escape > Key Bindings > AddOns*.

## Technical notes

- WoW Forever's gamepad UI forbids addons from closing the chat or opening panels
  (`SetPreferredGamepadInteractTarget` error, which can freeze the client). The addon never closes the
  chat itself, creates its frames outside the gamepad UI's watch, and sends with the mouse through a
  secure macro button.
- Gamepad buttons are bound (override bindings) only while typing, and released before combat.

## Development

Textures (PNG sources in `design/textures/`, converted to TGA for the game):

```bash
python tools/convert_textures.py
```

Dictionaries ([FrequencyWords](https://github.com/hermitdave/FrequencyWords) frequency lists,
OpenSubtitles):

```bash
python tools/build_dict.py fr
```

CurseForge / release package (`dist/ControllerKeyboard-<version>.zip`, page description in
`docs/curseforge.md`):

```bash
python tools/package.py
```

## License

Code under the MIT license (see `LICENSE`). `Dict_frFR.lua` and `Dict_enUS.lua` are derived from
FrequencyWords (Hermit Dave) and remain under the
[CC-BY-SA-4.0](https://creativecommons.org/licenses/by-sa/4.0/) license.

## AI disclosure

This addon was built with the help of AI: the code was written with Claude Code (Anthropic) and the
visual design created with Claude Design, directed by the author, who defined the features and tested
the addon in game.
