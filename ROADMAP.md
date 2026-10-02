# Roadmap

Everything planned for Easy Controller - Forever, so nothing gets lost. Each feature is built, tested
in game, then released on GitHub and CurseForge. Done items move to the [CHANGELOG](CHANGELOG.md)
(1.2.0: vibrations, supplies, consumables wheel; 1.2.1: the game's gamepad functions anywhere, its
buttons replaceable).

## 1.2.1: the game's own gamepad functions, on any button

How WoW Forever does it: jump, back (stop casting / targeting, clear the target), interact and
inspect are the four fixed buttons of the gamepad bar's top layer (A, B, X, Y alone), with their
function built in; the Start menu, interface focus, ping, ally / enemy targeting and the left /
right bars are the game's own key bindings, which it sets again whenever one of its gamepad windows
closes.

- [x] **Move a game function to another button** (a back paddle, L3, a free combination...): the
  Gamepad tab's Game list gets a "gamepad functions" section. The four fixed ones press the game's
  own button (its behaviour exactly: the smart interact, jump and sit...); the others are the
  game's own bindings.
- [x] **Put something else on a button the game uses** (A, B, X, Y alone, the D-pad, LB / RB alone,
  Start, Select, L3 / R3); since 1.2.2 open to all, with a Restore button in the Gamepad tab: a
  priority binding of ours over the game's, taken away while one of its gamepad windows has the focus (so its menus keep
  A / B), and set again when it closes. LT and RT become modifiers (a key per layer); the other
  layers of a replaced button are bound to what the game does there. Checked in game; still to
  watch: a menu opened in combat (bindings can't change then), `/ec binds`.

## Next: your own wheels

- [x] **Wheels of your own, like the consumables wheel** (built for 1.2.2, to test in game), each filled with the spells, items and
  macros you choose, and opened by a shortcut:
  - same look and handling as the consumables wheel: the left stick points, A uses, B cancels,
    LB / RB turn the pages, usable in combat;
  - created, named, filled and reordered from the configuration panel with the gamepad, from the
    same lists as the Gamepad tab (spells, items, macros); several wheels;
  - each wheel's shortcut: any free button, a back paddle, a game button replaced, or a key binding
    of the game (its Key Bindings menu);
  - limit: what a wheel holds can only change out of combat (the game locks secure buttons in
    combat).

## To decide

- **Chat keyboard, writing in the chat box**: let the game send the message natively when the text
  is unchanged; never bring back text already sent or erased.

## By hand on CurseForge (no API for these)

- [x] Rename the project to "Easy Controller - Forever".
- [ ] Paste [docs/curseforge.md](docs/curseforge.md) as the description, the one-line summary, and
  [docs/icon.png](docs/icon.png) as the logo.
