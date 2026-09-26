# Changelog

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
