# Asset manifest (Person C)

All art is flat SVG in the shared palette. No text is drawn into any image: titles, clues and labels are interface text. File names match the constructors in `src/Domain.elm`, in kebab case.

**Origin and licence:** drawn for this project. Generated with Google Gemini from the team's prompt and palette, then checked and edited by the team (with help from Claude). `shadow-fox.svg` was redrawn by hand. Free to use in this game.

## Palette

| Hex | Name | Hex | Name |
|---|---|---|---|
| `#291e1a` | ink | `#393e26` | dark olive |
| `#5a3428` | dark leather | `#496669` | teal slate |
| `#a6652b` | ochre | `#7687ab` | periwinkle |
| `#d9a443` | mustard / brass | `#d4d3d1` | paper |
| `#c95937` | vermilion | `#748b2c` | moss green |
| `#893f43` | wine | `#31542f` | deep green |

## Files

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

The palette has no true purple, so violet is periwinkle and blue is teal slate. The shelf plaque's colour guide should show these exact six swatches in order: `#893f43`, `#c95937`, `#d9a443`, `#748b2c`, `#496669`, `#7687ab`.

The ruined books deliberately share colour families with the recoverable ones, so colour never gives away a book's condition. Damage does that.

### Damage overlays (`viewBox 0 0 100 100`, `preserveAspectRatio="none"`)

All nine book covers are clean. In the **salvage scene only**, lay the matching overlay(s) on top of the cover, stretched to the same box. On the reopening shelf, show the clean covers, because the books have been repaired by then.

| File | `Damage` |
|---|---|
| `damage-scorched-edges.svg` | `ScorchedEdges` |
| `damage-water-stains.svg` | `WaterStains` |
| `damage-smoke-stains.svg` | `SmokeStains` |
| `damage-missing-pages.svg` | `MissingPages` |

Proposed damage per book (content to confirm in `src/Content`): the rule the player learns is that smoke or water can be repaired, but burning or missing pages cannot.

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
