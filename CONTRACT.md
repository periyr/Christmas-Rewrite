# Shared contract v1.5: Person A handoff

`one-more-christmas-shared-plan.md` is still the source of truth for the game, together with `visual-and-movement-update.md` (the walking character and visible room). This file records the code contract that implements it. `src/Domain.elm` is the contract itself. Any change to it needs a short message to the team first. Nobody renames shared types or constructors on their own.

## Commands (Mac and Windows)

The only requirement is Node.js 18 or newer. Nothing needs to be installed globally.

| What | Command |
|---|---|
| Install (once, and after pulling a `package.json` change) | `npm install` |
| Live preview at http://localhost:8000 (reload the page to rebuild) | `npm start` |
| Build into `build/` (git-ignored) | `npm run build` |
| Release build for submission into `release/one-more-christmas/` (git-ignored) | `npm run release` |
| Run the tests | `npm test` |

Compile errors appear in the browser while `npm start` is running. The page `build/index.html` can also be opened directly once it has been built. To use another port, run `PORT=9000 npm start` on Mac, or `$env:PORT=9000; npm start` in PowerShell.

## Files and owners (agreed)

| Owner | Files |
|---|---|
| A | `src/Main.elm`, `src/Domain.elm`, `src/Update.elm`, `src/Timeline.elm`, `src/Fixtures.elm`, `src/Rules/*`, `tests/*`, `elm.json`, `package.json`, `scripts/*`, `CONTRACT.md` |
| B | `src/View.elm`, `src/Views/*`, `src/Components/*`, `public/index.html`, `public/styles.css`, `public/*.js` |
| C | `src/Content/*`, `public/assets/*`, credits, walkthrough |

The build copies all of `public/` into `build/`. Until `public/index.html` exists, a temporary page is generated instead.

## Architecture in one paragraph

`Model = { history, phase, inspecting, notice, room }`. **History** (`List ChapterRecord`, in era order) is the only stored progress. Everything else is derived by `Timeline.deriveWorld model.history`: the foundations, the 1973 script variant, the 1998 inscription source, the next diary, and the ending. **Phase** says where the player is. Puzzle phases carry their own working state, so rewinding or leaving a chapter discards it. `Update.update : Msg -> Model -> Model` is pure. Actions that don't fit the current phase are ignored, so double clicks are harmless. **Room** (v1.3) is presentation only: where the player stands and whether a puzzle panel is open. It never affects history or attempts.

## For B: the view

```elm
view : Model -> Html Msg          -- in src/View.elm
```

`Main.elm` already uses `view = View.view` (B's agreed one-line change). From v1.3, A owns `Main.elm` again for the movement subscriptions.

`public/index.html` must load `elm.js` and call `Elm.Main.init({ node: document.getElementById("app") })`. Main uses `Browser.element` and takes no flags.

### What to render per phase, and which actions to send

| `model.phase` | Render | Dispatch |
|---|---|---|
| `Introduction step` (`PackingUp`, `DiariesFound`, `ClockStopped`) | shop, notice, photo, box, diaries | `Inspect ClosureNotice`, `Inspect FamilyPhotograph`, `Advance`. After `ClockStopped`, `Advance` goes to `PresentHub`. |
| `PresentHub` | the shop, built from `deriveWorld` (`premises`, `tradition`, `onlineService` are each `NotRevisited`, `Established` or `Missing`); the diary in `nextDiary` glows | `Inspect (HubProp p)`, `OpenNextDiary` |
| `Transition (OpeningDiary era)` | the diary's passage, over the present-day shop | `Advance` ("Step into …") starts the trip back (v1.5) |
| `Transition (TimeTravel era elapsed)` | the trip back into that era (`Views.TimeTravel`, v1.5) | `SkipTravel`; everything else is ignored |
| `Salvage placement` | 9 books, 3 crates of 3 spaces, a live count of misplaced books (not which ones, since #19) | `SalvageMove …`, then `Advance` to continue (stays put with `NotSolvedYet` until solved) |
| `RepairBoard puzzle` | tray, Mon–Fri, two "Not this week" spaces, spent/remaining | `BoardMove …`, `Inspect` the four clues, `Submit` ("Finish week"), `Retry` |
| `Transition (Slideshow era i)` | slide `i` of `Timeline.slides era model.history` | `Advance` |
| `ReopeningShelf placement` | 6 positions, plaque, matched order when complete | `ShelfMove …`, `Inspect ShelfPlaque`, then `Advance` to continue (stays put with `NotSolvedYet` until ordered) |
| `ShadowPuzzle puzzle` | 3 panels, each with a character slot and a prop slot | `StageMove …`, `Inspect ShadowScript / StageSketch / CutoutBox`, `Submit` ("Perform the story"), `Retry` |
| `BookMystery puzzle` | 4 candidates, tabs | `Inspect (CandidatePage c tab)`, `Inspect RuthsEmail / RememberedSentence / InscriptionClue`, `ChooseCandidate c`, `Submit` ("Send this book"), `Retry` |
| `Transition ReturningToPresent` | room changing back | `Advance` |
| `Ending` | fate from `(deriveWorld history).fate`: `ShopSaved` or `ShopClosed failedEras` | `ReopenDiary era`, `StartAgain` |

In every phase, if `model.inspecting = Just clue`, show the overlay and dispatch `CloseInspection`. If `model.notice = Just n`, show neutral text and dispatch `DismissNotice` (it also clears on the next move). The notices are `IncompleteSubmission`, `TargetFull`, `DoesNotFitThere` and `NotSolvedYet` (added in v1.2).

### Attempts and feedback (main puzzles only)

`puzzle.attempts` is one of three states:

- `NoAttemptUsed`: the first attempt is available. Show no correctness information at all.
- `ReviewingFirstMistake violations`: show the violations together. Disable Submit and moving. The only action is `Retry`.
- `RetryingAfterMistake violations`: the final attempt. The violations may stay visible for reference.

To get attempts left, compute `Rules.Attempts.maxAttempts - Rules.Attempts.attemptsUsed puzzle.attempts`. An incomplete Submit sets `notice = Just IncompleteSubmission` and spends nothing. A correct submission, or a second wrong one, leaves the puzzle: the chapter appears in `history`, and the phase becomes `Transition (Slideshow era 0)`.

### Placement (one reusable component, no answer rules in it)

```elm
type alias Placement item slot = { placed : List ( item, slot ), selected : Maybe item }

type PlacementAction item slot
    = SelectItem item                 -- click an item (tray or slot); same item again deselects
    | PlaceSelected slot              -- click a slot; occupied: swap, or the occupant returns to the tray
    | PlaceSelectedInGroup (List slot) -- click a crate / "Not this week" box: first free space
    | ReturnSelectedToTray
    | ClearSelection
```

- The tray is `Rules.Placement.inTray allItems placement`. Use `Rules.Placement.itemIn slot` and `Rules.Placement.slotOf item` to look things up.
- A full group produces `notice = Just TargetFull`. A prop clicked onto a character slot produces `DoesNotFitThere`. Both are neutral.
- Wrap each action with that puzzle's message: `SalvageMove`, `BoardMove`, `ShelfMove` or `StageMove`.

| Puzzle | Items | Slots |
|---|---|---|
| Salvage | `Rules.Books.allBooks` | `Rules.Salvage.crateSlots Fine` (likewise `NeedsRepair`, `TooFarGone`), i.e. `InCrate Fine 1..3` |
| Repair | `Rules.Repair.allTasks` | `OnDay Monday..Friday`, plus `Rules.Repair.notThisWeekSlots` (`NotThisWeek 1`, `NotThisWeek 2`) |
| Shelf | `Rules.Books.recoverableBooks` | `Rules.Shelf.slots` (`ShelfPosition 1..6`, left to right) |
| Shadow | `Rules.Shadow.allCutouts` | `CharacterSlot scene` and `PropSlot scene`, for `Scene1..3` |

### Numbers and facts B may display

- Repair costs and budget: `Rules.Repair.cost task`, `Rules.Repair.budget`, `Rules.Repair.spent arrangement` and `Rules.Repair.remaining arrangement`. Remaining may go negative. Show it as plain arithmetic, with no red styling before submission.
- Recoverable book heights and colours: `Rules.Books.height` (1 to 6) and `Rules.Books.colour`. The three ruined books' base colours are a presentation choice for B.
- Don't draw anything from `Rules.Books.condition`, because that is the salvage answer. Damage marks come from C's `BookContent.damage`.

## For C: content to populate

Everything is keyed by the IDs in `Domain.elm`. Every function must be total, so the compiler forces full coverage. Content takes the derived `World` wherever the text varies with history. Rule facts (costs, conditions, heights, colours, correct scripts, candidate matches) live in `Rules/*`. Don't re-enter them as data. Write words that agree with them, and tell A if any fact looks wrong.

Proposed module names and signatures (B will call these):

```elm
Content.Intro.step         : IntroStep -> Document
Content.Clues.clue         : World -> ClueId -> Document          -- every ClueId, incl. HubProp and CandidatePage tabs
Content.Diaries.passage    : World -> Era -> Document              -- later passages mention earlier outcomes
Content.Repair.taskCard    : TaskId -> TaskCardContent              -- title + rule note, no cost
Content.Repair.goal        : ReopeningGoal -> String
Content.Books.book         : BookId -> BookContent                  -- title + damage marks
Content.Shelf.matched      : ShelfOrder -> String
Content.Shadow.cutoutName  : Cutout -> String
Content.Shadow.scene       : ScriptVariant -> Scene -> ShadowSceneContent
Content.Mystery.candidate  : CandidateId -> CandidateContent        -- label, cover, text, dedication
Content.Feedback.violation : Violation -> String                    -- brief explanation, never the full answer
Content.Feedback.notice    : Notice -> String                       -- incl. NotSolvedYet (v1.2)
Content.Slides.slide       : World -> Slide -> Document
Content.Endings.saved      : Document
Content.Endings.missing    : Era -> Document                        -- one per missing foundation
```

The variants come from `World`. `scriptVariant` is `OriginalScript` or `NeighboursRetelling`, chosen by the 1950 outcome. `inscriptionSource` is `FamilyArchive` or `FollowUpEmail`, chosen by the 1973 outcome. Both variants must contain every clue needed to solve the puzzle.

The content record types are `Document { title, paragraphs }`, `TaskCardContent { title, note }`, `BookContent { title, damage }`, `CandidateContent { label, cover, text, dedication }` and `ShadowSceneContent { setting, caption }`.

## 1950 repair board: validator and submission (added in v1.1)

The repair board is now fully playable through `Update`. `Domain.elm` did not change. The only additions are a few functions in `Rules.Repair` and `Fixtures`.

### For B

| B needs to… | Use |
|---|---|
| Show spent and remaining while arranging | `Rules.Repair.spent arrangement` and `Rules.Repair.remaining arrangement` (both `{ timber, pounds }`), with `Rules.Repair.budget` for the totals and `Rules.Repair.cost task` on each card. Only cards on days count; cards in the tray and in "Not this week" cost nothing. Remaining can go negative, so show it as plain numbers. |
| Know whether the board is complete | `Rules.Repair.complete arrangement /= Nothing`. This is a structural check only: one card per day, two in "Not this week", each card exactly once. It is never a correctness signal. |
| Submit the plan ("Finish week") | `Submit`. An incomplete board sets `model.notice = Just IncompleteSubmission` and spends nothing. |
| Continue after first-error feedback | `Retry`. It keeps the arrangement and moves to the final attempt. While `ReviewingFirstMistake`, `Submit` and `BoardMove` are ignored, so disable them. |
| Read attempts and violations | `puzzle.attempts`, which is `NoAttemptUsed`, `ReviewingFirstMistake violations` or `RetryingAfterMistake violations`. Attempts left = `Rules.Attempts.maxAttempts - Rules.Attempts.attemptsUsed puzzle.attempts`. |
| Read the resolved outcome | Once resolved, the phase becomes `Transition (Slideshow Repairs1950 0)`. Then read `Timeline.recordFor Repairs1950 model.history`, which gives `{ outcome, attemptsUsed, finalSubmission, finalViolations }`, and the world via `Timeline.deriveWorld`. |

Never call `Rules.Repair.validate` from a view. Correctness exists only after `Submit`, in `attempts` or the history record.

After resolution, keep sending `Advance` for each slide in `Timeline.slides Repairs1950 model.history`:

- **Success:** `WeekdaySlide day task` for Monday to Friday, in the submitted order. On the `ShelveBooks` day the phase becomes `ReopeningShelf`; after the shelf, the slides resume, then `ReopeningSaturday`, `ReturningToPresent` and `PresentHub`.
- **Failure:** one `ConsequenceSlide Repairs1950 violation` built from the first recorded violation, then `ReturningToPresent` and `PresentHub`. The shelf is not played.

### Violations the repair board can produce (for B's feedback and C's text)

The list is ordered by consequence: roof, window, shelves, books, timber, money. Each problem is reported once, by its root cause.

| Violation | When |
|---|---|
| `RoofAfterRain Wednesday \| Thursday \| Friday` | The roof is scheduled too late (rain on Wednesday). |
| `GoalMissing WatertightRoof` | The roof is in "Not this week". |
| `GlassNotYetDelivered Monday \| Tuesday` | Glazing is scheduled before the Wednesday delivery. |
| `GoalMissing SealedWindow` | Neither glazing nor boarding is scheduled. |
| `MustComeBefore ClearRubble BuildShelves` | Shelves are scheduled, but rubble is later or deferred. |
| `GoalMissing UsableShelves` | Shelves are deferred. Books are then not blamed separately. |
| `MustComeBefore BuildShelves ShelveBooks` | Both are scheduled, with the books first. |
| `GoalMissing AllBooksShelved` | Books are deferred. |
| `TimberOverspent n` / `MoneyOverspent n` | `n` is the total spent; the budget is 4 timber and £10. |

### For C

- **`Content.Feedback.violation : Violation -> String`** needs text for every row above. The day argument can be woven into the text, for example "Wednesday's rain came before the roof was patched." Explain the rule that was broken; never reveal the full correct week.
- **`Content.Slides.slide`** needs text for:
  - `WeekdaySlide day task` for every task that can appear on a valid week: `PatchRoof`, `ClearRubble`, `BuildShelves`, `ShelveBooks`, `ReglazeWindow`
  - `ReopeningSaturday`
  - `ConsequenceSlide Repairs1950 v` for any repair violation `v`, since any of them can come first
- **`Content.Repair.taskCard`** (all seven `TaskId`s) and **`Content.Repair.goal`** (all four `ReopeningGoal`s) as before. Costs come from `Rules.Repair.cost`, so don't write them into the card text.

## 1950 warm-ups and the full chapter flow (added in v1.2)

The whole 1950 chapter now runs through `Update`, from a new game to the present with 1973 unlocked. The tests drive it with real actions. B's screens are not wired yet, so this has been verified in the model, not in a playable browser build.

**Contract change:** one new `Notice` constructor, `NotSolvedYet`. There are no renames and no other changes to `Domain.elm`.

**Flow change:** after `Introduction ClockStopped`, `Advance` now goes to `PresentHub`, where the 1950 diary glows (`nextDiary = Just Repairs1950`). `OpenNextDiary` then opens it.

### Flow

```
Introduction ×3 --Advance--> PresentHub --OpenNextDiary--> OpeningDiary Repairs1950 --Advance--> TimeTravel (2.5 s, or SkipTravel) -->
Salvage --Advance (when solved)--> RepairBoard (fresh: empty board, NoAttemptUsed) --Submit-->
  success: Slideshow 0..  shelving-day slide --Advance--> ReopeningShelf --Advance (when ordered)-->
           Slideshow (day after shelving) .. ReopeningSaturday --Advance--> ReturningToPresent --Advance--> PresentHub
  failure: ConsequenceSlide --Advance--> ReturningToPresent --Advance--> PresentHub   (no shelf)
```

- The week follows the submitted order. It pauses once, on the `WeekdaySlide day ShelveBooks` slide. After the shelf it resumes on the next day: Friday if shelving was Thursday, straight to Saturday if shelving was Friday. The shelving day is never replayed.
- The shelf and salvage never touch `history` or attempts. The 1950 record is written once, at the resolving `Submit`.

### Warm-up helpers (all safe to call while the player is arranging)

| Function | Meaning |
|---|---|
| `Rules.Salvage.misplaced placement : List BookId` | Books sitting in the wrong crate, in `Rules.Books.allBooks` order. Books in the tray are not listed. Its length gives the live count of misplaced books (the view no longer marks which ones, since #19). It was first meant for the immediate per-book feedback. |
| `Rules.Salvage.isSolved placement : Bool` | All nine books placed, each exactly once, all in the right crates. Move order and the space used within a crate don't matter. |
| `Rules.Placement.inTray Rules.Books.allBooks placement` | Books still to sort. |
| `Rules.Salvage.crateSlots crate` | A crate's three spaces. Send `SalvageMove (PlaceSelectedInGroup (crateSlots crate))` when a crate is clicked. |
| `Rules.Shelf.matchedOrder placement : Maybe ShelfOrder` | `Just ByHeight`, `Just TallToSmall`, `Just ByColour` or `Just Alphabetical` when the shelf is full and in one of the four orders (`TallToSmall` was added by C at the team's request after playtesting). Otherwise `Nothing`. Use it to show the celebration as soon as an order matches. |

### Leaving the warm-ups

Send `Advance` for both. If the warm-up isn't solved yet, the phase and arrangement stay as they are, `model.notice = Just NotSolvedYet` is set, and nothing is spent. The next move clears the notice. Corrections are unlimited.

### For C

- **`Content.Feedback.notice NotSolvedYet`**: one gentle line that works for both salvage and the shelf, such as "Not quite yet – keep arranging."
- **`Content.Shelf.matched : ShelfOrder -> String`**: celebration text for each order.
- **`Content.Books.book`**: titles and damage marks for all nine `BookId`s. Condition must be visible without relying on cover colour.
- **`Content.Clues.clue ShelfPlaque`**: the plaque text. Since the playtest change it hints that there are four orders.
- **Hub props** (`HubProp`) and **diary passages**: with `NotRevisited` foundations, i.e. the present before 1950 is played.

## The walking room (added in v1.3)

The brief now requires a walking character in a side-view room (see `visual-and-movement-update.md`). This section is the movement and interaction contract. It is **additive**: nothing existing was renamed or removed, every existing action works as before, and the chapter phases still decide what happens.

**Name clash to avoid:** `Character` (Fox, Owl, Child) is still the 1973 shadow puzzle. The human the player walks around is the `Player`.

**`Main.elm`:** A owns it again for the keyboard, frame and visibility subscriptions. B's `view = View.view` line stays as it is. Please don't edit `Main.elm` while this is in progress.

### What changed in `Domain.elm`

```elm
type alias Model = { history, phase, inspecting, notice, room : Room }   -- one new field

type alias Room = { player : Player, panelOpen : Bool }

type alias Player =
    { x : Float              -- centre of the feet, logical px, 72..1208; the feet are always at y = 708 (650 before v1.4)
    , facing : Facing        -- FacingLeft | FacingRight
    , walking : Bool         -- True while moving: draw the walk cycle; False: idle pose
    , held : List WalkKey    -- WalkLeft | WalkRight, most recent first (Main fills this in)
    , target : Maybe Hotspot -- a clicked hotspot the player is walking to
    }

type Hotspot
    = ClueSpot ClueId   -- same as Inspect clue
    | BoxSpot           -- introduction: the box beneath the counter, same as Advance
    | DiarySpot         -- present: the glowing diary on the counter, same as OpenNextDiary
    | CratesSpot        -- 1950: opens the salvage panel
    | BoardSpot         -- 1950: opens the repair board panel
    | ShelfSpot         -- 1950: opens the reopening shelf panel
    | StageSpot         -- 1973: opens the shadow stage panel
    | BookTableSpot     -- 1998: opens the candidate books panel

-- new Msg constructors
WalkKeyDown WalkKey | WalkKeyUp WalkKey | InteractNearby | AnimationFrame Float | PageVisibilityChanged Bool
    -- sent by Main (keys, frames, page visibility). B never sends these.
ApproachHotspot Hotspot | ClosePanel
    -- sent by B's views.
```

### Helpers in `Rules.Room` (the one shared layout)

| Helper | Meaning |
|---|---|
| `width`, `height` | The logical room: 1280 × 720. The stage is 80rem × 45rem, so **1rem = 16 logical px**. Place anything at `left: x/16 rem; top: y/16 rem`. |
| `floorY` | 708, the y of the player's feet: the front edge of the painted floor, in front of all the furniture (v1.4; it was 650). |
| `minX`, `maxX` | 72 and 1208, the bounds of the player's x. |
| `startX` | 160. The player starts here, facing right, on a new game, on entering a diary and on returning to the present. |
| `interactionDistance` | 64. A hotspot is in reach when the player's x is within 64 of the hotspot's x. |
| `walkSpeed`, `maxFrameDelta` | 300 px per second; frame deltas above 50 ms count as 50 ms. |
| `position hotspot` | `{ x, y }`. `x` is where the player stands to use it; `y` is the height of the object (for its highlight and prompt). |
| `hotspots model.phase` | The hotspots usable in this phase, left to right. Draw these as clickable. Empty means no walking in this phase. |
| `nearby model` | `Maybe Hotspot`: what E would use right now. Use it for the proximity prompt ("E: Look at the notice"). `Nothing` while walking is paused. |
| `canWalk model` | False while a panel, a clue, a notice or first-attempt feedback is open, and in phases without hotspots (narration, transitions, endings). |
| `hasPanel model.phase` | True for the five puzzle phases, whose station hotspot opens a panel. |

### Coordinates (logical px)

Taken from the room pictures in `public/assets` so the hotspots sit on the furniture: the door on the left, the till and counter, the cork board under the window, the right-hand bookcase and the photograph on the right wall.

| Phase | Hotspot (left to right) | x | y | Object |
|---|---|---:|---:|---|
| `Introduction PackingUp` | `ClueSpot ClosureNotice` | 100 | 540 | notice on the door |
| | `BoxSpot` | 470 | 625 | box beneath the counter |
| | `ClueSpot FamilyPhotograph` | 1200 | 315 | photograph on the right wall |
| `PresentHub` | `ClueSpot (HubProp OrderDesk)` | 235 | 410 | the till end of the counter |
| | `DiarySpot` | 430 | 465 | the diaries on the counter |
| | `ClueSpot (HubProp CommunityWall)` | 640 | 555 | cork board under the window |
| | `ClueSpot (HubProp RoofAndShelves)` | 880 | 180 | right-hand bookcase and ceiling |
| `Salvage` | `CratesSpot` | 400 | 615 | the book crates on the floor |
| `RepairBoard` | `ClueSpot GlassDeliverySlip` | 100 | 420 | slip pinned by the door |
| | `ClueSpot BudgetAllocation` | 235 | 410 | at the till |
| | `ClueSpot WalterDiaryPage` | 430 | 465 | diary on the counter |
| | `BoardSpot` | 640 | 555 | the planning board (the cork board) |
| | `ClueSpot RubbleAndShelvesNote` | 820 | 560 | note by the rubble pile |
| `ReopeningShelf` | `ShelfSpot` | 980 | 300 | the right-hand bookcase |
| `ShadowPuzzle` | `ClueSpot CutoutBox` | 170 | 610 | box of cut-outs on the floor |
| | `ClueSpot ShadowScript` | 330 | 465 | script on the counter |
| | `StageSpot` | 640 | 380 | sheet hung across the window |
| | `ClueSpot StageSketch` | 840 | 560 | sketch pinned by the bookcase |
| `BookMystery` | `ClueSpot RuthsEmail` | 240 | 410 | computer on the counter |
| | `ClueSpot InscriptionClue` | 440 | 465 | archive folder or printed email |
| | `BookTableSpot` | 820 | 590 | the four candidate books |
| | `ClueSpot RememberedSentence` | 1180 | 560 | Edwin's journal by the lamp |

All other phases have no hotspots. Usable hotspots are always more than 128 px apart, so reach zones never overlap. The 1950 rubble overlay already sits around x 744–910, right where the rubble note is.

### For B: rendering and dispatch

- **Room phases** (a non-empty `hotspots model.phase`): draw the room, the player, and the listed hotspots at their positions. Clicking a hotspot sends **`ApproachHotspot hotspot`**, never `Inspect` directly: the player walks there and uses it on arrival (at once if already in reach). Show the prompt for `nearby model`.
- **Panels:** when `model.room.panelOpen` is True, draw the current phase's existing puzzle screen (`Views.Salvage`, `Views.RepairBoard`, `Views.Shelf`, and later the shadow and candidate screens) as an overlay with a close button sending **`ClosePanel`**. Closing keeps the arrangement, selection, inspected clues and attempts. `ClosePanel` is ignored while `ReviewingFirstMistake` is shown: the player presses Retry first.
- **Clue overlays** still come from `model.inspecting`, whether opened from the room or from inside a panel.
- **The player:** draw the feet at (`player.x`, `floorY`), mirrored when `FacingLeft`. Use the walk cycle while `player.walking`, the idle pose otherwise. One way to keep the legs in step at any frame rate is `pose = floor (player.x / 24) mod 4`. Who it is follows the phase's era: present-day Edwin, Walter (1950), Henry (1973) or young Edwin (1998).
- **Phase changes close the panel.** Solving salvage (`Advance` in the panel) leaves the player in the room with `BoardSpot` as the station. The shelving-day pause does the same with `ShelfSpot`. Submitting closes the board for the slideshow.
- **Room changes** follow the actual phase, slide and history, as `Views.Slideshow.stageAttributes` already does (`data-roof`, `data-rubble`, `data-weather`). Don't show the room repaired before the week does it.
- Keep showing transitions, slides, narration and endings as before; walking is paused there.
- Don't keep a second player position, a second hotspot map, or any timer of your own.

### Behaviour (implemented in `Update`, pure and tested)

`Main.elm` subscribes to keydown and keyup (A/D, the arrows and E; keydowns with Ctrl, Cmd or Alt are ignored), to animation frames only while the player is moving, and to the page being hidden. B never sends the key, frame or visibility messages.

| Input | Effect |
|---|---|
| A or ← / D or → held | Walk at 300 px/s, facing that way; the most recent key wins. Stops exactly at 72 or 1208. Releasing stops at once. |
| E | Use `nearby model`, if any. |
| Click a hotspot (`ApproachHotspot`) | Use it at once if in reach, else walk to its x, stop exactly there, and use it. A walk key cancels the walk. |
| `AnimationFrame dt` | Moves by `walkSpeed × min dt 50 / 1000`. Ignored while walking is paused. |
| Open a panel, open a clue, show a notice or feedback, change phase, page hidden | Clears held keys and the walking target, and stops the player. |
| Enter a diary, return to the present, start again | The player goes back to x = 160, facing right. |

Walking never changes `history`, attempts, arrangements or the phase. Using a hotspot does exactly what the old button did (`Inspect`, `Advance`, `OpenNextDiary`) or opens the panel.

### For C

- **Prompt labels:** proposed `Content.Room.label : Hotspot -> String`, a short verb phrase for the prompt and the hotspot's accessible name, such as "Sort the salvaged books" for `CratesSpot`. Clue hotspots can reuse their clue titles, so only the seven other hotspots need words.
- **Character art:** one base paper-cutout human, two to four walk poses plus an idle pose, facing right (views mirror it), with era variants for present-day Edwin, Walter, Henry and young Edwin. Put the feet at the bottom centre of each image so it can stand on (`x`, `floorY`). The counter is about 165 px tall in the room, so a grown-up is roughly 290 px tall. Agree file names with B.
- **Room props** at the coordinates above: crates, timber and the planning board in 1950; torch, sheet and cut-out box in 1973; computer, book stacks and parcels in 1998.

## Fixtures (`src/Fixtures.elm`)

| Fixture | What it is |
|---|---|
| `initialModel` | A new game. |
| `repairBoardInProgress` | Three cards placed and "Patch the roof" selected. Spent is 3 timber and £6. |
| `repairBoardReady` | A complete valid week, not yet submitted. `Submit` succeeds. |
| `repairFirstAttemptFailed` | A complete wrong week, with first-attempt feedback open. It is exactly what `Submit` produces from that board, and its violations come from the real validator. |
| `repairBoard arrangement attempts` | The board in any state. |
| `boardFor week` | Turns a `WeekPlan` into a board arrangement. |
| `validWeek` / `wrongWeek` | Example `WeekPlan`s. |
| `repairsSucceeded` / `repairsFailed` | Resolved 1950 `ChapterRecord`s. |
| `hubAfterRepairs` | The present after a successful 1950. |
| `salvageWalking` | 1950 salvage in the room (v1.3): the player mid-walk to the crates, panel closed. |
| `repairBoardPanelOpen` | `repairBoardInProgress` with the player at the board and its panel open (v1.3). |
| `shadowOriginalScript` | A fresh 1973 stage after a successful 1950 (original script). Player at the stage, panel open. |
| `shadowRetelling` | A fresh 1973 stage after a failed 1950 (neighbours' retelling). Player at the stage, panel open. |
| `shadowFirstAttemptFailed` | `shadowOriginalScript` after performing the retelling's staging: first-attempt feedback open, all three scenes conflicting, stage kept. Only `Retry` works. |
| `mysteryFamilyArchive` | A fresh 1998 table after a successful 1973 (inscription from the family archive). Player at the books, panel open. |
| `mysteryFollowUpEmail` | A fresh 1998 table after a failed 1973 (inscription from Ruth's follow-up email). Player at the books, panel open. |
| `mysteryFirstAttemptFailed` | `mysteryFamilyArchive` after sending book B: first-attempt feedback open (the inscription does not match), B still chosen. Only `Retry` works. |
| `shadowsSucceeded` / `shadowsFailed` | Resolved 1973 records, after a successful 1950. |
| `stageFor staging` | Turns a `Staging` into a stage arrangement, like `boardFor`. |

The feedback fixtures are produced by the real `Submit`, and `tests/FixtureTests.elm` checks that every fixture derives the variant in its name. Send `ClosePanel` (or press its close button) to see the room behind a panel.

To preview a fixture, make two temporary edits in `src/Main.elm`, then reload the page while `npm start` is running:

```elm
import Fixtures                                           -- add next to the other imports

        { init = \_ -> ( Fixtures.shadowRetelling, Cmd.none )   -- instead of Update.init
```

Don't commit either edit: normal startup stays `Update.init`. Check with `git diff src/Main.elm` before committing.

## 1973 and 1998 validators (added in v1.3)

Both main puzzles are now playable through `Update`, with the same two-attempt flow as 1950. `Domain.elm` did not change for this.

### 1973 shadow story

- **Complete:** `Rules.Shadow.complete placement` gives `Just staging` only when all six slots hold the right kind of cut-out and each cut-out is used exactly once. Anything else is `IncompleteSubmission` and spends nothing.
- **Validate:** `Rules.Shadow.validate scriptVariant staging` returns one `SceneConflictsWithScript scene` per scene whose character or prop differs from the script, in scene order. The variant comes from `(Timeline.deriveWorld history).scriptVariant`: the original script after a successful 1950, the neighbours' retelling after a failed one.
- The scenes are numbered slots, so there are 3! × 3! = **36** complete stagings, not 216. Each variant accepts exactly one, and no staging passes under both. A wrong staging always conflicts in at least two scenes.
- **Success** plays `PerformanceSlide Scene1..3` with the performed cast. **Failure** plays `ConsequenceSlide Shadows1973 (SceneConflictsWithScript firstScene)`. Then `ReturningToPresent` and `PresentHub`, with the 1998 journal next.

### 1998 forgotten book

- **Complete:** a chosen candidate (`ChooseCandidate c`). Submitting with none chosen is `IncompleteSubmission`.
- **Validate:** `Rules.Mystery.validate candidate` returns one `DetailDoesNotMatch detail` per remembered detail the book lacks: B lacks `LucyInscription`, C lacks `LanternSentence`, D lacks `FoxLanternIllustration`, and A has all three. The answer doesn't depend on history; only the inscription clue's source does (`FamilyArchive` or `FollowUpEmail`).
- **Success** plays `ServiceFoundedSlide`. **Failure** plays `ConsequenceSlide Search1998 (DetailDoesNotMatch detail)`. Then `ReturningToPresent` goes straight to `Ending`, because all three chapters are resolved.

### For B

- `Views.Shop.unbuiltChapter` can now be replaced by real 1973 and 1998 panels. Submit ("Perform the story", "Send this book") and Retry work like "Finish week".
- Never call `Rules.Shadow.validate`, `Rules.Shadow.script`, `Rules.Mystery.validate` or `Rules.Mystery.matches` from a view: they are the answers. Correctness only exists after `Submit`, in `attempts` or the history record.
- `Rules.Shadow.complete arrangement /= Nothing` may be used to enable the submit button, as on the repair board.

### For C

- Every 1973 and 1998 violation can now reach `Content.Feedback.violation` and `Content.Slides.slide` (`ConsequenceSlide Shadows1973 (SceneConflictsWithScript scene)` for any scene, and `ConsequenceSlide Search1998 (DetailDoesNotMatch detail)` for any detail).
- `docs/test-examples-for-A.md` says there are 216 complete stagings. Please change it to 36: the scenes are fixed slots, so only the characters' order (3!) and the props' order (3!) vary. All the other examples matched the implementation exactly and are now tests.

## Time travel into a diary (added in v1.5)

"Step into [year]" on a diary's passage now plays a 2.5-second trip back in time before the chapter starts. The passage itself still waits for the player.

### State and messages

```elm
type Transition = OpeningDiary Era | TimeTravel Era Float | Slideshow Era Int | ReturningToPresent   -- TimeTravel is new
type Msg = ... | SkipTravel                                                                          -- new
```

- `TimeTravel era elapsed` is the trip into `era`, `elapsed` milliseconds in. It lives in the phase like every other screen, so it can't outlive the trip, and every trip starts at 0, including reopening the same era again.
- `Advance` on `OpeningDiary era` starts `TimeTravel era 0`. Nothing else starts a trip.
- `AnimationFrame dt` moves it on by `dt` clamped to 0–50 ms (a hidden tab coming back can't jump ahead). At 2500 ms the chapter starts by itself.
- `SkipTravel` starts the chapter at once. Skipping and finishing both go through `Update.arrive`, which is the old chapter entry (`startChapter era` in a fresh room), so they give exactly the same state.
- During the trip everything else is ignored: `Advance` (so a double click on "Step into" can't skip), walking, `E`, hotspots, `Inspect`, puzzle moves, `Submit`, `Retry`, diary actions. A second `SkipTravel`, and frames after arrival, do nothing to the chapter that started. History is never touched; reopening keeps the usual rewind (`ReopenDiary` rewinds, then the same passage and trip).
- `Main` asks for animation frames while walking or travelling (`Rules.Travel.wantsFrames`). It also ignores the browser's key auto-repeat now, so a key held through the trip (or a panel) doesn't start walking in the new room until it is pressed again.

### `Rules.Travel`

| Helper | Meaning |
|---|---|
| `duration`, `bookOpen`, `arrival` | 2500, 500 and 1800 ms: the book opens by 500, the destination is reached at 1800, the chapter starts at 2500. |
| `yearAt era elapsed` | The year on the open book: `Nothing` (the present) until the pages turn, then each year back in turn, then `Just era` from arrival. To 1950: Present, 1998, 1973, 1950. To 1973: Present, 1998, 1973. To 1998: Present, 1998. |
| `yearsBack era` | That whole list. |
| `hasArrived elapsed` | From 1800 ms: the room behind the book is the destination's starting room. |
| `isTravelling phase`, `wantsFrames model` | For views and `Main`. |

### The view (`Views.TimeTravel`, `public/styles.css`)

Made by A for this feature, in B's files, at the team's request; B is free to restyle it.

- One component for all three eras, drawn entirely from `elapsed`: no timers, CSS animations or view state. The shop darkens, and the diary (its existing cover picture) grows in the centre and opens. Paper pages (layered HTML shapes with perspective) turn back while a large faint clock spins backwards behind the book and warm light grows. The year counts back on the right-hand page, then stays while the book and light fade to reveal the room.
- **Rooms:** the passage is read in the present-day shop, and the trip shows it until 1800 ms. Then, under the brightest light, `View` swaps in exactly the room the chapter starts in (`startChapter era` with a fresh room), so the end of the trip runs straight into the chapter.
- A **Skip** button is visible the whole time. The overlay covers the stage and takes every click.
- **Reduced motion** (`prefers-reduced-motion: reduce`): no turning, spinning or growing. The shop darkens, the open diary shows the destination year, and it fades to the room.

`tests/TravelTests.elm` covers the timing, the clamp, Skip matching finishing, repeated clicks, ignored input, held keys, reopening and the year order.

## Release build

There are no `Debug.todo` stubs left, so the optimized build works. For the submission, run:

```
npm test
npm run release
```

`npm run release` compiles with `--optimize` and puts the whole game in `release/one-more-christmas/`: `index.html`, `elm.js`, `styles.css` and `assets/`. It then checks that every asset the page, the styles and the compiled Elm refer to is in the folder, and that every path is relative. It stops with a message if anything is missing.

- **Upload:** zip the *contents* of `release/one-more-christmas/`, so `index.html` is at the top of the zip (game hosts such as itch.io require this). Nothing else is needed: no server code, no network access while playing.
- **Play locally:** open `release/one-more-christmas/index.html` in a browser, or serve the folder with any static file server.
- **Why a separate folder:** `npm start` rebuilds `build/` as a debug build on every page load, so an optimized build left in `build/` can be silently replaced. `release/` is only written by `npm run release`.
- **Not yet checked:** opening `index.html` straight from disk was not tested in a desktop browser (the checks so far served the folder over HTTP). Check that once in Chrome, Firefox or Safari and on Windows before submitting.

## Open coordination items

1. **The 1973 and 1998 screens.** The walking room, player and 1950 panels are in (B, #21). The shadow stage and candidate-book panels still show `Views.Shop.unbuiltChapter`. Their rules, attempts and fixtures are ready: see the fixtures table.
2. **Audio.** There are no ports yet. If B wants sound, agree a port name (suggested: `port playSound : String -> Cmd msg`), and A will add it to `Main.elm`.
3. **The `svg-art` element in `public/index.html`** sets `innerHTML` from Art.elm strings. That goes beyond the brief's "startup and audio" JavaScript. The team should agree to keep it, or A can add `elm/svg` to `elm.json` instead.
4. **Keys and window focus.** Elm can see the page being hidden but not the window losing focus. If a key is held while switching to another window, the player keeps walking until the wall (where they stop) or until the key is pressed and released again. Hiding the tab clears it.
5. **Floor alignment (resolved in v1.4).** With the feet at 650, the painted armchair, lamp table, door and boxes (which stand at y 660–715) were nearer than the player, so #26 painted an opaque strip of boards over the bottom of every room from y 640. That hid the bottom of the furniture. Agreed fix, one coordinated change: `Rules.Room.floorY` is now 708, the front edge of the painted floor, so the player walks in front of everything and the strip is gone (`public/index.html`, `public/styles.css`). The sprite anchor is unchanged: (48, 152) at scale 2, drawn from `floorY` by `Components.Actor`. The walking hint (`room-bar`) moved from the floor to the ceiling at the top left, and the intro's top narration starts below it. The bottom narration box (intro narration screens, slides, return) still sits over the lower room; B may want to revisit that.
