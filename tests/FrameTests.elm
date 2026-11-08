module FrameTests exposing (suite)

{-| The broken frame after the 1973 show (contract v1.7), through Update.update:
it follows the last 1973 slide whatever the outcome, each piece fits only its
own gap, moves never touch history, and only the mended frame goes home.
-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Frame as Frame
import Rules.Placement as Placement
import Rules.Room as Room
import Test exposing (Test, describe, test)
import Timeline
import Update


send : List Msg -> Model -> Model
send msgs model =
    List.foldl Update.update model msgs


lastSlide : Era -> History -> Model
lastSlide era history =
    let
        model =
            Fixtures.initialModel
    in
    { model | history = history, phase = Transition (Slideshow era (List.length (Timeline.slides era history) - 1)) }


after1973 : ChapterRecord -> Model
after1973 shadows =
    send [ Advance ] (lastSlide Shadows1973 [ Fixtures.repairsSucceeded, shadows ])


put : Int -> Int -> List Msg
put piece gap =
    [ FrameMove (SelectItem (Shard piece)), FrameMove (PlaceSelected (FrameGap gap)) ]


mendAll : List Msg
mendAll =
    List.concatMap (\n -> put n n) (List.range 1 9)


placementOf : Model -> Maybe (Placement Shard FrameGap)
placementOf model =
    case model.phase of
        MendingFrame placement ->
            Just placement

        _ ->
            Nothing


suite : Test
suite =
    describe "1973 broken frame"
        [ describe "when it happens"
            [ test "after the last slide of a successful show" <|
                \_ ->
                    (after1973 Fixtures.shadowsSucceeded).phase
                        |> Expect.equal (MendingFrame Placement.empty)
            , test "after the last slide of a failed show too" <|
                \_ ->
                    (after1973 Fixtures.shadowsFailed).phase
                        |> Expect.equal (MendingFrame Placement.empty)
            , test "1950 and 1998 still tear home straight from their last slide" <|
                \_ ->
                    [ send [ Advance ] (lastSlide Repairs1950 [ Fixtures.repairsSucceeded ])
                    , send [ Advance ] (lastSlide Search1998 [ Fixtures.repairsSucceeded, Fixtures.shadowsSucceeded, Fixtures.shadowsSucceeded |> (\r -> { r | era = Search1998, finalSubmission = SentBook CandidateA }) ])
                    ]
                        |> List.map .phase
                        |> Expect.equal [ Transition (TearToPresent Repairs1950 0), Transition (TearToPresent Search1998 0) ]
            , test "the glass on the floor is the only thing to use, and it opens the panel" <|
                \_ ->
                    let
                        model =
                            after1973 Fixtures.shadowsSucceeded

                        player =
                            Room.initialPlayer

                        atTheGlass =
                            { model | room = { panelOpen = False, player = { player | x = (Room.position BrokenGlassSpot).x } } }
                    in
                    ( Room.hotspots model.phase, (send [ InteractNearby ] atTheGlass).room.panelOpen )
                        |> Expect.equal ( [ BrokenGlassSpot ], True )
            ]
        , describe "fitting the pieces"
            [ test "a piece only fits its own gap" <|
                \_ ->
                    List.range 1 9
                        |> List.concatMap (\a -> List.map (\b -> ( a == b, Frame.accepts (Shard a) (FrameGap b) )) (List.range 1 9))
                        |> List.all (\( same, fits ) -> same == fits)
                        |> Expect.equal True
            , test "the wrong gap leaves the piece in hand and says it doesn't fit" <|
                \_ ->
                    send (put 6 2) (after1973 Fixtures.shadowsSucceeded)
                        |> (\m -> ( placementOf m, m.notice ))
                        |> Expect.equal ( Just { placed = [], selected = Just (Shard 6) }, Just DoesNotFitThere )
            , test "the right gap takes the piece" <|
                \_ ->
                    send (put 6 6) (after1973 Fixtures.shadowsSucceeded)
                        |> placementOf
                        |> Expect.equal (Just { placed = [ ( Shard 6, FrameGap 6 ) ], selected = Nothing })
            , test "Hang it back up before every piece is in: a neutral notice, nothing moves" <|
                \_ ->
                    let
                        partly =
                            send (List.concatMap (\n -> put n n) (List.range 1 8)) (after1973 Fixtures.shadowsSucceeded)

                        tried =
                            send [ Advance ] partly
                    in
                    ( tried.phase == partly.phase, tried.notice )
                        |> Expect.equal ( True, Just NotSolvedYet )
            , test "every piece in, in any order, is solved" <|
                \_ ->
                    send (List.concatMap (\n -> put n n) (List.reverse (List.range 1 9))) (after1973 Fixtures.shadowsSucceeded)
                        |> placementOf
                        |> Maybe.map Frame.isSolved
                        |> Expect.equal (Just True)
            , test "piece moves never touch history" <|
                \_ ->
                    let
                        start =
                            after1973 Fixtures.shadowsFailed
                    in
                    (send (put 3 4 ++ put 3 3 ++ [ Advance ]) start).history
                        |> Expect.equal start.history
            ]
        , describe "going home"
            [ test "the mended frame tears home from 1973" <|
                \_ ->
                    send (mendAll ++ [ Advance ]) (after1973 Fixtures.shadowsSucceeded)
                        |> .phase
                        |> Expect.equal (Transition (TearToPresent Shadows1973 0))
            , test "then the present, with the 1998 journal next" <|
                \_ ->
                    send (mendAll ++ [ Advance, SkipTravel, Advance ]) (after1973 Fixtures.shadowsFailed)
                        |> (\m -> ( m.phase, (Timeline.deriveWorld m.history).nextDiary ))
                        |> Expect.equal ( PresentHub, Just Search1998 )
            , test "frame moves are ignored outside the frame scene" <|
                \_ ->
                    let
                        base =
                            Fixtures.initialModel

                        hub =
                            { base | phase = PresentHub }
                    in
                    send (put 1 1) hub
                        |> Expect.equal hub
            , test "the family photograph can be looked at in the present-day shop" <|
                \_ ->
                    Room.hotspots PresentHub
                        |> List.member (ClueSpot FamilyPhotograph)
                        |> Expect.equal True
            ]
        ]
