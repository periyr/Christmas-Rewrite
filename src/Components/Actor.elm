module Components.Actor exposing (Person(..), view)

{-| The human figure, from C's player sprites. It keeps no position, timer or
frame count of its own: everything it draws comes from A's Player.
-}

import Domain exposing (Facing(..), Player)
import Html exposing (Html, div, img)
import Html.Attributes exposing (alt, class, classList, src, style)
import Rules.Room


type Person
    = EdwinPresent
    | Walter
    | Henry
    | EdwinYoung


type Pose
    = Idle
    | Walk1
    | Walk2


{-| All three frames stay in the page and only the current one shows, so a step
never flickers while an image loads. Sizes follow ASSETS.md: the 96 x 160 sprite
is drawn at 2 logical px per unit, with its feet point (48, 152) on the floor.
-}
view : Person -> Player -> Html msg
view person player =
    let
        current =
            pose player

        frame candidate =
            img
                [ classList [ ( "actor__frame", True ), ( "is-current", candidate == current ) ]
                , src ("assets/player-" ++ personFile person ++ "-" ++ poseFile candidate ++ ".svg")
                , alt ""
                ]
                []
    in
    div
        [ classList [ ( "actor", True ), ( "is-facing-left", player.facing == FacingLeft ) ]
        , style "left" (rem (player.x - 96))
        , style "top" (rem (Rules.Room.floorY - 304))
        ]
        (div [ class "actor__shadow" ] [] :: List.map frame [ Idle, Walk1, Walk2 ])


{-| The step comes from how far the player has walked, so the legs stay in step
at any frame rate: one pose per 48 px is about six poses a second.
-}
pose : Player -> Pose
pose player =
    if not player.walking then
        Idle

    else if modBy 2 (floor (player.x / 48)) == 0 then
        Walk1

    else
        Walk2


rem : Float -> String
rem logical =
    String.fromFloat (logical / 16) ++ "rem"


personFile : Person -> String
personFile person =
    case person of
        EdwinPresent ->
            "edwin-present"

        Walter ->
            "walter"

        Henry ->
            "henry"

        EdwinYoung ->
            "edwin-young"


poseFile : Pose -> String
poseFile candidate =
    case candidate of
        Idle ->
            "idle"

        Walk1 ->
            "walk-1"

        Walk2 ->
            "walk-2"
