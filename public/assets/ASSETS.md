# Asset manifest (Person C)

All art except the room pictures is flat SVG in the shared palette. No text is drawn into any image: titles, clues and labels are interface text. File names match the constructors in `src/Domain.elm`, in kebab case.

**Origin and licence:** drawn for this project and free to use in this game.

- **Covers, diaries, damage, puppets, mystery books:** generated with Google Gemini from the team's prompt and palette, then checked and edited by the team (with help from Claude). `shadow-fox.svg` was redrawn by hand.
- **Walter and Henry (`player-walter-*.svg`, `player-henry-*.svg`):** built by `docs/asset-sources/chibi-family.mjs` (written with help from Claude) on Walter's body as drawn by Google Gemini from the team's prompt. Henry's look follows Gemini's Henry design, redrawn on that body so the two match.
- **Young Edwin (`player-edwin-young-*.svg`):** built the same way. His late-90s look follows Gemini's design, redrawn on the shared body.
- **Present-day Edwin (`player-edwin-present-*.svg`):** built the same way. His cosy Christmas outfit follows Gemini's design; he is about 40, with short brown hair, no beard and thin round glasses.
- **Room props (`room-*.svg`):** hand-written SVG for the team, with help from Claude.

## Quick mapping for B (existing assets)

All of these are already wired in `src/Components/Art.elm` and the views. Checked on 7 November against the current `main`; filenames are unchanged.

| Need | Asset | Driven by |
|---|---|---|
| Diary covers | `diary-walter-1950.svg`, `diary-henry-1973.svg`, `diary-edwin-1998.svg` | `Era` |
| Salvage book covers | `book-<title-in-kebab-case>.svg`, all nine | `BookId` (titles from `Content.Books.book`) |
| Damage overlays (salvage only) | `damage-<damage-in-kebab-case>.svg`, stretched over the cover | `(Content.Books.book id).damage` |
| Clean reopening-shelf books | the same six `book-*.svg` files, **no overlays** | `RecoverableBook` |
| Natural book heights | viewBox heights 150–250 in steps of 20; render at one shared width and align bottoms | agrees with `Rules.Books.height` |
| Rainbow order | `#893f43`, `#c95937`, `#d9a443`, `#748b2c`, `#496669`, `#7687ab` (red → violet) | agrees with `Rules.Books.colour`. The plaque no longer shows these swatches: it only says there are four ways to order the books. |

## Palette

| Hex | Name | Hex | Name |
|---|---|---|---|
| `#291e1a` | ink | `#393e26` | dark olive |
| `#5a3428` | dark leather | `#496669` | teal slate |
| `#a6652b` | ochre | `#7687ab` | periwinkle |
| `#d9a443` | mustard / brass | `#d4d3d1` | paper |
| `#c95937` | vermilion | `#748b2c` | moss green |
| `#893f43` | wine | `#31542f` | deep green |

People have their own fixed colour list (see Player sprites below).

Extra shades used only inside room props: darker and lighter wood (`#8a5424`, `#b9793c`, `#c08a4e`), night and dark screen (`#2c3a3c`), glass (`#c9d3d6`), bedsheet (`#ece6d8`, folds `#cfc6b2`), beige 1990s plastic (`#d9cfb4`, `#c4b997`, `#a89d7c`) and a few metal highlights.

## Files

### Room pictures (JPEG, 1920 × 1080, added by Person B)

Generated with Google Gemini from the team's prompt. Only cropped to 16:9 and resized.

| File | Use |
|---|---|
| `room-present.jpg` | Present day: introduction, hub, return from a diary. Dimmed by CSS for the closed ending until it has its own picture. No painted clock: `src/Components/Clock.elm` draws one on the right-hand wall. |
| `room-1950.jpg` | 1950, and a stand-in for 1998 until that has its own picture. |
| `room-1973.jpg` | 1973. No painted clock: `src/Components/Clock.elm` draws one on the right-hand wall. |
| `room-saved.jpg` | The saved ending. Cut from the original reference picture, inside its dark border. |

The ceiling stain, rubble and clock hands are small SVG overlays in `public/index.html`, so one picture can show a room before and after the work.

### Diary covers (`viewBox 0 0 300 400`)

| File | Use |
|---|---|
| `diary-walter-1950.svg` | Walter's 1950 diary |
| `diary-henry-1973.svg` | Henry's 1973 diary |
| `diary-edwin-1998.svg` | Edwin's 1998 journal |

### Salvage and shelf books (width 120, height varies)

Draw each book at its natural size and **align the bottoms** (for example `align-items: flex-end`). The heights then show the shelf's height order on their own. Every file has the same top and bottom margin.

| File | Book | Cover colour (`CoverColour`) | Height rank | viewBox height |
|---|---|---|---|---|
| `book-birdsong-for-beginners.svg` | Birdsong for Beginners | Yellow `#d9a443` | 1 | 150 |
| `book-gardens-in-winter.svg` | Gardens in Winter | Violet `#7687ab` | 2 | 170 |
| `book-pocket-of-wonders.svg` | Pocket of Wonders | Green `#748b2c` | 3 | 190 |
| `book-atlas-of-small-places.svg` | Atlas of Small Places | Blue `#496669` | 4 | 210 |
| `book-letters-from-the-sea.svg` | Letters from the Sea | Orange `#c95937` | 5 | 230 |
| `book-winter-tales.svg` | Winter Tales | Red `#893f43` | 6 | 250 |
| `book-harbour-tales.svg` | Harbour Tales (ruined) | `#31542f` | – | 200 |
| `book-mountain-paths.svg` | Mountain Paths (ruined) | `#a6652b` | – | 200 |
| `book-winter-almanac.svg` | Winter Almanac (ruined) | `#7687ab` | – | 200 |

The palette has no true purple, so violet is periwinkle and blue is teal slate. In rainbow order the six covers run `#893f43`, `#c95937`, `#d9a443`, `#748b2c`, `#496669`, `#7687ab`. The plaque no longer shows a colour guide.

The ruined books deliberately share colour families with the recoverable ones, so colour never gives away a book's condition. Damage does that.

### Damage overlays (`viewBox 0 0 100 100`, `preserveAspectRatio="none"`)

All nine book covers are clean. In the **salvage scene only**, lay the matching overlay(s) on top of the cover, stretched to the same box. On the reopening shelf, show the clean covers, because the books have been repaired by then.

| File | `Damage` |
|---|---|
| `damage-scorched-edges.svg` | `ScorchedEdges` |
| `damage-water-stains.svg` | `WaterStains` |
| `damage-smoke-stains.svg` | `SmokeStains` |
| `damage-missing-pages.svg` | `MissingPages` |

Damage per book (agreed; `src/Content` should use the same lists): the rule the player learns is that smoke or water can be repaired, but burning or missing pages cannot.

| Book | Condition | Damage |
|---|---|---|
| Atlas, Pocket, Winter Tales | Fine | none |
| Birdsong for Beginners | Needs repair | SmokeStains |
| Gardens in Winter | Needs repair | WaterStains |
| Letters from the Sea | Needs repair | WaterStains, SmokeStains |
| Harbour Tales | Too far gone | ScorchedEdges, MissingPages |
| Mountain Paths | Too far gone | ScorchedEdges |
| Winter Almanac | Too far gone | MissingPages, WaterStains |

### Shadow puppets

Solid ink silhouettes on a rod. The small cut-out holes are paper colour (`#d4d3d1`), so they read best on a light or warm sheet.

| File | viewBox | Domain |
|---|---|---|
| `shadow-fox.svg` | 300 × 300 | `CharacterCutout Fox` |
| `shadow-owl.svg` | 300 × 300 | `CharacterCutout Owl` |
| `shadow-child.svg` | 300 × 300 | `CharacterCutout Child` |
| `prop-lantern.svg` | 160 × 160 | `PropCutout Lantern` |
| `prop-key.svg` | 160 × 160 | `PropCutout Key` |
| `prop-book.svg` | 160 × 160 | `PropCutout Book` |

### 1998 mystery books

Covers (`viewBox 0 0 240 340`), equally worn, none more eye-catching than the others:

| File | Candidate |
|---|---|
| `candidate-a.svg` | `CandidateA` Fox and Lantern, illustrated edition |
| `candidate-b.svg` | `CandidateB` Fox and Lantern, school edition |
| `candidate-c.svg` | `CandidateC` River Stories, anthology |
| `candidate-d.svg` | `CandidateD` Fox and Lantern, plain edition |

Interior illustrations for the cover/illustration tab (`viewBox 0 0 400 300`):

| File | Shown for |
|---|---|
| `illustration-fox-bridge.svg` | A, B and C (fox with lantern beneath a stone bridge, the matching clue) |
| `illustration-fox-wood.svg` | D only (same fox and lantern in a snowy wood, no bridge) |

A, B and C must use the identical file, so the illustration alone never separates them.

### Player sprites (walking human characters)

Cute chibi paper-theatre cut-outs, separate from the shadow puppets. Big head, short body, thick wobbly ink outline and a cream cut-out border.

**Status:** all four are final, in the agreed style.

**Source:** `docs/asset-sources/chibi-family.mjs` holds the shared body (head, torso, arms, legs, eyes) and each person's colours, hair, headwear, face and clothing. To change someone, edit it there and re-run `node docs/asset-sources/chibi-family.mjs [walter|henry|edwin-young|edwin-present]`. Don't edit the SVGs by hand.

**Character colours (agreed, no others):**
- outlines `#291e1a`; highlights, eye whites and cut-out border `#f2e4c9`
- skin `#e8b98f`, `#c4875a` or `#7d4a30`; cheeks `#d9806a`
- hair `#291e1a`, `#5a3428`, `#a6652b` or `#d4d3d1`
- clothes `#393e26`, `#c95937`, `#d9a443`, `#496669`, `#7687ab`, `#893f43`, `#31542f`

Every frame (Walter's style):

- `viewBox 0 0 96 160`, transparent background, no ground shadow (B can add one in CSS).
- **Anchor:** shoe soles exactly on **y = 152**. The 3-unit outline reaches 153.5 and the cream border 155.5. Feet are centred near **x = 48**. Position a sprite by its anchor point (48, 152), e.g. `transform-origin: 50% 95%`.
- **Bounds:** the whole drawing, border included, stays inside the box. Walter spans x 3.5–91.5 and y 13.5–155.5; Henry spans x 3.5–89.5 and y 7.5–155.5; young Edwin spans x 3.5–89.5 and y 8.5–155.5; present-day Edwin spans x 3.5–89.5 and y 9.5–155.5.
- **Faces right:** the cap peak and face point right. Flip horizontally for walking left (`transform: scaleX(-1)`). The anchor stays put, because x = 48 is the centre.
- **Fixed body:** head, face, cap and torso are byte-identical in all three frames. Only arms and legs change, so nothing jumps when frames swap.
- **Frames:**
  - `idle` stands with feet together.
  - `walk-1` is a wide stride with arms swinging out.
  - `walk-2` is a narrow stride with arms by the sides.
  - Alternating `walk-1 ↔ walk-2` (around 4–6 frames a second) reads as walking. Return to `idle` when the character stops.
- **Fixes made to Gemini's drawing** (they apply to everyone, since the body is shared):
  - face: bigger outline-free irises, features shifted right, Walter's moustache reshaped, both blushes visible
  - walk-1: arms swing out instead of crossing the chest
  - walk-2: the legs no longer cross
  - idle: a gap between the shoes

| Person | Era | Files | Look | Style |
|---|---|---|---|---|
| Walter | 1950 | `player-walter-idle.svg`, `player-walter-walk-1.svg`, `player-walter-walk-2.svg` | Flat cap `#393e26`, grey hair and moustache, waistcoat `#893f43`, mustard shirt, teal trousers | **Final** |
| Henry | 1973 | `player-henry-idle.svg`, `player-henry-walk-1.svg`, `player-henry-walk-2.svg` | Side-parted brown hair, collar-length at the back, round glasses, corduroy jacket `#c95937`, mustard turtleneck, flared trousers `#393e26` | **Final** |
| Edwin (young) | 1998 | `player-edwin-young-idle.svg`, `player-edwin-young-walk-1.svg`, `player-edwin-young-walk-2.svg` | Late-90s look: middle-parted "curtains" hair, open plaid flannel shirt `#31542f` with rolled sleeves over a mustard T-shirt, cuffed jeans `#7687ab`, black boots with a mustard sole line | **Final** |
| Edwin (present) | present day | `player-edwin-present-idle.svg`, `player-edwin-present-walk-1.svg`, `player-edwin-present-walk-2.svg` | Cosy Christmas Eve look, about 40: short brown hair, clean-shaven, thin round glasses, wine Christmas jumper `#893f43` with a cream Fair Isle star band and ribbed hem, green scarf `#31542f` with mustard stripes, dark jeans `#496669`, brown Chelsea boots | **Final** |

#### Placing them in the walking room (contract v1.3)

Worked out against `Rules.Room` (room 1280 × 720 logical px, 1rem = 16 px, feet on `floorY` = 650).

- **Scale:** draw every player-scale asset at **2 logical px per unit**. A sprite is then 192 × 320 px (12rem × 20rem). The person stands about 288 px tall, matching the contract's grown-up of about 290 px next to the 165 px counter.
- **Anchor:** the feet point (48, 152) lands on (`player.x`, 650). So `left = player.x − 96` and `top = 650 − 304 = 346`, in px; divide by 16 for rem. The feet sit 8 units above the image's bottom edge, so line up this point, not the bottom of the image.
- **Facing left:** `transform: scaleX(-1)` with the default centre origin. x = 48 is the centre, so the feet stay put.
- **Walk cycle:** the contract suggests `pose = floor (player.x / 24) mod 4`. With two walk frames, map 0 → `walk-1`, 1 → `idle`, 2 → `walk-2`, 3 → `idle`; `idle` works as the passing pose between steps. Show `idle` whenever `player.walking` is False.
- **Who:**
  - present-day Edwin in the introduction and the present-day hub
  - Walter in the 1950 phases (salvage, repair board, reopening shelf)
  - Henry in 1973
  - young Edwin in 1998
- **In the game:** B's `Components.Actor` draws these files (her placeholder figure is gone), using the anchor and scale above. Checked in the browser: the sprite is 192 × 320 room px, the feet sit on y 650, and it flips and cycles both walk frames.

### Clue pictures (shown in the clue sheet instead of text)

| File | Clue | Size | Notes |
|---|---|---|---|
| `clue-family-photographs.svg` | `FamilyPhotograph` | 600 × 470 | One photo in a wooden frame, outside the shop: Grandad Walter with his walking stick, Henry, and little Edwin (about five) squinting into the sun, with "Grandad Walter, Dad and me" written underneath. Built from the player sprites by `docs/asset-sources/family-photo.mjs`. |
| `clue-family-photographs-taped.svg` | `FamilyPhotograph` after 1973 | 600 × 470 | The same photograph, its glass cracked along the nine pieces of the 1973 puzzle, with a strip of tape along every crack. Same generator. |
| `frame-photo-1973.svg` | (the 1973 broken-frame puzzle) | 480 × 330 | The same family photograph without frame or caption, so the puzzle shows exactly the picture in the shop. `Views.Frame` draws the glass pieces over it. Same generator. |
| `clue-closure-notice.svg` | `ClosureNotice` | 480 × 440 | Edwin's handwritten notice, taped up, with the words of `Content.Clues ClosureNotice`. Handwriting is the Caveat font (SIL OFL 1.1) as outlines, built by `docs/asset-sources/closure-note.mjs`. |
| `clue-repair-notes.svg` | `RubbleAndShelvesNote` | 480 × 300 | Walter's pencil sketch: new shelves drawn in dashes over the rubble ("rubble out first"), books waiting in a crate. |
| `clue-walter-diary.svg` | `WalterDiaryPage` | 480 × ~400 | The entry itself, handwritten on Walter's ruled diary page with a margin and ribbon. Shown as the whole page (`sheet--picture`); the words stay for screen readers. Built by `docs/asset-sources/handwritten-clues.mjs` (Caveat, SIL OFL 1.1). |
| `clue-budget.svg` | `BudgetAllocation` | 480 × 300 | Four wood planks and a ten-pound note. |
| `clue-glass-slip.svg` | `GlassDeliverySlip` | 460 × 330 | The supplier's handwritten delivery slip on a buff pad page, with the words of the clue. Shown as the whole page; the words stay for screen readers. Built by `docs/asset-sources/handwritten-clues.mjs`. |
| `clue-cutout-box.svg` | `CutoutBox` | 480 × 300 | The six cut-outs (the real `shadow-*.svg` and `prop-*.svg` drawn inside it) standing in their cardboard box. |
| `clue-script-original.svg`, `clue-script-retelling.svg` | `ShadowScript` (from `world.scriptVariant`) | 480 × ~260 | The parts, handwritten in the clue's order and not numbered: Walter's on aged paper, the neighbours' in blue ink on notebook paper. The first line of the clue stays as words above it (`sheet--script`). |
| `clue-sketch-original.svg`, `clue-sketch-retelling.svg` | `StageSketch` (from `world.scriptVariant`) | 480 × 268 | Three pencil panels, numbered, each with a little drawing of its setting and "Scene n: setting" underneath. |
| `clue-wall-<state>.svg` | `HubProp CommunityWall` (from `world.tradition`) | 480 × 300 (original: 332 × 202) | `original`: just the bare board with its old pin holes. `missing`: one faded "Christmas Reading 1973" poster. `established`: shadow-story posters, children's fox-and-lantern drawings, and the 1973 photo of Ruth and Lucy. |

`<state>` is `original` (NotRevisited), `missing` or `established`. The repair notes and budget pictures are built by `docs/asset-sources/repair-clues.mjs` (each shows only what its words say, never how to plan the week). The roof and shelves and the order desk have no picture. The community wall's pictures are built by `docs/asset-sources/hub-props.mjs` and shown above their words (`sheet--scene`).

The room overlays for the frame (bare wall and glass on the floor in 1973, tape on the glass afterwards) are drawn in `public/index.html` (`r-frame-gone`, `r-frame-tape`) and switched by `data-frame` on the stage.

`View.cluePicture` shows these with the `sheet--picture` style: the picture fills the sheet, and the clue's words stay in the page for screen readers.

### Room props (overlays for B's room composition)

B owns where these go and when they show. "Player scale" means the same 1 unit ≈ 1.1 cm as the sprites, so draw these at 2 logical px per unit too; "rests on" is the floor line.

**Already drawn by B** (inline in `public/index.html`, so there is no C file): the ceiling stain, the rubble, the clock hands, the book crates and a pile of wood planks (`r-crates`, `r-timber`). `room-timber.svg` below is an alternative to B's wood planks, so B keeps whichever fits the room better.

**One look for all room props:** a thin 1.5-unit `#291e1a` outline, no cream border, and a faint ground shadow (ink at 18% opacity) under props that stand on the floor. The characters keep their thicker outline and cream border, so they stand out from the room.

| File | viewBox | Anchor / fitting | Use |
|---|---|---|---|
| `room-timber.svg` | 170 × 30 | Player scale, rests on y = 28 | 1950: the four wood planks before they are used. (The file keeps its name; in the game they are always called "wood planks".) |
| `room-roof-damaged.svg` | 120 × 60 | Same box as the patched version | 1950: hole in the ceiling with dripping water, before the roof is patched (or after a failed week) |
| `room-roof-patched.svg` | 120 × 60 | Same box as the damaged version | 1950 onward: new boards nailed over the hole |
| `room-bucket.svg` | 36 × 38 | Player scale, rests on y = 36 | 1950: catches the drips under the damaged roof |
| `room-window-broken.svg` | 100 × 140, `preserveAspectRatio="none"` | Stretch to one pane inside the room's window frame | 1950: shattered pane |
| `room-window-glazed.svg` | 100 × 140, `preserveAspectRatio="none"` | Same box | 1950: new glass (succeeded week) |
| `room-window-boarded.svg` | 100 × 140, `preserveAspectRatio="none"` | Same box | Planks over the pane (for a week where the window was boarded) |
| `room-torch.svg` | 44 × 18 | Player scale; lens at (42, 9) | 1973: battery torch |
| `room-torch-beam.svg` | 240 × 120 | Origin (the lens) at (0, 60); semi-transparent | 1973: torch light, shown only while it is on |
| `room-story-sheet.svg` | 170 × 124 | Player scale, hanging line at the top | 1973: blank bedsheet stage; puppets and captions go on top as interface |
| `room-crt-computer.svg` | 64 × 58 | Player scale, rests on y = 56 | 1998: beige CRT monitor and keyboard; screen left blank for interface text |
| `room-parcels.svg` | 68 × 54 | Player scale, rests on y = 52 | 1998 (succeeded) and present: parcels with blank labels |
| `room-cutout-box.svg` | 64 × 56 | Player scale, rests on y = 50.5, centred on x = 32 | 1973: the box of shadow-puppet cut-outs at `ClueSpot CutoutBox` (x 170). An open cardboard box with fox, owl and lantern silhouettes on rods. Drawn with Google Gemini from the team's prompt; outline thinned to match the other props. |
| `room-book-stacks.svg` | 80 × 48 | Player scale, rests on y = 42.5, centred on x = 42 | 1998: the four books at `BookTableSpot` (x 820): a stack of two, one on its own, and one leaning. Plain covers and no titles, so none stands out. Layout from Gemini's design, redrawn with help from Claude so the books read at game size. Fits on the floor, or on a small table if B adds one. |

None of these contains text. Any label, address or screen text belongs in the interface.

## Fonts

| File | Font | Licence | Used for |
|---|---|---|---|
| `font-alegreya-*.woff2` | Alegreya by Juan Pablo del Peral (Huerta Tipográfica), Latin subset from Fontsource | SIL Open Font License 1.1 | All game text |
| `font-fraunces-semibold.woff2` | Fraunces by Undercase Type, Latin subset from Fontsource | SIL Open Font License 1.1 | The game title on the title screen |
| `font-courier-prime-*.woff2` | Courier Prime by Alan Dague-Greene, Latin subset from Fontsource | SIL Open Font License 1.1 | Typed forms (the delivery slip) |

The handwritten closure notice is a drawing, so it keeps its own lettering.
