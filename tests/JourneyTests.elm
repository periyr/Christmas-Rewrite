module JourneyTests exposing (suite)

{-| Whole games through Update.update only, from a new game to an ending,
using the same actions the screens send: every pass/fail combination of the
three chapters, and reopening a diary from an ending and playing on.

The answer for 1973 is read from the derived world, as a player reads the
script: after a failed 1950 the retelling is the right staging.

-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Room as Room
import Rules.Salvage as Salvage
import Rules.Repair as Repair
import Rules.Shadow as Shadow
import Test exposing (Test, describe, test)
import Timeline
import Update



-- PLAYING


send : List Msg -> Model -> Model
send msgs model =
    List.foldl Update.update model msgs


{-| A new game, through the three introduction screens to the present. -}
newGame : Model
newGame =
    send [ Advance, Advance, Advance ] Update.init


{-| From the present: open the glowing diary, step in (skipping the trip), resolve it with the given
outcome (a wrong answer twice for a failure), then play the slides through
to the present or the ending.
-}
playChapter : Outcome -> Model -> Model
playChapter outcome model =
    let
        opened =
            send [ OpenNextDiary, Advance, SkipTravel ] model

        world =
            Timeline.deriveWorld opened.history

        answer =
            case opened.phase of
                Salvage _ ->
                    sortBooks ++ [ Advance ] ++ planWeek (pick outcome Fixtures.validWeek Fixtures.wrongWeek)

                ShadowPuzzle _ ->
                    stage (Shadow.script (pick outcome world.scriptVariant (otherScript world.scriptVariant)))

                BookMystery _ ->
                    [ ChooseCandidate (pick outcome CandidateA CandidateB) ]

                _ ->
                    []

        submissions =
            pick outcome [ Submit ] [ Submit, Retry, Submit ]
    in
    send (answer ++ submissions) opened
        |> playOn 40


pick : Outcome -> a -> a -> a
pick outcome right wrong =
    case outcome of
        Succeeded ->
            right

        Failed ->
            wrong


otherScript : ScriptVariant -> ScriptVariant
otherScript variant =
    case variant of
        OriginalScript ->
            NeighboursRetelling

        NeighboursRetelling ->
            OriginalScript


{-| Advance through slides (shelving small to tall when the shelf appears)
until the present or an ending. Runs out of fuel rather than looping.
-}
playOn : Int -> Model -> Model
playOn fuel model =
    if fuel <= 0 then
        model

    else
        case model.phase of
            PresentHub ->
                model

            Ending ->
                model

            ReopeningShelf _ ->
                playOn (fuel - 1) (send (shelveSmallToTall ++ [ Advance ]) model)

            MendingFrame _ ->
                playOn (fuel - 1) (send (mendFrame ++ [ Advance ]) model)

            Transition (TearToPresent _ _) ->
                playOn (fuel - 1) (send [ SkipTravel ] model)

            _ ->
                playOn (fuel - 1) (send [ Advance ] model)


{-| Every piece of glass into its own gap (1973, contract v1.7). -}
mendFrame : List Msg
mendFrame =
    List.concatMap (\n -> [ FrameMove (SelectItem (Shard n)), FrameMove (PlaceSelected (FrameGap n)) ]) (List.range 1 9)


playGame : ( Outcome, Outcome, Outcome ) -> Model
playGame ( first, second, third ) =
    newGame
        |> playChapter first
        |> playChapter second
        |> playChapter third


sortBooks : List Msg
sortBooks =
    [ ( Recoverable AtlasOfSmallPlaces, Fine )
    , ( Recoverable PocketOfWonders, Fine )
    , ( Recoverable WinterTales, Fine )
    , ( Recoverable BirdsongForBeginners, NeedsRepair )
    , ( Recoverable GardensInWinter, NeedsRepair )
    , ( Recoverable LettersFromTheSea, NeedsRepair )
    , ( Ruined HarbourTales, TooFarGone )
    , ( Ruined MountainPaths, TooFarGone )
    , ( Ruined WinterAlmanac, TooFarGone )
    ]
        |> List.concatMap (\( book, crate ) -> [ SalvageMove (SelectItem book), SalvageMove (PlaceSelectedInGroup (Salvage.crateSlots crate)) ])


planWeek : WeekPlan -> List Msg
planWeek week =
    List.concatMap
        (\day -> [ BoardMove (SelectItem (Repair.taskOn day week)), BoardMove (PlaceSelected (OnDay day)) ])
        Repair.days
        ++ List.concatMap
            (\task -> [ BoardMove (SelectItem task), BoardMove (PlaceSelectedInGroup Repair.notThisWeekSlots) ])
            week.notThisWeek


shelveSmallToTall : List Msg
shelveSmallToTall =
    [ BirdsongForBeginners, GardensInWinter, PocketOfWonders, AtlasOfSmallPlaces, LettersFromTheSea, WinterTales ]
        |> List.indexedMap (\i book -> [ ShelfMove (SelectItem book), ShelfMove (PlaceSelected (ShelfPosition (i + 1))) ])
        |> List.concat


stage : Staging -> List Msg
stage staging =
    List.concatMap
        (\( scene, cast ) ->
            [ StageMove (SelectItem (CharacterCutout cast.character))
            , StageMove (PlaceSelected (CharacterSlot scene))
            , StageMove (SelectItem (PropCutout cast.prop))
            , StageMove (PlaceSelected (PropSlot scene))
            ]
        )
        [ ( Scene1, staging.scene1 ), ( Scene2, staging.scene2 ), ( Scene3, staging.scene3 ) ]


combinations : List ( Outcome, Outcome, Outcome )
combinations =
    List.concatMap
        (\a -> List.concatMap (\b -> List.map (\c -> ( a, b, c )) [ Succeeded, Failed ]) [ Succeeded, Failed ])
        [ Succeeded, Failed ]


{-| What a finished game recorded: each chapter's outcome and attempts. -}
summary : Model -> List ( Era, Outcome, Int )
summary model =
    List.map (\record -> ( record.era, record.outcome, record.attemptsUsed )) model.history


expectedFate : ( Outcome, Outcome, Outcome ) -> ShopFate
expectedFate ( a, b, c ) =
    case List.filterMap identity [ failedIn Repairs1950 a, failedIn Shadows1973 b, failedIn Search1998 c ] of
        [] ->
            ShopSaved

        failed ->
            ShopClosed failed


failedIn : Era -> Outcome -> Maybe Era
failedIn era outcome =
    if outcome == Failed then
        Just era

    else
        Nothing


attemptsFor : Outcome -> Int
attemptsFor outcome =
    pick outcome 1 2



-- TESTS


suite : Test
suite =
    describe "Whole games"
        [ describe "every pass/fail combination, played from a new game" <|
            List.map
                (\(( a, b, c ) as plan) ->
                    test (Debug.toString plan) <|
                        \_ ->
                            playGame plan
                                |> (\m -> ( m.phase, Timeline.fate m.history, summary m ))
                                |> Expect.equal
                                    ( Ending
                                    , Just (expectedFate plan)
                                    , [ ( Repairs1950, a, attemptsFor a ), ( Shadows1973, b, attemptsFor b ), ( Search1998, c, attemptsFor c ) ]
                                    )
                )
                combinations
        , test "between chapters the story always comes back to the present with the next diary glowing" <|
            \_ ->
                [ newGame |> playChapter Failed
                , newGame |> playChapter Failed |> playChapter Failed
                ]
                    |> List.map (\m -> ( m.phase, (Timeline.deriveWorld m.history).nextDiary, m.room ))
                    |> Expect.equal
                        [ ( PresentHub, Just Shadows1973, Room.initialRoom )
                        , ( PresentHub, Just Search1998, Room.initialRoom )
                        ]
        , describe "reopening a diary from an ending"
            [ test "reopening a failed 1973 keeps 1950, gives two fresh attempts, and can turn a closed shop into a saved one" <|
                \_ ->
                    let
                        closed =
                            playGame ( Succeeded, Failed, Succeeded )

                        reopened =
                            send [ ReopenDiary Shadows1973, Advance, SkipTravel ] closed

                        -- One wrong performance, then the right one: only possible with two attempts.
                        replayed =
                            send (stage (Shadow.script NeighboursRetelling) ++ [ Submit, Retry ] ++ stage (Shadow.script OriginalScript) ++ [ Submit ]) reopened
                                |> playOn 40

                        finished =
                            playChapter Succeeded replayed
                    in
                    Expect.all
                        [ \_ -> Timeline.fate closed.history |> Expect.equal (Just (ShopClosed [ Shadows1973 ]))
                        , \_ -> ( reopened.history, reopened.phase, reopened.room ) |> Expect.equal ( List.take 1 closed.history, Update.startChapter Shadows1973, Room.initialRoom )
                        , \_ -> Timeline.recordFor Shadows1973 replayed.history |> Maybe.map (\r -> ( r.outcome, r.attemptsUsed )) |> Expect.equal (Just ( Succeeded, 2 ))
                        , \_ -> ( replayed.phase, (Timeline.deriveWorld replayed.history).nextDiary ) |> Expect.equal ( PresentHub, Just Search1998 )
                        , \_ -> ( finished.phase, Timeline.fate finished.history ) |> Expect.equal ( Ending, Just ShopSaved )
                        ]
                        ()
            , test "reopening 1950 from the saved ending clears everything, replays from salvage, and a failure there changes the 1973 script" <|
                \_ ->
                    let
                        reopened =
                            send [ ReopenDiary Repairs1950, Advance, SkipTravel ] (playGame ( Succeeded, Succeeded, Succeeded ))

                        afterFailing =
                            replay1950 Failed reopened
                    in
                    ( ( reopened.history, reopened.phase )
                    , ( afterFailing.phase, (Timeline.deriveWorld afterFailing.history).scriptVariant, (Timeline.deriveWorld afterFailing.history).nextDiary )
                    )
                        |> Expect.equal
                            ( ( [], Update.startChapter Repairs1950 )
                            , ( PresentHub, NeighboursRetelling, Just Shadows1973 )
                            )
            , test "reopening the 1998 journal keeps 1950 and 1973 exactly as they were" <|
                \_ ->
                    let
                        ended =
                            playGame ( Failed, Succeeded, Failed )
                    in
                    send [ ReopenDiary Search1998, Advance, SkipTravel ] ended
                        |> (\m -> ( m.history, m.phase ))
                        |> Expect.equal ( List.take 2 ended.history, Update.startChapter Search1998 )
            , test "Start again from an ending is a brand-new game" <|
                \_ ->
                    send [ StartAgain ] (playGame ( Failed, Failed, Failed ))
                        |> Expect.equal Update.init
            ]
        ]


{-| Finish a replayed 1950 that is already at salvage. -}
replay1950 : Outcome -> Model -> Model
replay1950 outcome model =
    send (sortBooks ++ [ Advance ] ++ planWeek (pick outcome Fixtures.validWeek Fixtures.wrongWeek) ++ pick outcome [ Submit ] [ Submit, Retry, Submit ]) model
        |> playOn 40
