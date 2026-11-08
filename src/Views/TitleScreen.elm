module Views.TitleScreen exposing (Config, view)

{-| The start/load menu shown when the page opens: the inside of Hale's
Bookshop at Christmas.

  - A garland of Christmas lights hangs across the top. Each bulb lights up
    when the pointer passes over it and slowly fades again, so sweeping across
    the garland leaves a trail of light.
  - Bookcases stand on both sides. Every book slides up out of its shelf on
    hover. The three family diaries (Walter 1950, Henry 1973, Edwin 1998) sit
    among them, the generations who ran the shop.
  - In the middle: the wall clock at a minute to midnight, the logo (an open
    book with a clock face and holly), and the menu as a stack of books lying
    on the counter. Hovering a menu book pulls it out of the stack.

"Continue" only appears when there is a save. The messages come from Main,
which owns the menu, so this view knows nothing about saving. All drawing is
fixed markup built from numbers here, shown through <svg-art>.

-}

import Components.Clock as Clock
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
            , bookcase "title-case title-case--left" leftShelves
            , bookcase "title-case title-case--right" rightShelves
            , Clock.view { hour = 23, minute = 59, ticking = True }
            , logo
            , menu config
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
        [ div [ class "title-menu__stack" ]
            (continueBook
                ++ [ menuBook "title-book--new"
                        (onClick config.onNewGame :: newGameNote)
                        "New Game"
                   , span [ class "title-book title-book--base", attribute "aria-hidden" "true" ]
                        [ span [ class "title-book__label" ] [ text "Hale’s Bookshop" ] ]
                   ]
            )
        , div [ class "title-menu__counter" ] []
        ]


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


{-| Colour, height and width (both in tenths of a rem) of each book. The
colours are the book colours already used in the room art.
-}
leftShelves : List (List Spine)
leftShelves =
    [ [ Book "#893f43" 62 16, Book "#496669" 70 13, Book "#d9a443" 56 18, Book "#31542f" 66 15, Gap 6, Book "#7687ab" 60 14, Book "#5a3428" 72 17, Book "#a6652b" 58 12, Book "#c95937" 64 15, Book "#748b2c" 68 14 ]
    , [ Book "#5a3428" 66 14, Diary "1950" "Walter Hale, 1950", Diary "1973" "Henry Hale, 1973", Diary "1998" "Edwin Hale, 1998", Gap 5, Book "#d9a443" 60 15, Book "#496669" 68 12, Book "#893f43" 56 17, Book "#7687ab" 64 13 ]
    , [ Book "#748b2c" 58 15, Book "#c95937" 70 13, Book "#31542f" 64 18, Book "#a6652b" 60 12, Book "#893f43" 68 16, Gap 8, Book "#496669" 62 14, Book "#d9a443" 72 15, Book "#5a3428" 56 13 ]
    , [ Book "#7687ab" 66 17, Book "#5a3428" 60 13, Book "#d9a443" 70 14, Book "#496669" 58 16, Book "#893f43" 64 12, Book "#748b2c" 68 15, Gap 6, Book "#c95937" 62 14, Book "#31542f" 56 15 ]
    ]


rightShelves : List (List Spine)
rightShelves =
    [ [ Book "#31542f" 68 15, Book "#a6652b" 58 13, Book "#893f43" 66 17, Book "#7687ab" 72 12, Book "#d9a443" 60 16, Gap 7, Book "#496669" 64 14, Book "#5a3428" 56 15, Book "#c95937" 70 13 ]
    , [ Book "#d9a443" 62 14, Book "#5a3428" 70 16, Book "#748b2c" 58 12, Gap 6, Book "#893f43" 66 15, Book "#496669" 60 17, Book "#c95937" 72 13, Book "#31542f" 56 14, Book "#7687ab" 64 15 ]
    , [ Book "#c95937" 60 16, Book "#496669" 68 13, Book "#5a3428" 64 15, Book "#d9a443" 56 14, Gap 7, Book "#893f43" 70 12, Book "#748b2c" 62 17, Book "#7687ab" 58 13, Book "#a6652b" 66 15 ]
    , [ Book "#893f43" 64 14, Book "#31542f" 58 16, Book "#a6652b" 70 13, Book "#7687ab" 62 15, Book "#5a3428" 66 12, Gap 5, Book "#d9a443" 60 17, Book "#496669" 72 14, Book "#c95937" 56 15 ]
    ]


bookcase : String -> List (List Spine) -> Html msg
bookcase kind shelves =
    div [ class kind, attribute "aria-hidden" "true" ]
        (List.map (\books -> div [ class "title-shelf" ] (List.map spine books)) shelves)


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
