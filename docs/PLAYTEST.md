# Playtest log and handoff notes (Person C)

Checked on 7 November. The last full pass was against `main` at `c9ad11f`, after B's #26 (floor strip) and #27 (1973 stage and 1998 book table) and A's #25 (journey tests). Every check is labelled by **how** it was done:

- **Browser:** played or measured in the running game (`npm start`).
- **Model:** driven through the real `Update` with real messages in a scratch elm-test, printing the text the player would read. Not a visual check.
- **Render:** a view rendered to HTML in a scratch test and queried. Not a visual check.

## Summary

| Area | Result |
|---|---|
| Intro → present-day shop → 1950 diary → salvage → planning board | Works (browser). |
| 1950 success week → slides → shelving pause → shelf → Saturday → back to the shop | Works (browser, and model). |
| 1950 two wrong weeks → feedback → retry → consequence slide → back to the shop | Works (browser, and model). |
| 1973 room and stage, both script versions | Works (browser): wrong first try, retry, performance with matching puppets and captions; the failure slide on the retelling. |
| 1998 room and book table, both inscription sources | Works (browser): picture, text and dedication tabs; wrong book, then retry; the "Lucy's book" slide. |
| Saved ending, closed endings, Reopen 1950/1973/1998, Start again | Works (browser). See "Whole game in the browser" below. |
| 1973 and 1998 content | Checked against A's rules (model and render): solvable on every route, captions match, no answer hints in labels. |
| Player sprites | Consistent (browser pixel scan). No regeneration needed. |

## Issues

Ordered by priority. Owner: **A** logic, **B** presentation, **C** content and art.

| # | Priority | Screen | Steps | What happened | What should happen | Owner | Status |
|---|---|---|---|---|---|---|---|
| 1 | Blocker | 1973 and 1998 | Finish 1950, open Henry's diary, press "Step into 1973" | A sheet says "1973 isn't built yet … Reload the page". 1998, the endings and "Reopen …" can't be reached. | The shadow stage and the book comparison panels | B | **Fixed** by B in #27 (browser) |
| 2 | High | All rooms | Look at any 1950/1973/1998 room | None of C's 14 `room-*.svg` props are placed. 1950 shows B's own crates, rubble and planks. | Torch, story sheet and cut-out box in 1973; computer, book stacks and parcels in 1998; roof and window states in 1950 | B | **Fixed** for 1973 and 1998 in #27: the sheet, torch, beam, cut-out box, puppets, computer, book stacks and parcels are all placed (browser). 1950 keeps B's own inline crates, rubble and planks, so C's 1950 roof, window, timber and bucket files stay spare. That's B's call; closed. |
| 3 | Medium | 1973 and 1998 panels | Open any panel except the 1950 ones | The Help button exists only on salvage, the board and the shelf | Help on the shadow stage and the book comparison | B | **Fixed** in #27 (browser) |
| 4 | Medium | Walking room, feet | Stand still and look at the feet against the floor line | With the sprite's soles on y 650, the ink outline hangs 3 room px below the floor and the cream border 7 px. This is probably the "floor issue". | Team decision: keep the agreed anchor (the soles on the line, the border overlapping the floor like a card standing on it), or agree a new one (below) | B (decision with the team) | **Fixed** by B in #26: the player now stands on a floor strip in front of the furniture, and the feet look grounded (browser, all four eras) |
| 5 | Low | 1973 panels | Open the stage (once built) | If each panel shows `Content.Shadow.scene`'s `setting` ("The bridge", "The door", "Home"), the stage sketch clue becomes redundant: it gives the scene order away without reading the sketch | Label panels "Scene 1/2/3" and keep `setting` for the performance slide titles (where `Content.Slides` already uses it) | B | Open (low). B kept the setting labels on the panels. The puzzle is still solvable; the sketch is just optional. Team call. |
| 6 | Low | 1998 covers | Compare the four `candidate-*.svg` covers | A has a gold-framed moon panel, slightly more decorative than B (library label), C (river) and D (plain) | Covers equally eye-catching | C | Left as is: judgement call, artwork reused as asked. Redraw only if playtesters fixate on A. |
| 7 | Low | Docs | Read WALKTHROUGH or SUBMISSION, then reach an ending | The docs said "Reopen a diary"; the buttons say "Reopen 1950", "Reopen 1973", "Reopen 1998" and "Start again" | Docs match the buttons | C | **Fixed** in this PR |
| 8 | Low | Docs | Read CONTRACT.md or the brief | They still describe three shelf orders and "live misplaced marks" on salvage | Four orders (tall to small added); salvage shows a live count | A (CONTRACT), team (brief) | Partly fixed: A's #25 added the fourth shelf order. CONTRACT.md still says "live misplaced marks" for salvage. |
| 9 | Low | Styles | n/a | `.plaque__swatches` styles are unused since the plaque change; salvage captions may reserve two lines for one | Remove or tighten | B | Open |

## Whole game in the browser (after #26 and #27)

**Run A: all three succeed.**
- **1950:** the correct week and the tall-to-small shelf.
- **1973** (original script):
  - The stage panels read "Scene 1 The bridge / Scene 2 The door / Scene 3 Home".
  - A first try with the retelling's answer uses one attempt and shows "The story didn't hold together. Here's what went wrong:" with "Scene 1/2/3 doesn't match what the story says happens there.", then "You have one more try. Your cut-outs stay where they are."
  - After "Try again", Fox + Lantern, Owl + Key, Child + Book performs three slides, each showing the matching puppet images (`shadow-fox` + `prop-lantern`, and so on) with matching captions, ending with Lucy and Henry's promise.
- **Back in the shop:** the community wall shows decades of posters, and Edwin's journal says "Dad still puts on the shadow story every Christmas".
- **1998:**
  - Young Edwin appears, with the computer and book stacks in the room.
  - Ruth's email mentions the 1973 shadow story, and the inscription comes "From the shop archive".
  - The book table shows four equal cards. Picture tabs: A shows `illustration-fox-bridge`, D shows `illustration-fox-wood`. C's text is the river passage; B's dedication is "For Peter, love Dad".
  - Sending B shows "That isn't Lucy's book. Here's what doesn't match:" with the inscription line. "Try again", then A, gives the "Lucy's book" slide.
- **Saved ending:** "One more Christmas", with the clock at midnight, Ruth and family, and the buttons Reopen 1950, Reopen 1973, Reopen 1998 and Start again.

**Rewind 1998 from the saved ending.**
- Edwin's original 1998 journal opens, and the book table has 2 of 2 attempts.
- The inscription still comes from the family archive, because 1973 is kept.
- D (wrong picture), then C (wrong line): the "The wrong copy" slide, then the closed ending "The shop closes", explaining only 1998.

**Start again → Run B: 1950 and 1973 fail, 1998 succeeds.**
- **New game:** Start again goes back to the opening Christmas Eve scene.
- **1950:** two wrong weeks.
- **1973** (neighbours' retelling):
  - The panels read "The gate / Inside / Home".
  - The original's answer is wrong in all three scenes, twice.
  - "The lights stay out" plays. In the shop, the community wall has one faded 1973 poster.
- **1998** (follow-up email):
  - The journal says "There has been no Christmas reading here since the lights went out in 1973".
  - Ruth's email doesn't mention the shadow story, and the inscription comes from "Ruth's second email".
  - A succeeds on the first try.
- **Closed ending:** it explains the repair week (1950) and the shadow story (1973), each in its own words.

**Rewind 1973 from the closed ending.**
- Henry's diary still says the script was spoiled (1950 is kept).
- The stage shows the retelling's settings with 2 of 2 attempts.
- Help is on the stage.

**Rooms:** in the 1973 room, Henry stands on B's floor strip, with the sheet across the window, the torch on the counter and the cut-out box by the door. The styles match.

## Browser playthrough of 1950 (both routes)

The browser pane had to be visible: with it hidden, the page gets 0 animation frames and nobody can walk.

- **Correct week** (Roof, Rubble, Shelves, Books, Glaze; Sign and Boarding left out):
  - the allowance shows "Wood planks 4 spent · 0 left"
  - the slides follow the week, and Wednesday has the rain with the roof holding
  - Thursday pauses on "Shelve the books", and Walter walks to the shelf
  - the shelf shows the new plaque and no swatches; the books start as Letters, Pocket, Gardens, Winter Tales, Atlas, Birdsong
  - tall to small is celebrated
  - Friday and Saturday (with Ruth) follow, then the return to the shop
  - in the shop, the roof text has changed; Henry's diary says the script is safe; in 1973 Henry appears and the original script and its bridge/door/home sketch read correctly
- **Two wrong weeks** (Sign Monday, Roof Wednesday):
  - the first submit uses one attempt ("2 of 2" → "1 of 2") and shows "The week didn't hold. Here's what went wrong:" with three numbered lines, matching the numbered badges on the roof card, the goals and the plank allowance
  - "You have one more try. Your cards stay where they are."
  - "Try again", then the unchanged week, gives one "The week goes wrong" slide (rain on Wednesday), then the shop
  - the roof text and Henry's diary show the failure versions
  - the 1973 room has the neighbours' retelling and its gate/inside/home sketch
- **Feet:** zoomed in, Henry and Walter stand on the floorboards with B's shadow under them. They don't look sunk or floating at this size.
- **Not reproduced:** once, right after a reload, clicking "Open the box" walked Edwin to the box without opening it. A second try, after the page had settled, opened it with one click, and every other label (diary, crates, board, shelf, clues) worked first time. Not logged as a bug.

## Verified wording

- **Two attempts:** the board's Help says "You have two attempts", and the attempt tokens show what's left (browser). The first wrong week shows every broken rule together, e.g. "The roof is patched on Wednesday, but the rain comes that same day." / "Nothing done this week seals the broken window." / "This week uses 5 wood planks, but the licence allows only 4." (model). Retry keeps the arrangement, and the second wrong week plays one consequence slide (model).
- **Unlimited warm-ups:** salvage Help says "You can correct mistakes as often as you like"; shelf Help says "You can rearrange as often as you like, and it never costs an attempt" (code and render).
- **Changed diaries (model):**
  - After a successful 1950, Walter's diary reads "…at last the shop looks like a shop…". After a failed one: "…We opened on Saturday half-ready…".
  - Henry's 1973 entry then says the script is "still safe in its tin", or that it "was spoiled by the damp after 1950". The 1973 script switches to match: the original, or the neighbours' retelling.
- **Present-day shop (model):** the roof-and-shelves text changes with the 1950 result.
- **Endings and rewind:** text checked in `Content.Endings`; buttons read in `Views/Shop.elm`. Not reachable in the browser (issue 1).
- **Names and dates:** only Walter, Henry, Edwin, Ruth, Lucy (and "Peter" on book B), and only the years 1950, 1973 and 1998 appear in the game text.

## For B: player sprites (the floor issue)

**The sprites are consistent. No files changed.** Measured in the browser by drawing each of the 12 files at 4× and scanning pixels:

| Check | Result (all 12 files) |
|---|---|
| viewBox / natural size | `0 0 96 160` / 96 × 160 |
| Sole path (the agreed anchor) | y = **152** |
| Lowest ink pixel (outline) | y = **153.5** in every frame |
| Lowest pixel of any kind (cream border) | y = **155.5** in every frame |
| Feet centre | x = 47–50 (idle 48, walk-1 47, walk-2 50) |
| Clipping | No opaque pixel touches any edge |
| Body jump | Head and neck (y 0–73) are pixel-identical across idle, walk-1 and walk-2 for all four people. The SVG source of head, face and torso is byte-identical. |

**Exact anchor:** the agreed anchor is (48, 152), at 2 room px per unit.

- **Sprite position:** `left = player.x − 96` and `top = 650 − 304 = 346` (room px). `Components.Actor` already does exactly this.
- **What it looks like:** the soles sit on y 650, the ink outline ends at 653, and the cream border at 657. So the drawn feet overlap the floor line by 3–7 px.
- **If the team prefers the ink to rest on the line:** use (48, 153.5), so `top = 650 − 307 = 343`. That's a team decision, not something C changed.
- **Shadow:** B's `.actor__shadow` (bottom 0.75rem) is centred around y 151 in sprite units, so it sits under the feet.

## For B: 1973 and 1998 assets and placement notes

All files exist, contain no text, and are reused as they are.

| Use | File(s) | Size (viewBox) | Notes |
|---|---|---|---|
| Shadow puppets (characters) | `shadow-fox.svg`, `shadow-owl.svg`, `shadow-child.svg` | 300 × 300 | `CharacterCutout Fox/Owl/Child`. Ink silhouettes with paper-coloured holes, so put them on a light sheet. Names: `Content.Shadow.cutoutName`. |
| Shadow puppets (props) | `prop-lantern.svg`, `prop-key.svg`, `prop-book.svg` | 160 × 160 | `PropCutout Lantern/Key/Book` |
| Stage | `room-story-sheet.svg` | 170 × 124 | The sheet at `StageSpot` (x 640, y 380, across the window). Blank: draw panels and puppets on top. |
| Light | `room-torch.svg`, `room-torch-beam.svg` | 44 × 18, 240 × 120 | The beam's origin is the lens (torch x 42, y 9; beam x 0, y 60). Show the beam only while performing. |
| Cut-out box | `room-cutout-box.svg` | 64 × 56 | `ClueSpot CutoutBox` (x 170), rests on y 50.5 |
| Candidate covers | `candidate-a.svg` … `candidate-d.svg` | 240 × 340 | Same size and treatment for all four; don't order or highlight them differently |
| Picture tab | `illustration-fox-bridge.svg` for A, B and C; `illustration-fox-wood.svg` for D | 400 × 300 | A, B and C must use the identical file |
| Tab text | `Content.Mystery.candidate c` (`label`, `cover`, `text`, `dedication`) or `Content.Clues.clue world (CandidatePage c tab)` | | Same layout for all four |
| Book table | `room-book-stacks.svg` | 80 × 48 | `BookTableSpot` (x 820), rests on y 42.5. Plain, so no book stands out. |
| Computer | `room-crt-computer.svg` | 64 × 58 | `ClueSpot RuthsEmail` (x 240, on the counter), rests on y 56. The screen is blank. |
| Parcels | `room-parcels.svg` | 68 × 54 | Rests on y 52. 1998 after success, and the present-day order desk when `onlineService` is established |

Scene panels: please label them "Scene 1", "Scene 2", "Scene 3" (issue 5). Performance captions come from `Content.Slides.slide`, which already matches the performed cast.

## For A

- Issue 8: CONTRACT.md still says three shelf orders (`TallToSmall` was added in #23) and "live misplaced marks" on salvage (now a count, #19).
- Content checks against the rules (model and render, all passing):
  - **1973:** for both script variants, matching each stage-sketch setting to the one script line that mentions it gives exactly `Rules.Shadow.script` for every scene.
  - **1998:** every candidate's tab text contains a remembered detail exactly when `Rules.Mystery.matches` says so, and only A has all three.
  - **Inscription sources:** both carry the picture, the sentence and the inscription.

## Still to do (C)

- Nothing blocking. The whole game was played in the browser (above) and the docs describe what works.
- Before submitting:
  - take the screenshots listed in SUBMISSION.md
  - make the repository public (or give the judges access)
  - test the release build (`npm run build -- --optimize`, then open `build/index.html`) on a second machine and in the submission's browser frame
