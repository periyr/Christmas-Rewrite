module View exposing (view)

{-| The root view: picks the screen for the current phase and lays any open
document over it. All game state stays in the model.
-}

import Content.Clues
import Domain exposing (..)
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (attribute, class)
import Timeline
import Views.Common as Common
import Views.Labels exposing (eraYear)
import Views.RepairBoard
import Views.Salvage
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
            (screen world model ++ inspection world model)
        ]


screen : World -> Model -> List (Html Msg)
screen world model =
    case model.phase of
        Introduction step ->
            Views.Shop.introduction world step

        PresentHub ->
            Views.Shop.presentHub world model.history

        Salvage placement ->
            Views.Salvage.view placement model.notice

        RepairBoard puzzle ->
            Views.RepairBoard.view world puzzle model.notice

        ReopeningShelf placement ->
            Views.Shelf.view world placement model.notice

        ShadowPuzzle _ ->
            Views.Shop.unbuiltChapter Shadows1973

        BookMystery _ ->
            Views.Shop.unbuiltChapter Search1998

        Transition (OpeningDiary era) ->
            Views.Shop.openingDiary world era

        Transition (Slideshow era index) ->
            Views.Slideshow.view world model.history era index

        Transition ReturningToPresent ->
            Views.Shop.returning

        Ending ->
            Views.Shop.ending world


stageAttributes : World -> Model -> List (Attribute msg)
stageAttributes world model =
    case model.phase of
        Introduction _ ->
            [ eraAttribute "present" ]

        PresentHub ->
            eraAttribute "present" :: premisesAttribute world

        Salvage _ ->
            [ eraAttribute "1950" ]

        RepairBoard _ ->
            [ eraAttribute "1950" ]

        ReopeningShelf _ ->
            [ eraAttribute "1950" ]

        ShadowPuzzle _ ->
            [ eraAttribute "1973" ]

        BookMystery _ ->
            [ eraAttribute "1998" ]

        Transition (OpeningDiary era) ->
            [ eraAttribute (eraYear era) ]

        Transition (Slideshow era index) ->
            eraAttribute (eraYear era) :: Views.Slideshow.stageAttributes model.history era index

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
            []


inspection : World -> Model -> List (Html Msg)
inspection world model =
    case model.inspecting of
        Just clue ->
            [ Common.documentSheet
                { variant = sheetVariant clue
                , document = Content.Clues.clue world clue
                , buttonLabel = "Put it back"
                , onPress = CloseInspection
                }
            ]

        Nothing ->
            []


sheetVariant : ClueId -> String
sheetVariant clue =
    case clue of
        WalterDiaryPage ->
            "sheet--diary"

        GlassDeliverySlip ->
            "sheet--form"

        _ ->
            ""
