module Components.Actor exposing (Pose(..), view)

{-| The human figure, drawn wherever the caller says. It keeps no position of its
own: the walking state belongs to Person A's model, and this only draws it.
Not wired in yet, because that movement contract hasn't landed.
-}

import Html exposing (Html, div, node)
import Html.Attributes exposing (attribute, classList, style)


type Pose
    = Idle
    | StepA
    | StepB


{-| `x` is the centre of the feet in logical room units (0 to 1280). -}
view : { x : Float, facingLeft : Bool, pose : Pose } -> Html msg
view { x, facingLeft, pose } =
    div
        [ classList [ ( "actor", True ), ( "is-facing-left", facingLeft ) ]
        , style "left" (String.fromFloat (x / 16) ++ "rem")
        ]
        [ node "svg-art"
            [ attribute "markup"
                ("<svg class=\"actor__art\" viewBox=\"0 0 200 400\" aria-hidden=\"true\"><use href=\"#actor-" ++ poseName pose ++ "\"/></svg>")
            ]
            []
        ]


poseName : Pose -> String
poseName pose =
    case pose of
        Idle ->
            "idle"

        StepA ->
            "walk-a"

        StepB ->
            "walk-b"
