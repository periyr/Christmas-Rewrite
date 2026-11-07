module TravelTests exposing (suite)

{-| The trip back in time into a diary (contract v1.5), through Update.update:
it starts only when the player steps in, runs on clamped animation frames,
enters the chapter by itself or on Skip in exactly the same state, ignores
everything else while it plays, and starts fresh on every entry.
-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Room as Room
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


{-| The diary's passage for each era, with the history that leads to it. -}
passage : Era -> Model
passage era =
    let
        history =
            case era of
                Repairs1950 ->
                    []

                Shadows1973 ->
                    [ Fixtures.repairsSucceeded ]

                Search1998 ->
                    [ Fixtures.repairsSucceeded, Fixtures.shadowsSucceeded ]

        model =
            Fixtures.initialModel
    in
    { model | history = history, phase = Transition (OpeningDiary era) }


{-| What every trip must end in: the chapter's fresh start in a fresh room,
with the history untouched.
-}
arrivedIn : Era -> Model
arrivedIn era =
    let
        before =
            passage era
    in
    { before | phase = Update.startChapter era, room = Room.initialRoom }


eras : List Era
eras =
    [ Repairs1950, Shadows1973, Search1998 ]


travelling : Model -> Maybe ( Era, Float )
travelling model =
    case model.phase of
        Transition (TimeTravel era elapsed) ->
            Just ( era, elapsed )

        _ ->
            Nothing


suite : Test
suite =
    describe "Time travel into a diary"
        [ starting
        , timing
        , skipping
        , ignoring
        , reopening
        , years
        ]


starting : Test
starting =
    describe "starting"
        [ test "Step into starts a fresh trip to that era, for all three diaries" <|
            \_ ->
                eras
                    |> List.map (\era -> send [ Advance ] (passage era) |> travelling)
                    |> Expect.equal [ Just ( Repairs1950, 0 ), Just ( Shadows1973, 0 ), Just ( Search1998, 0 ) ]
        , test "the passage waits for the player: frames and Skip do not dismiss it" <|
            \_ ->
                send (frames 300 16 ++ [ SkipTravel ]) (passage Repairs1950)
                    |> Expect.equal (passage Repairs1950)
        , test "frames are wanted during the trip, not while reading the passage" <|
            \_ ->
                [ passage Shadows1973, send [ Advance ] (passage Shadows1973) ]
                    |> List.map Travel.wantsFrames
                    |> Expect.equal [ False, True ]
        ]


timing : Test
timing =
    describe "frames move the trip on"
        [ test "the trip is still playing just before 2.5 seconds" <|
            \_ ->
                send (Advance :: frames 156 16) (passage Repairs1950)
                    |> travelling
                    |> Expect.equal (Just ( Repairs1950, 2496 ))
        , test "at 2.5 seconds it enters the chapter by itself, for all three diaries" <|
            \_ ->
                eras
                    |> List.map (\era -> send (Advance :: frames 50 50) (passage era))
                    |> Expect.equal (List.map arrivedIn eras)
        , test "a stalled or hidden tab cannot jump ahead: a huge frame counts as 50 ms" <|
            \_ ->
                send [ Advance, PageVisibilityChanged False, AnimationFrame 60000, PageVisibilityChanged True ] (passage Search1998)
                    |> travelling
                    |> Expect.equal (Just ( Search1998, 50 ))
        , test "a negative frame does not move it" <|
            \_ ->
                send [ Advance, AnimationFrame -100 ] (passage Search1998)
                    |> travelling
                    |> Expect.equal (Just ( Search1998, 0 ))
        , test "on arrival no more frames are wanted" <|
            \_ ->
                send (Advance :: frames 60 50) (passage Shadows1973)
                    |> Travel.wantsFrames
                    |> Expect.equal False
        ]


skipping : Test
skipping =
    describe "Skip"
        [ test "skipping at any moment gives exactly the state of letting it finish" <|
            \_ ->
                [ 0, 1, 10, 25, 49 ]
                    |> List.map (\n -> send (Advance :: frames n 50 ++ [ SkipTravel ]) (passage Repairs1950))
                    |> Expect.equal (List.repeat 5 (arrivedIn Repairs1950))
        , test "Skip and finishing both start in a fresh room, wherever the player stood before" <|
            \_ ->
                let
                    hub =
                        Fixtures.hubAfterRepairs

                    room =
                        hub.room

                    player =
                        room.player

                    started =
                        send [ OpenNextDiary, Advance ] { hub | room = { room | player = { player | x = 900, facing = FacingLeft } } }

                    fresh =
                        { started | phase = Update.startChapter Shadows1973, room = Room.initialRoom }
                in
                ( send [ SkipTravel ] started, send (frames 50 50) started )
                    |> Expect.equal ( fresh, fresh )
        , test "a second Skip does nothing to the chapter that started" <|
            \_ ->
                send [ Advance, SkipTravel, SkipTravel ] (passage Shadows1973)
                    |> Expect.equal (arrivedIn Shadows1973)
        , test "frames that arrive after the chapter starts do nothing to it" <|
            \_ ->
                send ([ Advance, SkipTravel ] ++ frames 100 50) (passage Search1998)
                    |> Expect.equal (arrivedIn Search1998)
        ]


ignoring : Test
ignoring =
    describe "while the trip plays"
        [ test "a double click on Step into starts one trip and skips nothing" <|
            \_ ->
                send [ Advance, Advance, Advance ] (passage Repairs1950)
                    |> travelling
                    |> Expect.equal (Just ( Repairs1950, 0 ))
        , test "walking, using things, puzzle moves and submitting are all ignored" <|
            \_ ->
                let
                    midway =
                        send (Advance :: frames 20 50) (passage Repairs1950)
                in
                send
                    [ WalkKeyDown WalkRight
                    , InteractNearby
                    , ApproachHotspot CratesSpot
                    , ClosePanel
                    , Inspect WalterDiaryPage
                    , SalvageMove (SelectItem (Recoverable WinterTales))
                    , BoardMove (SelectItem PatchRoof)
                    , Submit
                    , Retry
                    , OpenNextDiary
                    , ReopenDiary Shadows1973
                    , StartAgain
                    ]
                    midway
                    |> Expect.equal midway
        , test "keys held in the present do not carry on walking in the past" <|
            \_ ->
                let
                    hub =
                        Fixtures.hubAfterRepairs
                in
                send ([ WalkKeyDown WalkRight ] ++ frames 10 16 ++ [ OpenNextDiary, Advance, WalkKeyDown WalkRight ] ++ frames 60 50) hub
                    |> (\m -> ( m.phase, m.room.player ))
                    |> Expect.equal ( Update.startChapter Shadows1973, Room.initialPlayer )
        , test "the trip never changes history or spends anything" <|
            \_ ->
                send (Advance :: frames 30 50) (passage Search1998)
                    |> .history
                    |> Expect.equal (passage Search1998).history
        ]


reopening : Test
reopening =
    let
        ending =
            send [ ChooseCandidate CandidateA, Submit, Advance, Advance ] (arrivedIn Search1998)
    in
    describe "reopening a diary"
        [ test "the setup reaches an ending" <|
            \_ -> ending.phase |> Expect.equal Ending
        , test "reopening uses the same trip, after the usual rewind" <|
            \_ ->
                send [ ReopenDiary Shadows1973, Advance ] ending
                    |> (\m -> ( travelling m, m.history ))
                    |> Expect.equal ( Just ( Shadows1973, 0 ), [ Fixtures.repairsSucceeded ] )
        , test "it ends in the same fresh chapter as a first visit" <|
            \_ ->
                send ([ ReopenDiary Shadows1973, Advance ] ++ frames 60 50) ending
                    |> Expect.equal (arrivedIn Shadows1973)
        , test "reopening the same era again starts the trip from the beginning" <|
            \_ ->
                let
                    replayed =
                        send ([ ReopenDiary Search1998, Advance ] ++ frames 30 50 ++ [ SkipTravel, ChooseCandidate CandidateA, Submit, Advance, Advance ]) ending
                in
                ( replayed.phase, send [ ReopenDiary Search1998, Advance ] replayed |> travelling )
                    |> Expect.equal ( Ending, Just ( Search1998, 0 ) )
        ]


years : Test
years =
    let
        seen era =
            List.range 0 50
                |> List.map (\n -> Travel.yearAt era (toFloat n * 50))
                |> List.foldr
                    (\y acc ->
                        if List.head acc == Just y then
                            acc

                        else
                            y :: acc
                    )
                    []
    in
    describe "the years on the way back"
        [ test "to 1950: Present, 1998, 1973, 1950" <|
            \_ -> seen Repairs1950 |> Expect.equal [ Nothing, Just Search1998, Just Shadows1973, Just Repairs1950 ]
        , test "to 1973: Present, 1998, 1973" <|
            \_ -> seen Shadows1973 |> Expect.equal [ Nothing, Just Search1998, Just Shadows1973 ]
        , test "to 1998: Present, 1998" <|
            \_ -> seen Search1998 |> Expect.equal [ Nothing, Just Search1998 ]
        , test "the present shows while the book opens, and the destination from arrival to the end" <|
            \_ ->
                eras
                    |> List.map
                        (\era ->
                            ( Travel.yearAt era 0
                            , Travel.yearAt era (Travel.bookOpen - 1)
                            , List.map (Travel.yearAt era) [ Travel.arrival, Travel.duration ]
                            )
                        )
                    |> Expect.equal
                        (List.map (\era -> ( Nothing, Nothing, [ Just era, Just era ] )) eras)
        , test "every trip takes 2.5 seconds: open by 0.5, arrived by 1.8" <|
            \_ ->
                ( ( Travel.bookOpen, Travel.arrival, Travel.duration )
                , List.map Travel.hasArrived [ 1799, 1800 ]
                )
                    |> Expect.equal ( ( 500, 1800, 2500 ), [ False, True ] )
        , test "the world is unaffected by where the trip is: it stays derived from history" <|
            \_ ->
                send (Advance :: frames 30 50) (passage Shadows1973)
                    |> .history
                    |> Timeline.deriveWorld
                    |> Expect.equal (Timeline.deriveWorld (passage Shadows1973).history)
        ]
