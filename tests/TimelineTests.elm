module TimelineTests exposing (suite)

import Domain exposing (..)
import Expect
import Fixtures
import Test exposing (Test, describe, test)
import Timeline


{-| A record for any era/outcome; the submission content is irrelevant here. -}
record : Era -> Outcome -> ChapterRecord
record era outcome =
    { era = era
    , outcome = outcome
    , attemptsUsed =
        if outcome == Succeeded then
            1

        else
            2
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
    , finalViolations =
        if outcome == Succeeded then
            []

        else
            [ DetailDoesNotMatch LucyInscription ]
    }


historyOf : Outcome -> Outcome -> Outcome -> History
historyOf a b c =
    [ record Repairs1950 a, record Shadows1973 b, record Search1998 c ]


allCombinations : List History
allCombinations =
    let
        both =
            [ Succeeded, Failed ]
    in
    List.concatMap (\a -> List.concatMap (\b -> List.map (\c -> historyOf a b c) both) both) both


suite : Test
suite =
    describe "Timeline"
        [ test "all eight outcome combinations: only all-success saves the shop" <|
            \_ ->
                allCombinations
                    |> List.map Timeline.fate
                    |> List.filter ((==) (Just ShopSaved))
                    |> List.length
                    |> Expect.equal 1
        , test "a closed ending lists exactly the failed eras" <|
            \_ ->
                Timeline.fate (historyOf Failed Succeeded Failed)
                    |> Expect.equal (Just (ShopClosed [ Repairs1950, Search1998 ]))
        , test "no fate until all three chapters are resolved" <|
            \_ ->
                Timeline.fate [ record Repairs1950 Succeeded ]
                    |> Expect.equal Nothing
        , test "the same history always derives the same world" <|
            \_ ->
                Timeline.deriveWorld (historyOf Succeeded Failed Succeeded)
                    |> Expect.equal (Timeline.deriveWorld (historyOf Succeeded Failed Succeeded))
        , test "1950 success gives the original script; failure the retelling" <|
            \_ ->
                ( (Timeline.deriveWorld [ record Repairs1950 Succeeded ]).scriptVariant
                , (Timeline.deriveWorld [ record Repairs1950 Failed ]).scriptVariant
                )
                    |> Expect.equal ( OriginalScript, NeighboursRetelling )
        , test "1973 success gives the archive inscription; failure the follow-up email" <|
            \_ ->
                ( (Timeline.deriveWorld [ record Repairs1950 Failed, record Shadows1973 Succeeded ]).inscriptionSource
                , (Timeline.deriveWorld [ record Repairs1950 Succeeded, record Shadows1973 Failed ]).inscriptionSource
                )
                    |> Expect.equal ( FamilyArchive, FollowUpEmail )
        , test "foundations follow recorded outcomes" <|
            \_ ->
                let
                    world =
                        Timeline.deriveWorld [ record Repairs1950 Failed ]
                in
                ( world.premises, world.tradition, world.onlineService )
                    |> Expect.equal ( Missing, NotRevisited, NotRevisited )
        , test "rewinding 1973 keeps 1950 and clears 1973 and 1998" <|
            \_ ->
                Timeline.rewindTo Shadows1973 (historyOf Failed Succeeded Succeeded)
                    |> Expect.equal [ record Repairs1950 Failed ]
        , test "rewinding 1950 clears every chapter" <|
            \_ ->
                Timeline.rewindTo Repairs1950 (historyOf Succeeded Succeeded Succeeded)
                    |> Expect.equal []
        , test "rewound world is recomputed from what remains" <|
            \_ ->
                Timeline.deriveWorld (Timeline.rewindTo Shadows1973 (historyOf Succeeded Succeeded Succeeded))
                    |> Expect.equal (Timeline.deriveWorld [ record Repairs1950 Succeeded ])
        , test "append refuses duplicates and out-of-order chapters" <|
            \_ ->
                [ record Repairs1950 Succeeded ]
                    |> Timeline.append (record Repairs1950 Failed)
                    |> Timeline.append (record Search1998 Succeeded)
                    |> Expect.equal [ record Repairs1950 Succeeded ]
        , test "the successful 1950 slideshow follows the submitted week, then Saturday" <|
            \_ ->
                Timeline.slides Repairs1950 [ Fixtures.repairsSucceeded ]
                    |> Expect.equal
                        [ WeekdaySlide Monday PatchRoof
                        , WeekdaySlide Tuesday ClearRubble
                        , WeekdaySlide Wednesday BuildShelves
                        , WeekdaySlide Thursday ShelveBooks
                        , WeekdaySlide Friday ReglazeWindow
                        , ReopeningSaturday
                        ]
        , test "a failed chapter shows the consequence of its first recorded violation" <|
            \_ ->
                Timeline.slides Repairs1950 [ Fixtures.repairsFailed ]
                    |> Expect.equal [ ConsequenceSlide Repairs1950 (RoofAfterRain Wednesday) ]
        ]
