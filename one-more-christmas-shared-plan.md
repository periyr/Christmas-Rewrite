# One More Christmas — shared design and production brief

Give this entire brief to all three teammates and their coding assistants. Assign each assistant Person A, B, or C. This document is the shared source of truth. Changes to mechanics, names, rules, or interfaces must be agreed by the humans and reflected here before another assistant implements them.

This is a plan, not an instruction to start three competing implementations. Build one repository and one game. The small continuity details and exact puzzle contents supplied below fill gaps in the discussion so every assistant has the same specification.

## 1. Game and scope

**Title:** One More Christmas.

**Tagline:** Every decade has its mistakes. Every diary remembers them.

**Format:** A single-player, browser-based, 2D puzzle adventure written in Elm, with a controllable character walking through a fixed-camera, side-view bookshop. The same room appears in different eras. Approaching objects opens the existing document and puzzle panels. Character movement and visible room changes are required features.

**Target playtime:** Approximately 10–15 minutes on a first playthrough. Main puzzles take roughly 2–3 minutes each; warm-ups are much shorter. This is a target, not a gameplay timer.

**Timeline:** Present-day Christmas Eve → 1950 repairs → 1973 shadow story → 1998 forgotten-book mystery → present-day ending.

**Content:** Three main puzzles, two short 1950 arrangement scenes, an introduction, a present-day diary hub, and two endings. There is no real-time countdown.

**Technology:** Elm for game state, puzzle rules, history, consequences, and UI. HTML/CSS/SVG for presentation. A small JavaScript boundary may initialise Elm and optionally play sounds. No JavaScript game rules, backend, database, live AI, or network-dependent gameplay.

## 2. Story and continuity

The Hale family bookshop has lasted four generations. Edwin Hale is its current owner. On Christmas Eve, with the shop about to close for good, he discovers diaries while packing the back room.

Use this family tree consistently: unnamed founder → Walter Hale → Henry Hale → Edwin Hale. Walter is Edwin’s grandfather; Henry is Edwin’s father.

**Continuity decision:** The three books are Walter’s 1950 diary, Henry’s 1973 diary, and Edwin’s own forgotten 1998 journal, written when he worked alongside Henry. The last chapter makes Edwin confront his own missed opportunity. This preserves Walter being Edwin’s grandfather and the shop having four generations of owners.

Opening sequence, about 45–60 seconds:

1. Edwin is packing the shop. The player inspects the closure notice and family photograph, then opens a box beneath the counter.
2. Inside are the three diaries. Each contains the sentence, “I thought we had more time.”
3. Edwin wishes for one more chance. The clock stops just before midnight and the oldest diary glows.
4. Opening it sends pages turning rapidly while the room changes around it.
5. Edwin inhabits Walter in 1950, Henry in 1973, and his younger self in 1998.

The 1950 diary is written retrospectively on Christmas Eve. Entering it takes the player to the start of the repair week it describes. The planning board and slideshow cover that whole week.

After each resolved chapter, the player returns to the present. Props and diary passages change. The next diary unlocks whether the previous chapter succeeded or failed.

**Recurring customer:** Ruth appears as a child in a 1950 photograph, as a parent attending the 1973 event with her daughter Lucy, and as the sender of the 1998 book request. Use photographs, captions, and letters rather than animated people. In the saved-shop ending, an elderly Ruth returns with family. This is a small recurring thread, not a separate quest.

Tone: cosy, magical, and bittersweet, with understandable family mistakes. These historical situations affect stock, opening routines, customers, and opportunities. The characters cannot change national events.

## 3. Shared play and failure rules

In the room, the player walks left/right using A/D or the arrow keys and presses E near an object to interact. Clicking an interactive object also walks the character to it and then opens it. The player inspects clues, selects and places objects within panels, then explicitly submits a main puzzle. Selecting and placing is click-to-select, then click-to-place. Dragging is optional polish and must not be required. Walking pauses while a clue, puzzle, feedback panel, or transition is active; closing an ordinary panel preserves its puzzle state.

Each main puzzle gets **two attempts**:

- Inspecting clues and rearranging objects never spends an attempt.
- Incomplete submissions are blocked with a neutral completion message and spend no attempt.
- Before submission, do not show correctness, broken-rule icons, solution highlights, or red error warnings. Resource numbers may update as ordinary arithmetic.
- Pressing the chapter’s final button evaluates a complete submission and spends one attempt.
- A correct first or second submission succeeds.
- First incorrect submission: show the violated rules and explain them briefly. The player gets one retry. Keep their arrangement so they can edit it.
- Second incorrect submission: record the chapter as failed and show its consequence. Continue the story into the remaining chapters.
- Disable submission while feedback or transition is active. A double-click must never consume both attempts.
- Never reveal a full correct solution automatically after the first error.

Only the main puzzles affect chapter success. The salvage and reopening shelf are forgiving practice/celebration scenes, with unlimited corrections and immediate local feedback.

All three main chapters must succeed for the shop to survive the final Christmas. A failed chapter remains failed through that run; succeeding at later chapters does not erase it.

### Rewind

Reopening an earlier diary is available **after reaching an ending**. It clears that chapter and all later chapter records, including attempts, arrangements, feedback, inspected clues, and outcomes. Earlier records remain. Recalculate the world from the remaining history and give the reopened main puzzle two fresh attempts. Replaying 1950 starts with salvage; the introductory discovery does not repeat.

## 4. Chapter one: The Repair Week, 1950

Walter’s diary:

“Christmas Eve, 1950. Five years since the war ended, and the shop is still a mess. The timber licence finally came through. Four planks and £10 for the whole week. I spent it on a grand new sign for the reopening. It looked wonderful. Then Wednesday’s rain came through the roof onto every book we’d saved.”

The chapter has three parts.

### 4A. Salvage the books — short warm-up

Sort nine books into three crates: **Fine**, **Needs repair**, and **Too far gone**. Use scorch edges, stains, missing pages, and colour to make condition visible. “Needs repair” covers recoverable smoke/water damage.

Three books belong in each crate. Any order of moves is allowed; correct final classification is required. Crate fill order is not an alternative classification rule. All six recoverable books are ready by their scheduled shelving day.

Use these six recoverable books for the final shelf:

| Book | Condition | Height rank, shortest first | Cover |
|---|---|---:|---|
| Atlas of Small Places | Fine | 4 | Blue |
| Birdsong for Beginners | Needs repair | 1 | Yellow |
| Gardens in Winter | Needs repair | 2 | Violet |
| Letters from the Sea | Needs repair | 5 | Orange |
| Pocket of Wonders | Fine | 3 | Green |
| Winter Tales | Fine | 6 | Red |

The three ruined books are Harbour Tales, Mountain Paths, and Winter Almanac. Simple procedurally drawn covers are sufficient. Condition must be indicated separately from the base cover colour.

### 4B. Repair planning board — main puzzle

Display five day slots, Monday–Friday, and one “Not this week” box with room for two cards. Initially all seven task cards are in a tray. Each day holds exactly one task; all seven cards must be assigned before submission.

Budget: **4 timber and £10**. Show both spent and remaining amounts as cards move. Unused resources are allowed. Do not show red error styling until submission.

| Card | Cost | Rule |
|---|---|---|
| Patch the roof | 2 timber | Monday or Tuesday; Wednesday is already too late |
| Clear the rubble | Free | Before Build shelves |
| Build shelves | 2 timber | After rubble and before Shelve the books |
| Shelve the books | Free | After Build shelves |
| Re-glaze the window | £6 | Wednesday, Thursday, or Friday |
| Paint a grand new sign | £6 + 1 timber | Optional cosmetic work; attractive distraction |
| Board up the window | 1 timber | Alternative way to seal the window |

**Visible reopening goals:** a watertight roof, a sealed window, usable shelves, and all recovered books shelved. Make the goals clear without saying which cards to exclude.

Clues: diary describing Wednesday’s rain, Wednesday glass-delivery slip, notes about clearing rubble and building shelves, and the budget allocation. These are inspectable objects around the shop/board.

A valid plan must satisfy all goals, respect every ordering/date rule, stay within both budgets, and assign every card exactly once. A sealed window requires glazing or boarding. Do not hard-code one target schedule. With these constraints, the roof and shelves use all timber, so the valid plans exclude the sign and boarding, and use glazing.

There are exactly **six valid weeks**, verified by enumerating all 2,520 complete five-day selections and orders:

1. Roof, Rubble, Shelves, Books, Glaze.
2. Roof, Rubble, Shelves, Glaze, Books.
3. Roof, Rubble, Glaze, Shelves, Books.
4. Rubble, Roof, Shelves, Books, Glaze.
5. Rubble, Roof, Shelves, Glaze, Books.
6. Rubble, Roof, Glaze, Shelves, Books.

Final button: **Finish week**.

On the first wrong submission, show relevant warnings together: rain for a late roof, timber/money overspend, glass delivery timing, prerequisite arrows, and any missing reopening goal. Explain the rules broken, not the complete correct week. The second wrong submission resolves the chapter as failed.

On success, play a cheap day-by-day slideshow using text and room changes. Wednesday’s rain arrives and the roof holds. Pause on the scheduled shelving day for 4C, then continue to Saturday’s reopening. The order of slideshow events follows the submitted valid schedule.

On final failure, show a short consequence slideshow based on a recorded violation, then return to the present. Do not invent a successful reopening or play the celebratory shelf scene.

### 4C. Reopening shelf — short celebration

Arrange the six recovered books. Accept any of three complete ascending orders:

- Height: Birdsong, Gardens, Pocket, Atlas, Letters, Winter.
- Colour, following a small red→orange→yellow→green→blue→violet guide: Winter, Letters, Birdsong, Pocket, Atlas, Gardens.
- Alphabetical: Atlas, Birdsong, Gardens, Letters, Pocket, Winter.

Show a small plaque suggesting “Small to tall / rainbow / A–Z.” Unlimited corrections. This does not spend another main-puzzle attempt or change an already successful repair outcome.

## 5. Chapter two: The Shadow Story, 1973

During the energy crisis, a fictional local power cut interrupts the shop’s Christmas reading. Henry’s diary says he sent the children home because he thought nothing could be done without lights.

**Player task:** find a battery torch, a sheet, and cardboard cut-outs, then recreate a three-scene shadow story from clues. No electrical repair puzzle and no real-time performance controls.

Inspect three hotspots: the story/script, a stage sketch, and the cut-out box. The stage has three numbered scene panels. Each scene takes one character and one prop. Available characters: **Fox, Owl, Child**. Props: **Lantern, Key, Book**. Use all six cut-outs exactly once.

There are two explicit script variants, chosen from the 1950 outcome:

| Prior outcome | Scene 1 | Scene 2 | Scene 3 |
|---|---|---|---|
| 1950 succeeded: original script preserved | Fox + Lantern | Owl + Key | Child + Book |
| 1950 failed: neighbours supply a retelling | Child + Key | Owl + Book | Fox + Lantern |

Original script clues establish: the fox carries the lantern across the bridge; the owl uses the key at the door; the child opens the book when everyone is home. The stage sketch establishes bridge → door → home.

Retelling clues establish: the child finds the key at the gate; the owl reads the book inside; the fox carries the lantern to guide everyone home. Its sketch establishes gate → inside → home.

Every necessary clue must be available in either variant. The failed 1950 route changes the puzzle’s answer but never makes it impossible.

Final button: **Perform the story**. Two attempts, using the shared failure rules. On the first error, identify which scene(s) conflict with the inspected script. On success, show three brief silhouette scenes with text; this establishes the annual storytelling tradition. On failure, show the cancelled event and its future consequence. Return to the present.

## 6. Chapter three: The Forgotten Book, 1998

Edwin is a young adult working with Henry. His journal describes feeling that the internet would make their small shop irrelevant, and dismissing an email request that seemed too difficult.

**Player task:** use an email, a remembered sentence, and a personal inscription to find the correct edition among four secondhand books. Inspect physical books through tabs for cover/illustration, text, and dedication. This is a book-detective puzzle, not filling out a catalogue.

Ruth requests a book her daughter Lucy loved. The family donated books to the shop years ago; Ruth hopes to recover that edition for Lucy’s daughter this Christmas.

The three required clues are:

1. An illustration of a fox carrying a lantern beneath a stone bridge.
2. The sentence “The lantern stayed lit until the last traveller came home.”
3. The inscription “For Lucy, love Mum.”

Use fictional books with these fixed properties:

| Candidate | Illustration matches | Sentence matches | Inscription matches |
|---|---|---|---|
| A: Fox and Lantern — illustrated edition | Yes | Yes | Yes |
| B: Fox and Lantern — school edition | Yes | Yes | No: “For Peter, love Dad” |
| C: River Stories — anthology | Yes | No: different passage | Yes |
| D: Fox and Lantern — plain edition | No: different illustration | Yes | Yes |

Candidate A is the only answer satisfying all three clues. Do not make its cover more obviously important than the others.

If 1973 succeeded, the family/event archive provides the inscription clue and Ruth mentions Lucy’s memory of the shadow story. If 1973 failed, a follow-up email supplies the same inscription clue. Both routes remain solvable; the clue source and emotional context change. The displayed request still concerns the same book and the same three facts.

Final button: **Send this book**. Two attempts. First error identifies which remembered details do not match the selected candidate. Success establishes an online book-finding service, combining the shop’s personal knowledge with the web’s reach. Failure leaves that opportunity unfinished. Return to the present for the ending.

## 7. Consequences, hub, and endings

Each chapter represents a lasting foundation: sound premises and recovered stock in 1950, community tradition in 1973, and wider reach in 1998. These are historical turning points, rather than a claim that one ordinary mistake alone caused bankruptcy decades later.

The present-day hub derives its appearance from recorded outcomes:

- 1950: roof stain/repair condition, usable shelves, and archive condition.
- 1973: event posters, children’s drawings, and community photographs.
- 1998: parcel labels, order notifications, and book-finding correspondence.

Later diary passages must explicitly mention at least one earlier action. Keep authored variants small; do not generate branching stories at runtime.

**Saved ending:** all three succeeded. The shop has working premises, customers connected through its events, and an order service. Edwin turns the sign to OPEN as the clock reaches midnight. Ruth and family return.

**Closed ending:** at least one failed. The shop closes. Show a short, specific explanation for each missing foundation, using the actual outcomes. The tone remains humane and acknowledges the shop’s impact. Offer **Reopen a diary** and **Start again**.

Both endings offer diary replay. There are eight possible pass/fail combinations and only two ending categories; seven combinations close the shop.

## 8. Elm architecture and shared contracts

Use a pure functional core. A starting world plus ordered chapter records produces the resulting world. Views and later clue variants are derived from that world. Avoid separately maintained flags that can disagree with the history.

The shared domain must cover:

- Era: Repairs1950, Shadows1973, Search1998.
- Phase: intro, present hub, salvage, repair board, shelf, shadow puzzle, book mystery, feedback/transition, ending.
- Main outcome: succeeded or failed.
- Chapter record: era, outcome, attempts used, final submission, and final violations if any.
- Current puzzle state: placements/selection, inspected clues, attempts used, and feedback state.
- Room presentation state: player position, facing, walking target, held keys, nearby interaction target, and panel visibility. Walking does not spend attempts or create chapter-history records.
- Derived world: repaired premises, community tradition, online service, and the resulting clue/script variants.
- Typed actions for inspection, selection, placement, submission, retry, advancing, and reopening.
- Structured violations with stable identifiers and friendly text.

Keep validation, attempts, outcome recording, phase progression, and rewind pure. Asset loading and audio belong at the boundary. Sound must never decide a game outcome.

Shared action flow: inspect → select/place → submit → resolve feedback → record one outcome → advance. A submission records an outcome only on success or final failure. First-attempt failure remains local puzzle state.

Represent arrangements as item IDs mapped to slot IDs. The interface may group slots into crates or the two spaces in “Not this week.” Support occupied-slot swaps; when moving from a tray into an occupied slot, return the displaced item to the tray. Moving a card changes its location, never duplicates it. A full target gives neutral capacity feedback, not correctness feedback.

The reusable arrangement UI must not contain puzzle-answer rules. It serves salvage, the repair board, the shelf, and shadow panels; each has a separate validator. Use normal buttons and clickable objects first, not custom drag-and-drop.

Person A defines the exact records/actions and freezes the first contract within 45 minutes. Person B works against a fixture using that contract. Person C supplies content in the same domain types. Contract changes require a brief coordinated update; no assistant independently renames shared fields.

## 9. Ownership for three people

**Person A — core logic and integration lead**

Own Main.elm, Domain.elm, Update.elm, Timeline.elm, Rules/*, tests/*, Elm/package configuration, build scripts, and the integration branch. Implement the model, rules, attempts, progress, variants, endings, rewind, movement/interaction state and subscriptions, and validation tests. Publish the small additive movement contract before B connects the walking room. Merge the three work streams. Do not redesign the story or visual interface independently.

**Person B — presentation and interaction**

Own View.elm, Views/*, Components/*, public/index.html, public/styles.css, and optional startup/audio JavaScript. Implement the illustrated shop scene, visible player and walk cycle, object hotspots, proximity prompts, document overlay, reusable placement interface, visible resource counts, attempt display, post-submit feedback, page/room transitions, slideshow, and ending screens. Render from A's movement contract; do not maintain a second player position. Dispatch typed actions to A’s update logic; do not duplicate validation or maintain a second history.

**Person C — content, assets, and player clarity**

Own Content/*, public/assets/*, the asset manifest/credits, walkthrough, and submission copy. Enter all clues, diary variants, task/book data, scripts, and ending text. Create simple consistent assets and lead fresh-player playtests. Import shared domain types; do not create competing copies of the model or validators. Supply expected examples to A for tests.

Use one repository and one branch per person. Each person’s assistant edits their owned files. Read others’ work freely, but coordinate cross-owner changes. Merge small working changes approximately every two hours. Keep one integrator and one version of the game state.

### Shared instruction for every coding assistant

“Follow this entire brief as the source of truth. You are assisting Person [A/B/C]. Work in that role’s owned files. Preserve the exact puzzle rules, two-attempt system, content identifiers, and history-derived consequences. Do not add mechanics, substitute a different puzzle, or change shared interfaces independently. Coordinate dependencies through the human team. Report changed files, how you checked the work, and any dependency another role must supply. Prefer the smallest complete implementation.”

## 10. Visual and asset plan

Use a paper-theatre style: flat illustrated shapes, textured-looking CSS, readable documents, a visible human character with a simple walk cycle, and strong era colour changes. Reuse one base character with era-specific clothing/age details. Commissioned illustrations are not required; code-authored SVG and CSS are suitable first assets.

Required assets are one reusable shop composition with four era/present treatments; one base human character with two to four walking poses and era variants; three diary covers; nine salvage book covers; four mystery-book variants; three shadow-story character silhouettes; three prop silhouettes; simple task cards/icons; and a few photographs/posters represented as stylised cards with captions. Reuse cover shapes and room furniture.

Keep all important text as real interface text. Do not bake clues into generated images. Use CSS/SVG for the first version. Optional generated room artwork may be added only after the full game works. Keep filenames stable and maintain an asset/credit list.

Show the selected object and legal placement targets clearly without revealing which target is the correct answer. Provide readable overlays, visible focus states, a Help button explaining controls, and a mute toggle if sound exists. Aim for a comfortable desktop layout on both teammates’ computers. Test the actual submission viewport.

### Required movement and visual revision

This revision supersedes the earlier no-walking scope. The puzzles and failure rules remain unchanged.

- Use a fixed-camera side view with one clear horizontal floor strip. A/D or left/right arrows move; E interacts with a nearby object. Clicking an object walks there and interacts on arrival. No jumping, maze navigation, or pathfinding system is needed.
- Keep shared logical coordinates for actor positions, bounds, and hotspot anchors; scale those coordinates to the visible room. Furniture sits behind the walking strip so the initial version only needs left/right room bounds.
- Use Elm keyboard subscriptions and animation-frame deltas. Clear held keys and walking targets on entering panels, changing chapter, and hiding the page. Clamp unusually large frame deltas. Movement must pause during overlays and transitions.
- At the appropriate stations, open the current existing puzzle instead of replacing its rules. After salvage, the player approaches the repair board. During the shelving-day pause, the player approaches the shelf. Closing a puzzle panel does not reset its answer or attempts.
- Present: dusty shelves, packing boxes, closure notice, cold light. 1950: damaged window/roof, rubble, timber, book crates; repairs visibly appear during the week. 1973: dark room, battery torch, sheet, and actual projected story silhouettes. 1998: CRT glow, book stacks, and parcel props. Later present-day props derive from history.
- Make the character visibly walk, face the direction of movement, and idle when stopped. Keep it recognisably human using a simple paper-cutout design. The shop and character are not just text descriptions.
- A owns the movement/interaction state and publishes the contract. B owns rendering, animation, hotspots, and panels. C owns compatible character/prop assets and era details. Coordinate any Main.elm integration; only one person edits it at a time.
- First implement and playtest the walking 1950 chapter, then reuse the room system for the other eras. Preserve the current working build as a checkpoint. The original 22-hour budget does not restart; cut optional audio and decorative effects to make room for these required changes.

## 11. 22-hour production budget

Treat these as elapsed hours from starting implementation. If less time remains than the earlier 22-hour estimate, keep the final submission buffer and apply the cuts below. Stagger breaks and meals.

| Hours | Person A | Person B | Person C | Milestone |
|---|---|---|---|---|
| 0–0.75 | Set up project; define shared types/actions and fixtures | Establish page and room layout against fixtures | Lock content IDs, clue wording, and asset list | All machines run the same skeleton; contract agreed |
| 0.75–3.5 | Repair rules, two attempts, progress | Repair board and reusable selection/placement UI | 1950 content and simple book/task assets | Complete playable repair puzzle, including failure |
| 3.5–7 | Shadow/mystery validation, chapter progression, basic endings | Shadow and book screens, hub, feedback | All remaining puzzle data, scripts, diary variants | All three main puzzles work start to ending with plain visuals |
| 7–11 | Salvage/shelf rules, slideshow state, consequence derivation | Intro, salvage, shelf, simple week playback | Populate all content; check story continuity | Complete agreed content is playable |
| 11–14 | Rewind and state cleanup; integration tests | Polish transitions, attempts, and room consequences | Fresh-player clarity pass and corrections | Feature-complete build; feature freeze |
| 14–17 | Fix bugs; run rule/history checks | Fix layout and interaction problems on Mac/Windows | Lead playtests; verify every clue and both endings | Stable release candidate |
| 17–19 | Final fixes; package build | Restrained visual polish; audio only if stable | Screenshots, credits, description, controls | Submission-ready game and materials |
| 19–20 | Build and support upload | Test submission frame/viewport | Upload candidate and verify with another machine | Working submission exists |
| 20–22 | Serious bug fixes only | Serious bug fixes only | Check submission and preserve backup | Protected deadline buffer |

Important checkpoints: a complete 1950 main puzzle by hour 3.5; all main puzzles and an ending by hour 7; full agreed content by hour 11; no new features after hour 14; an uploaded candidate by hour 20.

## 12. Verification and completion criteria

Person A owns the checks, with examples supplied by C and UI verification by B:

- Enumerate all 2,520 complete repair-board arrangements and accept exactly six.
- Reject Wednesday-or-later roofs, early glazing, broken prerequisites, overspending, and missing reopening goals.
- Check salvage by final classification regardless of move order; accept all three specified shelf orders.
- Check both 1973 script variants and all four 1998 book candidates.
- An incomplete submission spends no attempt. First wrong spends one; second wrong fails. A correct second attempt succeeds.
- A double-click or a click during feedback never spends an extra attempt or records duplicate history.
- Warm-up/coda corrections never spend main-puzzle attempts.
- Check all eight chapter outcome combinations: only all-success saves the shop.
- The same history always derives the same world and clue variant.
- Rewinding 1973 preserves 1950, resets 1973/1998 completely, and recomputes their world. Rewinding 1950 clears all chapters.
- Later chapters remain solvable after earlier failures.
- Walking is frame-rate independent and bounded by the room edges; approaching/clicking hotspots opens the correct existing panel.
- Walking pauses during panels and transitions. Closing a panel preserves answers and attempts. Hiding the page clears held keys. Movement never changes puzzle attempts or history.
- A fresh player can find every required clue and finish without spoken guidance.
- Test the final packaged build on Mac and Windows and in the submission’s browser frame. Verify relative asset paths, both endings, and replay.

The submission must contain the complete intro, three main puzzles, the two 1950 arrangement scenes, visible consequences, both endings, and functional rewind. Missing optional audio or elaborate animation must not block submission.

## 13. Packaging and scope protection

Build one static browser release with an index page, compiled Elm, local styles, and local assets. Use relative asset paths. The game must not need a running Haskell program, API keys, a database, or live services. Test the exported build, not only the development server.

Submission materials: game title/description, controls, screenshots, credits/asset licences, source link if required, and a short explanation of the functional design: immutable state, pure validators, history-derived world, deterministic replay, and rewind by clearing later records.

Cut in this order when behind: optional audio; elaborate page turns; decorative room details beyond the required era changes; extra hover effects; fancy dragging; extended ending animation. Keep the walking character, illustrated room, visible consequences, and existing puzzles. Use basic click placement, simple SVG artwork, and text slides as needed.

Do not add extra eras, another full shelf chapter, inventory-combination systems, real-time shop simulation, extra currencies, procedural narrative, online accounts, or a 3D environment. Preserve the agreed puzzle rules and finish the complete small game.

## 14. Official Elm references

- Architecture: https://guide.elm-lang.org/architecture/
- Compiler and builds: https://guide.elm-lang.org/install/elm.html
- Immutable records: https://guide.elm-lang.org/core_language.html
- Optional JavaScript boundary: https://guide.elm-lang.org/interop/ports.html
