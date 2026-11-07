module UpdateTests exposing (suite)

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Repair
import Test exposing (Test, describe, test)
import Update


boardOf : Model -> Maybe (MainPuzzle (Placement TaskId RepairSlot))
boardOf model =
    case model.phase of
        RepairBoard puzzle ->
            Just puzzle

        _ ->
            Nothing


endingAfterAll : Model
endingAfterAll =
    { history =
        [ Fixtures.repairsSucceeded
        , { era = Shadows1973
          , outcome = Failed
          , attemptsUsed = 2
          , finalSubmission =
                ShadowPerformance
                    { scene1 = { character = Owl, prop = Lantern }
                    , scene2 = { character = Fox, prop = Key }
                    , scene3 = { character = Child, prop = Book }
                    }
          , finalViolations = [ SceneConflictsWithScript Scene1, SceneConflictsWithScript Scene2 ]
          }
        , { era = Search1998
          , outcome = Succeeded
          , attemptsUsed = 1
          , finalSubmission = SentBook CandidateA
          , finalViolations = []
          }
        ]
    , phase = Ending
    , inspecting = Nothing
    , notice = Nothing
    }


suite : Test
suite =
    describe "Update"
        [ test "resource numbers update as cards are placed (plain arithmetic)" <|
            \_ ->
                Fixtures.repairBoardInProgress
                    |> Update.update (BoardMove (PlaceSelected (OnDay Thursday)))
                    |> boardOf
                    |> Maybe.map (.arrangement >> Rules.Repair.spent)
                    |> Expect.equal (Just { timber = 5, pounds = 6 })
        , test "remaining may go negative without any correctness judgement" <|
            \_ ->
                Fixtures.repairBoardInProgress
                    |> Update.update (BoardMove (PlaceSelected (OnDay Thursday)))
                    |> boardOf
                    |> Maybe.map (.arrangement >> Rules.Repair.remaining)
                    |> Expect.equal (Just { timber = -1, pounds = 4 })
        , test "incomplete Finish week shows a neutral notice and spends no attempt" <|
            \_ ->
                let
                    after =
                        Update.update Submit Fixtures.repairBoardInProgress
                in
                Expect.all
                    [ \m -> m.notice |> Expect.equal (Just IncompleteSubmission)
                    , \m -> boardOf m |> Maybe.map .attempts |> Expect.equal (Just NoAttemptUsed)
                    , \m -> m.history |> Expect.equal []
                    ]
                    after
        , test "Submit while first-attempt feedback is open changes nothing" <|
            \_ ->
                Update.update Submit Fixtures.repairFirstAttemptFailed
                    |> Expect.equal Fixtures.repairFirstAttemptFailed
        , test "cards cannot be moved while first-attempt feedback is open" <|
            \_ ->
                Fixtures.repairFirstAttemptFailed
                    |> Update.update (BoardMove (SelectItem PatchRoof))
                    |> Expect.equal Fixtures.repairFirstAttemptFailed
        , test "Retry keeps the arrangement and allows editing for the final attempt" <|
            \_ ->
                let
                    before =
                        boardOf Fixtures.repairFirstAttemptFailed

                    after =
                        boardOf (Update.update Retry Fixtures.repairFirstAttemptFailed)
                in
                Expect.all
                    [ \_ -> Maybe.map .arrangement after |> Expect.equal (Maybe.map .arrangement before)
                    , \_ ->
                        Maybe.map .attempts after
                            |> Expect.equal
                                (Maybe.map
                                    (\p ->
                                        case p.attempts of
                                            ReviewingFirstMistake vs ->
                                                RetryingAfterMistake vs

                                            other ->
                                                other
                                    )
                                    before
                                )
                    ]
                    ()
        , test "the hub opens the next unresolved diary" <|
            \_ ->
                (Update.update OpenNextDiary Fixtures.hubAfterRepairs).phase
                    |> Expect.equal (Transition (OpeningDiary Shadows1973))
        , test "reopening 1973 from the ending keeps 1950 and restarts 1973 fresh" <|
            \_ ->
                let
                    reopened =
                        endingAfterAll
                            |> Update.update (ReopenDiary Shadows1973)
                            |> Update.update Advance
                in
                Expect.all
                    [ \m -> m.history |> Expect.equal [ Fixtures.repairsSucceeded ]
                    , \m -> m.phase |> Expect.equal (Update.startChapter Shadows1973)
                    ]
                    reopened
        , test "replaying 1950 starts at salvage, not the introduction" <|
            \_ ->
                (endingAfterAll |> Update.update (ReopenDiary Repairs1950) |> Update.update Advance)
                    |> Expect.equal { endingAfterAll | history = [], phase = Update.startChapter Repairs1950 }
        , test "reopening a diary is only possible from the ending" <|
            \_ ->
                Update.update (ReopenDiary Repairs1950) Fixtures.hubAfterRepairs
                    |> Expect.equal Fixtures.hubAfterRepairs
        , test "inspecting a clue during a puzzle records it once" <|
            \_ ->
                Fixtures.repairBoardInProgress
                    |> Update.update (Inspect GlassDeliverySlip)
                    |> Update.update CloseInspection
                    |> Update.update (Inspect GlassDeliverySlip)
                    |> boardOf
                    |> Maybe.map .inspected
                    |> Expect.equal (Just [ WalterDiaryPage, BudgetAllocation, GlassDeliverySlip ])
        , test "the introduction advances to the 1950 diary" <|
            \_ ->
                Update.init
                    |> Update.update Advance
                    |> Update.update Advance
                    |> Update.update Advance
                    |> .phase
                    |> Expect.equal (Transition (OpeningDiary Repairs1950))
        ]
