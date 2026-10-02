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

- [ ] **Move a game function to another button** (a back paddle, L3, a free combination...): the
  Gamepad tab's Game list gets a "gamepad functions" section. The four fixed ones press the game's
  own button (its behaviour exactly: the smart interact, jump and sit...); the others are the
  game's own bindings.
- [ ] **Put something else on a button the game uses** (A, B, X, Y alone, LB / RB, Start, Select,
  L3 / R3): only with a priority binding of ours over the game's, taken away while one of its
  gamepad windows has the focus (so its menus keep A / B), and set again when it closes. Limit: in
  combat bindings can't change, so a window opened in combat gives the button back to the game
  until the fight ends. To decide together before building it.

## To decide

- **Vibrations, low health and big hit**: WoW Forever hides the player's health from addons in
  combat. Look for another signal (the game's own low health warning), or remove them.
- **Chat keyboard, writing in the chat box**: let the game send the message natively when the text
  is unchanged; never bring back text already sent or erased.

## By hand on CurseForge (no API for these)

- [x] Rename the project to "Easy Controller - Forever".
- [ ] Paste [docs/curseforge.md](docs/curseforge.md) as the description, the one-line summary, and
  [docs/icon.png](docs/icon.png) as the logo.
