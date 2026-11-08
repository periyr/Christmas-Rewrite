# How we used AI

A full record of where AI was and wasn't used in **Christmas Rewrite**, for the judges and for ourselves.

**Team:** Avissa Rasoulinia (core logic, Person A), Defne Göçken (presentation, Person B), Peri Yarci (content and assets, Person C), Ata Karasoy (debugging and small implementation details).

**Tools:** Claude (Anthropic), mostly through Claude Code, and Google Gemini (image generation).

---

## Summary

| Area | Who did it | AI involvement |
|---|---|---|
| Game idea, story, characters, eras | The team | None |
| Puzzle designs and their rules | The team | None |
| Consequences between eras and the endings | The team | None |
| Planning and team coordination | The team | Claude helped structure the brief, the contract and the schedule |
| Learning Elm and functional programming | The team | Claude explained concepts and our own code |
| Code | The team, with Claude Code | Used as an assistant to help write code, debug it, and make or understand changes; we reviewed, tested and playtested everything |
| Debugging | The team, with Claude | Claude helped find and fix bugs |
| Game text (clues, diaries, slides, endings) | The team | Minimal: written by us; Claude Code only polished the wording |
| Room backgrounds, book covers, diaries, damage marks, puppets, mystery books | Google Gemini, from our prompts | Generated, then checked and edited by us |
| Walking characters | Google Gemini designs, rebuilt in code | Gemini drew the designs; a script written with Claude rebuilds all four on one shared body |
| Room props, family photograph, closure notice | Claude | SVG made with Claude's help from our descriptions |
| Shadow fox puppet | The team | Redrawn by hand |
| Music and sound | Claude Code | Entirely generated in code by Claude Code: every effect and the music are synthesised with the Web Audio API (`public/audio.js`, `src/Sounds.elm`). There are no sound files. |

---

## 1. What is our own

The following came from the team, not from AI.

- **The concept:** Edwin closing his family's bookshop on Christmas Eve, finding three diaries, and stepping into 1950, 1973 and 1998 to change what happened.
- **The family and the story:** Walter, Henry and Edwin, four generations of the shop, the line "I thought we had more time", the clock stopping before midnight.
- **The puzzles:**
  - 1950: sorting salvaged books by damage, the repair-week planning board (budget, weather, delivery day, order of tasks) and the reopening shelf.
  - 1973: the shadow-puppet story during a power cut, with the script changing depending on 1950, and mending the broken photograph frame.
  - 1998: finding the right copy of a book from a picture, a remembered line and an inscription.
- **The rules:** two attempts per main puzzle, free inspecting and rearranging, and no correctness hints before submitting.
- **How eras affect each other:** 1950 decides which 1973 script you get; 1973 decides where the 1998 inscription clue comes from; all three must succeed for the shop to be saved; rewinding from the ending.
- **The visual direction:** a paper-theatre look, a fixed side view of the shop, one family palette (see `public/assets/ASSETS.md`).

## 2. Planning

- The design brief (`one-more-christmas-shared-plan.md`) and the code contract (`CONTRACT.md`) set out our idea, the split of work between the three of us, the shared types and a 22-hour schedule. Claude helped us structure and word these documents; the decisions in them are ours.
- The brief includes a "Shared instruction for every coding assistant", which each of us gave to our own assistant so it would follow our rules and only edit that person's files.
- Example planning prompt: section 7.

## 3. Learning

We used Claude to learn:

- Elm and the Elm Architecture (`Model`, `Msg`, `update`, `view`, `subscriptions`).
- Functional programming ideas: pure functions, immutability, custom types, deriving state instead of storing it.
- How our own code works, so we can explain it ourselves.

Example learning prompt: section 7.

## 4. Code and debugging

- The game is written in Elm. We did not generate all of the code with Claude Code. Each of us worked in our own files and used **Claude Code** as an assistant: to debug, to learn, to generate some parts of the code, and, when needed, to make a change or to understand how a change should be made. We reviewed what it produced, ran the tests and played the game in the browser.
- **The git history shows this openly:** 77 of the 93 non-merge commits on `main` (as of 8 November, after sound and saving were added) carry a `Co-Authored-By: Claude` line. To save time, we often had Claude Code make our commits and open our pull requests, and it adds that line to every commit it makes, so the line shows Claude Code was involved in that change, not that it wrote all of it.
- **How we checked the code:**
  - About 300 automated tests (`npm test`), including every one of the 2,520 possible repair weeks, all 36 shadow stagings, the four accepted shelf orders out of 720, and whole games through all eight pass/fail combinations.
  - Full playtests in the browser, logged in `docs/PLAYTEST.md`.

## 5. Writing

- All game text (clues, diary passages, slides, endings, labels) lives in `src/Content/`. We wrote it ourselves. AI involvement was minimal: we only used Claude Code to polish it, such as tightening wording, fixing grammar and keeping names and terms consistent.
- Docs such as the walkthrough, the playtest log and the submission copy were written with Claude's help.

## 6. Art and assets

The full list of files is in `public/assets/ASSETS.md`.

| Asset | Files | How it was made | What we changed afterwards |
|---|---|---|---|
| Room backgrounds | `room-present.jpg`, `room-1950.jpg`, `room-1973.jpg`, `room-saved.jpg` | Google Gemini, from our prompt | Cropped to 16:9 and resized. Changes inside a room (stain, rubble, patched roof, broken window) are small SVG overlays drawn in code. 1998 reuses the 1950 room. |
| Salvage book covers | `book-*.svg` (9) | Google Gemini, from our prompt and palette | Checked and edited; heights and colours fixed to match the shelf puzzle |
| Damage marks | `damage-*.svg` (4) | Google Gemini | Checked and edited |
| Diary covers | `diary-*.svg` (3) | Google Gemini | Checked and edited |
| Shadow puppets and props | `shadow-owl.svg`, `shadow-child.svg`, `prop-*.svg` | Google Gemini | Checked and edited |
| Shadow fox | `shadow-fox.svg` | Redrawn by hand | — |
| 1998 mystery books | `candidate-*.svg`, `illustration-fox-*.svg` | Google Gemini | Checked and edited |
| Walking characters | `player-*.svg` (4 people × 3 poses) | Google Gemini drew Walter's body and each person's design | Rebuilt on one shared body by a script (`docs/asset-sources/chibi-family.mjs`), with small fixes to the drawing |
| Room props | `room-*.svg` (torch, sheet, computer, crates, parcels…) | Hand-written SVG made with Claude's help | Some follow Gemini's layouts (the book stacks and cut-out box) |
| Family photograph, closure notice, 1973 frame photo | `clue-family-photographs*.svg`, `clue-closure-notice.svg`, `frame-photo-1973.svg` | SVG made with Claude's help, reusing the walking characters | The notice's handwriting is the Caveat font (SIL OFL 1.1), turned into outlines |
| Wall clock | drawn in `src/Components/Clock.elm` | Code, written with Claude Code | — |

**Rules we set for every asset** (from `ASSETS.md` and the brief):

- No text baked into images. Clues and labels are real interface text.
- One shared palette, listed in `ASSETS.md`.
- Ruined and good books share colour families, so colour never gives away a book's condition.
- The three matching mystery books use the identical illustration, so the picture alone never gives the answer.

### Music and sound

All of the game's audio was generated entirely in code by Claude Code. There are no recorded or downloaded sound files.

- **How it works:** `public/audio.js` builds every sound at runtime with the browser's Web Audio API (oscillators, noise, filters and a short generated reverb). `src/Sounds.elm` decides which sounds each game step plays by comparing the game state before and after it, and sends their names to `audio.js` through a port.
- **Sound effects:** page turns, opening and closing clues and panels, picking up and placing books, cards, cut-outs and glass, success and mistake sounds, footsteps, the diary opening, the trip back in time, the tear home, the clock stopping, both endings, and the fox, owl and child voices and scene sounds of the 1973 shadow-puppet show.
- **Music:** "Silent Night" (Franz Gruber, 1818, public domain), played as a quiet looping music box.
- **Mute:** a toggle, remembered in the browser.
- **Our part:** we asked for each sound and for changes until it fit (for example quieter music, and fixing the shadow-play sounds being cut off).

## 7. Example prompts

Real prompts we used. More can be added in the same layout.

### Room background: `room-1973.jpg` (Google Gemini)

This version asked for the clock to sit above the family portrait. Afterwards the picture was cropped to 16:9 and resized (see `ASSETS.md`).

```
I standard 2D view and straight-on perspective.
- **Wall**: Warm beige (#d9cfae) upper section, warm-toned wood trim (#bfb28c), warm-toned lower wall panels (#7e6443).
- **Door**:
  - Positioned at left (x 2-9%, y 28-88%).
  - Narrow wooden door in warm caramel (#a6652b).
  - Small glass window pane reflecting a cool, snowy blue night (#7687ab) and a glowing street lamp (#d9a443).
  - Brass door handle and a small brass bell above it (honey gold #d9a443).
  - Clear and unblocked.
- **Left Bookcase**:
  - Positioned at x 10-42%, y 12-60%, now slightly narrower to fit the door.
  - Dark walnut (#5a3428) with dark/interior backing (#3f2c1c).
  - Filled with colourful book spines (burnt orange #c95937, slate teal #496669, and #a08a5a).
- **Shop Counter & Register**:
  - Positioned at x 10-42%, top at y 62%, panelled front down to y 82%.
  - Warm caramel/brown (#80593a, top #a47a50).
  - Old-fashioned brass cash register on the left (x 11-18%).
  - **EMPTY counter top** from x 19 to 42%.
- **Arched Window**:
  - Centered at x 44-56%, y 16-58%.
  - Small panes showing a dark periwinkle blue night (#7687ab), falling snow (#d4d3d1), and a glowing street lamp (#d9a443).
- **Noticeboard**:
  - Empty blank cork board below the window (x 44-56%, y 62-78%).
- **Right Bookcase**:
  - Positioned at x 58-83%, y 12-80%.
  - Dark walnut (#5a3428) filled with colourful book spines.
- **Wall Clock & Family Portrait**:
  - ** Clock moved**: Round wall clock with a plain, empty face (no numbers, no hands, #d4d3d1) is placed **directly on top of / above the small framed family portrait** on the right-hand wall.
  - The framed family portrait sits below the clock at x 85-93%, y 34-46%, containing soft, blurred, indistinct shapes.
- **Armchair & Side Table**:
  - Worn, cozy, cranberry-red armchair (#893f43) at x 68-88%, y 56-86%.
  - Small side table at x 89-97%, y 58-88% with a glowing warm lamp (honey gold #d9a443).
- **Christmas Tree & Garland**:
  - Small decorated Christmas tree (moss green #748b2c, pine green #31542f, cranberry red baubles #893f43, gold star #d9a443) behind/beside the armchair.
  - Paper garland with warm fairy lights hanging along the top of the shelves.
- **Floor & Foreground**:
  - Dark walnut wooden floorboards (#5b4330).
  - Small rug in the front left.
  - Clear, empty floor space at the bottom front.
- **Framing**:
  - Thin, clean, straight-edged decorative paper border around the very edge of the image only.
  - **NO curtains, NO drapes, NO overlays** in the corners or inside the frame.

- **Style**: Paper-theatre / toy-theatre aesthetic. Layered cut-card objects with visible, slightly imperfect hand-cut edges, thin pale paper outlines (#d4d3d1), soft drop-shadows between overlapping layers, and subtle paper/cardboard texture throughout.
- **Color Palette**: Strictly uses the requested palette (Espresso Brown #291E1A, Dark Chestnut/Walnut #5A3428, Caramel #A6652B, Honey Gold #D9A443, Burnt Orange/Terracotta #C95937, Cranberry Red #893F43, Dark Olive #393E26, Slate Teal #496669, Dusty Periwinkle #7687AB, Pale Paper Grey #D4D3D1, Moss Green #748B2C, Forest Green #31542F).
- **Lighting/Mood**: Warm golden light from lamps and fairy lights contrasting with cool, dusty periwinkle moonlight and snow through the window. Cozy, nostalgic, storybook atmosphere.
- **Strict Exclusions**: No people, no animals, no text, no numbers, no clock hands, no watermarks, flat 2D style, 16:9 aspect ratio.
```

### Planning: turning our design into a 12-hour team plan (Claude, shortened)

```
Act as our senior software architect and technical project manager. We have
already agreed on our game concept, mechanics and visual direction: do NOT
invent a new game, change the concept or add mechanics.

Read our game design document, then turn it into a realistic 12-hour plan for
three developers (Person A, B and C) working in parallel on ONE game:

1. Analyse the spec: features, mechanics, screens, game state, dependencies,
   shared interfaces, assets and integration points.
2. Split the work along technical boundaries. For each person: responsibility,
   features, files they own, functions, inputs/outputs, dependencies,
   deliverables and how to test their work alone.
3. Define the shared interfaces before coding: file structure, data
   structures, function signatures, shared state, events and what each module
   imports and exports. Coding assistants must not invent competing versions.
4. A phased schedule for the first 12 hours with milestones (setup, core
   work, first integration, feature completion, stabilisation).
5. Git workflow: branch per person, file ownership, when to merge, handling
   conflicts.
6. Functional programming rules: pure functions, immutable state, state
   transitions, logic separate from UI, side effects at the edge.
7. Acceptance criteria for each checkpoint.
8. Priorities P0–P3, and what to drop if we fall behind. Never sacrifice the
   core gameplay loop for polish.

Produce one shared brief we can give to all three developers and their coding
assistants. Do not start coding.
```

### Learning: how Elm and JavaScript work together in our game (Claude, shortened)

```
Analyse our repository and explain how Elm and JavaScript work together in
our game, using the official Elm guide (https://guide.elm-lang.org/) and its
interop pages (https://guide.elm-lang.org/interop/) to stay accurate.

Cover: why we use both languages and what each is responsible for; how they
communicate (ports, subscriptions, commands, flags, JS event listeners, only
where we actually use them); one real interaction traced from JavaScript to
Elm and back; the exact files and functions involved; how Elm's functional
model sits alongside JavaScript; and the benefits and trade-offs.

Base everything on our actual code, separate what Elm offers from what we
actually use, keep it beginner-friendly, and finish with a simple diagram and
a short answer we could give judges about why we used both languages.
```

## 8. What AI did not do

- It didn't come up with the game, the story, the puzzles or their rules.
- It didn't decide the puzzle answers. They come from our design, and the tests check that each puzzle has exactly the answers we intended.
- It isn't part of the game: the game makes no network calls and uses no AI while you play.
