module Domain exposing
    ( Era(..), Outcome(..), Foundation(..), ScriptVariant(..), InscriptionSource(..), ShopFate(..)
    , Day(..), TaskId(..), RepairSlot(..), WeekPlan, Resources, ReopeningGoal(..)
    , BookId(..), RecoverableBook(..), RuinedBook(..), Condition(..), CoverColour(..), Damage(..), SalvageSlot(..)
    , ShelfSlot(..), ShelfOrder(..)
    , Character(..), Prop(..), Cutout(..), Scene(..), ShadowSlot(..), SceneCast, Staging
    , CandidateId(..), BookTab(..), RememberedDetail(..)
    , ClueId(..), HubProp(..)
    , Placement, PlacementAction(..), Notice(..)
    , Violation(..), Attempts(..), MainPuzzle
    , FinalSubmission(..), ChapterRecord, History, World
    , IntroStep(..), Transition(..), Slide(..), Phase(..), Model
    , Msg(..)
    , Document, TaskCardContent, BookContent, CandidateContent, ShadowSceneContent
    )

{-| The shared contract for One More Christmas.

Every module (rules, update, views, content) imports this one. It imports
nothing from the project, so there can be no import cycles.

Identifiers are custom types, never visible text. Content (Person C) maps these
IDs to words; views (Person B) render them; rules (Person A) judge them.

Changing anything here is a coordinated change: tell the team first.

-}

-- ═══════════════════════════════════════════════════════════════════════
-- ERAS, OUTCOMES, DERIVED WORLD
-- ═══════════════════════════════════════════════════════════════════════


{-| The three diaries, in play order. -}
type Era
    = Repairs1950
    | Shadows1973
    | Search1998


{-| How a main chapter was resolved. Only main puzzles have outcomes. -}
type Outcome
    = Succeeded
    | Failed


{-| One lasting foundation of the shop, as seen in the present.
NotRevisited means that diary has not been resolved in this run, so the
present shows the original, closing-down history.
-}
type Foundation
    = NotRevisited
    | Established
    | Missing


{-| 1973 script: original if 1950 succeeded, neighbours' retelling otherwise. -}
type ScriptVariant
    = OriginalScript
    | NeighboursRetelling


{-| 1998 inscription clue source: family/event archive if 1973 succeeded,
a follow-up email from Ruth otherwise.
-}
type InscriptionSource
    = FamilyArchive
    | FollowUpEmail


{-| The ending. ShopClosed lists the failed eras (the missing foundations),
in era order, never empty.
-}
type ShopFate
    = ShopSaved
    | ShopClosed (List Era)



-- ═══════════════════════════════════════════════════════════════════════
-- 1950 · REPAIR BOARD (main puzzle)
-- ═══════════════════════════════════════════════════════════════════════


type Day
    = Monday
    | Tuesday
    | Wednesday
    | Thursday
    | Friday


type TaskId
    = PatchRoof
    | ClearRubble
    | BuildShelves
    | ShelveBooks
    | ReglazeWindow
    | PaintSign
    | BoardUpWindow


{-| Where a task card can sit. Every slot holds at most one card.
"Not this week" is two slots: NotThisWeek 1 and NotThisWeek 2.
Cards not in any slot are in the tray.
-}
type RepairSlot
    = OnDay Day
    | NotThisWeek Int


{-| A complete week: one card per day plus the two cards left out.
Only produced from a complete board; this is what gets validated and recorded.
-}
type alias WeekPlan =
    { monday : TaskId
    , tuesday : TaskId
    , wednesday : TaskId
    , thursday : TaskId
    , friday : TaskId
    , notThisWeek : List TaskId
    }


{-| Timber planks and pounds. Used for costs, budget, spent and remaining. -}
type alias Resources =
    { timber : Int
    , pounds : Int
    }


type ReopeningGoal
    = WatertightRoof
    | SealedWindow
    | UsableShelves
    | AllBooksShelved



-- ═══════════════════════════════════════════════════════════════════════
-- 1950 · SALVAGE (warm-up) AND REOPENING SHELF (celebration)
-- ═══════════════════════════════════════════════════════════════════════


{-| The nine salvage books. The six recoverable ones go on the reopening shelf. -}
type BookId
    = Recoverable RecoverableBook
    | Ruined RuinedBook


type RecoverableBook
    = AtlasOfSmallPlaces
    | BirdsongForBeginners
    | GardensInWinter
    | LettersFromTheSea
    | PocketOfWonders
    | WinterTales


type RuinedBook
    = HarbourTales
    | MountainPaths
    | WinterAlmanac


{-| Book condition, also the three salvage crates. -}
type Condition
    = Fine
    | NeedsRepair
    | TooFarGone


{-| Base cover colours, in the shelf's rainbow guide order. -}
type CoverColour
    = Red
    | Orange
    | Yellow
    | Green
    | Blue
    | Violet


{-| Visible damage marks, drawn separately from the cover colour. -}
type Damage
    = ScorchedEdges
    | WaterStains
    | SmokeStains
    | MissingPages


{-| A space inside a crate: InCrate Fine 1 … InCrate Fine 3, etc. -}
type SalvageSlot
    = InCrate Condition Int


{-| Shelf positions 1–6, left to right. -}
type ShelfSlot
    = ShelfPosition Int


{-| The three accepted shelf orders (plaque: small to tall / rainbow / A–Z). -}
type ShelfOrder
    = ByHeight
    | ByColour
    | Alphabetical



-- ═══════════════════════════════════════════════════════════════════════
-- 1973 · SHADOW STORY (main puzzle)
-- ═══════════════════════════════════════════════════════════════════════


type Character
    = Fox
    | Owl
    | Child


type Prop
    = Lantern
    | Key
    | Book


type Cutout
    = CharacterCutout Character
    | PropCutout Prop


type Scene
    = Scene1
    | Scene2
    | Scene3


{-| Each scene panel has one character slot and one prop slot. -}
type ShadowSlot
    = CharacterSlot Scene
    | PropSlot Scene


type alias SceneCast =
    { character : Character
    , prop : Prop
    }


{-| A complete stage: what gets validated and recorded. -}
type alias Staging =
    { scene1 : SceneCast
    , scene2 : SceneCast
    , scene3 : SceneCast
    }



-- ═══════════════════════════════════════════════════════════════════════
-- 1998 · FORGOTTEN BOOK (main puzzle)
-- ═══════════════════════════════════════════════════════════════════════


type CandidateId
    = CandidateA
    | CandidateB
    | CandidateC
    | CandidateD


{-| Tabs for inspecting a physical book. -}
type BookTab
    = CoverTab
    | TextTab
    | DedicationTab


{-| The three facts Ruth's request depends on. -}
type RememberedDetail
    = FoxLanternIllustration
    | LanternSentence
    | LucyInscription



-- ═══════════════════════════════════════════════════════════════════════
-- INSPECTABLE CLUES
-- ═══════════════════════════════════════════════════════════════════════


{-| Everything the player can open and read. The text for a clue may vary
with the derived World (e.g. ShadowScript under either ScriptVariant).
-}
type ClueId
    = -- Introduction
      ClosureNotice
    | FamilyPhotograph
      -- Present hub
    | HubProp HubProp
      -- 1950 repair board
    | WalterDiaryPage
    | GlassDeliverySlip
    | RubbleAndShelvesNote
    | BudgetAllocation
      -- 1950 reopening shelf
    | ShelfPlaque
      -- 1973
    | ShadowScript
    | StageSketch
    | CutoutBox
      -- 1998
    | RuthsEmail
    | RememberedSentence
    | InscriptionClue
    | CandidatePage CandidateId BookTab


{-| Present-day props whose appearance comes from the World.
RoofAndShelves: 1950 · CommunityWall: 1973 · OrderDesk: 1998.
-}
type HubProp
    = RoofAndShelves
    | CommunityWall
    | OrderDesk



-- ═══════════════════════════════════════════════════════════════════════
-- PLACEMENT (shared by salvage, repair board, shelf, shadow stage)
-- ═══════════════════════════════════════════════════════════════════════


{-| Item IDs mapped to slot IDs. Each item appears at most once, each slot
holds at most one item. Items not listed are in the tray.
`selected` is the item picked up by the first click.
-}
type alias Placement item slot =
    { placed : List ( item, slot )
    , selected : Maybe item
    }


{-| Click-to-select, click-to-place.

  - SelectItem: pick up an item (tray or slot). Same item again deselects.
  - PlaceSelected slot: put it there. Occupied slot: swap if the item came
    from a slot, or send the occupant back to the tray if it came from the tray.
  - PlaceSelectedInGroup slots: put it in the first free slot of a group
    (a crate, or "Not this week"). Full group: neutral TargetFull notice.
  - ReturnSelectedToTray, ClearSelection: as named.

-}
type PlacementAction item slot
    = SelectItem item
    | PlaceSelected slot
    | PlaceSelectedInGroup (List slot)
    | ReturnSelectedToTray
    | ClearSelection


{-| Neutral messages. They never spend attempts, and the main-puzzle ones
never reveal correctness.

  - IncompleteSubmission: Submit on a main puzzle with cards/cut-outs/choice missing.
  - TargetFull: the clicked group (crate, "Not this week") has no free space.
  - DoesNotFitThere: that kind of item cannot go in that slot.
  - NotSolvedYet: Advance in a warm-up (salvage or reopening shelf) before it
    is solved. The player stays and keeps correcting. (Added in contract v1.2.)

-}
type Notice
    = IncompleteSubmission
    | TargetFull
    | DoesNotFitThere
    | NotSolvedYet



-- ═══════════════════════════════════════════════════════════════════════
-- VALIDATION, ATTEMPTS, RECORDS
-- ═══════════════════════════════════════════════════════════════════════


{-| Rule violations of a complete main-puzzle submission.
Shown only after a submission. Friendly text comes from content.

  - RoofAfterRain day: roof scheduled on `day` (Wednesday or later).
  - GlassNotYetDelivered day: glazing scheduled on `day` (before Wednesday).
  - MustComeBefore first second: prerequisite arrow broken; `first` must be
    scheduled on an earlier day than `second`.
  - TimberOverspent n / MoneyOverspent n: `n` is the total the plan spends.
  - GoalMissing goal: a visible reopening goal is not met.
  - SceneConflictsWithScript scene: that panel disagrees with the script.
  - DetailDoesNotMatch detail: the chosen book lacks that remembered detail.

-}
type Violation
    = -- 1950
      RoofAfterRain Day
    | GlassNotYetDelivered Day
    | MustComeBefore TaskId TaskId
    | TimberOverspent Int
    | MoneyOverspent Int
    | GoalMissing ReopeningGoal
      -- 1973
    | SceneConflictsWithScript Scene
      -- 1998
    | DetailDoesNotMatch RememberedDetail


{-| Attempts for the main puzzle currently being played (two in total).

  - NoAttemptUsed: editing, first attempt available.
  - ReviewingFirstMistake: first submission was wrong; its violations are
    shown and Submit is ignored until Retry.
  - RetryingAfterMistake: editing again for the final attempt; the earlier
    violations are kept for reference.

A second wrong or any correct submission leaves the puzzle and is stored in
History as a ChapterRecord instead.

-}
type Attempts
    = NoAttemptUsed
    | ReviewingFirstMistake (List Violation)
    | RetryingAfterMistake (List Violation)


{-| State of a main puzzle in progress. Cleared completely by leaving the
chapter or by rewinding.
-}
type alias MainPuzzle arrangement =
    { arrangement : arrangement
    , inspected : List ClueId
    , attempts : Attempts
    }


type FinalSubmission
    = RepairWeek WeekPlan
    | ShadowPerformance Staging
    | SentBook CandidateId


{-| One resolved main chapter. Created only by Update, once per chapter. -}
type alias ChapterRecord =
    { era : Era
    , outcome : Outcome
    , attemptsUsed : Int
    , finalSubmission : FinalSubmission
    , finalViolations : List Violation
    }


{-| Resolved chapters in era order (1950 first). The only source of progress. -}
type alias History =
    List ChapterRecord


{-| Everything derived from History (see Timeline.deriveWorld).
Never stored in the Model.
-}
type alias World =
    { premises : Foundation
    , tradition : Foundation
    , onlineService : Foundation
    , scriptVariant : ScriptVariant
    , inscriptionSource : InscriptionSource
    , nextDiary : Maybe Era
    , fate : Maybe ShopFate
    }



-- ═══════════════════════════════════════════════════════════════════════
-- PHASES AND MODEL
-- ═══════════════════════════════════════════════════════════════════════


type IntroStep
    = PackingUp
    | DiariesFound
    | ClockStopped


type Transition
    = OpeningDiary Era
    | Slideshow Era Int
    | ReturningToPresent


{-| Slideshow frames, generated from the latest ChapterRecord
(see Timeline.slides). Text comes from content.
-}
type Slide
    = WeekdaySlide Day TaskId
    | ReopeningSaturday
    | PerformanceSlide Scene SceneCast
    | ServiceFoundedSlide
    | ConsequenceSlide Era Violation


{-| Where the player is. Puzzle phases carry their own working state, so
that state cannot outlive the phase.
-}
type Phase
    = Introduction IntroStep
    | PresentHub
    | Salvage (Placement BookId SalvageSlot)
    | RepairBoard (MainPuzzle (Placement TaskId RepairSlot))
    | ReopeningShelf (Placement RecoverableBook ShelfSlot)
    | ShadowPuzzle (MainPuzzle (Placement Cutout ShadowSlot))
    | BookMystery (MainPuzzle (Maybe CandidateId))
    | Transition Transition
    | Ending


type alias Model =
    { history : History
    , phase : Phase
    , inspecting : Maybe ClueId
    , notice : Maybe Notice
    }



-- ═══════════════════════════════════════════════════════════════════════
-- ACTIONS
-- ═══════════════════════════════════════════════════════════════════════


type Msg
    = Inspect ClueId
    | CloseInspection
    | DismissNotice
    | SalvageMove (PlacementAction BookId SalvageSlot)
    | BoardMove (PlacementAction TaskId RepairSlot)
    | ShelfMove (PlacementAction RecoverableBook ShelfSlot)
    | StageMove (PlacementAction Cutout ShadowSlot)
    | ChooseCandidate CandidateId
    | Submit
    | Retry
    | Advance
    | OpenNextDiary
    | ReopenDiary Era
    | StartAgain



-- ═══════════════════════════════════════════════════════════════════════
-- CONTENT RECORDS (populated by Person C, rendered by Person B)
-- ═══════════════════════════════════════════════════════════════════════


{-| Any readable text: clues, diary pages, letters, slides, ending text. -}
type alias Document =
    { title : String
    , paragraphs : List String
    }


{-| Words on a repair task card. The cost is not here: it is rule data
(Rules.Repair.cost) so the numbers can never disagree.
-}
type alias TaskCardContent =
    { title : String
    , note : String
    }


{-| A salvage book's title and visible damage. -}
type alias BookContent =
    { title : String
    , damage : List Damage
    }


{-| A 1998 candidate book: label plus the text of each inspection tab. -}
type alias CandidateContent =
    { label : String
    , cover : String
    , text : String
    , dedication : String
    }


{-| A shadow stage panel's setting label and its performance caption. -}
type alias ShadowSceneContent =
    { setting : String
    , caption : String
    }
