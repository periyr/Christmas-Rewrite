module Fixtures exposing
    ( initialModel
    , repairBoardInProgress
    , repairFirstAttemptFailed
    , validWeek
    , wrongWeek
    , repairsSucceeded
    , repairsFailed
    , hubAfterRepairs
    )

{-| Development fixtures for building views and tests against the contract.

These are example states, not story data: all words live in Content/*.
To preview one, temporarily start Main from it instead of Update.init.

-}

import Domain exposing (..)
import Update


{-| A brand-new game: introduction, no history. -}
initialModel : Model
initialModel =
    Update.init


{-| 1950 repair board mid-plan. Rubble Monday, sign Tuesday, shelves
Wednesday; "Patch the roof" is picked up (selected) but not yet placed.
Rules.Repair.spent gives 3 timber and £6; remaining 1 timber and £4.
-}
repairBoardInProgress : Model
repairBoardInProgress =
    { history = []
    , phase =
        RepairBoard
            { arrangement =
                { placed =
                    [ ( ClearRubble, OnDay Monday )
                    , ( PaintSign, OnDay Tuesday )
                    , ( BuildShelves, OnDay Wednesday )
                    ]
                , selected = Just PatchRoof
                }
            , inspected = [ WalterDiaryPage, BudgetAllocation ]
            , attempts = NoAttemptUsed
            }
    , inspecting = Nothing
    , notice = Nothing
    }


{-| A complete but wrong week: sign Monday, rubble Tuesday, roof Wednesday,
shelves Thursday, books Friday; glazing and boarding left out.
-}
wrongWeek : WeekPlan
wrongWeek =
    { monday = PaintSign
    , tuesday = ClearRubble
    , wednesday = PatchRoof
    , thursday = BuildShelves
    , friday = ShelveBooks
    , notThisWeek = [ ReglazeWindow, BoardUpWindow ]
    }


{-| Valid week 1 from the brief: Roof, Rubble, Shelves, Books, Glaze. -}
validWeek : WeekPlan
validWeek =
    { monday = PatchRoof
    , tuesday = ClearRubble
    , wednesday = BuildShelves
    , thursday = ShelveBooks
    , friday = ReglazeWindow
    , notThisWeek = [ PaintSign, BoardUpWindow ]
    }


{-| Hand-written violations for wrongWeek, following the brief: the roof is
too late, timber is overspent (1 + 2 + 2 = 5 of 4), and the window is
never sealed. (The real validator's exact list is the next Person A task.)
-}
wrongWeekViolations : List Violation
wrongWeekViolations =
    [ RoofAfterRain Wednesday
    , TimberOverspent 5
    , GoalMissing SealedWindow
    ]


{-| The board just after the first wrong "Finish week": feedback is open,
the arrangement is kept, Submit is ignored until Retry.
-}
repairFirstAttemptFailed : Model
repairFirstAttemptFailed =
    { history = []
    , phase =
        RepairBoard
            { arrangement =
                { placed =
                    [ ( PaintSign, OnDay Monday )
                    , ( ClearRubble, OnDay Tuesday )
                    , ( PatchRoof, OnDay Wednesday )
                    , ( BuildShelves, OnDay Thursday )
                    , ( ShelveBooks, OnDay Friday )
                    , ( ReglazeWindow, NotThisWeek 1 )
                    , ( BoardUpWindow, NotThisWeek 2 )
                    ]
                , selected = Nothing
                }
            , inspected = [ WalterDiaryPage, GlassDeliverySlip, RubbleAndShelvesNote, BudgetAllocation ]
            , attempts = ReviewingFirstMistake wrongWeekViolations
            }
    , inspecting = Nothing
    , notice = Nothing
    }


{-| 1950 resolved successfully on the first attempt with valid week 1. -}
repairsSucceeded : ChapterRecord
repairsSucceeded =
    { era = Repairs1950
    , outcome = Succeeded
    , attemptsUsed = 1
    , finalSubmission = RepairWeek validWeek
    , finalViolations = []
    }


{-| 1950 failed: wrongWeek submitted twice. -}
repairsFailed : ChapterRecord
repairsFailed =
    { era = Repairs1950
    , outcome = Failed
    , attemptsUsed = 2
    , finalSubmission = RepairWeek wrongWeek
    , finalViolations = wrongWeekViolations
    }


{-| Back in the present after a successful 1950; the 1973 diary is next. -}
hubAfterRepairs : Model
hubAfterRepairs =
    { history = [ repairsSucceeded ]
    , phase = PresentHub
    , inspecting = Nothing
    , notice = Nothing
    }
