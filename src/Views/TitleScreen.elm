module Views.TitleScreen exposing (Config, view)

{-| The start/load menu shown when the page opens.

The present-day shop, dimmed, with snow falling in front. The title and the
menu sit on the left. A garland of Christmas lights hangs across the top: each
bulb lights up when the pointer passes over it and slowly fades again, so
sweeping across it leaves a trail of light.

"Continue" is always there and works once there is a save. The messages come from Main,
which owns the menu, so this view knows nothing about saving.

-}

import Html exposing (Html, button, div, h1, nav, node, p, span, text)
import Html.Attributes exposing (attribute, class, disabled, style, type_)
import Html.Events exposing (onClick)


type alias Config msg =
    { onNewGame : msg
    , onContinue : Maybe msg
    }


view : Config msg -> Html msg
view config =
    div [ class "app" ]
        [ div [ class "stage title-screen" ]
            [ div [ class "title-screen__room" ] []
            , div [ class "title-screen__shade" ] []
            , snow
            , div [ class "title-screen__panel" ]
                [ div []
                    [ h1 [ class "title-screen__name" ] [ text "Christmas", Html.br [] [], text "Rewrite" ]
                    , p [ class "title-screen__tagline" ] [ text "The Story of the Hale Family" ]
                    ]
                , menu config
                ]
            , garland
            ]
        ]


menu : Config msg -> Html msg
menu config =
    let
        -- Always shown, so the menu keeps its shape; it only works with a save.
        continue =
            case config.onContinue of
                Just msg ->
                    item msg "Continue" []

                Nothing ->
                    button [ type_ "button", class "title-menu__item", disabled True ] [ text "Continue" ]

        note =
            case config.onContinue of
                Just _ ->
                    [ attribute "data-note" "Replaces your saved progress" ]

                Nothing ->
                    []
    in
    nav [ class "title-menu", attribute "aria-label" "Menu" ]
        [ continue, item config.onNewGame "New Game" note ]


item : msg -> String -> List (Html.Attribute msg) -> Html msg
item msg label extra =
    button (type_ "button" :: class "title-menu__item" :: onClick msg :: extra) [ text label ]



-- ═══════════════════════════════════════════════════════════════════════
-- SNOW: plain CSS flakes, placed from fixed numbers
-- ═══════════════════════════════════════════════════════════════════════


snow : Html msg
snow =
    div [ class "title-snow", attribute "aria-hidden" "true" ]
        (List.map flake (List.range 0 59))


flake : Int -> Html msg
flake i =
    let
        -- Spread the flakes evenly but not in a visible pattern.
        x =
            modBy 100 (i * 37 + 11)

        size =
            0.18 + toFloat (modBy 4 i) * 0.07

        duration =
            9 + modBy 7 (i * 3)

        delay =
            negate (toFloat (modBy 13 (i * 5)) * 0.9)
    in
    span
        [ class "title-snow__flake"
        , style "left" (String.fromInt x ++ "%")
        , style "width" (String.fromFloat size ++ "rem")
        , style "height" (String.fromFloat size ++ "rem")
        , style "animation-duration" (String.fromInt duration ++ "s")
        , style "animation-delay" (String.fromFloat delay ++ "s")
        ]
        []



-- ═══════════════════════════════════════════════════════════════════════
-- GARLAND AND LIGHTS
-- ═══════════════════════════════════════════════════════════════════════


{-| Three swags pinned at four points across the top of the stage. The
greenery and the bulbs follow the same curve. Coordinates are in a
1280 x 110 drawing that spans the stage.
-}
garlandY : Float -> Float
garlandY x =
    18 + 44 * abs (sin (pi * 3 * x / 1280))


bulbCount : Int
bulbCount =
    27


bulbColours : List String
bulbColours =
    [ "red", "gold", "green", "blue" ]


garland : Html msg
garland =
    div [ class "title-garland" ]
        (svgArt "title-garland__art" garlandMarkup
            :: List.map bulb (List.range 0 (bulbCount - 1))
        )


bulb : Int -> Html msg
bulb i =
    let
        x =
            1280 * (toFloat i + 0.5) / toFloat bulbCount

        colour =
            bulbColours
                |> List.drop (modBy (List.length bulbColours) i)
                |> List.head
                |> Maybe.withDefault "red"
    in
    span
        [ class ("title-bulb title-bulb--" ++ colour)
        , style "left" (String.fromFloat (x / 12.8) ++ "%")
        , style "top" (String.fromFloat ((garlandY x + 4) / 1.1) ++ "%")
        ]
        []


garlandMarkup : String
garlandMarkup =
    let
        points =
            List.range 0 128
                |> List.map (\i -> toFloat i * 10)
                |> List.map (\x -> String.fromFloat x ++ " " ++ String.fromFloat (garlandY x))
                |> String.join " "

        line attrs =
            "<polyline fill=\"none\" points=\"" ++ points ++ "\" " ++ attrs ++ "/>"

        pins =
            [ 0, 426.67, 853.33, 1280 ]
                |> List.map
                    (\x ->
                        "<g stroke=\"#291e1a\" stroke-width=\"2\"><circle cx=\""
                            ++ String.fromFloat x
                            ++ "\" cy=\"18\" r=\"11\" fill=\"#893f43\"/><path fill=\"#c4352f\" d=\"M"
                            ++ String.fromFloat (x - 14)
                            ++ " 18l-10 14 12-2ZM"
                            ++ String.fromFloat (x + 14)
                            ++ " 18l10 14-12-2Z\"/></g>"
                    )
                |> String.concat
    in
    "<svg viewBox=\"0 0 1280 110\" preserveAspectRatio=\"none\" aria-hidden=\"true\" stroke-linejoin=\"round\" stroke-linecap=\"round\">"
        ++ line "stroke=\"#291e1a\" stroke-width=\"17\""
        ++ line "stroke=\"#31542f\" stroke-width=\"13\""
        ++ line "stroke=\"#496669\" stroke-width=\"4\" stroke-dasharray=\"3 9\""
        ++ pins
        ++ "</svg>"


svgArt : String -> String -> Html msg
svgArt kind markup =
    div [ class kind ] [ node "svg-art" [ attribute "markup" markup ] [] ]
