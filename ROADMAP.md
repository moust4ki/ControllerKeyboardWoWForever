# Roadmap

Everything planned for Easy Controller - Forever, so nothing gets lost. Each feature is built, tested
in game, then released on GitHub and CurseForge. Done items move to the [CHANGELOG](CHANGELOG.md).

## 1.2.0: vibrations and supplies (built, testing in game)

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
- [x] The addon list shows the addon's icon.
- [ ] Release 1.2.0.

## 1.3.0: consumables wheel

Decided with the player:

- A key of its own, set in the Gamepad tab (a paddle, L3, a free combination...), **opens a wheel**
  drawn with the game's own radial art.
- The **right stick aims** (like the game's spell wheel), **A uses**, **B closes**; the mouse can
  click a slot.
- **Up to 12 slots**: food, drink, health and mana potions, healthstone, mana gem, bandages (used on
  yourself), elixirs and flasks, buff food, scrolls. Every variant carried while there is room, the
  best of each kind first, with counts and cooldowns.
- Works **in combat** (secure code): food and drink are greyed there, as the game forbids them.
  The wheel's content is updated out of combat only (a rule of the game).
- The "wheel: moving from slot to slot" vibration.

## 1.4.0: remap the game's own buttons

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
