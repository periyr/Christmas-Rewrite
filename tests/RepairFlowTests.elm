module RepairFlowTests exposing (suite)

{-| The repair board's two-attempt submission flow through Update.update,
using the real validator.
-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Repair as Repair
import Test exposing (Test, describe, test)
import Timeline
import Update


attemptsOf : Model -> Maybe Attempts
attemptsOf model =
    case model.phase of
        RepairBoard puzzle ->
            Just puzzle.attempts

        _ ->
            Nothing


arrangementOf : Model -> Maybe (Placement TaskId RepairSlot)
arrangementOf model =
    case model.phase of
        RepairBoard puzzle ->
            Just puzzle.arrangement

        _ ->
            Nothing


send : List Msg -> Model -> Model
send msgs model =
    List.foldl Update.update model msgs


wrongBoard : Model
wrongBoard =
    Fixtures.repairBoard (Fixtures.boardFor Fixtures.wrongWeek) NoAttemptUsed


wrongViolations : List Violation
wrongViolations =
    Repair.validate Fixtures.wrongWeek


{-| From the wrong week to valid week 3 (Roof, Rubble, Glaze, Shelves, Books)
in two click-to-place swaps.
-}
fixTheWeek : List Msg
fixTheWeek =
    [ BoardMove (SelectItem PatchRoof)
    , BoardMove (PlaceSelected (OnDay Monday))
    , BoardMove (SelectItem ReglazeWindow)
    , BoardMove (PlaceSelected (OnDay Wednesday))
    ]


failedTwice : Model
failedTwice =
    send [ Submit, Retry, Submit ] wrongBoard


suite : Test
suite =
    describe "Repair board submission flow"
        [ describe "free actions"
            [ test "inspecting and moving cards spends no attempt" <|
                \_ ->
                    Fixtures.repairBoardInProgress
                        |> send
                            [ Inspect GlassDeliverySlip
                            , CloseInspection
                            , BoardMove (PlaceSelected (OnDay Tuesday))
                            , BoardMove (SelectItem ClearRubble)
                            , BoardMove (PlaceSelectedInGroup Repair.notThisWeekSlots)
                            ]
                        |> Expect.all
                            [ attemptsOf >> Expect.equal (Just NoAttemptUsed)
                            , .history >> Expect.equal []
                            ]
            , test "an incomplete submission spends no attempt" <|
                \_ ->
                    Fixtures.repairBoardInProgress
                        |> send [ Submit, Submit ]
                        |> Expect.all
                            [ attemptsOf >> Expect.equal (Just NoAttemptUsed)
                            , .notice >> Expect.equal (Just IncompleteSubmission)
                            , .history >> Expect.equal []
                            ]
            , test "an incomplete submission on the final attempt spends nothing either" <|
                \_ ->
                    Fixtures.repairFirstAttemptFailed
                        |> send [ Retry, BoardMove (SelectItem PatchRoof), BoardMove ReturnSelectedToTray, Submit ]
                        |> Expect.all
                            [ attemptsOf >> Expect.equal (Just (RetryingAfterMistake wrongViolations))
                            , .notice >> Expect.equal (Just IncompleteSubmission)
                            , .history >> Expect.equal []
                            ]
            ]
        , describe "first attempt"
            [ test "a wrong week shows its violations, keeps the arrangement and records nothing" <|
                \_ ->
                    Update.update Submit wrongBoard
                        |> Expect.equal Fixtures.repairFirstAttemptFailed
            , test "a double click on a wrong week spends only one attempt" <|
                \_ ->
                    send [ Submit, Submit ] wrongBoard
                        |> Expect.equal Fixtures.repairFirstAttemptFailed
            , test "Retry continues to the final attempt with the same arrangement" <|
                \_ ->
                    Update.update Retry Fixtures.repairFirstAttemptFailed
                        |> Expect.all
                            [ attemptsOf >> Expect.equal (Just (RetryingAfterMistake wrongViolations))
                            , arrangementOf >> Expect.equal (Just (Fixtures.boardFor Fixtures.wrongWeek))
                            ]
            , test "rearranging after the first failure keeps the attempt count" <|
                \_ ->
                    Fixtures.repairFirstAttemptFailed
                        |> send (Retry :: fixTheWeek)
                        |> Expect.all
                            [ attemptsOf >> Expect.equal (Just (RetryingAfterMistake wrongViolations))
                            , arrangementOf >> Maybe.andThen Repair.complete >> Maybe.map Repair.validate >> Expect.equal (Just [])
                            , .history >> Expect.equal []
                            ]
            , test "Retry does nothing when no feedback is open" <|
                \_ ->
                    Update.update Retry Fixtures.repairBoardReady
                        |> Expect.equal Fixtures.repairBoardReady
            ]
        , describe "resolution"
            [ test "a correct first submission succeeds and records one outcome" <|
                \_ ->
                    Update.update Submit Fixtures.repairBoardReady
                        |> Expect.all
                            [ .history >> Expect.equal [ Fixtures.repairsSucceeded ]
                            , .phase >> Expect.equal (Transition (Slideshow Repairs1950 0))
                            ]
            , test "a correct second submission succeeds with two attempts used" <|
                \_ ->
                    Fixtures.repairFirstAttemptFailed
                        |> send (Retry :: fixTheWeek ++ [ Submit ])
                        |> .history
                        |> List.map (\r -> ( r.era, r.outcome, r.attemptsUsed ))
                        |> Expect.equal [ ( Repairs1950, Succeeded, 2 ) ]
            , test "a second wrong submission fails the chapter with its final violations" <|
                \_ ->
                    failedTwice
                        |> Expect.all
                            [ .history >> Expect.equal [ Fixtures.repairsFailed ]
                            , .phase >> Expect.equal (Transition (Slideshow Repairs1950 0))
                            ]
            , test "a double click on a correct week records exactly one outcome" <|
                \_ ->
                    send [ Submit, Submit ] Fixtures.repairBoardReady
                        |> Expect.equal (Update.update Submit Fixtures.repairBoardReady)
            , test "submitting after the chapter is resolved changes nothing" <|
                \_ ->
                    send [ Submit, Retry, BoardMove (SelectItem PatchRoof) ] failedTwice
                        |> Expect.equal failedTwice
            ]
        , describe "what follows"
            [ test "success plays the submitted week day by day" <|
                \_ ->
                    Fixtures.repairBoardReady
                        |> send [ Submit, Advance, Advance, Advance ]
                        |> .phase
                        |> Expect.equal (Transition (Slideshow Repairs1950 3))
            , test "success pauses on the shelving day for the reopening shelf" <|
                \_ ->
                    Fixtures.repairBoardReady
                        |> send [ Submit, Advance, Advance, Advance, Advance ]
                        |> .phase
                        |> Expect.equal (ReopeningShelf { placed = [], selected = Nothing })
            , test "final failure shows the consequence, then returns to the present" <|
                \_ ->
                    let
                        slide =
                            List.head (Timeline.slides Repairs1950 failedTwice.history)

                        afterConsequence =
                            Update.update Advance failedTwice
                    in
                    ( slide
                    , afterConsequence.phase
                    , List.map .phase [ Update.update SkipTravel afterConsequence, send [ SkipTravel, Advance ] afterConsequence ]
                    )
                        |> Expect.equal
                            ( Just (ConsequenceSlide Repairs1950 (RoofAfterRain Wednesday))
                            , Transition (TearToPresent Repairs1950 0)
                            , [ Transition ReturningToPresent, PresentHub ]
                            )
            , test "after final failure the present shows missing premises and the retelling" <|
                \_ ->
                    Timeline.deriveWorld failedTwice.history
                        |> (\w -> ( w.premises, w.scriptVariant, w.nextDiary ))
                        |> Expect.equal ( Missing, NeighboursRetelling, Just Shadows1973 )
            ]
        ]
