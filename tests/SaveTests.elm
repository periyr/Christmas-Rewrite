module SaveTests exposing (suite)

import Domain exposing (..)
import Expect
import Fixtures
import Json.Decode as D
import Json.Encode as E
import Save
import Test exposing (Test, describe, test)
import Update


roundTrip : Save.Saved -> Maybe Save.Saved
roundTrip saved =
    Save.decode (Save.encode saved)


failedMystery : ChapterRecord
failedMystery =
    { era = Search1998
    , outcome = Failed
    , attemptsUsed = 2
    , finalSubmission = SentBook CandidateB
    , finalViolations = [ DetailDoesNotMatch LucyInscription, DetailDoesNotMatch FoxLanternIllustration ]
    }


suite : Test
suite =
    describe "Save"
        [ describe "round trip"
            [ test "an empty history at the start of the introduction" <|
                \_ ->
                    let
                        saved =
                            { history = [], place = Save.placeOf Update.init }
                    in
                    roundTrip saved |> Expect.equal (Just saved)
            , test "every kind of record, submission and violation" <|
                \_ ->
                    let
                        saved =
                            { history = [ Fixtures.repairsFailed, Fixtures.shadowsFailed, failedMystery ]
                            , place = Save.placeOf { initial | history = [ Fixtures.repairsFailed ], phase = PresentHub }
                            }
                    in
                    roundTrip saved |> Expect.equal (Just saved)
            ]
        , describe "unreadable saves count as no save"
            [ test "null" <| \_ -> Save.decode E.null |> Expect.equal Nothing
            , test "another version" <|
                \_ ->
                    Save.decode (E.object [ ( "version", E.int 99 ), ( "history", E.list identity [] ) ])
                        |> Expect.equal Nothing
            , test "nonsense" <|
                \_ ->
                    D.decodeString D.value "{\"version\":1,\"history\":[{\"era\":\"1066\"}]}"
                        |> Result.toMaybe
                        |> Maybe.andThen Save.decode
                        |> Expect.equal Nothing
            ]
        , describe "continue comes back to the same place"
            [ test "an introduction page" <|
                \_ ->
                    let
                        model =
                            { initial | phase = Introduction DiariesFound }
                    in
                    (Save.resume { history = [], place = Save.placeOf model }).phase
                        |> Expect.equal (Introduction DiariesFound)
            , test "a chapter in progress restarts that chapter" <|
                \_ ->
                    let
                        history =
                            [ Fixtures.repairsSucceeded ]
                    in
                    (Save.resume { history = history, place = Save.placeOf { initial | history = history, phase = Update.startChapter Shadows1973 } }).phase
                        |> Expect.equal (Update.startChapter Shadows1973)
            , test "a chapter already recorded comes back to the shop" <|
                \_ ->
                    let
                        history =
                            [ Fixtures.repairsSucceeded ]
                    in
                    (Save.resume { history = history, place = Save.placeOf { initial | history = history, phase = Transition (Slideshow Repairs1950 0) } }).phase
                        |> Expect.equal PresentHub
            , test "the ending" <|
                \_ ->
                    let
                        history =
                            [ Fixtures.repairsSucceeded, Fixtures.shadowsSucceeded, failedMystery ]
                    in
                    (Save.resume { history = history, place = Save.placeOf { initial | history = history, phase = Ending } }).phase
                        |> Expect.equal Ending
            ]
        ]


initial : Model
initial =
    Update.init
