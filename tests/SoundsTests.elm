module SoundsTests exposing (suite)

import Domain exposing (..)
import Expect
import Fixtures
import Sounds
import Rules.Shadow
import Test exposing (Test, describe, test)
import Update


step : Msg -> Model -> List String
step msg model =
    Sounds.forStep msg model (Update.update msg model)


suite : Test
suite =
    describe "Sounds"
        [ test "turning an introduction page sounds like a page" <|
            \_ -> step Advance Fixtures.initialModel |> Expect.equal [ "page" ]
        , test "opening a clue rustles paper, closing it too" <|
            \_ ->
                let
                    opened =
                        Update.update (Inspect ClosureNotice) Fixtures.initialModel
                in
                ( step (Inspect ClosureNotice) Fixtures.initialModel, step CloseInspection opened )
                    |> Expect.equal ( [ "paper-open" ], [ "paper-close" ] )
        , test "a valid week finishes 1950 with the success chime" <|
            \_ -> step Submit Fixtures.repairBoardReady |> List.member "success" |> Expect.equal True
        , test "a wrong first week plays the gentle mistake sound" <|
            \_ ->
                step Submit (Fixtures.repairBoard (Fixtures.boardFor Fixtures.wrongWeek) NoAttemptUsed)
                    |> Expect.equal [ "mistake" ]
        , test "picking up a task card" <|
            \_ -> step (BoardMove (SelectItem PatchRoof)) Fixtures.repairBoardInProgress |> Expect.equal [ "card-pick" ]
        , test "nothing happens, nothing plays" <|
            \_ -> step Submit Fixtures.initialModel |> Expect.equal []
        , test "the shadow play starts the first scene's puppet sounds, and the next slide swaps them" <|
            \_ ->
                let
                    staged =
                        Fixtures.shadowOriginalScript

                    ready =
                        { staged
                            | phase =
                                ShadowPuzzle
                                    { arrangement = Fixtures.stageFor (Rules.Shadow.script OriginalScript)
                                    , inspected = []
                                    , attempts = NoAttemptUsed
                                    }
                        }

                    performed =
                        Update.update Submit ready
                in
                ( performed.phase, step Advance performed )
                    |> Expect.equal ( Transition (Slideshow Shadows1973 0), [ "page", "scene-door-owl" ] )
        , test "the clock stopping has its own sound" <|
            \_ ->
                step Advance { initial | phase = Introduction DiariesFound }
                    |> Expect.equal [ "clock-stop" ]
        ]


initial : Model
initial =
    Fixtures.initialModel
