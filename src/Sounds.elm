module Sounds exposing (forStep)

{-| Which sound effects one game step should play.

Kept out of Update so the game stays pure and unchanged: Main compares the
model before and after each message and sends the names here through the
`playSound` port. public/audio.js makes every sound in code (Web Audio), so
there are no sound files.

A step can play more than one sound (a page turn and a success chime, say);
most play none. Walking plays a soft step each time the walk animation
changes pose. Each 1973 performance slide starts that scene's puppet sounds,
timed in audio.js to its animation, and leaving the slide stops them.

-}

import Domain exposing (..)
import Timeline


forStep : Msg -> Model -> Model -> List String
forStep msg before after =
    List.concat
        [ phaseSounds before after
        , resultSounds before after
        , moveSounds msg before after
        , paperSounds before after
        , noticeSounds before after
        , roomSounds before after
        , showSounds before after
        ]



-- ═══════════════════════════════════════════════════════════════════════
-- MOVING BETWEEN SCREENS
-- ═══════════════════════════════════════════════════════════════════════


phaseSounds : Model -> Model -> List String
phaseSounds before after =
    if sameScreen before.phase after.phase then
        []

    else
        case after.phase of
            Introduction ClockStopped ->
                [ "clock-stop" ]

            Introduction _ ->
                [ "page" ]

            PresentHub ->
                [ "page" ]

            Transition (OpeningDiary _) ->
                [ "diary-open" ]

            Transition (TimeTravel _ _) ->
                [ "travel" ]

            Transition (TearToPresent _ _) ->
                [ "tear" ]

            Transition _ ->
                [ "page" ]

            MendingFrame _ ->
                [ "shatter" ]

            Ending ->
                case (Timeline.deriveWorld after.history).fate of
                    Just ShopSaved ->
                        [ "ending-saved" ]

                    _ ->
                        [ "ending-closed" ]

            _ ->
                -- Arriving in a chapter: the travel sound already covers it.
                []


{-| Same screen means same phase constructor and, for the screens that carry
one, the same era and step. A trip's elapsed time ticking on is the same screen.
-}
sameScreen : Phase -> Phase -> Bool
sameScreen a b =
    case ( a, b ) of
        ( Introduction x, Introduction y ) ->
            x == y

        ( PresentHub, PresentHub ) ->
            True

        ( Salvage _, Salvage _ ) ->
            True

        ( RepairBoard _, RepairBoard _ ) ->
            True

        ( ReopeningShelf _, ReopeningShelf _ ) ->
            True

        ( ShadowPuzzle _, ShadowPuzzle _ ) ->
            True

        ( BookMystery _, BookMystery _ ) ->
            True

        ( MendingFrame _, MendingFrame _ ) ->
            True

        ( Ending, Ending ) ->
            True

        ( Transition (OpeningDiary x), Transition (OpeningDiary y) ) ->
            x == y

        ( Transition (TimeTravel x _), Transition (TimeTravel y _) ) ->
            x == y

        ( Transition (Slideshow x i), Transition (Slideshow y j) ) ->
            x == y && i == j

        ( Transition (TearToPresent x _), Transition (TearToPresent y _) ) ->
            x == y

        ( Transition ReturningToPresent, Transition ReturningToPresent ) ->
            True

        _ ->
            False



-- ═══════════════════════════════════════════════════════════════════════
-- SUBMITTING A MAIN PUZZLE
-- ═══════════════════════════════════════════════════════════════════════


resultSounds : Model -> Model -> List String
resultSounds before after =
    if List.length after.history > List.length before.history then
        case List.head (List.reverse after.history) of
            Just record ->
                if record.outcome == Succeeded then
                    [ "success" ]

                else
                    [ "fail" ]

            Nothing ->
                []

    else if not (reviewing before.phase) && reviewing after.phase then
        [ "mistake" ]

    else
        []


reviewing : Phase -> Bool
reviewing phase =
    let
        isReviewing attempts =
            case attempts of
                ReviewingFirstMistake _ ->
                    True

                _ ->
                    False
    in
    case phase of
        RepairBoard puzzle ->
            isReviewing puzzle.attempts

        ShadowPuzzle puzzle ->
            isReviewing puzzle.attempts

        BookMystery puzzle ->
            isReviewing puzzle.attempts

        _ ->
            False



-- ═══════════════════════════════════════════════════════════════════════
-- PICKING UP AND PLACING PIECES
-- ═══════════════════════════════════════════════════════════════════════


{-| Each puzzle's pieces have their own pair of sounds: books, paper task
cards, cardboard cut-outs, pieces of glass. A move that was refused plays its
notice sound instead (see noticeSounds).
-}
moveSounds : Msg -> Model -> Model -> List String
moveSounds msg before after =
    let
        refused =
            after.notice /= Nothing && after.notice /= before.notice

        changed =
            before.phase /= after.phase

        move kind action =
            if refused || not changed then
                []

            else
                case action of
                    SelectItem _ ->
                        [ kind ++ "-pick" ]

                    PlaceSelected _ ->
                        [ kind ++ "-place" ]

                    PlaceSelectedInGroup _ ->
                        [ kind ++ "-place" ]

                    ReturnSelectedToTray ->
                        [ kind ++ "-place" ]

                    ClearSelection ->
                        []
    in
    case msg of
        SalvageMove action ->
            move "book" action

        ShelfMove action ->
            move "book" action

        BoardMove action ->
            move "card" action

        StageMove action ->
            move "cutout" action

        FrameMove action ->
            move "glass" action

        ChooseCandidate _ ->
            if changed then
                [ "book-pick" ]

            else
                []

        Retry ->
            if changed then
                [ "page" ]

            else
                []

        _ ->
            []



-- ═══════════════════════════════════════════════════════════════════════
-- READING, NOTICES, THE ROOM
-- ═══════════════════════════════════════════════════════════════════════


paperSounds : Model -> Model -> List String
paperSounds before after =
    case ( before.inspecting, after.inspecting ) of
        ( Nothing, Just _ ) ->
            [ "paper-open" ]

        ( Just a, Just b ) ->
            if a /= b then
                [ "paper-open" ]

            else
                []

        ( Just _, Nothing ) ->
            if sameScreen before.phase after.phase then
                [ "paper-close" ]

            else
                []

        ( Nothing, Nothing ) ->
            []


noticeSounds : Model -> Model -> List String
noticeSounds before after =
    if after.notice == before.notice then
        []

    else
        case after.notice of
            Just DoesNotFitThere ->
                [ "nope" ]

            Just TargetFull ->
                [ "nope" ]

            Just NotSolvedYet ->
                [ "hmm" ]

            Just IncompleteSubmission ->
                [ "hmm" ]

            Nothing ->
                []


roomSounds : Model -> Model -> List String
roomSounds before after =
    let
        panel =
            if after.room.panelOpen && not before.room.panelOpen then
                [ "panel-open" ]

            else if before.room.panelOpen && not after.room.panelOpen && sameScreen before.phase after.phase then
                [ "panel-close" ]

            else
                []

        -- One soft step each time the walk animation changes pose (every 48 px).
        stride x =
            floor (x / 48)

        step =
            if after.room.player.walking && stride before.room.player.x /= stride after.room.player.x then
                [ "step" ]

            else
                []
    in
    panel ++ step



-- ═══════════════════════════════════════════════════════════════════════
-- THE 1973 SHADOW PLAY
-- ═══════════════════════════════════════════════════════════════════════


showSounds : Model -> Model -> List String
showSounds before after =
    if sameScreen before.phase after.phase then
        []

    else
        -- One name per step: a step's port commands can reach the page in any
        -- order, so a separate stop could cut off the scene that just began.
        -- Starting a scene already fades out the one before it (audio.js).
        case ( performance before, performance after ) of
            ( _, Just name ) ->
                [ "scene-" ++ name ]

            ( Just _, Nothing ) ->
                [ "scene-stop" ]

            ( Nothing, Nothing ) ->
                []


{-| The scene on screen, named like its animation (Components.Props, the
data-shadow-scene attribute) plus whose voice it has, if a performance slide
is showing: "door-owl", say.
-}
performance : Model -> Maybe String
performance model =
    case model.phase of
        Transition (Slideshow era index) ->
            case List.drop index (Timeline.slides era model.history) |> List.head of
                Just (PerformanceSlide scene cast) ->
                    Just (setting (Timeline.deriveWorld model.history).scriptVariant scene ++ "-" ++ voice cast.character)

                _ ->
                    Nothing

        _ ->
            Nothing


setting : ScriptVariant -> Scene -> String
setting variant scene =
    case ( variant, scene ) of
        ( OriginalScript, Scene1 ) ->
            "bridge"

        ( OriginalScript, Scene2 ) ->
            "door"

        ( OriginalScript, Scene3 ) ->
            "reading-home"

        ( NeighboursRetelling, Scene1 ) ->
            "gate"

        ( NeighboursRetelling, Scene2 ) ->
            "fireplace"

        ( NeighboursRetelling, Scene3 ) ->
            "lantern-home"


voice : Character -> String
voice character =
    case character of
        Fox ->
            "fox"

        Owl ->
            "owl"

        Child ->
            "child"
