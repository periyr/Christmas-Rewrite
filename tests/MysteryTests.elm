module MysteryTests exposing (suite)

{-| 1998 forgotten book: Rules.Mystery.validate for all four candidates (C's
expected examples), and the two-attempt flow through
Update into the ending.
-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Attempts as Attempts
import Rules.Mystery as Mystery
import Test exposing (Test, describe, test)
import Timeline
import Update


send : List Msg -> Model -> Model
send msgs model =
    List.foldl Update.update model msgs


record : Era -> Outcome -> ChapterRecord
record era outcome =
    { era = era
    , outcome = outcome
    , attemptsUsed = 1
    , finalSubmission =
        case era of
            Repairs1950 ->
                RepairWeek Fixtures.validWeek

            Shadows1973 ->
                ShadowPerformance
                    { scene1 = { character = Fox, prop = Lantern }
                    , scene2 = { character = Owl, prop = Key }
                    , scene3 = { character = Child, prop = Book }
                    }

            Search1998 ->
                SentBook CandidateA
    , finalViolations = []
    }


{-| The 1998 puzzle after 1950 and 1973, reached by playing on from the
present: open the next diary, step in, skip the trip.
-}
mysteryAfter : Outcome -> Outcome -> Model
mysteryAfter outcome1950 outcome1973 =
    send [ OpenNextDiary, Advance, SkipTravel ]
        { history = [ record Repairs1950 outcome1950, record Shadows1973 outcome1973 ]
        , runSeed = Fixtures.initialModel.runSeed
        , phase = PresentHub
        , inspecting = Nothing
        , notice = Nothing
        , room = Fixtures.initialModel.room
        }


attemptsOf : Model -> Maybe Attempts
attemptsOf model =
    case model.phase of
        BookMystery puzzle ->
            Just puzzle.attempts

        _ ->
            Nothing


suite : Test
suite =
    describe "1998 forgotten book"
        [ describe "C's expected examples"
            [ test "A (illustrated edition) matches every remembered detail" <|
                \_ -> Mystery.validate CandidateA |> Expect.equal []
            , test "B (school edition) has the wrong inscription" <|
                \_ -> Mystery.validate CandidateB |> Expect.equal [ DetailDoesNotMatch LucyInscription ]
            , test "C (River Stories) has a different passage" <|
                \_ -> Mystery.validate CandidateC |> Expect.equal [ DetailDoesNotMatch LanternSentence ]
            , test "D (plain edition) has a different illustration" <|
                \_ -> Mystery.validate CandidateD |> Expect.equal [ DetailDoesNotMatch FoxLanternIllustration ]
            ]
        , describe "the whole space"
            [ test "exactly one candidate is valid: A" <|
                \_ ->
                    List.filter (\c -> Mystery.validate c == []) Mystery.candidates
                        |> Expect.equal [ CandidateA ]
            , test "each wrong candidate fails exactly one detail" <|
                \_ ->
                    [ CandidateB, CandidateC, CandidateD ]
                        |> List.map (Mystery.validate >> List.length)
                        |> Expect.equal [ 1, 1, 1 ]
            , test "each detail rules out exactly one candidate, so all three clues are needed" <|
                \_ ->
                    Mystery.details
                        |> List.map (\detail -> List.filter (\c -> not (Mystery.matches c detail)) Mystery.candidates)
                        |> Expect.equal [ [ CandidateD ], [ CandidateC ], [ CandidateB ] ]
            , test "without any one clue, two books still fit" <|
                \_ ->
                    Mystery.details
                        |> List.map
                            (\dropped ->
                                Mystery.candidates
                                    |> List.filter
                                        (\c ->
                                            Mystery.details
                                                |> List.filter ((/=) dropped)
                                                |> List.all (Mystery.matches c)
                                        )
                                    |> List.length
                            )
                        |> Expect.equal [ 2, 2, 2 ]
            ]
        , describe "Send this book (one attempt, through Update)"
            [ test "A succeeds whichever source gave the inscription (1973 succeeded or failed)" <|
                \_ ->
                    [ ( Succeeded, Succeeded ), ( Succeeded, Failed ), ( Failed, Succeeded ), ( Failed, Failed ) ]
                        |> List.map
                            (\( a, b ) ->
                                let
                                    start =
                                        mysteryAfter a b
                                in
                                ( (Timeline.deriveWorld start.history).inscriptionSource
                                , send [ ChooseCandidate CandidateA, Submit ] start |> .history |> Timeline.outcomeOf Search1998
                                )
                            )
                        |> Expect.equal
                            [ ( FamilyArchive, Just Succeeded )
                            , ( FollowUpEmail, Just Succeeded )
                            , ( FamilyArchive, Just Succeeded )
                            , ( FollowUpEmail, Just Succeeded )
                            ]
            , test "sending nothing spends no attempt" <|
                \_ ->
                    let
                        after =
                            send [ Submit ] (mysteryAfter Succeeded Succeeded)
                    in
                    ( attemptsOf after, after.notice )
                        |> Expect.equal ( Just NoAttemptUsed, Just IncompleteSubmission )
            , test "a wrong book fails 1998 at once, recording the detail that does not match" <|
                \_ ->
                    send [ ChooseCandidate CandidateC, Submit ] (mysteryAfter Succeeded Succeeded)
                        |> .history
                        |> Timeline.recordFor Search1998
                        |> Expect.equal
                            (Just
                                { era = Search1998
                                , outcome = Failed
                                , attemptsUsed = 1
                                , finalSubmission = SentBook CandidateC
                                , finalViolations = [ DetailDoesNotMatch LanternSentence ]
                                }
                            )
            , test "after a wrong book there is no second try: the consequence slide plays" <|
                \_ ->
                    send [ ChooseCandidate CandidateB, Submit, Retry, ChooseCandidate CandidateA, Submit ] (mysteryAfter Succeeded Succeeded)
                        |> (\m -> ( m.phase, Timeline.outcomeOf Search1998 m.history ))
                        |> Expect.equal ( Transition (Slideshow Search1998 0), Just Failed )
            , test "every wrong book fails on its own detail" <|
                \_ ->
                    [ CandidateB, CandidateC, CandidateD ]
                        |> List.map (\c -> send [ ChooseCandidate c, Submit ] (mysteryAfter Succeeded Succeeded) |> .history |> Timeline.recordFor Search1998 |> Maybe.map .finalViolations)
                        |> Expect.equal
                            [ Just [ DetailDoesNotMatch LucyInscription ]
                            , Just [ DetailDoesNotMatch LanternSentence ]
                            , Just [ DetailDoesNotMatch FoxLanternIllustration ]
                            ]
            , test "choosing another book is ignored while the first mistake is shown" <|
                \_ ->
                    let
                        reviewing =
                            send [ ChooseCandidate CandidateB, Submit ] (mysteryAfter Succeeded Succeeded)
                    in
                    send [ ChooseCandidate CandidateA ] reviewing
                        |> Expect.equal reviewing
            , test "success founds the service; failure shows the unfinished opportunity" <|
                \_ ->
                    ( send [ ChooseCandidate CandidateA, Submit ] (mysteryAfter Succeeded Succeeded) |> .history |> Timeline.slides Search1998
                    , send [ ChooseCandidate CandidateB, Submit, Retry, Submit ] (mysteryAfter Succeeded Succeeded) |> .history |> Timeline.slides Search1998
                    )
                        |> Expect.equal
                            ( [ ServiceFoundedSlide ]
                            , [ ConsequenceSlide Search1998 (DetailDoesNotMatch LucyInscription) ]
                            )
            , test "all three succeeded: the slideshow ends at the saved shop" <|
                \_ ->
                    send [ ChooseCandidate CandidateA, Submit, Advance, SkipTravel, Advance ] (mysteryAfter Succeeded Succeeded)
                        |> (\m -> ( m.phase, Timeline.fate m.history ))
                        |> Expect.equal ( Ending, Just ShopSaved )
            , test "a failed 1998 after two successes closes the shop for that reason" <|
                \_ ->
                    send [ ChooseCandidate CandidateB, Submit, Retry, Submit, Advance, SkipTravel, Advance ] (mysteryAfter Succeeded Succeeded)
                        |> (\m -> ( m.phase, Timeline.fate m.history ))
                        |> Expect.equal ( Ending, Just (ShopClosed [ Search1998 ]) )
            ]
        ]
