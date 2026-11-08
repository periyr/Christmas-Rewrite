module Save exposing (Place, Saved, decode, encode, placeOf, resume, storageVersion)

{-| Saving and loading progress (start/load menu).

History is the only stored progress (see CONTRACT.md). A save is that History
plus the Place the player had reached, turned into JSON. Main writes it to the
browser's localStorage through a port whenever either changes, and reads it
back as a flag when the page opens, so a player who leaves early comes back to
the same screen: the same introduction page, the shop, the ending, or the
chapter they were in. A chapter restarts from its beginning, because puzzle
arrangements are working state and never stored.

Every custom type is written as a plain string tag. Each type has one table
below that both the encoder and the decoder use, so the two cannot drift
apart. A save that cannot be read (an old version, edited by hand) is treated
as no save at all.

-}

import Domain exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Rules.Room
import Timeline
import Update


{-| A readable save. -}
type alias Saved =
    { history : History
    , place : Place
    }


{-| Where to come back to. -}
type Place
    = InIntroduction IntroStep
    | InShop
    | InChapter Era
    | AtEnding


{-| The place for the screen the player is on. A chapter counts only until it
is recorded in History; after that (its slides, the way home) the player comes
back to the shop, where the next diary is waiting.
-}
placeOf : Model -> Place
placeOf model =
    let
        chapter era =
            if List.any (\record -> record.era == era) model.history then
                InShop

            else
                InChapter era
    in
    case model.phase of
        Introduction step ->
            InIntroduction step

        PresentHub ->
            InShop

        Salvage _ ->
            chapter Repairs1950

        RepairBoard _ ->
            chapter Repairs1950

        ReopeningShelf _ ->
            chapter Repairs1950

        ShadowPuzzle _ ->
            chapter Shadows1973

        BookMystery _ ->
            chapter Search1998

        -- The broken frame comes after 1973 is recorded, so this is the shop.
        MendingFrame _ ->
            chapter Shadows1973

        Transition (OpeningDiary era) ->
            chapter era

        Transition (TimeTravel era _) ->
            chapter era

        Transition _ ->
            InShop

        Ending ->
            AtEnding


{-| Bumped if the format ever changes, so old saves are ignored, not misread. -}
storageVersion : Int
storageVersion =
    1



-- ═══════════════════════════════════════════════════════════════════════
-- RESUMING
-- ═══════════════════════════════════════════════════════════════════════


{-| The model to continue from: the saved History, on the saved Place. -}
resume : Saved -> Model
resume { history, place } =
    let
        start =
            Update.init

        finished =
            (Timeline.deriveWorld history).nextDiary == Nothing
    in
    { start
        | history = history
        , phase =
            case place of
                InIntroduction step ->
                    Introduction step

                InChapter era ->
                    Update.startChapter era

                _ ->
                    if finished then
                        Ending

                    else
                        PresentHub
        , room = Rules.Room.initialRoom
    }



-- ═══════════════════════════════════════════════════════════════════════
-- TOP LEVEL
-- ═══════════════════════════════════════════════════════════════════════


encode : Saved -> E.Value
encode { history, place } =
    E.object
        [ ( "version", E.int storageVersion )
        , ( "history", E.list encodeRecord history )
        , ( "place", encodePlace place )
        ]


{-| Reads a save from whatever the page passed in. Anything unreadable,
including no save at all (null), is Nothing.
-}
decode : D.Value -> Maybe Saved
decode value =
    D.decodeValue decoder value |> Result.toMaybe


decoder : Decoder Saved
decoder =
    D.field "version" D.int
        |> D.andThen
            (\version ->
                if version == storageVersion then
                    D.map2 Saved
                        (D.field "history" (D.list recordDecoder))
                        (D.field "place" placeDecoder)

                else
                    D.fail "unknown save version"
            )



encodePlace : Place -> E.Value
encodePlace place =
    case place of
        InIntroduction step ->
            E.object [ ( "kind", E.string "Introduction" ), ( "step", encodeTag introSteps step ) ]

        InShop ->
            E.object [ ( "kind", E.string "Shop" ) ]

        InChapter era ->
            E.object [ ( "kind", E.string "Chapter" ), ( "era", encodeTag eras era ) ]

        AtEnding ->
            E.object [ ( "kind", E.string "Ending" ) ]


placeDecoder : Decoder Place
placeDecoder =
    D.field "kind" D.string
        |> D.andThen
            (\kind ->
                case kind of
                    "Introduction" ->
                        D.map InIntroduction (D.field "step" (tagDecoder introSteps))

                    "Shop" ->
                        D.succeed InShop

                    "Chapter" ->
                        D.map InChapter (D.field "era" (tagDecoder eras))

                    "Ending" ->
                        D.succeed AtEnding

                    _ ->
                        D.fail ("unknown place " ++ kind)
            )



-- ═══════════════════════════════════════════════════════════════════════
-- RECORDS
-- ═══════════════════════════════════════════════════════════════════════


encodeRecord : ChapterRecord -> E.Value
encodeRecord record =
    E.object
        [ ( "era", encodeTag eras record.era )
        , ( "outcome", encodeTag outcomes record.outcome )
        , ( "attemptsUsed", E.int record.attemptsUsed )
        , ( "finalSubmission", encodeSubmission record.finalSubmission )
        , ( "finalViolations", E.list encodeViolation record.finalViolations )
        ]


recordDecoder : Decoder ChapterRecord
recordDecoder =
    D.map5 ChapterRecord
        (D.field "era" (tagDecoder eras))
        (D.field "outcome" (tagDecoder outcomes))
        (D.field "attemptsUsed" D.int)
        (D.field "finalSubmission" submissionDecoder)
        (D.field "finalViolations" (D.list violationDecoder))


encodeSubmission : FinalSubmission -> E.Value
encodeSubmission submission =
    case submission of
        RepairWeek week ->
            E.object
                [ ( "kind", E.string "RepairWeek" )
                , ( "monday", encodeTag tasks week.monday )
                , ( "tuesday", encodeTag tasks week.tuesday )
                , ( "wednesday", encodeTag tasks week.wednesday )
                , ( "thursday", encodeTag tasks week.thursday )
                , ( "friday", encodeTag tasks week.friday )
                , ( "notThisWeek", E.list (encodeTag tasks) week.notThisWeek )
                ]

        ShadowPerformance staging ->
            E.object
                [ ( "kind", E.string "ShadowPerformance" )
                , ( "scene1", encodeCast staging.scene1 )
                , ( "scene2", encodeCast staging.scene2 )
                , ( "scene3", encodeCast staging.scene3 )
                ]

        SentBook candidate ->
            E.object
                [ ( "kind", E.string "SentBook" )
                , ( "candidate", encodeTag candidates candidate )
                ]


submissionDecoder : Decoder FinalSubmission
submissionDecoder =
    D.field "kind" D.string
        |> D.andThen
            (\kind ->
                case kind of
                    "RepairWeek" ->
                        D.map6 WeekPlan
                            (D.field "monday" (tagDecoder tasks))
                            (D.field "tuesday" (tagDecoder tasks))
                            (D.field "wednesday" (tagDecoder tasks))
                            (D.field "thursday" (tagDecoder tasks))
                            (D.field "friday" (tagDecoder tasks))
                            (D.field "notThisWeek" (D.list (tagDecoder tasks)))
                            |> D.map RepairWeek

                    "ShadowPerformance" ->
                        D.map3 Staging
                            (D.field "scene1" castDecoder)
                            (D.field "scene2" castDecoder)
                            (D.field "scene3" castDecoder)
                            |> D.map ShadowPerformance

                    "SentBook" ->
                        D.field "candidate" (tagDecoder candidates)
                            |> D.map SentBook

                    _ ->
                        D.fail ("unknown submission " ++ kind)
            )


encodeCast : SceneCast -> E.Value
encodeCast cast =
    E.object
        [ ( "character", encodeTag characters cast.character )
        , ( "prop", encodeTag props cast.prop )
        ]


castDecoder : Decoder SceneCast
castDecoder =
    D.map2 SceneCast
        (D.field "character" (tagDecoder characters))
        (D.field "prop" (tagDecoder props))



-- ═══════════════════════════════════════════════════════════════════════
-- VIOLATIONS
-- ═══════════════════════════════════════════════════════════════════════


encodeViolation : Violation -> E.Value
encodeViolation violation =
    let
        tagged kind fields =
            E.object (( "kind", E.string kind ) :: fields)
    in
    case violation of
        RoofAfterRain day ->
            tagged "RoofAfterRain" [ ( "day", encodeTag days day ) ]

        GlassNotYetDelivered day ->
            tagged "GlassNotYetDelivered" [ ( "day", encodeTag days day ) ]

        MustComeBefore first second ->
            tagged "MustComeBefore" [ ( "first", encodeTag tasks first ), ( "second", encodeTag tasks second ) ]

        TimberOverspent n ->
            tagged "TimberOverspent" [ ( "amount", E.int n ) ]

        MoneyOverspent n ->
            tagged "MoneyOverspent" [ ( "amount", E.int n ) ]

        GoalMissing goal ->
            tagged "GoalMissing" [ ( "goal", encodeTag goals goal ) ]

        SceneConflictsWithScript scene ->
            tagged "SceneConflictsWithScript" [ ( "scene", encodeTag scenes scene ) ]

        DetailDoesNotMatch detail ->
            tagged "DetailDoesNotMatch" [ ( "detail", encodeTag details detail ) ]


violationDecoder : Decoder Violation
violationDecoder =
    D.field "kind" D.string
        |> D.andThen
            (\kind ->
                case kind of
                    "RoofAfterRain" ->
                        D.map RoofAfterRain (D.field "day" (tagDecoder days))

                    "GlassNotYetDelivered" ->
                        D.map GlassNotYetDelivered (D.field "day" (tagDecoder days))

                    "MustComeBefore" ->
                        D.map2 MustComeBefore (D.field "first" (tagDecoder tasks)) (D.field "second" (tagDecoder tasks))

                    "TimberOverspent" ->
                        D.map TimberOverspent (D.field "amount" D.int)

                    "MoneyOverspent" ->
                        D.map MoneyOverspent (D.field "amount" D.int)

                    "GoalMissing" ->
                        D.map GoalMissing (D.field "goal" (tagDecoder goals))

                    "SceneConflictsWithScript" ->
                        D.map SceneConflictsWithScript (D.field "scene" (tagDecoder scenes))

                    "DetailDoesNotMatch" ->
                        D.map DetailDoesNotMatch (D.field "detail" (tagDecoder details))

                    _ ->
                        D.fail ("unknown violation " ++ kind)
            )



-- ═══════════════════════════════════════════════════════════════════════
-- TAG TABLES: one per custom type, shared by the encoder and the decoder
-- ═══════════════════════════════════════════════════════════════════════


encodeTag : List ( a, String ) -> a -> E.Value
encodeTag table value =
    table
        |> List.filter (\( v, _ ) -> v == value)
        |> List.head
        |> Maybe.map (Tuple.second >> E.string)
        |> Maybe.withDefault E.null


tagDecoder : List ( a, String ) -> Decoder a
tagDecoder table =
    D.string
        |> D.andThen
            (\name ->
                case List.filter (\( _, n ) -> n == name) table of
                    ( value, _ ) :: _ ->
                        D.succeed value

                    [] ->
                        D.fail ("unknown tag " ++ name)
            )


eras : List ( Era, String )
eras =
    [ ( Repairs1950, "Repairs1950" ), ( Shadows1973, "Shadows1973" ), ( Search1998, "Search1998" ) ]


introSteps : List ( IntroStep, String )
introSteps =
    [ ( PackingUp, "PackingUp" ), ( DiariesFound, "DiariesFound" ), ( ClockStopped, "ClockStopped" ) ]


outcomes : List ( Outcome, String )
outcomes =
    [ ( Succeeded, "Succeeded" ), ( Failed, "Failed" ) ]


days : List ( Day, String )
days =
    [ ( Monday, "Monday" ), ( Tuesday, "Tuesday" ), ( Wednesday, "Wednesday" ), ( Thursday, "Thursday" ), ( Friday, "Friday" ) ]


tasks : List ( TaskId, String )
tasks =
    [ ( PatchRoof, "PatchRoof" )
    , ( ClearRubble, "ClearRubble" )
    , ( BuildShelves, "BuildShelves" )
    , ( ShelveBooks, "ShelveBooks" )
    , ( ReglazeWindow, "ReglazeWindow" )
    , ( PaintSign, "PaintSign" )
    , ( BoardUpWindow, "BoardUpWindow" )
    ]


goals : List ( ReopeningGoal, String )
goals =
    [ ( WatertightRoof, "WatertightRoof" ), ( SealedWindow, "SealedWindow" ), ( UsableShelves, "UsableShelves" ), ( AllBooksShelved, "AllBooksShelved" ) ]


characters : List ( Character, String )
characters =
    [ ( Fox, "Fox" ), ( Owl, "Owl" ), ( Child, "Child" ) ]


props : List ( Prop, String )
props =
    [ ( Lantern, "Lantern" ), ( Key, "Key" ), ( Book, "Book" ) ]


scenes : List ( Scene, String )
scenes =
    [ ( Scene1, "Scene1" ), ( Scene2, "Scene2" ), ( Scene3, "Scene3" ) ]


candidates : List ( CandidateId, String )
candidates =
    [ ( CandidateA, "CandidateA" ), ( CandidateB, "CandidateB" ), ( CandidateC, "CandidateC" ), ( CandidateD, "CandidateD" ) ]


details : List ( RememberedDetail, String )
details =
    [ ( FoxLanternIllustration, "FoxLanternIllustration" ), ( LanternSentence, "LanternSentence" ), ( LucyInscription, "LucyInscription" ) ]
