module Update exposing (init, newRun, startChapter, update)

{-| The single, pure update entry point.

Actions that do not make sense in the current phase are ignored, which is
what makes double clicks and clicks during feedback/transitions harmless.

The room (contract v1.3) wraps the game: walking only changes `model.room`,
and using a hotspot sends the same game action the old button did. Walking
never touches history, attempts or arrangements.

-}

import Domain exposing (..)
import Rules.Attempts as Attempts exposing (SubmitResult(..))
import Rules.Frame
import Rules.Mystery
import Rules.Placement as Placement
import Rules.Repair
import Rules.Room
import Rules.Salvage
import Rules.Shadow
import Rules.Shelf
import Rules.Travel
import Timeline


init : Model
init =
    newRun 0


newRun : Int -> Model
newRun runSeed =
    { history = []
    , runSeed = runSeed
    , phase = Introduction PackingUp
    , inspecting = Nothing
    , notice = Nothing
    , room = Rules.Room.initialRoom
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


{-| Every phase change closes the panel and stops the player (held keys and
any walking target are cleared). The player stays where they are, so after
salvage they walk on to the board, and at the shelving pause to the shelf.
-}
goTo : Phase -> Model -> Model
goTo phase model =
    { model
        | phase = phase
        , inspecting = Nothing
        , notice = Nothing
        , room = { panelOpen = False, player = Rules.Room.stop model.room.player }
    }


{-| The end of the trip back, whether it finished or was skipped: the chapter
starts fresh (startChapter) in a new room. This is the only way into a chapter.
-}
arrive : Era -> Model -> Model
arrive era model =
    enterRoom (goTo (startChapter era) model)


{-| The end of the way back, whether it finished or was skipped: the existing
"Back to the present" narration.
-}
backInThePresent : Model -> Model
backInThePresent model =
    goTo (Transition ReturningToPresent) model


{-| Entering a diary or coming back to the present: a new room, so the player
starts again at the door end, facing right.
-}
enterRoom : Model -> Model
enterRoom model =
    { model | room = Rules.Room.initialRoom }


update : Msg -> Model -> Model
update msg model =
    case msg of
        WalkKeyDown key ->
            if Rules.Room.canWalk model then
                withPlayer (Rules.Room.press key) model

            else
                model

        WalkKeyUp key ->
            withPlayer (Rules.Room.release key) model

        InteractNearby ->
            case Rules.Room.nearby model of
                Just hotspot ->
                    useHotspot hotspot model

                Nothing ->
                    model

        ApproachHotspot hotspot ->
            approach hotspot model

        AnimationFrame delta ->
            case model.phase of
                Transition (TimeTravel era elapsed) ->
                    let
                        next =
                            Rules.Travel.step delta elapsed
                    in
                    if Rules.Travel.isComplete next then
                        arrive era model

                    else
                        { model | phase = Transition (TimeTravel era next) }

                Transition (TearToPresent era elapsed) ->
                    let
                        next =
                            Rules.Travel.step delta elapsed
                    in
                    if Rules.Travel.hasReturned next then
                        backInThePresent model

                    else
                        { model | phase = Transition (TearToPresent era next) }

                _ ->
                    walk delta model

        ClosePanel ->
            if model.room.panelOpen && not (phaseIsReviewing model.phase) then
                let
                    room =
                        model.room
                in
                { model | room = { room | panelOpen = False }, notice = Nothing }

            else
                model

        PageVisibilityChanged visible ->
            if visible then
                model

            else
                withPlayer Rules.Room.stop model

        _ ->
            settle (play msg model)


{-| The game itself: everything except the room messages. -}
play : Msg -> Model -> Model
play msg model =
    case msg of
        Inspect clue ->
            if Rules.Travel.isTravelling model.phase then
                -- Nothing can be opened over the trip back.
                model

            else
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

        FrameMove action ->
            case model.phase of
                MendingFrame placement ->
                    withPlacement MendingFrame (Placement.apply Rules.Frame.accepts action placement) model

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

        SkipTravel ->
            case model.phase of
                Transition (TimeTravel era _) ->
                    arrive era model

                Transition (TearToPresent _ _) ->
                    backInThePresent model

                _ ->
                    model

        -- The room messages are handled in `update`.
        WalkKeyDown _ ->
            model

        WalkKeyUp _ ->
            model

        InteractNearby ->
            model

        ApproachHotspot _ ->
            model

        AnimationFrame _ ->
            model

        ClosePanel ->
            model

        PageVisibilityChanged _ ->
            model



{-| One animation frame of walking (frames only arrive while moving). -}
walk : Float -> Model -> Model
walk delta model =
    if Rules.Room.isMoving model then
        let
            ( player, arrived ) =
                Rules.Room.step delta model.room.player

            moved =
                withPlayer (\_ -> player) model
        in
        case arrived of
            Just hotspot ->
                useHotspot hotspot moved

            Nothing ->
                moved

    else
        model


-- ROOM


withPlayer : (Player -> Player) -> Model -> Model
withPlayer change model =
    let
        room =
            model.room
    in
    { model | room = { room | player = change room.player } }


{-| Whenever the player cannot walk (a clue, notice, feedback or panel is
open, or the phase has no room), nothing is held and nothing is targeted.
-}
settle : Model -> Model
settle model =
    if Rules.Room.canWalk model then
        model

    else
        withPlayer Rules.Room.stop model


{-| Clicking a hotspot: use it now if it is in reach, otherwise walk to it. -}
approach : Hotspot -> Model -> Model
approach hotspot model =
    let
        goal =
            (Rules.Room.position hotspot).x

        player =
            model.room.player
    in
    if not (Rules.Room.canWalk model && List.member hotspot (Rules.Room.hotspots model.phase)) then
        model

    else if abs (goal - player.x) <= Rules.Room.interactionDistance then
        useHotspot hotspot model

    else
        withPlayer
            (\p -> { p | held = [], target = Just hotspot, facing = Rules.Room.facingTowards goal p, walking = True })
            model


{-| Use a hotspot of the current phase: exactly the old action, or open the
phase's panel. The player stops and turns to face it first.
-}
useHotspot : Hotspot -> Model -> Model
useHotspot hotspot model =
    if Rules.Room.canWalk model && List.member hotspot (Rules.Room.hotspots model.phase) then
        let
            stopped =
                withPlayer
                    (\player ->
                        Rules.Room.stop { player | facing = Rules.Room.facingTowards (Rules.Room.position hotspot).x player }
                    )
                    model
        in
        case hotspot of
            ClueSpot clue ->
                settle (play (Inspect clue) stopped)

            BoxSpot ->
                settle (play Advance stopped)

            DiarySpot ->
                settle (play OpenNextDiary stopped)

            _ ->
                if Rules.Room.hasPanel model.phase then
                    let
                        room =
                            stopped.room
                    in
                    { stopped | room = { room | panelOpen = True } }

                else
                    model

    else
        model


phaseIsReviewing : Phase -> Bool
phaseIsReviewing phase =
    case phase of
        RepairBoard puzzle ->
            isReviewing puzzle

        ShadowPuzzle puzzle ->
            isReviewing puzzle

        BookMystery puzzle ->
            isReviewing puzzle

        _ ->
            False



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
            -- Back in the shop, where the oldest diary now glows (OpenNextDiary).
            goTo PresentHub model

        Transition (OpeningDiary era) ->
            -- "Step into": the trip back starts; the chapter begins when it ends.
            goTo (Transition (TimeTravel era 0)) model

        Salvage placement ->
            if Rules.Salvage.isSolved placement then
                goTo (RepairBoard (freshPuzzle Placement.empty)) model

            else
                { model | notice = Just NotSolvedYet }

        ReopeningShelf placement ->
            case ( Rules.Shelf.matchedOrder placement, shelvingSlideIndex model.history ) of
                ( Just _, Just index ) ->
                    -- Resume the week on the day after shelving (never replay it).
                    goTo (Transition (Slideshow Repairs1950 (index + 1))) model

                _ ->
                    { model | notice = Just NotSolvedYet }

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

                    else if era == Shadows1973 then
                        -- After the show, in the dark, the family photograph falls:
                        -- mend its glass before going home (contract v1.7).
                        goTo (MendingFrame Placement.empty) model

                    else
                        -- The last slide: tear back through the page to the present.
                        goTo (Transition (TearToPresent era 0)) model

        MendingFrame placement ->
            if Rules.Frame.isSolved placement then
                goTo (Transition (TearToPresent Shadows1973 0)) model

            else
                { model | notice = Just NotSolvedYet }

        Transition ReturningToPresent ->
            if Timeline.fate model.history == Nothing then
                enterRoom (goTo PresentHub model)

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
