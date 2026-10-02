# Roadmap

Everything planned for Easy Controller - Forever, so nothing gets lost. Each feature is built, tested
in game, then released on GitHub and CurseForge. Done items move to the [CHANGELOG](CHANGELOG.md).

## 1.2.0: vibrations, supplies, consumables wheel (built, testing in game)

- [x] **Vibrations** tab: one switch and one intensity, then each event with its box and its pattern
  (Off or micro tick, tick, double tick, pulse, long, heartbeat, crescendo). The D-pad picks the
  pattern, A tests it, X turns it on or off.
  - 23 events: combat, social, progress, Easy Controller (low supplies, little room, wheel ticks,
    chat keyboard keys).
  - [ ] In-game check: `/ec vibe`, how the patterns feel (length, strength).
  - [ ] **Low health** and **big hit**: WoW Forever hides the player's health from addons in
    combat. Look for another signal (the game's own low health warning), or remove them.
- [x] **Supplies** tab: one round button per resource (free bag slots, equipped ammunition, class
  reagents, any item added from the bags), its count, and a glow under its low threshold, stronger
  and redder down to the critical one. Each resource on or off, thresholds set with the D-pad. The
  bar is placed freely (mouse drag while unlocked, or the D-pad), growing in 4 directions, 3 sizes;
  a click opens the bags. Low supplies and little room vibrate.
  - [ ] In-game check: detection (reagent item IDs of WoW Forever), the glow, the placement.
- [x] **Consumables wheel** (Wheel tab): a key of its own (Gamepad tab, Items list, any free button
  or back paddle in any layer; or the game's key bindings) opens a wheel of up to 12 consumables:
  food, drink, healing and mana potions, healthstone, mana gem, bandages (on yourself), buff food,
  elixirs and flasks, scrolls; the best of each kind first, the variants after (an option). The
  hold its key, aim with a stick, let the key go to use the item; a quick press keeps it
  open (aim, then A); B cancels; the sticks are taken while open (camera and character still).
  Secure: works in combat
  (food and drink greyed there); its content changes out of combat only. "Wheel ticks" vibrate.
  - [ ] In-game check: hold / aim / release, the sticks taken while open, in and out of combat, the
    kinds found in the bags. (Letting the stick go itself cannot be seen by secure code.)

- [x] The addon list shows the addon's icon.
- [ ] Release 1.2.0.

## 1.3.0: remap the game's own buttons

- Remap the buttons WoW Forever uses itself (jump, interact, back / cancel, inspect, targeting,
  Start and Select menus...): give their functions to other buttons, and other functions to them.
- To investigate first: how Forever binds them (its input binding manager, priority overrides,
  the GamepadModeInGameCore binding context), whether an addon can change them without tainting or
  breaking the native gamepad UI, and a way back to the game's own layout.

## To decide

- **Chat keyboard, writing in the chat box**: let the game send the message natively when the text
  is unchanged; never bring back text already sent or erased.

## By hand on CurseForge (no API for these)

- [ ] Rename the project to "Easy Controller - Forever".
- [ ] Paste [docs/curseforge.md](docs/curseforge.md) as the description, the one-line summary, and
  [docs/icon.png](docs/icon.png) as the logo.
