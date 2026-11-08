module Fixtures exposing
    ( initialModel
    , repairBoardInProgress
    , repairBoard
    , repairBoardReady
    , repairFirstAttemptFailed
    , validWeek
    , wrongWeek
    , boardFor
    , repairsSucceeded
    , repairsFailed
    , hubAfterRepairs
    , salvageWalking
    , repairBoardPanelOpen
    , shadowOriginalScript
    , shadowRetelling
    , shadowFirstAttemptFailed
    , stageFor
    , shadowsSucceeded
    , shadowsFailed
    , mysteryFamilyArchive
    , mysteryFollowUpEmail
    , mysteryFirstAttemptFailed
    )

{-| Development fixtures for building views and tests against the contract.

These are example states, not story data: all words live in Content/*.
To preview one, temporarily start Main from it instead of Update.init.

-}

import Domain exposing (..)
import Rules.Repair
import Rules.Room
import Rules.Shadow
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
    , runSeed = initialModel.runSeed
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
    , room = Rules.Room.initialRoom
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


{-| What the validator reports for wrongWeek, in its order: the roof is too
late, the window is never sealed, and timber is overspent (1 + 2 + 2 = 5 of 4).
Computed, not hand-written, so it always matches Rules.Repair.validate.
-}
wrongWeekViolations : List Violation
wrongWeekViolations =
    Rules.Repair.validate wrongWeek


{-| The board arrangement for a complete week: days in order, the two
deferred cards in NotThisWeek 1 and 2.
-}
boardFor : WeekPlan -> Placement TaskId RepairSlot
boardFor week =
    { placed =
        List.map (\day -> ( Rules.Repair.taskOn day week, OnDay day )) Rules.Repair.days
            ++ List.map2 (\task n -> ( task, NotThisWeek n )) week.notThisWeek [ 1, 2 ]
    , selected = Nothing
    }


{-| The 1950 repair board with any arrangement and attempt state
(all four clues already inspected, no history).
-}
repairBoard : Placement TaskId RepairSlot -> Attempts -> Model
repairBoard arrangement attempts =
    { history = []
    , runSeed = initialModel.runSeed
    , phase =
        RepairBoard
            { arrangement = arrangement
            , inspected = [ WalterDiaryPage, GlassDeliverySlip, RubbleAndShelvesNote, BudgetAllocation ]
            , attempts = attempts
            }
    , inspecting = Nothing
    , notice = Nothing
    , room = Rules.Room.initialRoom
    }


{-| A complete, valid week (validWeek) that has not been submitted yet.
Submit leads to success and the week slideshow.
-}
repairBoardReady : Model
repairBoardReady =
    repairBoard (boardFor validWeek) NoAttemptUsed


{-| The board just after the first wrong "Finish week": feedback is open,
the arrangement is kept, Submit is ignored until Retry.
-}
repairFirstAttemptFailed : Model
repairFirstAttemptFailed =
    repairBoard (boardFor wrongWeek) (ReviewingFirstMistake wrongWeekViolations)


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
    , runSeed = initialModel.runSeed
    , phase = PresentHub
    , inspecting = Nothing
    , notice = Nothing
    , room = Rules.Room.initialRoom
    }


{-| The start of 1950 in the room: salvage not opened yet, the player
mid-walk to the crates after clicking them (contract v1.3).
-}
salvageWalking : Model
salvageWalking =
    { history = []
    , runSeed = initialModel.runSeed
    , phase = Salvage { placed = [], selected = Nothing }
    , inspecting = Nothing
    , notice = Nothing
    , room =
        { player = { x = 300, facing = FacingRight, walking = True, held = [], target = Just CratesSpot }
        , panelOpen = False
        }
    }


{-| repairBoardInProgress with the player standing at the board and its
panel open (contract v1.3).
-}
repairBoardPanelOpen : Model
repairBoardPanelOpen =
    { repairBoardInProgress
        | room =
            { player = { x = 640, facing = FacingRight, walking = False, held = [], target = Nothing }
            , panelOpen = True
            }
    }



-- 1973 AND 1998
--
-- Each puzzle fixture has the player standing at the puzzle's station with
-- its panel open, so the screen shows at once. ClosePanel shows the room.
-- The history before it is real, so Timeline.deriveWorld gives the variant
-- named in the fixture.


{-| A puzzle phase in the room: the player at `station`, its panel open. -}
atStation : Hotspot -> History -> Phase -> Model
atStation station history phase =
    let
        player =
            Rules.Room.initialPlayer
    in
    { history = history
    , runSeed = initialModel.runSeed
    , phase = phase
    , inspecting = Nothing
    , notice = Nothing
    , room = { player = { player | x = (Rules.Room.position station).x }, panelOpen = True }
    }


{-| The stage arrangement for a complete staging: each scene's character and
prop in that scene's two slots.
-}
stageFor : Staging -> Placement Cutout ShadowSlot
stageFor staging =
    { placed =
        List.concatMap
            (\( scene, cast ) -> [ ( CharacterCutout cast.character, CharacterSlot scene ), ( PropCutout cast.prop, PropSlot scene ) ])
            [ ( Scene1, staging.scene1 ), ( Scene2, staging.scene2 ), ( Scene3, staging.scene3 ) ]
    , selected = Nothing
    }


{-| A fresh 1973 stage after a successful 1950: the original script
(Fox + Lantern, Owl + Key, Child + Book). Nothing placed, two attempts.
-}
shadowOriginalScript : Model
shadowOriginalScript =
    atStation StageSpot [ repairsSucceeded ] (Update.startChapter Shadows1973)


{-| A fresh 1973 stage after a failed 1950: the neighbours' retelling
(Child + Key, Owl + Book, Fox + Lantern). Nothing placed, two attempts.
-}
shadowRetelling : Model
shadowRetelling =
    atStation StageSpot [ repairsFailed ] (Update.startChapter Shadows1973)


{-| shadowOriginalScript after performing the retelling's staging by mistake:
first-attempt feedback is open (every scene conflicts), the stage is kept,
and only Retry is possible. Produced by the real Submit.
-}
shadowFirstAttemptFailed : Model
shadowFirstAttemptFailed =
    Update.update Submit (withStage (Rules.Shadow.script NeighboursRetelling) shadowOriginalScript)


withStage : Staging -> Model -> Model
withStage staging model =
    case model.phase of
        ShadowPuzzle puzzle ->
            { model | phase = ShadowPuzzle { puzzle | arrangement = stageFor staging } }

        _ ->
            model


{-| 1973 performed correctly (original script, after a successful 1950). -}
shadowsSucceeded : ChapterRecord
shadowsSucceeded =
    { era = Shadows1973
    , outcome = Succeeded
    , attemptsUsed = 1
    , finalSubmission = ShadowPerformance (Rules.Shadow.script OriginalScript)
    , finalViolations = []
    }


{-| 1973 failed after a successful 1950: the retelling's staging performed
twice under the original script.
-}
shadowsFailed : ChapterRecord
shadowsFailed =
    { era = Shadows1973
    , outcome = Failed
    , attemptsUsed = 2
    , finalSubmission = ShadowPerformance (Rules.Shadow.script NeighboursRetelling)
    , finalViolations = Rules.Shadow.validate OriginalScript (Rules.Shadow.script NeighboursRetelling)
    }


{-| A fresh 1998 table after a successful 1973: the inscription clue comes
from the family archive. No book chosen, two attempts.
-}
mysteryFamilyArchive : Model
mysteryFamilyArchive =
    atStation BookTableSpot [ repairsSucceeded, shadowsSucceeded ] (Update.startChapter Search1998)


{-| A fresh 1998 table after a failed 1973: the inscription clue comes from
Ruth's follow-up email. No book chosen, two attempts.
-}
mysteryFollowUpEmail : Model
mysteryFollowUpEmail =
    atStation BookTableSpot [ repairsSucceeded, shadowsFailed ] (Update.startChapter Search1998)


{-| mysteryFamilyArchive after sending candidate B (the school edition):
first-attempt feedback is open (the inscription does not match), the choice
is kept, and only Retry is possible. Produced by the real Submit.
-}
mysteryFirstAttemptFailed : Model
mysteryFirstAttemptFailed =
    mysteryFamilyArchive
        |> Update.update (ChooseCandidate CandidateB)
        |> Update.update Submit
