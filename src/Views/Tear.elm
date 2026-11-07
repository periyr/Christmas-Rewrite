module Views.Tear exposing (view)

{-| The way back to the present after a chapter's last slide (contract v1.6):
a tear in the page. Deliberately unlike the trip into the past: no book, no
clock, no years.

Everything is drawn from `elapsed`, which Update moves on with animation
frames (Rules.Travel), over about 1.8 seconds:

  - 0 to 150: the finished era's room stays as it was on the last slide.
  - 150 to 550: a paper tint and texture settle over it.
  - 450 to 700: a thin, irregular golden tear opens near the centre, showing
    the present-day shop.
  - 700 to 1500: the tear widens, with glowing paper edges, until the present
    fills the screen.
  - 1450 to 1800: the glow fades; then the "Back to the present" narration.

The two rooms are separate layers, each with its own stage attributes, so the
past keeps its finished look and the present comes from the actual history.
The tear is a clip-path polygon recomputed from `elapsed`. public/styles.css
has the look, and a plain crossfade for prefers-reduced-motion.

-}

import Domain exposing (..)
import Html exposing (Attribute, Html, button, div, p, text)
import Html.Attributes exposing (attribute, class, style, type_)
import Html.Events exposing (onClick)
import Views.Labels exposing (eraYear)


type alias Rooms =
    { era : Era
    , past : List (Html Msg)
    , pastAttributes : List (Attribute Msg)
    , present : List (Html Msg)
    , presentAttributes : List (Attribute Msg)
    }


view : Rooms -> Float -> List (Html Msg)
view rooms t =
    let
        opening =
            halfWidth t

        glow =
            smooth (between 450 650 t) * (1 - smooth (between 1450 1800 t))
    in
    [ div [ class "tear", attribute "data-stage" (stageName t) ]
        [ div (class "stage tear__layer tear__layer--past" :: rooms.pastAttributes) rooms.past
        , div [ class "tear__paper", style "opacity" (number (0.75 * smooth (between 150 550 t))) ] []
        , div [ class "tear__glow", style "opacity" (number glow) ]
            [ div [ class "tear__rim", style "clip-path" (tearShape (opening + rimWidth opening)) ] [] ]
        , div [ class "tear__fade", style "opacity" (number (smooth (between 200 1400 t))) ]
            [ div
                (class "stage tear__layer tear__layer--present"
                    :: style "clip-path" (tearShape opening)
                    :: rooms.presentAttributes
                )
                rooms.present
            ]
        , p [ class "visually-hidden", attribute "aria-live" "polite" ] [ text ("Back from " ++ eraYear rooms.era ++ " to the present") ]
        , button [ type_ "button", class "btn travel__skip", onClick SkipTravel ] [ text "Skip" ]
        ]
    ]


stageName : Float -> String
stageName t =
    if t < 450 then
        "settle"

    else if t < 1500 then
        "tear"

    else
        "present"



-- THE TEAR


{-| Half the tear's width, as a percentage of the room's width: nothing at
first, a thin slit from 450 ms, then spreading out past both edges by 1500.
-}
halfWidth : Float -> Float
halfWidth t =
    if t < 450 then
        0

    else if t < 700 then
        0.7 * smooth (between 450 700 t)

    else
        0.7 + 64 * smooth (between 700 1500 t)


{-| The glowing paper edge just outside the opening. -}
rimWidth : Float -> Float
rimWidth opening =
    if opening <= 0 then
        0

    else
        0.35 + 0.18 * min opening 5


{-| A torn opening `width` either side of a wavering centre line. Each edge is
pushed outwards by a fixed irregular amount, so the two sides never cross and
the tear looks ragged rather than cut. Nothing shows while `width` is 0.
-}
tearShape : Float -> String
tearShape width =
    if width <= 0 then
        "inset(0 50% 0 50%)"

    else
        let
            ragged =
                0.25 + 0.55 * min width 3

            rows =
                List.indexedMap (\i ( l, r ) -> ( toFloat i * 100 / toFloat (List.length jags - 1), l, r )) jags

            centre y =
                50 + 1.1 * sin (y / 17) - 0.6 * cos (y / 7)

            left =
                List.map (\( y, l, _ ) -> point (centre y - width - ragged * l) y) rows

            right =
                List.map (\( y, _, r ) -> point (centre y + width + ragged * r) y) (List.reverse rows)
        in
        "polygon(" ++ String.join ", " (left ++ right) ++ ")"


point : Float -> Float -> String
point x y =
    number x ++ "% " ++ number y ++ "%"


{-| How far each edge is pushed out at each row, from 0 to 1 (left, right). -}
jags : List ( Float, Float )
jags =
    [ ( 0.2, 0.7 ), ( 0.9, 0.1 ), ( 0.4, 0.8 ), ( 0.0, 0.5 ), ( 0.7, 0.2 ), ( 0.3, 1.0 ), ( 1.0, 0.3 ), ( 0.1, 0.6 ), ( 0.6, 0.0 ), ( 0.2, 0.9 ), ( 0.8, 0.4 ), ( 0.4, 0.1 ), ( 0.9, 0.7 ), ( 0.1, 0.3 ), ( 0.5, 0.8 ), ( 0.7, 0.2 ), ( 0.3, 0.6 ) ]



-- EASING


between : Float -> Float -> Float -> Float
between from to t =
    clamp 0 1 ((t - from) / (to - from))


smooth : Float -> Float
smooth x =
    x * x * (3 - 2 * x)


number : Float -> String
number x =
    String.fromFloat (toFloat (round (x * 1000)) / 1000)
