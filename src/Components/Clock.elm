module Components.Clock exposing (view)

{-| A wall clock drawn in code, for room pictures that have no painted clock.
It only draws the time it is given: no timers, no subscriptions, no model.

The drawing is fixed SVG (outlines, flat fills, a slight hand-drawn wobble),
shown through the page's existing <svg-art> element. Elm only turns the hands
and switches the ticking on or off; the movement is CSS in public/styles.css.

-}

import Html exposing (Html, div, node)
import Html.Attributes exposing (attribute, class, classList, style)


view : { hour : Int, minute : Int, ticking : Bool } -> Html msg
view { hour, minute, ticking } =
    div
        [ classList [ ( "clock", True ), ( "is-stopped", not ticking ) ]
        , attribute "role" "img"
        , attribute "aria-label" ("Clock showing " ++ label hour minute)
        ]
        [ div [ class "clock__body" ]
            [ drawing face
            , hand "clock__hand--hour" (toFloat (modBy 12 hour) * 30 + toFloat minute * 0.5) hourHand
            , hand "clock__hand--minute" (toFloat minute * 6) minuteHand
            , div [ class "clock__hand clock__hand--second" ] [ drawing secondHand ]
            , drawing centreCap
            ]
        ]


hand : String -> Float -> String -> Html msg
hand kind degrees shape =
    div [ class ("clock__hand " ++ kind), style "transform" ("rotate(" ++ String.fromFloat degrees ++ "deg)") ]
        [ drawing shape ]


{-| One layer of the clock: a 100 x 100 SVG filling the clock. -}
drawing : String -> Html msg
drawing shapes =
    node "svg-art"
        [ attribute "markup" ("<svg class=\"clock__layer\" viewBox=\"0 0 100 100\" aria-hidden=\"true\">" ++ shapes ++ "</svg>") ]
        []



-- THE DRAWING (viewBox units: the clock is 100 across, outlines 2.3 = about 2px)


{-| The wobble filter, the wooden rim (7 of the 47 radius, about 15%), its
walnut shadow ring and honey highlight, the paper face with a faint honey wash,
and the 12 marks.
-}
face : String
face =
    "<defs><filter id=\"clock-wobble\" x=\"-5%\" y=\"-5%\" width=\"110%\" height=\"110%\">"
        ++ "<feTurbulence type=\"fractalNoise\" baseFrequency=\"0.05\" numOctaves=\"2\" seed=\"7\"/>"
        ++ "<feDisplacementMap in=\"SourceGraphic\" scale=\"1.3\"/></filter></defs>"
        ++ "<g filter=\"url(#clock-wobble)\" stroke=\"#291e1a\" stroke-width=\"2.3\" stroke-linecap=\"round\" stroke-linejoin=\"round\">"
        ++ "<circle cx=\"50\" cy=\"50\" r=\"47\" fill=\"#a6652b\"/>"
        ++ "<circle cx=\"50\" cy=\"50\" r=\"41.2\" fill=\"none\" stroke=\"#5a3428\" stroke-width=\"1.6\"/>"
        ++ "<path d=\"M10.3 37.4 A43.7 43.7 0 0 1 28.4 12.1\" fill=\"none\" stroke=\"#d9a443\" stroke-width=\"2\"/>"
        ++ "<circle cx=\"50\" cy=\"50\" r=\"40\" fill=\"#d4d3d1\"/>"
        ++ "<circle cx=\"50\" cy=\"50\" r=\"38.9\" fill=\"#d9a443\" fill-opacity=\"0.1\" stroke=\"none\"/>"
        ++ String.concat (List.map tick (List.range 0 11))
        ++ "</g>"


{-| An hour mark. The 12, 3, 6 and 9 marks are longer. -}
tick : Int -> String
tick n =
    let
        angle =
            degrees (toFloat n * 30)

        inner =
            if modBy 3 n == 0 then
                29.5

            else
                32.5

        point r =
            num (50 + r * sin angle) ++ " " ++ num (50 - r * cos angle)
    in
    "<path d=\"M" ++ point 36 ++ " L" ++ point inner ++ "\" fill=\"none\"/>"


{-| Hands point to 12; Elm turns their layer. Tapered, with rounded ends. -}
hourHand : String
hourHand =
    "<path filter=\"url(#clock-wobble)\" d=\"M46.6 52 L48.6 28.5 Q50 26 51.4 28.5 L53.4 52 Q50 56 46.6 52 Z\" fill=\"#291e1a\" stroke=\"#291e1a\" stroke-width=\"1.4\" stroke-linejoin=\"round\"/>"


minuteHand : String
minuteHand =
    "<path filter=\"url(#clock-wobble)\" d=\"M47.6 52.5 L49.3 16.5 Q50 14.5 50.7 16.5 L52.4 52.5 Q50 55.5 47.6 52.5 Z\" fill=\"#291e1a\" stroke=\"#291e1a\" stroke-width=\"1.2\" stroke-linejoin=\"round\"/>"


{-| Thin cranberry hand with a small counterweight. -}
secondHand : String
secondHand =
    "<g stroke-linecap=\"round\" stroke-linejoin=\"round\">"
        ++ "<path d=\"M50 60 L50 15\" stroke=\"#893f43\" stroke-width=\"1.3\"/>"
        ++ "<circle cx=\"50\" cy=\"62\" r=\"2.6\" fill=\"#893f43\" stroke=\"#291e1a\" stroke-width=\"0.9\"/></g>"


centreCap : String
centreCap =
    "<circle cx=\"50\" cy=\"50\" r=\"3.8\" fill=\"#d9a443\" stroke=\"#291e1a\" stroke-width=\"1.3\"/>"


{-| Two decimals are plenty for a 100-unit drawing. -}
num : Float -> String
num value =
    String.fromFloat (toFloat (round (value * 100)) / 100)


{-| The time as people say it: 23:59 is "11:59", 0:05 is "12:05". -}
label : Int -> Int -> String
label hour minute =
    let
        h =
            if modBy 12 hour == 0 then
                12

            else
                modBy 12 hour
    in
    String.fromInt h ++ ":" ++ String.padLeft 2 '0' (String.fromInt minute)
