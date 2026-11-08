module Main exposing (main)

{-| Entry point. Pure core: Update.update does all the work; there are no
commands yet (audio ports, if any, get added here later by agreement).

Subscriptions (contract v1.3) only turn browser events into room messages:
the walk keys and E, animation frames while the player is moving or a diary
trip is playing, and the page being hidden.

-}

import Browser
import Browser.Events exposing (Visibility(..))
import Domain exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Rules.Room
import Rules.Travel
import Update
import View


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( Update.init, Cmd.none )
        , update = \msg model -> ( Update.update msg model, Cmd.none )
        , view = View.view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onKeyDown (keyDown Rules.Room.keyDown)
        , Browser.Events.onKeyUp (keyUp Rules.Room.keyUp)
        , Browser.Events.onVisibilityChange (\visibility -> PageVisibilityChanged (visibility == Visible))
        , if Rules.Travel.wantsFrames model then
            -- Frames only while walking or travelling, so an idle room costs nothing.
            Browser.Events.onAnimationFrameDelta AnimationFrame

          else
            Sub.none
        ]


{-| A game key pressed without Ctrl, Cmd or Alt, so browser shortcuts such as
Cmd+D are left alone. The browser's auto-repeat while a key stays down is
ignored too: the key is already held until its keyup, and a key held through
a panel, the trip into a diary or a phase change must be pressed again.
-}
keyDown : (String -> Maybe Msg) -> Decoder Msg
keyDown toMsg =
    Decode.map5
        (\key ctrl meta alt repeat ->
            if ctrl || meta || alt || repeat then
                Nothing

            else
                toMsg key
        )
        (Decode.field "key" Decode.string)
        (Decode.field "ctrlKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)
        (Decode.field "altKey" Decode.bool)
        (Decode.oneOf [ Decode.field "repeat" Decode.bool, Decode.succeed False ])
        |> Decode.andThen orIgnore


{-| A game key released, whatever modifiers are down, so a key never stays held. -}
keyUp : (String -> Maybe Msg) -> Decoder Msg
keyUp toMsg =
    Decode.field "key" Decode.string
        |> Decode.map toMsg
        |> Decode.andThen orIgnore


orIgnore : Maybe Msg -> Decoder Msg
orIgnore maybeMsg =
    case maybeMsg of
        Just msg ->
            Decode.succeed msg

        Nothing ->
            Decode.fail "not a game key"
