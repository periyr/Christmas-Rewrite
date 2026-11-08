module ReturnTests exposing (suite)

{-| The tear home after a chapter's last slide (contract v1.6), through
Update.update: it starts only from the last slide, runs on clamped animation
frames to the existing "Back to the present" narration, Skip lands in the same
state, everything else is ignored, and the hub, unlocking and endings that
follow are unchanged.
-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Travel as Travel
import Test exposing (Test, describe, test)
import Timeline
import Update


send : List Msg -> Model -> Model
send msgs model =
    List.foldl Update.update model msgs


frames : Int -> Float -> List Msg
frames n ms =
    List.repeat n (AnimationFrame ms)


search : Outcome -> ChapterRecord
search outcome =
    { era = Search1998
    , outcome = outcome
    , attemptsUsed = 2
    , finalSubmission =
        SentBook
            (if outcome == Succeeded then
                CandidateA

             else
                CandidateB
            )
    , finalViolations =
        if outcome == Succeeded then
            []

        else
            [ DetailDoesNotMatch LucyInscription ]
    }


{-| Each chapter just resolved, on either outcome: its history. -}
resolved : List ( String, Era, History )
resolved =
    [ ( "1950 succeeded", Repairs1950, [ Fixtures.repairsSucceeded ] )
    , ( "1950 failed", Repairs1950, [ Fixtures.repairsFailed ] )
    , ( "1973 succeeded", Shadows1973, [ Fixtures.repairsSucceeded, Fixtures.shadowsSucceeded ] )
    , ( "1973 failed", Shadows1973, [ Fixtures.repairsSucceeded, Fixtures.shadowsFailed ] )
    , ( "1998 succeeded", Search1998, [ Fixtures.repairsSucceeded, Fixtures.shadowsSucceeded, search Succeeded ] )
    , ( "1998 failed", Search1998, [ Fixtures.repairsSucceeded, Fixtures.shadowsSucceeded, search Failed ] )
    ]


{-| The chapter's last slide, with its "Return to the present" button. -}
lastSlide : Era -> History -> Model
lastSlide era history =
    let
        model =
            Fixtures.initialModel
    in
    { model | history = history, phase = Transition (Slideshow era (List.length (Timeline.slides era history) - 1)) }


slideAt : Era -> History -> Int -> Model
slideAt era history index =
    let
        model =
            Fixtures.initialModel
    in
    { model | history = history, phase = Transition (Slideshow era index) }


{-| The existing narration the tear ends in. -}
backHome : Era -> History -> Model
backHome era history =
    let
        model =
            lastSlide era history
    in
    { model | phase = Transition ReturningToPresent }


suite : Test
suite =
    describe "The tear home"
        [ describe "starts from the last slide only" <|
            List.map
                (\( name, era, history ) ->
                    test name <|
                        \_ ->
                            send [ Advance ] (lastSlide era history)
                                |> .phase
                                |> Expect.equal (Transition (TearToPresent era 0))
                )
                resolved
                ++ [ test "earlier slides still move on to the next slide" <|
                        \_ ->
                            send [ Advance ] (slideAt Repairs1950 [ Fixtures.repairsSucceeded ] 0)
                                |> .phase
                                |> Expect.equal (Transition (Slideshow Repairs1950 1))
                   , test "frames are wanted during the tear" <|
                        \_ ->
                            send [ Advance ] (lastSlide Shadows1973 [ Fixtures.repairsSucceeded, Fixtures.shadowsFailed ])
                                |> Travel.wantsFrames
                                |> Expect.equal True
                   ]
        , describe "timing"
            [ test "still tearing just before 1.8 seconds" <|
                \_ ->
                    send (Advance :: frames 35 50) (lastSlide Repairs1950 [ Fixtures.repairsFailed ])
                        |> .phase
                        |> Expect.equal (Transition (TearToPresent Repairs1950 1750))
            , test "at 1.8 seconds, the existing Back to the present narration, for every era and outcome" <|
                \_ ->
                    resolved
                        |> List.map (\( _, era, history ) -> send (Advance :: frames 36 50) (lastSlide era history))
                        |> Expect.equal (List.map (\( _, era, history ) -> backHome era history) resolved)
            , test "a stalled or hidden tab cannot jump ahead: a huge frame counts as 50 ms" <|
                \_ ->
                    send [ Advance, AnimationFrame 60000 ] (lastSlide Search1998 [ Fixtures.repairsSucceeded, Fixtures.shadowsSucceeded, search Failed ])
                        |> .phase
                        |> Expect.equal (Transition (TearToPresent Search1998 50))
            ]
        , describe "Skip and repeated clicks"
            [ test "skipping at any moment gives exactly the state of letting it finish" <|
                \_ ->
                    [ 0, 1, 12, 30, 35 ]
                        |> List.map (\n -> send (Advance :: frames n 50 ++ [ SkipTravel ]) (lastSlide Shadows1973 [ Fixtures.repairsSucceeded, Fixtures.shadowsSucceeded ]))
                        |> Expect.equal (List.repeat 5 (backHome Shadows1973 [ Fixtures.repairsSucceeded, Fixtures.shadowsSucceeded ]))
            , test "a double click on Return to the present starts one tear and skips nothing" <|
                \_ ->
                    send [ Advance, Advance, Advance ] (lastSlide Repairs1950 [ Fixtures.repairsSucceeded ])
                        |> .phase
                        |> Expect.equal (Transition (TearToPresent Repairs1950 0))
            , test "a second Skip, or frames afterwards, do not move past the narration" <|
                \_ ->
                    send ([ Advance, SkipTravel, SkipTravel ] ++ frames 40 50) (lastSlide Repairs1950 [ Fixtures.repairsSucceeded ])
                        |> Expect.equal (backHome Repairs1950 [ Fixtures.repairsSucceeded ])
            , test "walking, using things, puzzle moves and diary actions are ignored during the tear" <|
                \_ ->
                    let
                        midway =
                            send (Advance :: frames 15 50) (lastSlide Shadows1973 [ Fixtures.repairsSucceeded, Fixtures.shadowsFailed ])
                    in
                    send
                        [ WalkKeyDown WalkRight
                        , InteractNearby
                        , ApproachHotspot DiarySpot
                        , Inspect (HubProp CommunityWall)
                        , StageMove (SelectItem (CharacterCutout Fox))
                        , Submit
                        , Retry
                        , OpenNextDiary
                        , ReopenDiary Repairs1950
                        , StartAgain
                        ]
                        midway
                        |> Expect.equal midway
            ]
        , describe "afterwards, nothing changes"
            [ test "the tear never touches history or attempts" <|
                \_ ->
                    resolved
                        |> List.map (\( _, era, history ) -> (send (Advance :: frames 20 50) (lastSlide era history)).history == history)
                        |> Expect.equal (List.repeat 6 True)
            , test "after 1950 and 1973 the hub follows, with the next diary unlocked" <|
                \_ ->
                    resolved
                        |> List.take 4
                        |> List.map (\( _, era, history ) -> send (Advance :: frames 36 50 ++ [ Advance ]) (lastSlide era history))
                        |> List.map (\m -> ( m.phase, (Timeline.deriveWorld m.history).nextDiary ))
                        |> Expect.equal
                            [ ( PresentHub, Just Shadows1973 )
                            , ( PresentHub, Just Shadows1973 )
                            , ( PresentHub, Just Search1998 )
                            , ( PresentHub, Just Search1998 )
                            ]
            , test "after 1998 the ending follows, saved or closed by the real outcomes" <|
                \_ ->
                    resolved
                        |> List.drop 4
                        |> List.map (\( _, era, history ) -> send (Advance :: frames 36 50 ++ [ Advance ]) (lastSlide era history))
                        |> List.map (\m -> ( m.phase, Timeline.fate m.history ))
                        |> Expect.equal
                            [ ( Ending, Just ShopSaved )
                            , ( Ending, Just (ShopClosed [ Search1998 ]) )
                            ]
            , test "the trip into the past is unchanged: Step into still starts a fresh trip" <|
                \_ ->
                    send [ Advance, OpenNextDiary, Advance ] (backHome Repairs1950 [ Fixtures.repairsSucceeded ])
                        |> .phase
                        |> Expect.equal (Transition (TimeTravel Shadows1973 0))
            , test "the tear lasts 1.8 seconds" <|
                \_ ->
                    ( Travel.returnDuration, List.map Travel.hasReturned [ 1799, 1800 ] )
                        |> Expect.equal ( 1800, [ False, True ] )
            ]
        ]
