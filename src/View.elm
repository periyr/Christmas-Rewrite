module View exposing (view)

{-| The root view: picks the screen for the current phase and lays any open
document over it. All game state stays in the model.
-}

import Components.Art as Art
import Components.Clock as Clock
import Components.Props as Props
import Content.Clues
import Content.Frame
import Domain exposing (..)
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (attribute, class)
import Rules.BookTrays as BookTrays
import Rules.Room
import Rules.Travel
import Timeline
import Update
import Views.Common as Common
import Views.BookTable
import Views.ClueSheets
import Views.Frame
import Views.Labels exposing (eraYear)
import Views.RepairBoard
import Views.Room
import Views.Salvage
import Views.ShadowStage
import Views.Shelf
import Views.Shop
import Views.Slideshow
import Views.Tear
import Views.TimeTravel


view : Model -> Html Msg
view model =
    let
        world =
            Timeline.deriveWorld model.history
    in
    div [ class "app" ]
        [ div (class "stage" :: stageAttributes world model)
            (wallClock (shownPhase model.phase) :: screen world model ++ inspection world model)
        ]


{-| The clock on the wall, first in the stage so it stays the same element (and
keeps ticking smoothly) from screen to screen. It ticks everywhere except the
intro moment when "the clock stops a minute before midnight". CSS places it in
each room. Person A's model should supply the real time later.
-}
wallClock : Phase -> Html msg
wallClock phase =
    let
        ( hour, minute ) =
            clockTime phase
    in
    Clock.view { hour = hour, minute = minute, ticking = phase /= Introduction ClockStopped }


{-| Each era keeps the time its old painted clock showed; the ending is midnight. -}
clockTime : Phase -> ( Int, Int )
clockTime phase =
    case ( phase, clockEra phase ) of
        ( Ending, _ ) ->
            ( 0, 0 )

        ( _, Just Repairs1950 ) ->
            ( 10, 10 )

        ( _, Just Shadows1973 ) ->
            ( 19, 5 )

        ( _, Just Search1998 ) ->
            ( 14, 20 )

        ( _, Nothing ) ->
            ( 23, 59 )


{-| The past era a phase is set in, or Nothing for the present. -}
clockEra : Phase -> Maybe Era
clockEra phase =
    case phase of
        Salvage _ ->
            Just Repairs1950

        RepairBoard _ ->
            Just Repairs1950

        ReopeningShelf _ ->
            Just Repairs1950

        ShadowPuzzle _ ->
            Just Shadows1973

        MendingFrame _ ->
            Just Shadows1973

        BookMystery _ ->
            Just Search1998

        Transition (OpeningDiary era) ->
            Just era

        Transition (Slideshow era _) ->
            Just era

        _ ->
            Nothing


screen : World -> Model -> List (Html Msg)
screen world model =
    let
        room =
            Views.Room.view world model

        station panel =
            room { emptyScene | panel = panel }

        emptyScene =
            Views.Room.emptyScene
    in
    case model.phase of
        Introduction step ->
            room { emptyScene | front = Views.Shop.introduction step }

        PresentHub ->
            room (Views.Shop.presentHub world model.history)

        Salvage placement ->
            station (Views.Salvage.view (BookTrays.salvage model.runSeed) placement model.notice)

        RepairBoard puzzle ->
            station (Views.RepairBoard.view world puzzle model.notice)

        ReopeningShelf placement ->
            station (Views.Shelf.view world (BookTrays.shelf model.runSeed) placement model.notice)

        ShadowPuzzle puzzle ->
            station (Views.ShadowStage.view world puzzle model.notice)

        MendingFrame placement ->
            room { emptyScene | line = Just Content.Frame.arrival, panel = Views.Frame.view placement model.notice }

        BookMystery puzzle ->
            station (Views.BookTable.view world puzzle model.notice)

        Transition (OpeningDiary era) ->
            Views.Shop.openingDiary world era

        Transition (TimeTravel era elapsed) ->
            -- The darkened shop until the destination is reached, then the
            -- chapter's own starting room, revealed as the book fades.
            (if Rules.Travel.hasArrived elapsed then
                screen world (arriving era model)

             else
                [ Art.room ]
            )
                ++ Views.TimeTravel.view era elapsed

        Transition (Slideshow era index) ->
            Views.Slideshow.view world model.history era index

        Transition (TearToPresent era elapsed) ->
            Views.Tear.view (tearRooms world model era) elapsed

        Transition ReturningToPresent ->
            room { emptyScene | front = Views.Shop.returning }

        Ending ->
            Views.Shop.ending world


{-| The two rooms of the tear home: the finished era's room exactly as its last
slide left it (without the caption), and the present exactly as the "Back to
the present" screen draws it (without the narration), from the real history.
Each keeps its own stage attributes.
-}
tearRooms :
    World
    -> Model
    -> Era
    ->
        { era : Era
        , past : List (Html Msg)
        , pastAttributes : List (Attribute Msg)
        , present : List (Html Msg)
        , presentAttributes : List (Attribute Msg)
        }
tearRooms world model era =
    let
        slides =
            Timeline.slides era model.history

        lastSlide =
            { model | phase = Transition (Slideshow era (List.length slides - 1)) }

        present =
            { model | phase = Transition ReturningToPresent }
    in
    { era = era
    , past =
        Art.room
            :: (List.reverse slides |> List.head |> Maybe.map (Props.forSlide Props.Settled world.scriptVariant) |> Maybe.withDefault [])
            ++ [ stoppedClock era ]
    , pastAttributes = stageAttributes world lastSlide
    , present = Clock.view { hour = 23, minute = 59, ticking = False } :: Views.Room.view world present Views.Room.emptyScene
    , presentAttributes = stageAttributes world present
    }


{-| The wall clock, held still while the page tears. CSS hides it in rooms
whose picture already has a clock.
-}
stoppedClock : Era -> Html msg
stoppedClock era =
    if era == Shadows1973 then
        Clock.view { hour = 19, minute = 5, ticking = False }

    else
        Clock.view { hour = 23, minute = 59, ticking = False }


{-| What the destination looks like when the trip ends: exactly the state
Update.arrive starts the chapter in. Only drawn, never stored.
-}
arriving : Era -> Model -> Model
arriving era model =
    { model | phase = Update.startChapter era, room = Rules.Room.initialRoom, inspecting = Nothing, notice = Nothing }


{-| The phase the room and wall clock show. A trip shows the present until it
arrives, then the chapter it arrives in.
-}
shownPhase : Phase -> Phase
shownPhase phase =
    case phase of
        Transition (TimeTravel era elapsed) ->
            if Rules.Travel.hasArrived elapsed then
                Update.startChapter era

            else
                PresentHub

        _ ->
            phase


stageAttributes : World -> Model -> List (Attribute msg)
stageAttributes world model =
    frameAttribute world model.phase ++ eraStageAttributes world model


{-| The family photograph on the right wall: on the floor while it is mended
after the 1973 show (in the dark), and taped up in the rooms after that.
-}
frameAttribute : World -> Phase -> List (Attribute msg)
frameAttribute world phase =
    let
        mended =
            world.tradition /= NotRevisited

        taped =
            if mended then
                [ attribute "data-frame" "taped" ]

            else
                []
    in
    case phase of
        MendingFrame _ ->
            [ attribute "data-frame" "fallen", attribute "data-lights" "down" ]

        Introduction _ ->
            taped

        PresentHub ->
            taped

        BookMystery _ ->
            taped

        Transition (Slideshow Search1998 _) ->
            taped

        Transition (OpeningDiary _) ->
            taped

        Transition ReturningToPresent ->
            taped

        Ending ->
            taped

        _ ->
            []


eraStageAttributes : World -> Model -> List (Attribute msg)
eraStageAttributes world model =
    case model.phase of
        Introduction _ ->
            eraAttribute "present" :: premisesAttribute world

        PresentHub ->
            eraAttribute "present" :: premisesAttribute world

        Salvage _ ->
            [ eraAttribute "1950" ]

        RepairBoard _ ->
            [ eraAttribute "1950" ]

        ReopeningShelf _ ->
            eraAttribute "1950" :: Views.Slideshow.atShelvingPause model.history

        ShadowPuzzle _ ->
            [ eraAttribute "1973" ]

        MendingFrame _ ->
            [ eraAttribute "1973" ]

        BookMystery _ ->
            [ eraAttribute "1998" ]

        Transition (OpeningDiary _) ->
            -- The passage is read in the present: the past only appears after the trip.
            eraAttribute "present" :: premisesAttribute world

        Transition (TimeTravel era elapsed) ->
            attribute "data-travel" (eraYear era) :: eraStageAttributes world { model | phase = shownPhase (Transition (TimeTravel era elapsed)) }

        Transition (Slideshow era index) ->
            eraAttribute (eraYear era) :: Views.Slideshow.stageAttributes model.history era index ++ Views.Slideshow.lights model.history era index

        Transition (TearToPresent era _) ->
            -- Neutral: each of the tear's two rooms carries its own attributes.
            [ attribute "data-tear" (eraYear era) ]

        Transition ReturningToPresent ->
            eraAttribute "present" :: premisesAttribute world

        Ending ->
            endingAttributes world


eraAttribute : String -> Attribute msg
eraAttribute era =
    attribute "data-era" era


endingAttributes : World -> List (Attribute msg)
endingAttributes world =
    case world.fate of
        Just (ShopClosed _) ->
            eraAttribute "closed" :: premisesAttribute world

        _ ->
            [ eraAttribute "saved" ]


{-| The hub's room shows how 1950 went. -}
premisesAttribute : World -> List (Attribute msg)
premisesAttribute world =
    case world.premises of
        Missing ->
            [ attribute "data-premises" "missing" ]

        Established ->
            [ attribute "data-premises" "established" ]

        NotRevisited ->
            [ attribute "data-premises" "original" ]


inspection : World -> Model -> List (Html Msg)
inspection world model =
    case model.inspecting of
        Just clue ->
            let
                document =
                    Content.Clues.clue world clue
            in
            case Views.ClueSheets.custom clue document of
                Just ( variant, body ) ->
                    [ Common.customSheet
                        { variant = variant
                        , title = document.title
                        , body = body
                        , buttonLabel = "Put it back"
                        , onPress = CloseInspection
                        }
                    ]

                Nothing ->
                    [ Common.documentSheet
                        { variant = sheetVariant world clue
                        , document = document
                        , picture = cluePicture world clue
                        , buttonLabel = "Put it back"
                        , onPress = CloseInspection
                        }
                    ]

        Nothing ->
            []


{-| A 1998 book's picture page shows the picture itself above its description.
The family photographs and the handwritten closure notice are shown as pictures
only; their words stay in the page for screen readers.
-}
cluePicture : World -> ClueId -> Maybe String
cluePicture world clue =
    case clue of
        CandidatePage candidate CoverTab ->
            Just (Art.candidateIllustration candidate)

        FamilyPhotograph ->
            if world.tradition /= NotRevisited then
                Just "assets/clue-family-photographs-taped.svg"

            else
                Just "assets/clue-family-photographs.svg"

        ClosureNotice ->
            Just "assets/clue-closure-notice.svg"

        RubbleAndShelvesNote ->
            Just "assets/clue-repair-notes.svg"

        CutoutBox ->
            Just "assets/clue-cutout-box.svg"

        -- From the shop archive: the photo's front (the one on the community
        -- wall) and its back, with Henry's note in his hand.
        InscriptionClue ->
            if world.inscriptionSource == FamilyArchive then
                Just "assets/clue-archive-photo.svg"

            else
                Nothing

        ShadowScript ->
            Just ("assets/clue-script-" ++ scriptFile world.scriptVariant ++ ".svg")

        StageSketch ->
            Just ("assets/clue-sketch-" ++ scriptFile world.scriptVariant ++ ".svg")

        WalterDiaryPage ->
            Just "assets/clue-walter-diary.svg"

        BudgetAllocation ->
            Just "assets/clue-budget.svg"

        GlassDeliverySlip ->
            Just "assets/clue-glass-slip.svg"

        HubProp CommunityWall ->
            Just ("assets/clue-wall-" ++ foundationFile world.tradition ++ ".svg")

        _ ->
            Nothing


{-| The 1973 script and stage sketch follow the script variant. -}
scriptFile : ScriptVariant -> String
scriptFile variant =
    case variant of
        OriginalScript ->
            "original"

        NeighboursRetelling ->
            "retelling"


{-| The community wall has a picture per state of the 1973 tradition. The
roof and shelves and the order desk are words only.
-}
foundationFile : Foundation -> String
foundationFile foundation =
    case foundation of
        NotRevisited ->
            "original"

        Missing ->
            "missing"

        Established ->
            "established"


sheetVariant : World -> ClueId -> String
sheetVariant world clue =
    case clue of
        FamilyPhotograph ->
            "sheet--picture sheet--photo"

        ClosureNotice ->
            "sheet--picture sheet--note"

        HubProp _ ->
            "sheet--scene"

        -- Handwritten pages: the picture is the page, the words stay for screen readers.
        WalterDiaryPage ->
            "sheet--picture sheet--note"

        GlassDeliverySlip ->
            "sheet--picture sheet--note"

        RubbleAndShelvesNote ->
            "sheet--scene"

        CutoutBox ->
            "sheet--scene"

        -- The photo's front and back are the clue; the words stay for screen readers.
        InscriptionClue ->
            if world.inscriptionSource == FamilyArchive then
                "sheet--picture sheet--archive"

            else
                ""

        StageSketch ->
            "sheet--scene"

        -- The handwritten parts are the picture; the first line stays as words.
        ShadowScript ->
            "sheet--script"

        BudgetAllocation ->
            "sheet--scene"

        _ ->
            ""
