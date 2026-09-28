# Changelog

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
