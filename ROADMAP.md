# Roadmap

Everything planned for Easy Controller - Forever, so nothing gets lost. Each feature is built, tested
in game, then released on GitHub and CurseForge. Done items move to the [CHANGELOG](CHANGELOG.md)
(1.2.0: vibrations, supplies, consumables wheel).

## 1.3.0: the game's own gamepad functions, on any button

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
  Start, Select, L3 / R3), behind a switch in the Gamepad tab, off by default: a priority binding of
  ours over the game's, taken away while one of its gamepad windows has the focus (so its menus keep
  A / B), and set again when it closes. LT and RT become modifiers (a key per layer); the other
  layers of a replaced button are bound to what the game does there. To check in game: a menu
  opened in combat (bindings can't change then), `/ec binds`.

## To decide

- **Vibrations, low health and big hit**: WoW Forever hides the player's health from addons in
  combat. Look for another signal (the game's own low health warning), or remove them.
- **Chat keyboard, writing in the chat box**: let the game send the message natively when the text
  is unchanged; never bring back text already sent or erased.

## By hand on CurseForge (no API for these)

- [x] Rename the project to "Easy Controller - Forever".
- [ ] Paste [docs/curseforge.md](docs/curseforge.md) as the description, the one-line summary, and
  [docs/icon.png](docs/icon.png) as the logo.
