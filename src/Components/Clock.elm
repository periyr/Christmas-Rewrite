module Components.Clock exposing (view)

{-| A wall clock drawn in code, for room pictures that have no painted clock.
It only draws the time it is given: no timers, no subscriptions, no model.
The look and the movement are in public/styles.css (".clock").
-}

import Html exposing (Html, div, span)
import Html.Attributes exposing (attribute, class, classList, style)


view : { hour : Int, minute : Int, ticking : Bool } -> Html msg
view { hour, minute, ticking } =
    div
        [ classList [ ( "clock", True ), ( "is-stopped", not ticking ) ]
        , attribute "role" "img"
        , attribute "aria-label" ("Clock showing " ++ label hour minute)
        ]
        [ div [ class "clock__face" ]
            (List.map tick (List.range 0 11)
                ++ [ hand "clock__hand--hour" (toFloat (modBy 12 hour) * 30 + toFloat minute * 0.5)
                   , hand "clock__hand--minute" (toFloat minute * 6)
                   , div [ class "clock__hand clock__hand--second" ] []
                   , div [ class "clock__pin" ] []
                   ]
            )
        ]


{-| One of the 12 hour marks, turned into place around the face. -}
tick : Int -> Html msg
tick n =
    span [ class "clock__tick", style "transform" (rotate (toFloat n * 30)) ] []


hand : String -> Float -> Html msg
hand kind degrees =
    div [ class ("clock__hand " ++ kind), style "transform" (rotate degrees) ] []


rotate : Float -> String
rotate degrees =
    "rotate(" ++ String.fromFloat degrees ++ "deg)"


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
