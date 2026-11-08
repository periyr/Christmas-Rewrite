module Views.TimeTravel exposing (view)

{-| The trip back in time into a diary's era (contract v1.5). One component for
all three eras.

Everything here is computed from `elapsed`, which Update moves on with
animation frames (Rules.Travel), so every trip starts fresh at 0 and there is
no timer or animation state in the view. The stages, in milliseconds:

  - 0 to 500, open the book: the shop darkens, the diary grows in the centre
    and its cover swings open.
  - 500 to 1800, travel back: pages turn backwards, a faint clock spins
    backwards behind the book, warm light grows between the pages, and the
    year on the page counts back from the present.
  - 1800 to 2500, arrive: the destination year stays, and the book, light and
    darkness fade to reveal the era's room (View draws it behind from 1800).

The pages are layered HTML shapes turned with perspective; the cover is the
diary's existing cover picture. public/styles.css has the look, and a calm
fade for prefers-reduced-motion.

-}

import Components.Art as Art
import Domain exposing (..)
import Html exposing (Html, button, div, p, span, text)
import Html.Attributes exposing (attribute, class, classList, style, type_)
import Html.Events exposing (onClick)
import Rules.Travel
import Views.Labels exposing (eraYear)


view : Era -> Float -> List (Html Msg)
view era elapsed =
    let
        t =
            elapsed

        fadeOut =
            smooth (between 2000 Rules.Travel.duration t)

        darkness =
            0.9 * smooth (between 0 400 t) * (1 - fadeOut)

        -- The light peaks around arrival, when the room behind becomes the
        -- destination, so the change of room happens under it.
        glow =
            smooth (between 450 1700 t) * (1 - smooth (between 1950 2450 t))
    in
    [ div
        [ class "travel"
        , attribute "data-stage" (stageName t)
        ]
        [ div [ class "travel__dark", style "opacity" (number darkness) ] []
        , clock t fadeOut
        , div
            [ class "travel__glow"
            , style "opacity" (number glow)
            , style "transform" ("translate(-50%, -50%) scale(" ++ number (0.5 + 1.1 * smooth (between 450 1850 t)) ++ ")")
            ]
            []
        , book era t glow fadeOut
        , p [ class "visually-hidden", attribute "aria-live" "polite" ] [ text ("Going back to " ++ eraYear era) ]
        , button [ type_ "button", class "btn travel__skip", onClick SkipTravel ] [ text "Skip" ]
        ]
    ]


stageName : Float -> String
stageName t =
    if t < Rules.Travel.bookOpen then
        "open"

    else if Rules.Travel.hasArrived t then
        "arrive"

    else
        "travel"



-- THE BOOK


{-| The diary: a cover that swings open over two pages, then pages turning
back from left to right. Closed, the cover sits in the middle of the screen;
open, the spine does.
-}
book : Era -> Float -> Float -> Float -> Html Msg
book era t glow fadeOut =
    let
        grow =
            smooth (between 0 Rules.Travel.bookOpen t)

        coverOpen =
            smooth (between 150 Rules.Travel.bookOpen t)

        isOpen =
            coverOpen >= 1

        scale =
            0.5 + 0.5 * grow + 0.06 * fadeOut

        shift =
            -8.125 * (1 - coverOpen)
    in
    div
        [ class "travel__book"
        , style "transform" ("translate(-50%, -50%) translateX(" ++ number shift ++ "rem) scale(" ++ number scale ++ ")")
        , style "opacity" (number (smooth (between 0 150 t) * (1 - fadeOut)))
        ]
        ([ div [ classList [ ( "travel__board travel__board--left", True ), ( "is-shown", isOpen ) ] ] []
         , div [ class "travel__board travel__board--right" ] []
         , div [ classList [ ( "travel__page travel__page--left", True ), ( "is-shown", isOpen ) ] ] []
         , div [ class "travel__page travel__page--right" ] [ year era t ]
         ]
            ++ List.filterMap (leaf t) (List.range 0 (leafCount - 1))
            ++ [ div [ class "travel__light", style "opacity" (number glow) ] []
               , cover era coverOpen
               ]
        )


{-| The cover turns about the spine, from closed (0) to lying open on the left
(-180 degrees), showing its leather inside on the way down.
-}
cover : Era -> Float -> Html Msg
cover era opened =
    if opened >= 1 then
        text ""

    else
        div
            [ class "travel__cover"
            , style "transform" ("perspective(110rem) rotateY(" ++ number (-180 * opened) ++ "deg)")
            ]
            [ div [ class "travel__cover-front" ] [ Art.diaryCover era ]
            , div [ class "travel__cover-back" ] []
            ]


leafCount : Int
leafCount =
    7


{-| Leaf `i` turns back from the left page to the right one. Only leaves in the
air are drawn: one that has landed becomes the right page, under the new year.
-}
leaf : Float -> Int -> Maybe (Html Msg)
leaf t i =
    let
        start =
            520 + toFloat i * 150

        turned =
            smooth (between start (start + 330) t)

        angle =
            -180 + 180 * turned
    in
    if turned <= 0 || turned >= 1 then
        Nothing

    else
        Just
            (div
                [ class "travel__leaf"
                , style "transform" ("perspective(110rem) rotateY(" ++ number angle ++ "deg)")
                , style "filter" ("brightness(" ++ number (0.82 + 0.18 * abs (cos (degrees angle))) ++ ")")
                ]
                []
            )


{-| The year written on the right page. The moving one counts back; the
destination one replaces it for reduced motion (see styles.css).
-}
year : Era -> Float -> Html Msg
year era t =
    let
        shown =
            Rules.Travel.yearAt era t
    in
    div [ class "travel__years" ]
        [ span
            [ classList
                [ ( "travel__year travel__year--moving", True )
                , ( "is-present", shown == Nothing )
                , ( "is-destination", Rules.Travel.hasArrived t )
                ]
            ]
            [ text (label shown) ]
        , span [ class "travel__year travel__year--destination" ] [ text (eraYear era) ]
        ]


label : Maybe Era -> String
label shown =
    case shown of
        Just era ->
            eraYear era

        Nothing ->
            "Present"



-- THE CLOCK


{-| A large, faint clock behind the book. It starts at 11:59, where the shop's
clock stopped, and spins backwards while the pages turn.
-}
clock : Float -> Float -> Html Msg
clock t fadeOut =
    let
        spin =
            smooth (between 450 1850 t)

        minute =
            354 - 360 * 6 * spin

        hour =
            359.5 - 30 * 6 * spin

        shown =
            0.3 * smooth (between 300 700 t) * (1 - smooth (between 1750 2200 t)) * (1 - fadeOut)
    in
    div [ class "travel__clock", style "opacity" (number shown) ]
        [ div [ class "travel__clock-hand travel__clock-hand--hour", style "transform" ("rotate(" ++ number hour ++ "deg)") ] []
        , div [ class "travel__clock-hand travel__clock-hand--minute", style "transform" ("rotate(" ++ number minute ++ "deg)") ] []
        , div [ class "travel__clock-pin" ] []
        ]



-- EASING


{-| How far `t` is through `from`..`to`, from 0 to 1. -}
between : Float -> Float -> Float -> Float
between from to t =
    clamp 0 1 ((t - from) / (to - from))


smooth : Float -> Float
smooth x =
    x * x * (3 - 2 * x)


number : Float -> String
number x =
    String.fromFloat (toFloat (round (x * 1000)) / 1000)
