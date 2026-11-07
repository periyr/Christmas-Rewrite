module Update exposing (init, startChapter, update)

{-| The single, pure update entry point.

Actions that do not make sense in the current phase are ignored, which is
what makes double clicks and clicks during feedback/transitions harmless.

-}

import Domain exposing (..)
import Rules.Attempts as Attempts exposing (SubmitResult(..))
import Rules.Mystery
import Rules.Placement as Placement
import Rules.Repair
import Rules.Salvage
import Rules.Shadow
import Rules.Shelf
import Timeline


init : Model
init =
    { history = []
    , phase = Introduction PackingUp
    , inspecting = Nothing
    , notice = Nothing
    }


freshPuzzle : arrangement -> MainPuzzle arrangement
freshPuzzle arrangement =
    { arrangement = arrangement, inspected = [], attempts = NoAttemptUsed }


{-| The first phase of a diary, with completely fresh state.
Replaying 1950 starts at salvage; the introduction never repeats.
-}
startChapter : Era -> Phase
startChapter era =
    case era of
        Repairs1950 ->
            Salvage Placement.empty

        Shadows1973 ->
            ShadowPuzzle (freshPuzzle Placement.empty)

        Search1998 ->
            BookMystery (freshPuzzle Nothing)


goTo : Phase -> Model -> Model
goTo phase model =
    { model | phase = phase, inspecting = Nothing, notice = Nothing }


update : Msg -> Model -> Model
update msg model =
    case msg of
        Inspect clue ->
            { model | inspecting = Just clue, phase = noteInspected clue model.phase }

        CloseInspection ->
            { model | inspecting = Nothing }

        DismissNotice ->
            { model | notice = Nothing }

        SalvageMove action ->
            case model.phase of
                Salvage placement ->
                    withPlacement Salvage (Placement.apply Rules.Salvage.accepts action placement) model

                _ ->
                    model

        BoardMove action ->
            case model.phase of
                RepairBoard puzzle ->
                    movePuzzle RepairBoard Rules.Repair.accepts action puzzle model

                _ ->
                    model

        ShelfMove action ->
            case model.phase of
                ReopeningShelf placement ->
                    withPlacement ReopeningShelf (Placement.apply Rules.Shelf.accepts action placement) model

                _ ->
                    model

        StageMove action ->
            case model.phase of
                ShadowPuzzle puzzle ->
                    movePuzzle ShadowPuzzle Rules.Shadow.accepts action puzzle model

                _ ->
                    model

        ChooseCandidate candidate ->
            case model.phase of
                BookMystery puzzle ->
                    if isReviewing puzzle then
                        model

                    else
                        { model | phase = BookMystery { puzzle | arrangement = Just candidate }, notice = Nothing }

                _ ->
                    model

        Submit ->
            submit model

        Retry ->
            case model.phase of
                RepairBoard puzzle ->
                    { model | phase = RepairBoard (Attempts.retry puzzle) }

                ShadowPuzzle puzzle ->
                    { model | phase = ShadowPuzzle (Attempts.retry puzzle) }

                BookMystery puzzle ->
                    { model | phase = BookMystery (Attempts.retry puzzle) }

                _ ->
                    model

        Advance ->
            advance model

        OpenNextDiary ->
            case model.phase of
                PresentHub ->
                    case Timeline.nextEra model.history of
                        Just era ->
                            goTo (Transition (OpeningDiary era)) model

                        Nothing ->
                            goTo Ending model

                _ ->
                    model

        ReopenDiary era ->
            case model.phase of
                Ending ->
                    goTo (Transition (OpeningDiary era)) { model | history = Timeline.rewindTo era model.history }

                _ ->
                    model

        StartAgain ->
            case model.phase of
                Ending ->
                    init

                _ ->
                    model



-- PLACEMENT


withPlacement : (Placement item slot -> Phase) -> ( Placement item slot, Maybe Notice ) -> Model -> Model
withPlacement wrap ( placement, notice ) model =
    { model | phase = wrap placement, notice = notice }


{-| Rearranging is free, but frozen while first-attempt feedback is open. -}
movePuzzle :
    (MainPuzzle (Placement item slot) -> Phase)
    -> (item -> slot -> Bool)
    -> PlacementAction item slot
    -> MainPuzzle (Placement item slot)
    -> Model
    -> Model
movePuzzle wrap accepts action puzzle model =
    if isReviewing puzzle then
        model

    else
        let
            ( arrangement, notice ) =
                Placement.apply accepts action puzzle.arrangement
        in
        { model | phase = wrap { puzzle | arrangement = arrangement }, notice = notice }


isReviewing : MainPuzzle a -> Bool
isReviewing puzzle =
    case puzzle.attempts of
        ReviewingFirstMistake _ ->
            True

        _ ->
            False


noteInspected : ClueId -> Phase -> Phase
noteInspected clue phase =
    let
        note puzzle =
            if List.member clue puzzle.inspected then
                puzzle

            else
                { puzzle | inspected = puzzle.inspected ++ [ clue ] }
    in
    case phase of
        RepairBoard puzzle ->
            RepairBoard (note puzzle)

        ShadowPuzzle puzzle ->
            ShadowPuzzle (note puzzle)

        BookMystery puzzle ->
            BookMystery (note puzzle)

        _ ->
            phase



-- SUBMISSION


submit : Model -> Model
submit model =
    case model.phase of
        RepairBoard puzzle ->
            applySubmit RepairBoard
                (Attempts.submit
                    { era = Repairs1950
                    , complete = Rules.Repair.complete
                    , validate = Rules.Repair.validate
                    , toFinal = RepairWeek
                    }
                    puzzle
                )
                puzzle
                model

        ShadowPuzzle puzzle ->
            applySubmit ShadowPuzzle
                (Attempts.submit
                    { era = Shadows1973
                    , complete = Rules.Shadow.complete
                    , validate = Rules.Shadow.validate (Timeline.deriveWorld model.history).scriptVariant
                    , toFinal = ShadowPerformance
                    }
                    puzzle
                )
                puzzle
                model

        BookMystery puzzle ->
            applySubmit BookMystery
                (Attempts.submit
                    { era = Search1998
                    , complete = Rules.Mystery.complete
                    , validate = Rules.Mystery.validate
                    , toFinal = SentBook
                    }
                    puzzle
                )
                puzzle
                model

        _ ->
            model


applySubmit : (MainPuzzle a -> Phase) -> SubmitResult -> MainPuzzle a -> Model -> Model
applySubmit wrap result puzzle model =
    case result of
        Ignored ->
            model

        Incomplete ->
            { model | notice = Just IncompleteSubmission }

        FirstMistake violations ->
            { model | phase = wrap { puzzle | attempts = ReviewingFirstMistake violations }, notice = Nothing }

        Resolved record ->
            goTo (Transition (Slideshow record.era 0)) { model | history = Timeline.append record model.history }



-- PROGRESSION


advance : Model -> Model
advance model =
    case model.phase of
        Introduction PackingUp ->
            goTo (Introduction DiariesFound) model

        Introduction DiariesFound ->
            goTo (Introduction ClockStopped) model

        Introduction ClockStopped ->
            goTo (Transition (OpeningDiary Repairs1950)) model

        Transition (OpeningDiary era) ->
            goTo (startChapter era) model

        Salvage placement ->
            if Rules.Salvage.isSolved placement then
                goTo (RepairBoard (freshPuzzle Placement.empty)) model

            else
                model

        ReopeningShelf placement ->
            case ( Rules.Shelf.matchedOrder placement, shelvingSlideIndex model.history ) of
                ( Just _, Just index ) ->
                    goTo (Transition (Slideshow Repairs1950 (index + 1))) model

                _ ->
                    model

        Transition (Slideshow era index) ->
            let
                all =
                    Timeline.slides era model.history
            in
            case List.head (List.drop index all) of
                Just (WeekdaySlide _ ShelveBooks) ->
                    -- Pause the successful week on its shelving day for the shelf scene.
                    goTo (ReopeningShelf Placement.empty) model

                _ ->
                    if index + 1 < List.length all then
                        goTo (Transition (Slideshow era (index + 1))) model

                    else
                        goTo (Transition ReturningToPresent) model

        Transition ReturningToPresent ->
            if Timeline.fate model.history == Nothing then
                goTo PresentHub model

            else
                goTo Ending model

        _ ->
            model


{-| Where the 1950 week resumes after the shelf: the slide after shelving day. -}
shelvingSlideIndex : History -> Maybe Int
shelvingSlideIndex history =
    Timeline.slides Repairs1950 history
        |> List.indexedMap Tuple.pair
        |> List.filterMap
            (\( index, slide ) ->
                case slide of
                    WeekdaySlide _ ShelveBooks ->
                        Just index

                    _ ->
                        Nothing
            )
        |> List.head
