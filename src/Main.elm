module Main exposing (main)

{-| Entry point. Pure core: Update.update does all the work; there are no
commands yet (audio ports, if any, get added here later by agreement).

TEMPORARY: `view` below is a plain debug screen so the skeleton compiles
before Person B's interface exists. When src/View.elm lands, replace
`view = temporaryView` with `view = View.view` and delete temporaryView.

-}

import Browser
import Domain exposing (..)
import Html exposing (Html, button, div, h1, li, p, text, ul)
import Html.Events exposing (onClick)
import Timeline
import Update


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( Update.init, Cmd.none )
        , update = \msg model -> ( Update.update msg model, Cmd.none )
        , view = temporaryView
        , subscriptions = \_ -> Sub.none
        }



-- TEMPORARY SKELETON SCREEN (delete when View.view exists)


temporaryView : Model -> Html Msg
temporaryView model =
    div []
        [ h1 [] [ text "One More Christmas — skeleton" ]
        , p [] [ text ("Phase: " ++ phaseName model.phase) ]
        , p [] [ text ("Resolved chapters: " ++ String.fromInt (List.length model.history)) ]
        , ul [] (List.map (\record -> li [] [ text (eraName record.era ++ ": " ++ outcomeName record.outcome) ]) model.history)
        , div []
            [ button [ onClick Advance ] [ text "Advance" ]
            , button [ onClick OpenNextDiary ] [ text "Open next diary" ]
            ]
        , p [] [ text (nextDiaryLine model) ]
        ]


nextDiaryLine : Model -> String
nextDiaryLine model =
    case (Timeline.deriveWorld model.history).nextDiary of
        Just era ->
            "Next diary: " ++ eraName era

        Nothing ->
            "All diaries resolved"


phaseName : Phase -> String
phaseName phase =
    case phase of
        Introduction _ ->
            "Introduction"

        PresentHub ->
            "Present hub"

        Salvage _ ->
            "Salvage (1950)"

        RepairBoard _ ->
            "Repair board (1950)"

        ReopeningShelf _ ->
            "Reopening shelf (1950)"

        ShadowPuzzle _ ->
            "Shadow story (1973)"

        BookMystery _ ->
            "Forgotten book (1998)"

        Transition _ ->
            "Transition"

        Ending ->
            "Ending"


eraName : Era -> String
eraName era =
    case era of
        Repairs1950 ->
            "1950"

        Shadows1973 ->
            "1973"

        Search1998 ->
            "1998"


outcomeName : Outcome -> String
outcomeName outcome =
    case outcome of
        Succeeded ->
            "succeeded"

        Failed ->
            "failed"
