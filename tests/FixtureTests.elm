module FixtureTests exposing (suite)

{-| The 1973 and 1998 development fixtures are real game states: the variant
in each name is what the history derives, the feedback fixtures are what
Submit produces, and each one still plays on correctly.
-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Mystery as Mystery
import Rules.Placement as Placement
import Rules.Room as Room
import Rules.Shadow as Shadow
import Test exposing (Test, describe, test)
import Timeline
import Update


send : List Msg -> Model -> Model
send msgs model =
    List.foldl Update.update model msgs


shadowPuzzle : Model -> Maybe (MainPuzzle (Placement Cutout ShadowSlot))
shadowPuzzle model =
    case model.phase of
        ShadowPuzzle puzzle ->
            Just puzzle

        _ ->
            Nothing


mysteryPuzzle : Model -> Maybe (MainPuzzle (Maybe CandidateId))
mysteryPuzzle model =
    case model.phase of
        BookMystery puzzle ->
            Just puzzle

        _ ->
            Nothing


{-| Place a whole staging through real moves, then perform it. -}
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
        ++ [ Submit ]


suite : Test
suite =
    describe "1973 and 1998 development fixtures"
        [ describe "1973"
            [ test "shadowOriginalScript and shadowRetelling derive the variant they are named after" <|
                \_ ->
                    [ Fixtures.shadowOriginalScript, Fixtures.shadowRetelling ]
                        |> List.map (\m -> (Timeline.deriveWorld m.history).scriptVariant)
                        |> Expect.equal [ OriginalScript, NeighboursRetelling ]
            , test "both are a fresh stage with two attempts, the panel open at the stage" <|
                \_ ->
                    [ Fixtures.shadowOriginalScript, Fixtures.shadowRetelling ]
                        |> List.map (\m -> ( shadowPuzzle m, m.room.panelOpen, m.room.player.x ))
                        |> Expect.equal
                            (List.repeat 2
                                ( Just { arrangement = Placement.empty, inspected = [], attempts = NoAttemptUsed }
                                , True
                                , (Room.position StageSpot).x
                                )
                            )
            , test "each is solved by its own script, in one attempt" <|
                \_ ->
                    [ send (perform (Shadow.script OriginalScript)) Fixtures.shadowOriginalScript
                    , send (perform (Shadow.script NeighboursRetelling)) Fixtures.shadowRetelling
                    ]
                        |> List.map (.history >> Timeline.recordFor Shadows1973 >> Maybe.map (\r -> ( r.outcome, r.attemptsUsed )))
                        |> Expect.equal [ Just ( Succeeded, 1 ), Just ( Succeeded, 1 ) ]
            , test "shadowFirstAttemptFailed shows every scene conflicting, keeps the stage, and waits for Retry" <|
                \_ ->
                    Fixtures.shadowFirstAttemptFailed
                        |> shadowPuzzle
                        |> Maybe.map (\p -> ( p.attempts, Shadow.complete p.arrangement ))
                        |> Expect.equal
                            (Just
                                ( ReviewingFirstMistake (List.map SceneConflictsWithScript [ Scene1, Scene2, Scene3 ])
                                , Just (Shadow.script NeighboursRetelling)
                                )
                            )
            , test "shadowFirstAttemptFailed: Submit is ignored until Retry, then the final attempt can succeed" <|
                \_ ->
                    ( send [ Submit ] Fixtures.shadowFirstAttemptFailed == Fixtures.shadowFirstAttemptFailed
                    , send (Retry :: perform (Shadow.script OriginalScript)) Fixtures.shadowFirstAttemptFailed
                        |> .history
                        |> Timeline.recordFor Shadows1973
                        |> Maybe.map (\r -> ( r.outcome, r.attemptsUsed ))
                    )
                        |> Expect.equal ( True, Just ( Succeeded, 2 ) )
            , test "shadowsFailed is exactly what two wrong performances record" <|
                \_ ->
                    send (Retry :: [ Submit ]) Fixtures.shadowFirstAttemptFailed
                        |> .history
                        |> Timeline.recordFor Shadows1973
                        |> Expect.equal (Just Fixtures.shadowsFailed)
            , test "shadowsSucceeded is exactly what a right first performance records" <|
                \_ ->
                    send (perform (Shadow.script OriginalScript)) Fixtures.shadowOriginalScript
                        |> .history
                        |> Timeline.recordFor Shadows1973
                        |> Expect.equal (Just Fixtures.shadowsSucceeded)
            , test "closing the panel shows the 1973 room with its three clues and the stage" <|
                \_ ->
                    send [ ClosePanel ] Fixtures.shadowRetelling
                        |> (\m -> ( Room.canWalk m, Room.hotspots m.phase ))
                        |> Expect.equal ( True, [ ClueSpot CutoutBox, ClueSpot ShadowScript, StageSpot, ClueSpot StageSketch ] )
            ]
        , describe "1998"
            [ test "mysteryFamilyArchive and mysteryFollowUpEmail derive the inscription source they are named after" <|
                \_ ->
                    [ Fixtures.mysteryFamilyArchive, Fixtures.mysteryFollowUpEmail ]
                        |> List.map (\m -> (Timeline.deriveWorld m.history).inscriptionSource)
                        |> Expect.equal [ FamilyArchive, FollowUpEmail ]
            , test "both are a fresh table with two attempts, the panel open at the books" <|
                \_ ->
                    [ Fixtures.mysteryFamilyArchive, Fixtures.mysteryFollowUpEmail ]
                        |> List.map (\m -> ( mysteryPuzzle m, m.room.panelOpen, m.room.player.x ))
                        |> Expect.equal
                            (List.repeat 2
                                ( Just { arrangement = Nothing, inspected = [], attempts = NoAttemptUsed }
                                , True
                                , (Room.position BookTableSpot).x
                                )
                            )
            , test "candidate A solves both" <|
                \_ ->
                    [ Fixtures.mysteryFamilyArchive, Fixtures.mysteryFollowUpEmail ]
                        |> List.map (send [ ChooseCandidate CandidateA, Submit ] >> .history >> Timeline.outcomeOf Search1998)
                        |> Expect.equal [ Just Succeeded, Just Succeeded ]
            , test "mysteryWrongBookSent: one attempt, so book B loses 1998 with the inscription mismatch" <|
                \_ ->
                    Fixtures.mysteryWrongBookSent
                        |> (\m -> ( m.phase, Timeline.recordFor Search1998 m.history |> Maybe.map (\r -> ( r.outcome, r.attemptsUsed, r.finalViolations )) ))
                        |> Expect.equal ( Transition (Slideshow Search1998 0), Just ( Failed, 1, Mystery.validate CandidateB ) )
            , test "mysteryWrongBookSent: choosing and sending again are ignored" <|
                \_ ->
                    send [ ChooseCandidate CandidateA, Submit, Retry ] Fixtures.mysteryWrongBookSent
                        |> Expect.equal Fixtures.mysteryWrongBookSent
            , test "closing the panel shows the 1998 room with its three clues and the books" <|
                \_ ->
                    send [ ClosePanel ] Fixtures.mysteryFollowUpEmail
                        |> (\m -> ( Room.canWalk m, Room.hotspots m.phase ))
                        |> Expect.equal ( True, [ ClueSpot RuthsEmail, ClueSpot InscriptionClue, BookTableSpot, ClueSpot RememberedSentence ] )
            ]
        ]
