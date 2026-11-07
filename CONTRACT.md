# Shared contract v1: Person A handoff

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
| `Introduction step` (`PackingUp`, `DiariesFound`, `ClockStopped`) | shop, notice, photo, box, diaries | `Inspect ClosureNotice`, `Inspect FamilyPhotograph`, `Advance` |
| `PresentHub` | the shop, built from `deriveWorld` (`premises`, `tradition`, `onlineService` are each `NotRevisited`, `Established` or `Missing`) | `Inspect (HubProp p)`, `OpenNextDiary` |
| `Transition (OpeningDiary era)` | page-turn into that diary | `Advance` |
| `Salvage placement` | 9 books, 3 crates of 3 spaces | `SalvageMove …`, then `Advance` once solved |
| `RepairBoard puzzle` | tray, Mon–Fri, two "Not this week" spaces, spent/remaining | `BoardMove …`, `Inspect` the four clues, `Submit` ("Finish week"), `Retry` |
| `Transition (Slideshow era i)` | slide `i` of `Timeline.slides era model.history` | `Advance` |
| `ReopeningShelf placement` | 6 positions, plaque | `ShelfMove …`, `Inspect ShelfPlaque`, then `Advance` once ordered |
| `ShadowPuzzle puzzle` | 3 panels, each with a character slot and a prop slot | `StageMove …`, `Inspect ShadowScript / StageSketch / CutoutBox`, `Submit` ("Perform the story"), `Retry` |
| `BookMystery puzzle` | 4 candidates, tabs | `Inspect (CandidatePage c tab)`, `Inspect RuthsEmail / RememberedSentence / InscriptionClue`, `ChooseCandidate c`, `Submit` ("Send this book"), `Retry` |
| `Transition ReturningToPresent` | room changing back | `Advance` |
| `Ending` | fate from `(deriveWorld history).fate`: `ShopSaved` or `ShopClosed failedEras` | `ReopenDiary era`, `StartAgain` |

In every phase, if `model.inspecting = Just clue`, show the overlay and dispatch `CloseInspection`. If `model.notice = Just n`, show neutral text and dispatch `DismissNotice` (it also clears on the next move).

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
Content.Feedback.notice    : Notice -> String
Content.Slides.slide       : World -> Slide -> Document
Content.Endings.saved      : Document
Content.Endings.missing    : Era -> Document                        -- one per missing foundation
```

The variants come from `World`. `scriptVariant` is `OriginalScript` or `NeighboursRetelling`, chosen by the 1950 outcome. `inscriptionSource` is `FamilyArchive` or `FollowUpEmail`, chosen by the 1973 outcome. Both variants must contain every clue needed to solve the puzzle.

The content record types are `Document { title, paragraphs }`, `TaskCardContent { title, note }`, `BookContent { title, damage }`, `CandidateContent { label, cover, text, dedication }` and `ShadowSceneContent { setting, caption }`.

## Fixtures (`src/Fixtures.elm`)

| Fixture | What it is |
|---|---|
| `initialModel` | A new game. |
| `repairBoardInProgress` | Three cards placed and "Patch the roof" selected. Spent is 3 timber and £6. |
| `repairFirstAttemptFailed` | A complete wrong week, with first-attempt feedback open. |
| `validWeek` / `wrongWeek` | Example `WeekPlan`s. |
| `repairsSucceeded` / `repairsFailed` | Resolved 1950 `ChapterRecord`s. |
| `hubAfterRepairs` | The present after a successful 1950. |

To preview a fixture, temporarily change `init` in `Main.elm` to `\_ -> ( Fixtures.repairBoardInProgress, Cmd.none )`. Don't commit that change.

## Not implemented yet (deliberate stubs)

These functions are `Debug.todo`. Calling one stops the running app, rather than pretending the feature works:

| Function | Planned for |
|---|---|
| `Rules.Repair.validate` | the next A task |
| `Rules.Shadow.validate`, `Rules.Mystery.validate` | hours 3.5–7 |
| `Rules.Salvage.misplaced`, `Rules.Salvage.isSolved`, `Rules.Shelf.matchedOrder` | hours 7–11 |

Until those land, a complete Submit, or Advance out of salvage or the shelf, crashes the preview. Placement, resource numbers, the incomplete-submission notice, history, rewind and endings all work now.

`npm run build -- --optimize` refuses to build while any `Debug` remains. This is intentional: a stub can't reach the release.

## Open coordination items

1. **Fixture violations are hand-written.** The exact list for `wrongWeek` (for example, whether a late roof also reports `GoalMissing WatertightRoof`) is fixed by the repair validator task. A will update the fixture to match, so B should not hard-code that list.
2. **Audio.** There are no ports yet. If B wants sound, agree a port name (suggested: `port playSound : String -> Cmd msg`), and A will add it to `Main.elm`.
3. **Content module names** above are a proposal. C confirms or renames them once, before B calls them.
4. **The brief file is named `one-more-christmas-shared-plan.md`.** There is no `GAME_PLAN.md`.
