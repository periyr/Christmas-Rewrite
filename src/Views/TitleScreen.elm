module Views.TitleScreen exposing (Config, view)

{-| The start/load menu shown when the page opens: the inside of Hale's
Bookshop at Christmas.

  - A garland of Christmas lights hangs across the top. Each bulb lights up
    when the pointer passes over it and slowly fades again, so sweeping across
    the garland leaves a trail of light.
  - In the middle, like a usual game title screen: the logo (an open book
    with a clock face and holly), the title, and the menu as a short stack of
    books. Hovering a menu book pulls it out of the stack.
  - One shelf runs along the bottom. Every book slides up out of it on hover.
    The three family diaries (Walter 1950, Henry 1973, Edwin 1998) sit among
    them, the generations who ran the shop.

"Continue" only appears when there is a save. The messages come from Main,
which owns the menu, so this view knows nothing about saving. All drawing is
fixed markup built from numbers here, shown through <svg-art>.

-}

import Html exposing (Html, button, div, h1, node, p, span, text)
import Html.Attributes exposing (attribute, class, style, type_)
import Html.Events exposing (onClick)


type alias Config msg =
    { onNewGame : msg
    , onContinue : Maybe msg
    }


view : Config msg -> Html msg
view config =
    div [ class "app" ]
        [ div [ class "stage title-screen" ]
            [ div [ class "title-screen__wall" ] []
            , div [ class "title-screen__centre" ] [ logo, menu config ]
            , shelf
            , garland
            ]
        ]



-- ═══════════════════════════════════════════════════════════════════════
-- LOGO
-- ═══════════════════════════════════════════════════════════════════════


logo : Html msg
logo =
    div [ class "title-logo" ]
        [ svgArt "title-logo__art" logoMarkup
        , h1 [ class "title-logo__name" ] [ text "Christmas Rewrite" ]
        , p [ class "title-logo__tagline" ] [ text "The Story of the Hale Family" ]
        ]


{-| An open book: a clock face on the left page at a minute to midnight,
lines of writing and a sprig of holly on the right, a red ribbon marker.
Same drawing rules as the room art: flat fills, dark #291e1a outlines.
-}
logoMarkup : String
logoMarkup =
    """<svg viewBox="0 0 240 130" aria-hidden="true" stroke="#291e1a" stroke-linejoin="round" stroke-linecap="round">
<path fill="#4a3120" stroke-width="2.5" d="M14 30C50 20 96 22 120 34 144 22 190 20 226 30V114C190 106 146 108 120 120 94 108 50 106 14 114Z"/>
<path fill="#f6eedb" stroke-width="2" d="M20 26C54 16 98 18 118 30V112C96 100 56 100 20 108Z"/>
<path fill="#f6eedb" stroke-width="2" d="M222 26C188 16 144 18 122 30V112C144 100 184 100 222 108Z"/>
<path fill="none" stroke-width="2" d="M120 31V116"/>
<circle cx="69" cy="66" r="27" fill="#eadfc4" stroke-width="2.2"/>
<circle cx="69" cy="66" r="21.5" fill="none" stroke="#c9b792" stroke-width="1.2"/>
<g stroke-width="2"><path d="M69 42V47M69 85V90M45 66H50M88 66H93M52 49L55 52M86 49L83 52M52 83L55 80M86 83L83 80"/></g>
<path stroke-width="3.5" d="M69 66L67 52"/>
<path stroke-width="2.5" d="M69 66L68 44"/>
<circle cx="69" cy="66" r="2.6" fill="#893f43" stroke-width="1.2"/>
<g fill="none" stroke="#c9b792" stroke-width="2"><path d="M134 40C156 36 182 36 208 40M134 51C156 47 182 47 208 51M134 62C154 58 176 58 196 61M134 73C150 70 166 70 180 72"/></g>
<g stroke-width="1.8">
<path fill="#31542f" d="M178 98C182 88 192 84 200 86 198 90 202 94 198 96 202 100 196 104 192 102 188 106 182 102 178 98Z"/>
<path fill="#496669" d="M178 98C170 90 158 90 152 94 156 96 154 101 158 102 156 106 162 108 166 106 170 108 175 103 178 98Z"/>
<circle cx="176" cy="100" r="4" fill="#c4352f"/><circle cx="183" cy="102" r="3.6" fill="#c4352f"/><circle cx="178" cy="106" r="3.4" fill="#c4352f"/>
</g>
<path fill="#893f43" stroke-width="1.8" d="M116 116V128L120 124 124 128V116Z"/>
</svg>"""



-- ═══════════════════════════════════════════════════════════════════════
-- MENU: a stack of books on the counter
-- ═══════════════════════════════════════════════════════════════════════


menu : Config msg -> Html msg
menu config =
    let
        newGameNote =
            case config.onContinue of
                Just _ ->
                    [ attribute "data-note" "A new game replaces your saved progress" ]

                Nothing ->
                    []

        continueBook =
            case config.onContinue of
                Just continue ->
                    [ menuBook "title-book--continue" [ onClick continue ] "Continue" ]

                Nothing ->
                    []
    in
    div [ class "title-menu" ]
        (continueBook ++ [ menuBook "title-book--new" (onClick config.onNewGame :: newGameNote) "New Game" ])


menuBook : String -> List (Html.Attribute msg) -> String -> Html msg
menuBook kind attributes label =
    button (type_ "button" :: class ("title-book " ++ kind) :: attributes)
        [ span [ class "title-book__label" ] [ text label ] ]



-- ═══════════════════════════════════════════════════════════════════════
-- BOOKCASES
-- ═══════════════════════════════════════════════════════════════════════


type Spine
    = Book String Int Int
    | Diary String String
    | Gap Int


{-| One shelf along the bottom of the screen, with a cluster of books at
each end and the middle left clear under the menu. Colour, height and width
(both in tenths of a rem); the colours are the book colours already used in
the room art. The family diaries sit in the left cluster.
-}
leftBooks : List Spine
leftBooks =
    [ Book "#893f43" 52 14, Book "#496669" 60 11, Book "#d9a443" 48 15, Diary "1950" "Walter Hale, 1950", Diary "1973" "Henry Hale, 1973", Diary "1998" "Edwin Hale, 1998", Book "#31542f" 56 13, Book "#7687ab" 50 12, Book "#c95937" 58 14 ]


rightBooks : List Spine
rightBooks =
    [ Book "#748b2c" 54 13, Book "#5a3428" 60 15, Book "#a6652b" 48 11, Book "#893f43" 56 14, Book "#496669" 50 12, Book "#d9a443" 60 15, Book "#31542f" 52 13, Book "#7687ab" 58 11, Book "#c95937" 48 14 ]


shelf : Html msg
shelf =
    div [ class "title-shelf", attribute "aria-hidden" "true" ]
        [ div [ class "title-shelf__books" ] (List.map spine leftBooks)
        , div [ class "title-shelf__books" ] (List.map spine rightBooks)
        ]


spine : Spine -> Html msg
spine item =
    case item of
        Book colour height width ->
            -- One style attribute: Elm's `style` cannot set a custom property.
            span
                [ class "title-spine"
                , attribute "style" ("--spine:" ++ colour ++ ";height:" ++ tenths height ++ ";width:" ++ tenths (width * 3 // 2))
                ]
                []

        Diary year owner ->
            span [ class "title-spine title-spine--diary", attribute "data-owner" owner ]
                [ span [ class "title-spine__year" ] [ text year ] ]

        Gap width ->
            span [ class "title-gap", style "width" (tenths width) ] []


tenths : Int -> String
tenths n =
    String.fromFloat (toFloat n / 10) ++ "rem"



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
