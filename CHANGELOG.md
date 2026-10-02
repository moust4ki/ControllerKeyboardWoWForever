# Changelog

## 1.2.1

- **The game's own gamepad functions on any free button.** The Gamepad tab's Game list starts with
  them: jump, back, interact and inspect (the game's fixed A / B / X / Y buttons, pressed from the
  other button: their exact behaviour, the smart interact included), the Start menu, interface
  focus, ping, and ally / enemy targeting (held). Put jump on a back paddle, the Start menu on
  LT + L3...
- **Replace the game's own buttons (optional, off by default).** A switch at the top right of the
  Gamepad tab: "Game's buttons: left alone / replaceable". Turned on, A, B, X, Y, the D-pad, LB / RB
  (alone), Start and Select take any function, in any layer: a slot of the gamepad bar still takes a
  spell, an item or a macro in the slot; anything else replaces the button, with its picture over
  the game's, and X gives the button back (with what its slot held). The game's menus keep their
  buttons; LT and RT become modifiers so that each layer has a key of its own. Turned off again,
  every replaced button gets the game's default binding back (the game's slots, free buttons and
  paddles keep theirs). `/ec binds` shows the replaced keys.
  Ping put on a button is held to open the wheel and released to send: the game's own gamepad ping
  waits for its key to be pressed again, and a key changed meanwhile left its listener over the
  screen, every A in a menu becoming a ping.
- **Consumables wheel**: after a reload, the banner under the wheel was empty on its first opening.

## 1.2.0

- **Vibrations** (new tab). The controller vibrates on the events you choose: one switch and one
  intensity, then each event with its own pattern (micro tick, tick, double tick, pulse, long,
  heartbeat, crescendo) or Off, picked with the D-pad; A tests it, X turns it on or off.
  - Combat: death, your spell interrupted (by someone, not by moving), loss of control, aggro,
    entering combat, spell proc, action impossible. Low health and big hit are listed as
    unavailable when WoW Forever hides your health from addons in combat.
  - Social: whisper, group or raid invite, ready check, resurrection or summon, trade or duel.
  - Progress: level up, quest objective or quest complete, rare loot, bags full, gear almost broken.
  - Easy Controller: low supplies, little room in the bags, the wheel's slots, chat keyboard keys.
  - `/ec vibe` shows what the client allows and plays a pattern.
- **Supplies** (new tab). A round button per resource, in the gamepad bar's style: free bag slots
  (special bags apart), the equipped ammunition, the class reagents once carried (soul shards,
  powders, candles, symbols, seeds, poisons...) and any item added from your bags. Each shows its
  count and glows under its low threshold, bigger and redder down to the critical one; thresholds
  are set with the D-pad, each resource can be turned off. The bar is placed freely (dragged with
  the mouse while unlocked, or moved with the D-pad), grows right, left, down or up, in 3 sizes. A
  click opens the bags, through the game's own backpack button.
- **Consumables wheel** (new tab). A key of its own (Gamepad tab, Items list: any free button, or a
  back paddle in any layer; or the game's key bindings) opens a wheel drawn with the game's own
  radial menu art: food, drink, healing and mana potions, healthstone, mana gem, bandages (used on
  yourself), buff food, elixirs and flasks, scrolls from your bags, the best of each kind first,
  8 a page (LB / RB turn the pages, up to 3).
  - Point at an item with the left stick and press A to use it; the stick back in the middle points
    at nothing; B cancels. The right stick stays the game's, for its own spell wheels. The mouse
    works too.
  - While it is open, and after it closes until you let the stick go, the sticks don't move the
    character or the camera: eating isn't cut short.
  - It works in combat (food and drink greyed there); its content is updated out of combat. Items
    above your level are left out. No game setting is changed.
  - `/ec wheel` lists what it holds, and why an item of your bags is not in it.
- The configuration panel's tabs share the room for the new ones, and the panel can be dragged
  anywhere with the mouse.
- New icon, in the game's addon list too.

## 1.1.1

- Mapping window: the gamepad bar slots that hold a flyout (hunter aspects, tracking, pets) or
  anything else than a spell, an item or a macro show its name instead of "empty".
- The actions the game won't take off its gamepad bars (hunter aspects, pet actions while the pet
  has its bar) can no longer be replaced or cleared from the mapping window: it shows the game's own
  message, like its action bar editor.
- With a list open, the side panel no longer writes over the list's tabs.

## 1.1.0

- The addon's folder and package are now **EasyController** (were ControllerKeyboard). Settings saved
  under the old name stay in `WTF/.../SavedVariables/ControllerKeyboard.lua`: copy that file to
  `EasyController.lua` (game closed) to keep them. Remove the old `ControllerKeyboard` folder.
- `/ec` is the command (also `/easycontroller`; `/ck` still works).
- **Back paddles in every trigger layer.** L4 / R4 / L5 / R5 take a spell, an item or a macro in the
  RT and LT + RT layers too, without RT being a modifier: the paddle's key goes to a secure button
  that reads the triggers when it is pressed (the game lets secure code read the gamepad) and runs
  that layer's action. Game functions (key bindings) still need a key of their own: with "RT acts as
  a modifier" on, every layer has one. A game function on a paddle alone takes the key in the
  layers that share it; the mapping window says so.
- **Quest items: a border instead of the glow.** The items a quest asks to collect (meat, cloth...),
  which the game doesn't mark, get the game's own quest item border in orange; the pulsing glow is
  gone, and items the game already marks are left alone. Their tooltip line names the quest.

## 1.0.0

The addon is now **Easy Controller - Forever** (formerly Controller Keyboard): the name players see changes, the
addon's folder and all settings stay the same. `/ec` works as well as `/ck`.

### Configuration panel

- The addon has its own configuration panel, driven with the gamepad or the mouse: **RB + D-pad down**
  (only watched, never bound, so the game's buttons stay as they are; any other pair can be learned
  in the General tab: hold a button, press a second one), `/ck config`, or its key binding. Tabs **General**,
  **Keyboard** and **Gamepad** (LB / RB), D-pad to move and change values, A to choose, B to close.
  The game's options only point to it.
- The addon is a set of modules, and every function can be turned on or off in the General tab:
  keyboard (auto-open, quest links, Shift+click links, drafts, sticky channel), quest items (tooltip
  line, sale warning, merchant selection warning), gamepad mapping (extra buttons on screen), the
  RB + D-pad down shortcut.

### Gamepad mapping

- The Gamepad tab (`/ck map`) shows the whole controller in its four trigger layers (alone, LT, RT,
  LT + RT). Holding LT / RT shows their layer.
- WoW Forever's gamepad UI is never changed: the buttons the game uses are shown with what they do
  and their icon (jump, interact, back, inspect, targeting, Start menu...) and left as they are.
- The gamepad bar's own slots (D-pad and A / B / X / Y in the four layers, but the fixed jump /
  interact / back / inspect) take a spell, an item or a macro from the same window, placed in the
  game's slot like its own action bar editor does (X empties it).
- The free inputs get the missing functions: L3 / R3, trigger combinations nothing is bound to
  (LT + Start...) and the back paddles. Each one can run a game function (run / walk, autorun, game
  menu, map, bags, any key binding of the game, listed by its own categories), a spell, an item, a
  macro, or press a button of the gamepad action bar.
- Back paddles (L4 / R4 / L5 / R5, Steam Deck and others): set each paddle to a keyboard key in Steam
  Input (F13 to F16 for example), then "Identify the back paddles" asks for each paddle in turn (B
  skips one). Controllers whose paddles the game sees directly (PADPADDLE1-4) work as they are.
- The extra buttons that do something (back paddles, L3, R3) are shown around the gamepad action bar,
  in its round slot style, with the action's icon (zoomed like the game's), count, cooldown and
  usability; they show the held trigger layer's action, and press down like the game's buttons.
  Their name (R4...) shows on the outer side (left / right, or up / down following each button's
  place), above, below, left, right, or not at all (option).
  L3 / R3 can be shown too, with what the game does with them (autorun, ping...) or what you put on
  them. Spells are listed and shown with their rank.
- "Place the bar and extra buttons": the game's gamepad bar moves by steps with the D-pad (only its
  place on the screen, out of combat; X puts it back), the extra buttons following it; each extra
  button goes on one of the fixed places around the bar's controls
  (outer columns, two rows above, two below): the D-pad chooses the bar or a button, A picks it up,
  the D-pad moves it (taken places swap), A puts it down, B puts it back; or by clicking; the right side mirrors the left (Y turns it off). Places follow the compact layout.
- Game functions and the game's own L3 / R3 actions use interface icons (ping markers, the gamepad
  jump icon), never spell icons.
- When RT is no modifier in the game's gamepad settings (the RT and LT + RT layers then don't exist
  for the extra buttons), an option makes it one (Alt, or Ctrl), like LT already sends Shift.
- Bindings are set out of combat, only on inputs the game leaves free, and set again when one of the
  game's gamepad windows closes. `/ck keys` lists the keys the game receives and which pad buttons
  act as Shift / Ctrl / Alt.

### Quest items

- Item tooltips show an orange "Quest item: do not sell" line on quest items, including the items a
  quest asks to collect (cloth, ore, meat...), which the game does not mark; in the bags they also get
  a slowly pulsing orange glow (the game's own bag glow).
- Selling one to a merchant shows a warning with a reminder of the Buyback tab. At a merchant, with
  the gamepad bag tooltips turned off, selecting a quest item shows the warning too.

### Quest links and drafts

- The channel row ends with a "Quests" chip: it turns the suggestions row into the list of your
  quests, the right stick click inserts the quest link.
- Links inserted with Shift+click or the game's "Share in chat" go into the keyboard's message.
- When the game closes the chat (a panel opens, combat), the message is kept as a draft and comes back
  with the chat: type "LFM", open the quest log, "Share in chat", and the keyboard holds
  "LFM [quest]". Backspace deletes a link as a whole.

### Fixes

- Sending with Enter on a physical keyboard now always empties the keyboard's copy of the message
  (the game no longer calls the old `ChatEdit_SendText`).

## 0.4.2

- German, Spanish and Italian: dictionaries (12,000 words each), keyboard layouts for the split
  keyboard (QWERTZ with ö ä ü ß, Spanish QWERTY with ñ, Italian QWERTY), and the accents of the 123
  layer follow the language (ä ö ü ß / á é í ó ú ñ ¿ ¡ / à è é ì ò ù). A single language setting
  replaces the French / English switches; the old setting is converted.
- Interface translated into German, Spanish and Italian.
- Language and layout default to the game client's language.
- Fix: words with "à" (città, voilà…) could be cut in two in the suggestions.
- Spanish ¿ and ¡ no longer block the word search.

## 0.4.1

- Right stick click on the channel row confirms the channel and goes back to the suggestions, without
  inserting a suggestion.
- The channel picked in the channel row becomes the chat's own sticky channel, as if `/p` had been
  typed in the game: following messages go there too, including text from a physical keyboard or a
  dictation tool (Handy…), and the keyboard reopens on it. Option to turn it off.

## 0.4.0

### New

- Second input method, "split keyboard": a full AZERTY / QWERTY keyboard with a numbers / accents /
  symbols layer, cut in two halves. The left stick moves a cursor on the left half, the right stick
  on the right half; each stick's tilt is its cursor's absolute position around the center of its
  half (released = center), so the keys near the middle are at the edge of their half and easy to
  hit. LT / RT type the left / right cursor's key, LB deletes, RB space, left stick click 123. Dead
  zone, magnet against flicker, a line from each center, edge keys reachable from 80 % tilt. Large
  keys (54 x 50 px, 600 px wide panel), every key clickable.
- Keyboard size option with 4 presets: small (80 %), normal, large (125 %), extra large (150 %).
- Linear stick response on each axis (no acceleration toward the edges), with a "stick response"
  option: linear, gentle (precise near the center) or fast.
- Options: input method, layout, dead zone, magnet, cursor lines. Commands: `/ck mode wheel|stick`,
  `/ck layout azerty|qwerty`. The options panel scrolls with the mouse wheel.

### Changes

- B empties the message (both methods). With an empty message, B is the game's own and closes the
  chat.
- Code split into a common core (`Message.lua`) and input methods (`Wheel.lua`, `StickKeyboard.lua`).

## 0.3.0

### New

- Chat channel row under the wheel: `/s`, `/y`, `/p`, `/ra`, `/g`, `/1`, `/w`, `/r`. D-pad ↓ / ↑ picks the
  active row (channels or suggestions), D-pad ← → and the right stick move inside it; with the mouse,
  hover a channel (no click, so the chat keeps its focus). Unavailable channels are greyed out and
  skipped.
- `/w` always available: pick the recipient first (suggested names from recent correspondents,
  group, friends and guild, or A to confirm what you typed; names with a space work), then type the
  message. Deleting on an empty message goes back to the name.
- Option to hide the mouse buttons row (Shift, 123, Space, Delete, Send, X); the panel gets shorter.
- Suggestions default to the client's language: French on a French client, English otherwise (both
  12,000-word dictionaries are included; change it in the options).

### Changes

- The message now lives in the keyboard's own bar and A sends it (secure macro, or a direct whisper);
  the game's chat box is never written to. B still closes the chat.
- The keyboard is disabled in combat: trying to open it shows "Not possible in combat". The chat works
  as usual, and the keyboard comes back by itself after combat if the chat is still open.
- The wheel center no longer shows the gesture legend; it only shows the letter aimed with the right
  stick.

### Fixes

- Crashes and "action blocked" cascades in combat: text typed by the addon into the game's chat box
  tainted WoW Forever's gamepad UI when it read it back.
- The keyboard could be blocked from opening ("ControllerKeyboardFrame:Show()").
- LB / RB / LT / RT could stay captured by the addon until the end of combat.

## 0.2.0

- New look matching WoW Forever's gamepad UI: dark 8-petal wheel with bronze and gold rims, Friz
  Quadrata font, the game's own gamepad button icons.
- Dual-stick typing: left stick picks a petal, right stick flicks toward the letter.
- iPhone-style prediction: message starters with nothing typed, next word from your own 2 and 3 word
  sequences plus built-in French phrases.
- Slash command autocomplete: `/reload`, `/p`, `/ra`, `/g`, `/w` first, then your most used commands.
- Options panel in *Escape > Options > AddOns*: lock, auto-open, size, font, button style, language,
  learning, reset position, forget learned words.
- Mouse / Steam Controller: the keyboard stays open and keeps the message when a click closes the chat.
- `/ck lock` to lock / unlock the position.
- A, B, X, Y, Start and Select are left to the game's gamepad chat UI.
- Fixes for WoW Forever's gamepad UI: no more "blocked action" popup or client freeze when sending.

## 0.1.0

- First version: daisywheel keyboard, French word prediction, learning from sent messages.
