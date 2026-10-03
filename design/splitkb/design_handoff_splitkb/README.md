# Handoff: Split keyboard (dual-stick chat keyboard), Easy Controller - Forever

## Overview
Second mode of the gamepad chat keyboard in **Easy Controller - Forever** (World of Warcraft addon, WoW Forever). It is redesigned in the same visual language as the daisywheel and the radial wheel: dark backgrounds, bronze frames, copper highlight, gold pastille, gold FRIZQT text. **Functional behaviour does not change.** Only the textures, geometry and colours change.

## About the files
- `textures/` and `geometry.json` are the **production assets** (convert to BLP/TGA 32-bit if needed, keep alpha).
- `reference/Clavier double stick.dc.html` is an **HTML mockup** of the 600 × 400 window in the 6 states (1, 2, 3, 4, 5a, 5b), with the annotated key-area geometry and the texture sheet. **It is a design reference, not code to port.** Recreate it in Lua/XML with the WoW API, following the existing patterns of the module.
- `reference/splitkb/_mock/` holds pre-sliced key images **for the mockup only**. Do not ship them. In game, use the nine-slices from `textures/`.

## Fidelity
High fidelity: textures, sizes and colours are final. The mockup uses Marcellus as a stand-in. **In game, use `Fonts\FRIZQT__.TTF`.** The window chrome is exactly the daisywheel's (same rows, wells and copper pills).

## Unchanged behaviour (reminder)
- 10 columns split in two halves: columns 1–5 on the left, 6–10 on the right. 4 rows.
- Each half has its own cursor, positioned **absolutely** by its stick around the half's centre (stick released = centre).
- The key under each cursor is targeted, one per half, both at the same time. A **magnet** keeps the targeted key until the cursor is clearly on the neighbouring key.
- LT types the left target, RT the right target. LB deletes, RB types a space. Left-stick click (L3) toggles the 123 layer.
- Shift: one-shot or locked (double press).
- Mouse: hovering a key highlights it, clicking types it.
- Optional (setting): a line from the centre of each half to its cursor.

## Window (600 × 400)
Border 2, padding 10 top/bottom and 6 left/right (inner width 584).

| Row | Height | y from top |
|---|---|---|
| Input bar | 40 | 12 |
| Suggestions | 26 | 58 |
| **Key area** | **220** (584 wide) | 92 |
| Channels | 26 | 320 |
| Help (2 × 18, 5 columns) | 36 | 352 |

Gaps between rows: 6, 8, 8, 6. All colours of the bars, badge, copper pills and channels are **identical to the daisywheel** (see its README): window background gradient `#19160F` → `#0F0D0A`, border `#5A4D38`, wells `#080706` / `#3D3326`, copper pill `#8A6239` → `#5A402A` with border `#D8B27A`.
The channel row uses the full width (items spread with `space-between`).

## Key area (584 × 220)
Origin at the top-left of the area.
- **Left half** x 0–286, **right half** x 298–584, **gutter** 12 (x 286–298).
- Half centres (cursor position at rest): **(143, 110)** and **(441, 110)**.
- Rows at **y = 4, 58, 112, 166**, height **50**.
- Standard key **54 × 50**, gap 4, **pitch 58**. Columns are aligned across all rows.

| Row | Left (x · width) | Right (x · width) |
|---|---|---|
| 1 | 5 keys: 0, 58, 116, 174, 232 · 54 | 5 keys: 298, 356, 414, 472, 530 · 54 |
| 2 | same | same |
| 3 | **Shift 0 · 54**, then 58, 116, 174, 232 · 54 | 298, 356, 414 · 54, **Enter 472 · 112** |
| 4 | **123/abc 0 · 54**, 58, 116 · 54, **Space 174 · 236** (straddles the gutter) | 414, 472, 530 · 54 |

> **Proportions changed from the brief.** Shift at 1.5 units plus 4 keys does not fit in a 286 half. To keep the columns aligned (more predictable absolute cursor), Shift = 1 unit and Enter = 2 units. Space is a single key that **both cursors can target**.
> All keys are listed with their coordinates in `geometry.json → keys[]`.

**Separator** `sk_divider.png` (16 × 256), displayed at **x 284, y 4, 16 × 158** (rows 1–3; Space crosses row 4).

## Key textures: nine-slice
- Texture **128 × 64**. **Fixed corners 12 × 12** (margins 12 on all 4 sides), edges and centre stretched.
- In game: `tex:SetTextureSliceMargins(12, 12, 12, 12)` + `tex:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)`, or a NineSlice layout with the same margins.
- The visible frame starts 1 px inside the texture (soft shadow underneath).

| State | Texture | Text colour |
|---|---|---|
| Normal | `sk_key_normal.png` | letters `#FFD100` · special keys `#D9C9A0` |
| Mouse hover | `sk_key_hover.png` (lighter bronze, faint copper veil) | `#FFF5D9` |
| Active (Shift on, layer key in 123) | `sk_key_active.png` (copper, gold edge) | `#FFF0C8` |
| Left target (LT) | `sk_key_target_l.png` (copper, gold edge, **triangle in the bottom-left corner**) | `#FFF0C8` |
| Right target (RT) | `sk_key_target_r.png` (amber, gold edge, **triangle in the bottom-right corner**) | `#FFF0C8` |
| Pressed (feedback) | `sk_key_pressed.png` (gold) | `#000000`, no shadow |

Priority if several states apply: pressed > target > active > hover > normal.
**Pressed feedback**: on LT/RT, swap the texture to `sk_key_pressed` for **120 ms**, then back to the target texture (an optional 80 ms fade).

## Cursors
- Centre marker: `sk_center.png` 32 × 32, displayed **32 × 32**, centred on (143, 110) and (441, 110). It never moves.
- Cursor dot: `sk_cursor.png` 32 × 32, displayed **32 × 32** (gold disc Ø 20), centred on the cursor position.
- Optional line: `frame:CreateLine()`, from the half centre to the dot, **colour #E6BB77 (0.902, 0.733, 0.467) alpha 0.6, thickness 2**. Hide it when the cursor is at the centre.
- Layer order: keys (ARTWORK) → line → centre marker → dot (OVERLAY).

## Text
- FRIZQT **20** for letters, **13** for special keys (Shift, Enter, 123 / abc, Space). Labels are written by the code.
- Shadow `SetShadowOffset(1, -1)`, colour (0, 0, 0, 1). No shadow on the pressed key.
- Shift: letters in capitals, mode badge "Abc" (one-shot) / "ABC" (locked) / "123" (layer). Badge lit (copper) when it is not "abc".
- Help line: the RT, LT or L3 glyph lights up (`#E6BB77`) while the matching action is happening.

## States shown in the mockup
1. **Rest**: cursors at the centre, magnet on "d" (left) and "k" (right).
2. **In play**: left cursor on "z" (left target), right cursor on "n" (right target), lines visible.
3. **Key typed**: RT → "n" on `sk_key_pressed`, "n" appended to the input.
4. **Mouse hover**: "o" on `sk_key_hover`. The stick cursors stay at the centre.
5a. **Shift active**: Shift on `sk_key_active`, capitals, "Abc" badge.
5b. **123 layer**: digits, accents, symbols at the same positions. Layer key "abc" on `sk_key_active`, "123" badge, L3 lit.

123 layer proposed in the mockup (AZERTY, to adapt per language):
`1 2 3 4 5 | 6 7 8 9 0` · `é è à ç ù | â ê î ô û` · `Shift @ # € % | & * " Enter` · `abc ; / Space : + =`

## Files
- `textures/`: sk_key_normal, sk_key_hover, sk_key_active, sk_key_target_l, sk_key_target_r, sk_key_pressed (128 × 64), sk_center, sk_cursor (32 × 32), sk_divider (16 × 256)
- `geometry.json`: window, key area, every key, nine-slice margins, cursors, line, text colours
- `reference/Clavier double stick.dc.html`: mockup
