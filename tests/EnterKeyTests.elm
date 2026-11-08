module EnterKeyTests exposing (suite)

{-| Enter moves the story on in the narration and slides, the same Advance as
the screen's button, and nowhere else (Rules.Room.enterContinues).
-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Placement as Placement
import Rules.Room as Room
import Test exposing (Test, describe, test)


at : Phase -> Model
at phase =
    let
        model =
            Fixtures.initialModel
    in
    { model | phase = phase }


suite : Test
suite =
    describe "Enter to continue"
        [ test "the story screens: narration, Step into, every slide, and Back to the present" <|
            \_ ->
                [ Introduction DiariesFound
                , Introduction ClockStopped
                , Transition (OpeningDiary Shadows1973)
                , Transition (Slideshow Repairs1950 0)
                , Transition (Slideshow Shadows1973 2)
                , Transition (Slideshow Search1998 0)
                , Transition ReturningToPresent
                ]
                    |> List.map (at >> Room.enterContinues)
                    |> Expect.equal (List.repeat 7 True)
        , test "not in rooms, puzzles, trips or the ending" <|
            \_ ->
                [ Introduction PackingUp
                , PresentHub
                , Salvage Placement.empty
                , ReopeningShelf Placement.empty
                , MendingFrame Placement.empty
                , BookMystery { arrangement = Nothing, inspected = [], attempts = NoAttemptUsed }
                , Transition (TimeTravel Repairs1950 0)
                , Transition (TearToPresent Repairs1950 0)
                , Ending
                ]
                    |> List.map (at >> Room.enterContinues)
                    |> Expect.equal (List.repeat 9 False)
        , test "not while a clue sheet is open over a slide" <|
            \_ ->
                let
                    slide =
                        at (Transition (Slideshow Repairs1950 0))
                in
                Room.enterContinues { slide | inspecting = Just WalterDiaryPage }
                    |> Expect.equal False
        ]
