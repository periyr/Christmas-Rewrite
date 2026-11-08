module View exposing (view)

{-| The root view: picks the screen for the current phase and lays any open
document over it. All game state stays in the model.
-}

import Components.Art as Art
import Components.Clock as Clock
import Content.Clues
import Domain exposing (..)
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (attribute, class)
import Timeline
import Views.Common as Common
import Views.BookTable
import Views.Labels exposing (eraYear)
import Views.RepairBoard
import Views.Room
import Views.Salvage
import Views.ShadowStage
import Views.Shelf
import Views.Shop
import Views.Slideshow


view : Model -> Html Msg
view model =
    let
        world =
            Timeline.deriveWorld model.history
    in
    div [ class "app" ]
        [ div (class "stage" :: stageAttributes world model)
            (wallClock model.phase :: screen world model ++ inspection world model)
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
            station (Views.Salvage.view placement model.notice)

        RepairBoard puzzle ->
            station (Views.RepairBoard.view world puzzle model.notice)

        ReopeningShelf placement ->
            station (Views.Shelf.view world placement model.notice)

        ShadowPuzzle puzzle ->
            station (Views.ShadowStage.view world puzzle model.notice)

        BookMystery puzzle ->
            station (Views.BookTable.view world puzzle model.notice)

        Transition (OpeningDiary era) ->
            Views.Shop.openingDiary world era

        Transition (Slideshow era index) ->
            Views.Slideshow.view world model.history era index

        Transition ReturningToPresent ->
            room { emptyScene | front = Views.Shop.returning }

        Ending ->
            Views.Shop.ending world


stageAttributes : World -> Model -> List (Attribute msg)
stageAttributes world model =
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

        BookMystery _ ->
            [ eraAttribute "1998" ]

        Transition (OpeningDiary era) ->
            [ eraAttribute (eraYear era) ]

        Transition (Slideshow era index) ->
            eraAttribute (eraYear era) :: Views.Slideshow.stageAttributes model.history era index ++ Views.Slideshow.lights model.history era index

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
            [ Common.documentSheet
                { variant = sheetVariant clue
                , document = Content.Clues.clue world clue
                , picture = cluePicture clue
                , buttonLabel = "Put it back"
                , onPress = CloseInspection
                }
            ]

        Nothing ->
            []


{-| A 1998 book's picture page shows the picture itself above its description. -}
cluePicture : ClueId -> Maybe String
cluePicture clue =
    case clue of
        CandidatePage candidate CoverTab ->
            Just (Art.candidateIllustration candidate)

        _ ->
            Nothing


sheetVariant : ClueId -> String
sheetVariant clue =
    case clue of
        WalterDiaryPage ->
            "sheet--diary"

        GlassDeliverySlip ->
            "sheet--form"

        _ ->
            ""
