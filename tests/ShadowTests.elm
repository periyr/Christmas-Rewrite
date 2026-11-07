module ShadowTests exposing (suite)

{-| 1973 shadow story: Rules.Shadow.validate for both script variants (C's
examples in docs/test-examples-for-A.md), the whole space of 36 complete
stagings, structural completeness, and the two-attempt flow through Update.
-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Attempts as Attempts
import Rules.Placement as Placement
import Rules.Shadow as Shadow
import Test exposing (Test, describe, test)
import Timeline
import Update



-- HELPERS


stage : ( Character, Prop ) -> ( Character, Prop ) -> ( Character, Prop ) -> Staging
stage ( c1, p1 ) ( c2, p2 ) ( c3, p3 ) =
    { scene1 = { character = c1, prop = p1 }
    , scene2 = { character = c2, prop = p2 }
    , scene3 = { character = c3, prop = p3 }
    }


conflicts : List Scene -> List Violation
conflicts =
    List.map SceneConflictsWithScript


permutations : List a -> List (List a)
permutations items =
    case items of
        [] ->
            [ [] ]

        _ ->
            List.concatMap
                (\item -> List.map ((::) item) (permutations (List.filter ((/=) item) items)))
                items


{-| Every complete staging: the scenes are fixed, so 3! character orders
times 3! prop orders.
-}
allStagings : List Staging
allStagings =
    List.concatMap
        (\characters ->
            List.filterMap
                (\props ->
                    case List.map2 Tuple.pair characters props of
                        [ a, b, c ] ->
                            Just (stage a b c)

                        _ ->
                            Nothing
                )
                (permutations [ Lantern, Key, Book ])
        )
        (permutations [ Fox, Owl, Child ])


original : Staging
original =
    stage ( Fox, Lantern ) ( Owl, Key ) ( Child, Book )


retelling : Staging
retelling =
    stage ( Child, Key ) ( Owl, Book ) ( Fox, Lantern )


send : List Msg -> Model -> Model
send msgs model =
    List.foldl Update.update model msgs


{-| The actions that put a staging on the stage. -}
perform : Staging -> List Msg
perform staging =
    List.concatMap
        (\( scene, cast ) ->
            [ StageMove (SelectItem (CharacterCutout cast.character))
            , StageMove (PlaceSelected (CharacterSlot scene))
            , StageMove (SelectItem (PropCutout cast.prop))
            , StageMove (PlaceSelected (PropSlot scene))
            ]
        )
        [ ( Scene1, staging.scene1 ), ( Scene2, staging.scene2 ), ( Scene3, staging.scene3 ) ]


placementOf : Staging -> Placement Cutout ShadowSlot
placementOf staging =
    { placed =
        List.concatMap
            (\( scene, cast ) -> [ ( CharacterCutout cast.character, CharacterSlot scene ), ( PropCutout cast.prop, PropSlot scene ) ])
            [ ( Scene1, staging.scene1 ), ( Scene2, staging.scene2 ), ( Scene3, staging.scene3 ) ]
    , selected = Nothing
    }


{-| The 1973 puzzle after the given 1950 record, reached by playing on from
the present: open the next diary, turn the page.
-}
shadowAfter : ChapterRecord -> Model
shadowAfter record =
    send [ OpenNextDiary, Advance ] { hub | history = [ record ] }


hub : Model
hub =
    Fixtures.hubAfterRepairs


attemptsOf : Model -> Maybe Attempts
attemptsOf model =
    case model.phase of
        ShadowPuzzle puzzle ->
            Just puzzle.attempts

        _ ->
            Nothing


suite : Test
suite =
    describe "1973 shadow story"
        [ examples
        , wholeSpace
        , completeness
        , flow
        ]



-- C'S EXAMPLES


examples : Test
examples =
    describe "C's expected examples"
        [ describe "original script (1950 succeeded): Fox + Lantern, Owl + Key, Child + Book"
            [ test "correct" <|
                \_ -> Shadow.validate OriginalScript original |> Expect.equal []
            , test "the retelling's answer used by mistake" <|
                \_ -> Shadow.validate OriginalScript retelling |> Expect.equal (conflicts [ Scene1, Scene2, Scene3 ])
            , test "right pairs, wrong order (sketch ignored)" <|
                \_ ->
                    Shadow.validate OriginalScript (stage ( Owl, Key ) ( Fox, Lantern ) ( Child, Book ))
                        |> Expect.equal (conflicts [ Scene1, Scene2 ])
            , test "props swapped between scenes 1 and 2" <|
                \_ ->
                    Shadow.validate OriginalScript (stage ( Fox, Key ) ( Owl, Lantern ) ( Child, Book ))
                        |> Expect.equal (conflicts [ Scene1, Scene2 ])
            , test "characters swapped between scenes 2 and 3" <|
                \_ ->
                    Shadow.validate OriginalScript (stage ( Fox, Lantern ) ( Child, Key ) ( Owl, Book ))
                        |> Expect.equal (conflicts [ Scene2, Scene3 ])
            ]
        , describe "neighbours' retelling (1950 failed): Child + Key, Owl + Book, Fox + Lantern"
            [ test "correct" <|
                \_ -> Shadow.validate NeighboursRetelling retelling |> Expect.equal []
            , test "the original's answer used by mistake" <|
                \_ -> Shadow.validate NeighboursRetelling original |> Expect.equal (conflicts [ Scene1, Scene2, Scene3 ])
            , test "right pairs, wrong order" <|
                \_ ->
                    Shadow.validate NeighboursRetelling (stage ( Fox, Lantern ) ( Owl, Book ) ( Child, Key ))
                        |> Expect.equal (conflicts [ Scene1, Scene3 ])
            , test "props swapped between scenes 1 and 3" <|
                \_ ->
                    Shadow.validate NeighboursRetelling (stage ( Child, Lantern ) ( Owl, Book ) ( Fox, Key ))
                        |> Expect.equal (conflicts [ Scene1, Scene3 ])
            , test "characters swapped between scenes 1 and 2" <|
                \_ ->
                    Shadow.validate NeighboursRetelling (stage ( Owl, Key ) ( Child, Book ) ( Fox, Lantern ))
                        |> Expect.equal (conflicts [ Scene1, Scene2 ])
            ]
        ]



-- ALL 36 STAGINGS


wholeSpace : Test
wholeSpace =
    describe "all complete stagings"
        [ test "there are 3! × 3! = 36 distinct complete stagings" <|
            \_ ->
                ( List.length allStagings, List.length (unique allStagings) )
                    |> Expect.equal ( 36, 36 )
        , test "the original script accepts exactly one staging: its own" <|
            \_ ->
                List.filter (\s -> Shadow.validate OriginalScript s == []) allStagings
                    |> Expect.equal [ original ]
        , test "the retelling accepts exactly one staging: its own" <|
            \_ ->
                List.filter (\s -> Shadow.validate NeighboursRetelling s == []) allStagings
                    |> Expect.equal [ retelling ]
        , test "no staging passes under both variants" <|
            \_ ->
                List.filter (\s -> Shadow.validate OriginalScript s == [] && Shadow.validate NeighboursRetelling s == []) allStagings
                    |> Expect.equal []
        , test "every wrong staging conflicts in at least two scenes, listed once each in scene order" <|
            \_ ->
                [ OriginalScript, NeighboursRetelling ]
                    |> List.concatMap (\variant -> List.map (Shadow.validate variant) allStagings)
                    |> List.filter (\violations -> violations /= [])
                    |> List.filter
                        (\violations ->
                            List.length violations < 2 || violations /= List.filter (\v -> List.member v violations) (conflicts Shadow.scenes)
                        )
                    |> Expect.equal []
        , test "each script is exactly the brief's table" <|
            \_ ->
                ( Shadow.script OriginalScript, Shadow.script NeighboursRetelling )
                    |> Expect.equal ( original, retelling )
        ]


unique : List a -> List a
unique =
    List.foldl
        (\item kept ->
            if List.member item kept then
                kept

            else
                kept ++ [ item ]
        )
        []



-- STRUCTURAL COMPLETENESS


completeness : Test
completeness =
    describe "complete (structure only, checked before an attempt is spent)"
        [ test "an empty stage is incomplete" <|
            \_ -> Shadow.complete Placement.empty |> Expect.equal Nothing
        , test "five cut-outs placed is incomplete" <|
            \_ ->
                let
                    full =
                        placementOf original
                in
                Shadow.complete { full | placed = List.drop 1 full.placed }
                    |> Expect.equal Nothing
        , test "every one of the 36 full stages is complete and gives back its staging" <|
            \_ ->
                allStagings
                    |> List.filter (\s -> Shadow.complete (placementOf s) /= Just s)
                    |> Expect.equal []
        , test "a cut-out used twice is not complete, even with every slot filled" <|
            \_ ->
                let
                    full =
                        placementOf original
                in
                Shadow.complete
                    { full
                        | placed =
                            List.map
                                (\( cutout, slot ) ->
                                    if slot == CharacterSlot Scene2 then
                                        ( CharacterCutout Fox, slot )

                                    else
                                        ( cutout, slot )
                                )
                                full.placed
                    }
                    |> Expect.equal Nothing
        , test "a slot listed twice is not complete" <|
            \_ ->
                let
                    full =
                        placementOf original
                in
                Shadow.complete { full | placed = full.placed ++ [ ( CharacterCutout Owl, CharacterSlot Scene1 ) ] }
                    |> Expect.equal Nothing
        ]



-- THE TWO-ATTEMPT FLOW THROUGH UPDATE


flow : Test
flow =
    describe "Perform the story (two attempts, through Update)"
        [ test "the 1950 outcome picks the script: success gives the original" <|
            \_ ->
                send (perform original ++ [ Submit ]) (shadowAfter Fixtures.repairsSucceeded)
                    |> .history
                    |> Timeline.outcomeOf Shadows1973
                    |> Expect.equal (Just Succeeded)
        , test "the 1950 outcome picks the script: failure gives the retelling" <|
            \_ ->
                send (perform retelling ++ [ Submit ]) (shadowAfter Fixtures.repairsFailed)
                    |> .history
                    |> Timeline.outcomeOf Shadows1973
                    |> Expect.equal (Just Succeeded)
        , test "the other variant's answer is a mistake after each 1950 outcome" <|
            \_ ->
                [ send (perform retelling ++ [ Submit ]) (shadowAfter Fixtures.repairsSucceeded)
                , send (perform original ++ [ Submit ]) (shadowAfter Fixtures.repairsFailed)
                ]
                    |> List.map attemptsOf
                    |> Expect.equal
                        [ Just (ReviewingFirstMistake (conflicts [ Scene1, Scene2, Scene3 ]))
                        , Just (ReviewingFirstMistake (conflicts [ Scene1, Scene2, Scene3 ]))
                        ]
        , test "an incomplete stage spends no attempt" <|
            \_ ->
                let
                    after =
                        send (List.take 8 (perform original) ++ [ Submit ]) (shadowAfter Fixtures.repairsSucceeded)
                in
                ( attemptsOf after, after.notice, after.history )
                    |> Expect.equal ( Just NoAttemptUsed, Just IncompleteSubmission, [ Fixtures.repairsSucceeded ] )
        , test "wrong then right succeeds on the second attempt and records the performed staging" <|
            \_ ->
                let
                    wrong =
                        stage ( Owl, Key ) ( Fox, Lantern ) ( Child, Book )

                    after =
                        send (perform wrong ++ [ Submit, Submit, Retry ] ++ perform original ++ [ Submit ]) (shadowAfter Fixtures.repairsSucceeded)
                in
                Timeline.recordFor Shadows1973 after.history
                    |> Expect.equal
                        (Just
                            { era = Shadows1973
                            , outcome = Succeeded
                            , attemptsUsed = 2
                            , finalSubmission = ShadowPerformance original
                            , finalViolations = []
                            }
                        )
        , test "the first mistake names the conflicting scenes and keeps the stage for editing" <|
            \_ ->
                let
                    wrong =
                        stage ( Fox, Key ) ( Owl, Lantern ) ( Child, Book )
                in
                case (send (perform wrong ++ [ Submit, Retry ]) (shadowAfter Fixtures.repairsSucceeded)).phase of
                    ShadowPuzzle puzzle ->
                        ( puzzle.attempts, Shadow.complete puzzle.arrangement )
                            |> Expect.equal ( RetryingAfterMistake (conflicts [ Scene1, Scene2 ]), Just wrong )

                    other ->
                        Expect.fail ("Expected the shadow puzzle, got " ++ Debug.toString other)
        , test "a double click on the first wrong submission spends one attempt only" <|
            \_ ->
                send (perform retelling ++ [ Submit, Submit, Submit ]) (shadowAfter Fixtures.repairsSucceeded)
                    |> attemptsOf
                    |> Maybe.map Attempts.attemptsUsed
                    |> Expect.equal (Just 1)
        , test "two wrong submissions fail the chapter with the second submission's violations" <|
            \_ ->
                let
                    first =
                        stage ( Owl, Key ) ( Fox, Lantern ) ( Child, Book )

                    second =
                        stage ( Fox, Lantern ) ( Child, Key ) ( Owl, Book )

                    after =
                        send
                            (perform first
                                ++ [ Submit, Retry ]
                                ++ [ StageMove (SelectItem (CharacterCutout Fox)), StageMove (PlaceSelected (CharacterSlot Scene1)) ]
                                ++ [ StageMove (SelectItem (PropCutout Lantern)), StageMove (PlaceSelected (PropSlot Scene1)) ]
                                ++ [ StageMove (SelectItem (CharacterCutout Child)), StageMove (PlaceSelected (CharacterSlot Scene2)) ]
                                ++ [ Submit ]
                            )
                            (shadowAfter Fixtures.repairsSucceeded)
                in
                Timeline.recordFor Shadows1973 after.history
                    |> Expect.equal
                        (Just
                            { era = Shadows1973
                            , outcome = Failed
                            , attemptsUsed = 2
                            , finalSubmission = ShadowPerformance second
                            , finalViolations = conflicts [ Scene2, Scene3 ]
                            }
                        )
        , test "success plays the three performance scenes; failure plays the cancelled event" <|
            \_ ->
                let
                    succeeded =
                        send (perform original ++ [ Submit ]) (shadowAfter Fixtures.repairsSucceeded)

                    failed =
                        send (perform retelling ++ [ Submit, Retry, Submit ]) (shadowAfter Fixtures.repairsSucceeded)
                in
                ( Timeline.slides Shadows1973 succeeded.history, Timeline.slides Shadows1973 failed.history )
                    |> Expect.equal
                        ( [ PerformanceSlide Scene1 original.scene1, PerformanceSlide Scene2 original.scene2, PerformanceSlide Scene3 original.scene3 ]
                        , [ ConsequenceSlide Shadows1973 (SceneConflictsWithScript Scene1) ]
                        )
        , test "after 1973 resolves, the story returns to the present with the 1998 journal next" <|
            \_ ->
                send (perform retelling ++ [ Submit, Retry, Submit, Advance, Advance, Advance ]) (shadowAfter Fixtures.repairsSucceeded)
                    |> (\m -> ( m.phase, (Timeline.deriveWorld m.history).nextDiary ))
                    |> Expect.equal ( PresentHub, Just Search1998 )
        ]
