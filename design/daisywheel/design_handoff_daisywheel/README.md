# Handoff: Daisywheel (gamepad chat keyboard), Easy Controller - Forever

## Overview
**Easy Controller - Forever** (World of Warcraft addon, WoW Forever, gamepad interface) has a gamepad chat keyboard called the "daisywheel". Its current look (`ck_*` textures: disc, round petals, hub, highlights) is dated and does not match the rest of the addon. This redesign brings it into the same visual language as the addon's **adaptive radial wheel** (`wheel_bg_N`, `wheel_sel_N`, `wheel_off_N`): dark gradient crown, bronze frame and separators, centre ring, copper highlight.

**Functional behaviour does not change.** Only the textures and the layout/colour of the rendering change.

## About the files
- `textures/` and `geometry.json` are the **production assets**. Ship them as they are (convert to BLP/TGA 32-bit if the pipeline requires it, keeping alpha).
- `reference/Daisywheel.dc.html` is an **HTML mockup** (open it in a browser; `support.js` and `daisywheel/` must sit next to it). It shows the full 340 × 484 window in the 5 states, for variants A and B, plus the annotated geometry and the texture sheet. **It is a design reference, not code to port.** The job is to recreate it in Lua/XML with the WoW API (Textures, FontStrings, `SetRotation`, `SetPoint`), following the existing patterns of the addon's current daisywheel module.

## Fidelity
**High fidelity** for the wheel (final textures, exact geometry). **Medium-high fidelity** for the window chrome: the colours and sizes are final, but the bronze frame of the window should reuse the frame/backdrop system the addon already uses (for example the config panel's) if there is one.
The mockup uses the **Marcellus** web font as a stand-in. **In game, use FRIZQT (`Fonts\FRIZQT__.TTF`)**.

## Two variants (implement both)
- **A, base**: the 4 characters sit loose in each section.
- **B, groups encircled**: a bronze ring around each group of 4 characters (`dw_petal_ring.png`), gold on the selected petal (`dw_petal_ring_sel.png`). It makes it clear that the left stick picks a **group** and the right stick picks a character inside it.

Variant B = A + one ring texture per petal. Everything else is the same (geometry, states, other textures).

**Implement both variants.** The user will say which one to use by default and whether the choice is exposed. Suggested implementation: a single boolean option (for example `petalRings`, false = A, true = B) that only shows or hides the 8 `dw_petal_ring` textures. No separate code path.

---

## Unchanged behaviour (reminder)
- 8 petals in a circle. **Petal 1 at the top**, then clockwise.
- 4 characters per petal, in the order **left, up, right, down**.
  Letters: `a b c d | e f g h | i j k l | m n o p | q r s t | u v w x | y z ' - | . , ? !`
  123 layer (proposed in the mockup, to validate): `1 2 3 4 | 5 6 7 8 | 9 0 é è | à ç ù ê | @ # & * | ( ) " + | / = : ; | € % _ ~`
- Left stick = petal choice. Right stick left/up/right/down = character of that petal.
- **The character cross always stays aligned to the screen** (never rotated with the section).
- The hub shows the targeted character in large type.
- LT = Shift (one-shot capital), double LT = Caps lock: only the displayed case changes. RT = 123 layer.
- Mouse: hovering a character highlights it discreetly, clicking types it.

## Geometry (see `geometry.json`)
All values are in the **512 × 512 texture space**. Multiply by `scale = wheelDisplaySize / 512`. In the mockup the wheel is **304 px**, so `scale = 0.59375`.

| Element | 512 space | At 304 px |
|---|---|---|
| Wheel centre | (256, 256) | (152, 152) |
| Centre ring (hub ring) | r 58.3 → 75.9 | r 34.6 → 45.1 |
| Usable crown | r 75.4 → 213.1 | r 44.8 → 126.5 |
| **Petal centre radius** | **160** | **95** |
| Inscribed circle of a petal (free space) | r 52 | r 30.9 |
| **Offset of the 4 characters** from the petal centre | **±28** | **±16.6** |
| Petal text | 27 | **16 px** |
| Target pastille / hover (displayed size) | 54 (disc Ø 40.5) | 32 (disc Ø 24) |
| Hub (displayed size) | 120 (disc r 58.1) | 71.25 |
| **Hub text** | **64** | **38 px** |
| "123" label in the hub | 17, offset +24 below the centre | 10 px, +24 |
| Petal ring (variant B, displayed size) | 108 (ring r 48.5 → 51) | 64.1 |

Centre of petal k (1…8): `θ = (k−1) × 45°`, clockwise from the top.
- Image coordinates (y down): `x = 256 + 160·sin θ`, `y = 256 − 160·cos θ`
- **WoW** offsets from the wheel centre (y up): `SetPoint("CENTER", wheel, "CENTER", 160·s·sin θ, 160·s·cos θ)`
- Characters, relative to the petal centre (WoW): left `(−28s, 0)`, up `(0, +28s)`, right `(+28s, 0)`, down `(0, −28s)`.
- The values for each petal are precomputed in `geometry.json → petals[]`.

## Textures (`textures/`)
| File | Size | Use | Rotation |
|---|---|---|---|
| `dw_wheel_bg.png` | 512 | Wheel background (= `wheel_bg_8`, unchanged) | none |
| `dw_section_sel.png` | 512 | Copper highlight of the selected section, drawn on petal 1 | `SetRotation(-math.rad((k-1)*45))` |
| `dw_section_dim.png` | 512 | 50 % black veil for the 7 non-selected sections | same, one instance per section |
| `dw_key_target.png` | 64 | Gold pastille under the targeted character | **none** |
| `dw_key_hover.png` | 64 | Thin ring + faint copper veil under the hovered character (mouse) | **none** |
| `dw_hub.png` | 128 | Hub at rest | none |
| `dw_hub_lit.png` | 128 | Hub lit (a character is targeted) | none |
| `dw_petal_ring.png` | 128 | Variant B: bronze ring per petal | none (circle) |
| `dw_petal_ring_sel.png` | 128 | Variant B: gold ring of the selected petal | none |

`SetRotation` rotates counterclockwise for positive values, hence the minus sign. The 512 textures have their centre at (256, 256), so the default pivot is correct.

### Layer order (bottom to top)
1. `dw_wheel_bg` (BACKGROUND)
2. `dw_section_dim` ×7 (ARTWORK, sublevel 1), only when a petal is selected
3. `dw_section_sel` (ARTWORK, sublevel 2)
4. `dw_hub` / `dw_hub_lit` (ARTWORK, sublevel 3)
5. `dw_petal_ring` ×8 (ARTWORK, sublevel 4), variant B only (hidden in A)
6. `dw_key_hover`, `dw_key_target` (ARTWORK, sublevel 5–6)
7. Character FontStrings, hub character, "123" label (OVERLAY)

## The 5 states
| # | State | Wheel | Characters | Hub |
|---|---|---|---|---|
| 1 | **Rest** | bg only | all gold `#FFD100` (1, 0.82, 0), alpha 1 | `dw_hub`, empty |
| 2 | **Petal selected** (left stick) | `dw_section_sel` rotated onto the petal + `dw_section_dim` on the other 7. Variant B: gold ring on the petal, other rings alpha 0.55 | selected petal: light `#FFE8A8` (1, 0.91, 0.66). Others: alpha 0.4 | `dw_hub`, empty |
| 3 | **Character targeted** (right stick) | as in 2 + `dw_key_target` centred on the character | targeted character: **black** (0, 0, 0), no shadow | `dw_hub_lit` + character in large type, gold, alpha 1 |
| 4 | **Mouse hover** | `dw_key_hover` centred on the character (no section highlight if no petal is selected) | hovered character: `#FFF5D9` (1, 0.96, 0.85) | `dw_hub` + character as a preview at alpha 0.55 |
| 5 | **123 layer** | background unchanged | 123 layer characters | "123" label at 10 px, `#C9A44A`, under the centre. Mode badge lit, RT lit in the help line |

Text shadow for the characters: `SetShadowOffset(1, -1)`, shadow colour (0, 0, 0, 1). The mockup adds a soft 4 px halo; an `OUTLINE` font flag is not recommended, it is too heavy at 16 px.

Optional variant (Tweak "Texte seul" (text only) in the mockup): no `dw_section_dim`, only the alpha 0.4 on the text.

## Window (340 × 484)
Effective padding 12 top/bottom, 10 left/right (2 px bronze border + 10/8 inner padding). Rows from top to bottom:

| Row | Height | y (from the top) | Contents |
|---|---|---|---|
| Input bar | 40 | 12 | "Say:" white 14 px, text white 14 px, gold cursor 1 × 16, mode badge (abc / Abc / ABC / 123), drag handle (6 dots, 2 × 3) |
| gap | 6 | | |
| Suggestions | 26 | 58 | LB glyph on the left, 5 words `#C9B37E` 13 px, active word on a copper pill, RB glyph on the right |
| gap | 8 | | |
| **Wheel** | **304 × 304**, centred | 92 | see above |
| gap | 8 | | |
| Channels | 26 | 404 | /s /y /p /ra /g /1 /w /r + "!" Quests button 20 × 18. Active channel on a copper pill. Unavailable channels at alpha 0.4 |
| gap | 6 | | |
| Help | 36 (2 × 18) | 436 | 4-column grid: L Petal · R Letter · LB Delete · RB Space / LT Shift · RT 123 · ✚ Channel · ✚ Select, 11 px, `#D9D4CB`. Use the game's real gamepad glyphs |

### Window colours
- Window background: vertical gradient `#19160F` → `#0F0D0A`
- Window border: 2 px `#5A4D38`, outer line 1 px `#050403`, inner line 1 px `#241D15`, top highlight `rgba(143,130,111,0.25)`
- Rows (input / suggestions / channels): background `#080706`, border 1 px `#3D3326`, radius 3, inner shadow
- Copper pill (active word, active channel, lit 123 badge): gradient `#8A6239` → `#5A402A`, border 1 px `#D8B27A` (badge: `#E6BB77`), text `#FFF0C8` (channel: white)
- Mode badge at rest: background `#16130F`, border `#4A3F2F`, text `#A8946C`, height 18, radius 9, 11 px
- Channel colours: the standard WoW chat colours (`ChatTypeInfo`)

## Suggested state (Lua)
```lua
state = {
  layer    = "letters" | "num",
  case     = "lower" | "shift" | "caps",
  petal    = nil | 1..8,   -- left stick
  dir      = nil | 1..4,   -- right stick: 1 left, 2 up, 3 right, 4 down
  hover    = nil | {petal, dir},  -- mouse
}
```
- `petal` from the left stick: `a = deg(atan2(x, y)) % 360; petal = floor((a + 22.5) / 45) % 8 + 1` (with a dead zone).
- `dir` from the right stick: the dominant axis beyond the threshold.
- Typing: on the right stick's validation, insert `chars[layer][petal][dir]` with the case applied.

## Files
- `textures/*.png`: 9 textures
- `geometry.json`: all the values above, machine-readable
- `reference/Daisywheel.dc.html`: mockup (variants B and A × 5 states, annotated geometry, texture sheet)
