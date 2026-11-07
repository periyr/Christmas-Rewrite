module Timeline exposing (append, deriveWorld, eras, fate, nextEra, outcomeOf, recordFor, rewindTo, slides)

{-| Chapter history and everything derived from it.

History is the only stored progress. The World, the next diary, the ending,
clue/script variants and slideshows are all computed from it, so they can
never disagree with it. Same history in, same world out.

-}

import Domain exposing (..)
import Rules.Repair


{-| Play order. -}
eras : List Era
eras =
    [ Repairs1950, Shadows1973, Search1998 ]


eraIndex : Era -> Int
eraIndex era =
    case era of
        Repairs1950 ->
            0

        Shadows1973 ->
            1

        Search1998 ->
            2


recordFor : Era -> History -> Maybe ChapterRecord
recordFor era history =
    history
        |> List.filter (\record -> record.era == era)
        |> List.head


outcomeOf : Era -> History -> Maybe Outcome
outcomeOf era history =
    Maybe.map .outcome (recordFor era history)


{-| The first era without a record, if any. -}
nextEra : History -> Maybe Era
nextEra history =
    eras
        |> List.filter (\era -> recordFor era history == Nothing)
        |> List.head


{-| Add a resolved chapter. Ignored unless it is the next era, so history
stays in order and a chapter can never be recorded twice.
-}
append : ChapterRecord -> History -> History
append record history =
    if nextEra history == Just record.era then
        history ++ [ record ]

    else
        history


{-| Reopening a diary: keep only chapters before `era`. -}
rewindTo : Era -> History -> History
rewindTo era history =
    List.filter (\record -> eraIndex record.era < eraIndex era) history


{-| Known once all three chapters are resolved. -}
fate : History -> Maybe ShopFate
fate history =
    let
        outcomes =
            List.map (\era -> ( era, outcomeOf era history )) eras

        failed =
            List.filterMap
                (\( era, outcome ) ->
                    if outcome == Just Failed then
                        Just era

                    else
                        Nothing
                )
                outcomes
    in
    if List.any (\( _, outcome ) -> outcome == Nothing) outcomes then
        Nothing

    else if List.isEmpty failed then
        Just ShopSaved

    else
        Just (ShopClosed failed)


foundation : Era -> History -> Foundation
foundation era history =
    case outcomeOf era history of
        Nothing ->
            NotRevisited

        Just Succeeded ->
            Established

        Just Failed ->
            Missing


{-| The present-day world and the variants later chapters use.

An unrevisited 1950/1973 counts as the original (failed) history, so it
yields the retelling / follow-up-email variants. In play these variants are
only read after the earlier chapter is resolved.

-}
deriveWorld : History -> World
deriveWorld history =
    { premises = foundation Repairs1950 history
    , tradition = foundation Shadows1973 history
    , onlineService = foundation Search1998 history
    , scriptVariant =
        if outcomeOf Repairs1950 history == Just Succeeded then
            OriginalScript

        else
            NeighboursRetelling
    , inscriptionSource =
        if outcomeOf Shadows1973 history == Just Succeeded then
            FamilyArchive

        else
            FollowUpEmail
    , nextDiary = nextEra history
    , fate = fate history
    }


{-| Slides shown after a chapter resolves, generated from its record.

1950 success follows the submitted week day by day, then Saturday.
A failure shows the consequence of the first recorded violation.

-}
slides : Era -> History -> List Slide
slides era history =
    case recordFor era history of
        Nothing ->
            []

        Just record ->
            case ( record.outcome, record.finalSubmission ) of
                ( Succeeded, RepairWeek week ) ->
                    List.map (\day -> WeekdaySlide day (Rules.Repair.taskOn day week)) Rules.Repair.days
                        ++ [ ReopeningSaturday ]

                ( Succeeded, ShadowPerformance staging ) ->
                    [ PerformanceSlide Scene1 staging.scene1
                    , PerformanceSlide Scene2 staging.scene2
                    , PerformanceSlide Scene3 staging.scene3
                    ]

                ( Succeeded, SentBook _ ) ->
                    [ ServiceFoundedSlide ]

                ( Failed, _ ) ->
                    List.map (ConsequenceSlide era) (List.take 1 record.finalViolations)
