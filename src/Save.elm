module Save exposing (Saved, decode, encode, resume, storageVersion)

{-| Saving and loading progress (start/load menu).

History is the only stored progress (see CONTRACT.md), so a save is just the
History, turned into JSON. Main writes it to the browser's localStorage through
a port whenever the player reaches a checkpoint (the present-day shop or the
ending), and reads it back as a flag when the page opens.

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


{-| A readable save: the History it holds. -}
type alias Saved =
    History


{-| Bumped if the format ever changes, so old saves are ignored, not misread. -}
storageVersion : Int
storageVersion =
    1



-- ═══════════════════════════════════════════════════════════════════════
-- RESUMING
-- ═══════════════════════════════════════════════════════════════════════


{-| The model to continue from: the saved History, back in the present-day
shop, or at the ending once every diary has been resolved.
-}
resume : Saved -> Model
resume history =
    let
        start =
            Update.init
    in
    { start
        | history = history
        , phase =
            case (Timeline.deriveWorld history).nextDiary of
                Just _ ->
                    PresentHub

                Nothing ->
                    Ending
        , room = Rules.Room.initialRoom
    }



-- ═══════════════════════════════════════════════════════════════════════
-- TOP LEVEL
-- ═══════════════════════════════════════════════════════════════════════


encode : Saved -> E.Value
encode history =
    E.object
        [ ( "version", E.int storageVersion )
        , ( "history", E.list encodeRecord history )
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
                    D.field "history" (D.list recordDecoder)

                else
                    D.fail "unknown save version"
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
