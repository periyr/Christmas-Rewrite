module Views.TitleScreen exposing (Config, view)

{-| The start/load menu shown when the page opens.

"Continue" only appears when there is a save to continue from. The messages
come from Main, which owns the menu, so this view knows nothing about saving.

-}

import Html exposing (Html, button, div, h1, p, text)
import Html.Attributes exposing (autofocus, class, type_)
import Html.Events exposing (onClick)


type alias Config msg =
    { onNewGame : msg
    , onContinue : Maybe msg
    }


view : Config msg -> Html msg
view config =
    div [ class "app" ]
        [ div [ class "stage title-screen" ]
            [ div [ class "title-screen__panel" ]
                [ h1 [ class "title-screen__name" ] [ text "One More Christmas" ]
                , p [ class "title-screen__tagline" ] [ text "A puzzle adventure through time" ]
                , div [ class "title-screen__menu" ] (menuButtons config)
                ]
            ]
        ]


menuButtons : Config msg -> List (Html msg)
menuButtons config =
    case config.onContinue of
        Just continue ->
            [ button [ type_ "button", class "btn btn--primary", onClick continue, autofocus True ] [ text "Continue" ]
            , button [ type_ "button", class "btn title-screen__secondary", onClick config.onNewGame ] [ text "New game" ]
            , p [ class "title-screen__note" ] [ text "A new game replaces your saved progress." ]
            ]

        Nothing ->
            [ button [ type_ "button", class "btn btn--primary", onClick config.onNewGame, autofocus True ] [ text "New game" ] ]
