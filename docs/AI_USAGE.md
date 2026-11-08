# How we used AI

A full record of where AI was and wasn't used in **Christmas Rewrite**, for the judges and for ourselves.

**Team:** Avissa Rasoulinia (core logic, Person A), Defne Göçken (presentation, Person B), Peri Yarci (content and assets, Person C).

**Tools:** Claude (Anthropic), mostly through Claude Code, and Google Gemini (image generation).

> **Fill in before submitting:** the sections marked **[team to fill in]** need our real prompts and our own words. Don't invent prompts after the fact; paste the ones we actually used, or say we no longer have them.

---

## Summary

| Area | Who did it | AI involvement |
|---|---|---|
| Game idea, story, characters, eras | The team | None |
| Puzzle designs and their rules | The team | None |
| Consequences between eras and the endings | The team | None |
| Planning and team coordination | The team | Claude helped structure the brief, the contract and the schedule |
| Learning Elm and functional programming | The team | Claude explained concepts and our own code |
| Code | The team, with Claude Code | Claude Code wrote and edited much of the code from our instructions; we reviewed, tested and playtested it |
| Debugging | The team, with Claude | Claude helped find and fix bugs |
| Game text (clues, diaries, slides, endings) | The team | Drafted with Claude's help, then edited by us |
| Room backgrounds, book covers, diaries, damage marks, puppets, mystery books | Google Gemini, from our prompts | Generated, then checked and edited by us |
| Walking characters | Google Gemini designs, rebuilt in code | Gemini drew the designs; a script written with Claude rebuilds all four on one shared body |
| Room props, family photograph, closure notice | Claude | SVG made with Claude's help from our descriptions |
| Shadow fox puppet | The team | Redrawn by hand |
| Music and sound | — | The game has none |

---

## 1. What is our own

The following came from the team, not from AI. **[team to confirm, and add anything that's missing]**

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

**[team to fill in: what we asked, and what we decided ourselves]**

- The design brief (`one-more-christmas-shared-plan.md`) and the code contract (`CONTRACT.md`) set out our idea, the split of work between the three of us, the shared types and a 22-hour schedule. Claude helped us structure and word these documents; the decisions in them are ours.
- The brief includes a "Shared instruction for every coding assistant", which each of us gave to our own assistant so it would follow our rules and only edit that person's files.

## 3. Learning

**[team to fill in: examples of what we asked]**

We used Claude to learn:

- Elm and the Elm Architecture (`Model`, `Msg`, `update`, `view`, `subscriptions`).
- Functional programming ideas: pure functions, immutability, custom types, deriving state instead of storing it.
- How our own code works, so we can explain it ourselves.

## 4. Code and debugging

- The game is written in Elm. Each of us worked in our own files with **Claude Code** as a coding assistant: we described what we wanted, Claude Code wrote or changed the code, and we reviewed it, ran the tests and played the game in the browser.
- **The git history shows this openly:** 43 of the 55 non-merge commits on `main` (as of 8 November) carry a `Co-Authored-By: Claude` line.
- Claude also helped us debug, for example the wall clock's position (commits "Fixed clock", "Clock fix again", "Clock glitches fixed").
- **How we checked the code:**
  - About 300 automated tests (`npm test`), including every one of the 2,520 possible repair weeks, all 36 shadow stagings, the four accepted shelf orders out of 720, and whole games through all eight pass/fail combinations.
  - Full playtests in the browser, logged in `docs/PLAYTEST.md`.

## 5. Writing

- All game text lives in `src/Content/`. It was drafted with Claude's help and then edited by the team (also stated in `docs/SUBMISSION.md`).
- Docs such as the walkthrough, the playtest log and the submission copy were also written with Claude's help.

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
| Walking characters | `player-*.svg` (4 people × 3 poses) | Google Gemini drew Walter's body and each person's design | Rebuilt by `docs/asset-sources/chibi-family.mjs` (written with Claude) so all four share one body. Fixes to Gemini's drawing: bigger eyes, Walter's moustache, arms no longer crossing, legs no longer crossing, a gap between the idle shoes. |
| Room props | `room-*.svg` (torch, sheet, computer, crates, parcels…) | Hand-written SVG made with Claude's help | Some follow Gemini's layouts (the book stacks and cut-out box) |
| Family photograph, closure notice, 1973 frame photo | `clue-family-photographs*.svg`, `clue-closure-notice.svg`, `frame-photo-1973.svg` | SVG made with Claude's help, reusing the walking characters | The notice's handwriting is the Caveat font (SIL OFL 1.1), turned into outlines |
| Wall clock | drawn in `src/Components/Clock.elm` | Code, written with Claude Code | — |

**Rules we set for every asset** (from `ASSETS.md` and the brief):

- No text baked into images. Clues and labels are real interface text.
- One shared palette, listed in `ASSETS.md`.
- Ruined and good books share colour families, so colour never gives away a book's condition.
- The three matching mystery books use the identical illustration, so the picture alone never gives the answer.

## 7. Example prompts **[team to fill in]**

Paste the real prompts here, one per asset type. A suggested layout:

### Room background (e.g. `room-1950.jpg`)

- **Tool:** Google Gemini
- **Prompt:**
  ```
  [paste the exact prompt]
  ```
- **What we changed afterwards:** [crop, resize, edits]

### Book covers

- **Tool:** Google Gemini
- **Prompt:**
  ```
  [paste]
  ```

### Walking character (e.g. Walter)

- **Tool:** Google Gemini
- **Prompt:**
  ```
  [paste]
  ```
- **What we changed afterwards:** [see the fixes listed in section 6]

### Shadow puppets

- **Tool:** Google Gemini
- **Prompt:**
  ```
  [paste]
  ```

### Planning, learning or debugging (Claude)

- **Prompt:**
  ```
  [paste one or two representative examples]
  ```

## 8. What AI did not do

- It didn't come up with the game, the story, the puzzles or their rules.
- It didn't decide the puzzle answers. They come from our design, and the tests check that each puzzle has exactly the answers we intended.
- It isn't part of the game: the game makes no network calls and uses no AI while you play.
