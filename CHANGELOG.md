# Changelog

## 0.2.1

- The keyboard is now disabled in combat: the game blocks too many actions during a fight. Trying
  to open it shows "Not possible in combat"; the chat works as usual, and the keyboard comes back by
  itself after combat if the chat is still open.
- Suggestions default to the client's language: French on a French client, English otherwise
  (both 12,000-word dictionaries are included; change it in the options).
- Fix: the keyboard could be blocked from opening ("ControllerKeyboardFrame:Show()").
- Fix: LB / RB / LT / RT could stay captured by the addon until the end of combat.

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
