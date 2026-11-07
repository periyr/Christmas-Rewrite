# Shared contract v1.2: Person A handoff

`one-more-christmas-shared-plan.md` is still the source of truth for the game. This file records the code contract that implements it. `src/Domain.elm` is the contract itself. Any change to it needs a short message to the team first. Nobody renames shared types or constructors on their own.

## Commands (Mac and Windows)

The only requirement is Node.js 18 or newer. Nothing needs to be installed globally.

| What | Command |
|---|---|
| Install (once, and after pulling a `package.json` change) | `npm install` |
| Live preview at http://localhost:8000 (reload the page to rebuild) | `npm start` |
| Build into `build/` (git-ignored) | `npm run build` |
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

`Model = { history, phase, inspecting, notice }`. **History** (`List ChapterRecord`, in era order) is the only stored progress. Everything else is derived by `Timeline.deriveWorld model.history`: the foundations, the 1973 script variant, the 1998 inscription source, the next diary, and the ending. **Phase** says where the player is. Puzzle phases carry their own working state, so rewinding or leaving a chapter discards it. `Update.update : Msg -> Model -> Model` is pure. Actions that don't fit the current phase are ignored, so double clicks are harmless.

## For B: the view

```elm
view : Model -> Html Msg          -- in src/View.elm
```

To wire it up, change `view = temporaryView` to `view = View.view` in `src/Main.elm` and delete the temporary screen. This one line in `Main.elm` is the agreed exception, so B can make it on B's branch.

`public/index.html` must load `elm.js` and call `Elm.Main.init({ node: document.getElementById("app") })`. Main uses `Browser.element` and takes no flags.

### What to render per phase, and which actions to send

| `model.phase` | Render | Dispatch |
|---|---|---|
| `Introduction step` (`PackingUp`, `DiariesFound`, `ClockStopped`) | shop, notice, photo, box, diaries | `Inspect ClosureNotice`, `Inspect FamilyPhotograph`, `Advance`. After `ClockStopped`, `Advance` goes to `PresentHub`. |
| `PresentHub` | the shop, built from `deriveWorld` (`premises`, `tradition`, `onlineService` are each `NotRevisited`, `Established` or `Missing`); the diary in `nextDiary` glows | `Inspect (HubProp p)`, `OpenNextDiary` |
| `Transition (OpeningDiary era)` | page-turn into that diary | `Advance` |
| `Salvage placement` | 9 books, 3 crates of 3 spaces, live misplaced marks | `SalvageMove …`, then `Advance` to continue (stays put with `NotSolvedYet` until solved) |
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
Introduction ×3 --Advance--> PresentHub --OpenNextDiary--> OpeningDiary Repairs1950 --Advance-->
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
| `Rules.Salvage.misplaced placement : List BookId` | Books sitting in the wrong crate, in `Rules.Books.allBooks` order. Books in the tray are not listed. Use this for the immediate per-book feedback. |
| `Rules.Salvage.isSolved placement : Bool` | All nine books placed, each exactly once, all in the right crates. Move order and the space used within a crate don't matter. |
| `Rules.Placement.inTray Rules.Books.allBooks placement` | Books still to sort. |
| `Rules.Salvage.crateSlots crate` | A crate's three spaces. Send `SalvageMove (PlaceSelectedInGroup (crateSlots crate))` when a crate is clicked. |
| `Rules.Shelf.matchedOrder placement : Maybe ShelfOrder` | `Just ByHeight`, `Just ByColour` or `Just Alphabetical` when the shelf is full and in one of the three orders. Otherwise `Nothing`. Use it to show the celebration as soon as an order matches. |

### Leaving the warm-ups

Send `Advance` for both. If the warm-up isn't solved yet, the phase and arrangement stay as they are, `model.notice = Just NotSolvedYet` is set, and nothing is spent. The next move clears the notice. Corrections are unlimited.

### For C

- **`Content.Feedback.notice NotSolvedYet`**: one gentle line that works for both salvage and the shelf, such as "Not quite yet – keep arranging."
- **`Content.Shelf.matched : ShelfOrder -> String`**: celebration text for each order.
- **`Content.Books.book`**: titles and damage marks for all nine `BookId`s. Condition must be visible without relying on cover colour.
- **`Content.Clues.clue ShelfPlaque`**: the plaque text ("Small to tall / rainbow / A–Z").
- **Hub props** (`HubProp`) and **diary passages**: with `NotRevisited` foundations, i.e. the present before 1950 is played.

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

To preview a fixture, temporarily change `init` in `Main.elm` to `\_ -> ( Fixtures.repairBoardInProgress, Cmd.none )`. Don't commit that change.

## Not implemented yet (deliberate stubs)

These functions are `Debug.todo`. Calling one stops the running app, rather than pretending the feature works:

| Function | Planned for |
|---|---|
| `Rules.Shadow.validate`, `Rules.Mystery.validate` | the next A task |

All 1950 rules are done: repair, salvage and shelf. Only a complete Submit on the 1973 or 1998 puzzle still stops the preview. Everything up to and including the return from 1950 works now, as do history, rewind and endings.

`npm run build -- --optimize` refuses to build while any `Debug` remains. This is intentional: a stub can't reach the release.

## Open coordination items

1. **No playable browser build yet.** The 1950 flow is verified through `Update` in tests. A browser playthrough needs B's `View.view` wired into `Main.elm` (salvage, board, slides, shelf) and C's content. The temporary screen in `Main.elm` only has Advance and Open-next-diary buttons.
2. **Audio.** There are no ports yet. If B wants sound, agree a port name (suggested: `port playSound : String -> Cmd msg`), and A will add it to `Main.elm`.
3. **Content module names** above are a proposal. C confirms or renames them once, before B calls them.
4. **The brief file is named `one-more-christmas-shared-plan.md`.** There is no `GAME_PLAN.md`.
