port module Main exposing (main)

{-| Entry point. Pure core: Update.update does all the work.

The start/load menu wraps the game here, so Domain and Update stay unchanged:
the page opens on the title screen (Views.TitleScreen) with "New game" and,
when a save exists, "Continue". The saved History arrives as the flag and is
written back through the `saveGame` port whenever the player reaches a
checkpoint, the present-day shop or the ending (see Save). "New game" and
"Start again" at the ending clear it (the port is sent null).

Subscriptions (contract v1.3) only turn browser events into room messages:
the walk keys and E, animation frames while the player is moving or a diary
trip is playing, and the page being hidden.

-}

import Browser
import Browser.Events exposing (Visibility(..))
import Domain exposing (..)
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Rules.Room
import Rules.Travel
import Save exposing (Saved)
import Update
import View
import Views.TitleScreen as TitleScreen


{-| Writes the save to localStorage (public/index.html). null clears it. -}
port saveGame : Encode.Value -> Cmd msg


{-| The title screen or the game, plus the save as it is stored right now,
so the game is only written when its History actually changed.
-}
type alias App =
    { screen : Screen
    , saved : Maybe Saved
    }


type Screen
    = Title
    | Playing Model


type AppMsg
    = NewGame
    | Continue
    | Game Msg


main : Program Decode.Value App AppMsg
main =
    Browser.element
        { init = \flags -> ( { screen = Title, saved = Save.decode flags }, Cmd.none )
        , update = update
        , view = view
        , subscriptions = appSubscriptions
        }


update : AppMsg -> App -> ( App, Cmd AppMsg )
update msg app =
    case ( msg, app.screen ) of
        ( NewGame, Title ) ->
            ( { screen = Playing Update.init, saved = Nothing }, clearSave app )

        ( Continue, Title ) ->
            case app.saved of
                Just history ->
                    ( { app | screen = Playing (Save.resume history) }, Cmd.none )

                Nothing ->
                    ( app, Cmd.none )

        ( Game StartAgain, Playing model ) ->
            -- Starting again from the ending is a new game: the old save goes.
            if model.phase == Ending then
                ( { screen = Playing (Update.update StartAgain model), saved = Nothing }, clearSave app )

            else
                ( app, Cmd.none )

        ( Game gameMsg, Playing model ) ->
            checkpoint { app | screen = Playing (Update.update gameMsg model) }

        _ ->
            ( app, Cmd.none )


{-| Saves when the game stands in the present-day shop or at the ending with
a History that is not the stored one. Mid-chapter progress is never saved:
Continue always resumes from the last checkpoint.
-}
checkpoint : App -> ( App, Cmd AppMsg )
checkpoint app =
    case app.screen of
        Playing model ->
            if isCheckpoint model.phase && app.saved /= Just model.history then
                ( { app | saved = Just model.history }, saveGame (Save.encode model.history) )

            else
                ( app, Cmd.none )

        Title ->
            ( app, Cmd.none )


isCheckpoint : Phase -> Bool
isCheckpoint phase =
    phase == PresentHub || phase == Ending


clearSave : App -> Cmd msg
clearSave app =
    if app.saved == Nothing then
        Cmd.none

    else
        saveGame Encode.null


view : App -> Html AppMsg
view app =
    case app.screen of
        Title ->
            TitleScreen.view
                { onNewGame = NewGame
                , onContinue = Maybe.map (\_ -> Continue) app.saved
                }

        Playing model ->
            Html.map Game (View.view model)


{-| No game keys or frames on the title screen. -}
appSubscriptions : App -> Sub AppMsg
appSubscriptions app =
    case app.screen of
        Title ->
            Sub.none

        Playing model ->
            Sub.map Game (subscriptions model)


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
