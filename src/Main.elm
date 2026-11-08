port module Main exposing (main)

{-| Entry point. Pure core: Update.update does all the work.

The page opens on the title screen (Views.TitleScreen) with "New game" and
"Continue", which works once there is a save. The save arrives in the flags
and is written back through the `saveGame` port whenever the History or the
player's place changes (see Save), so leaving early is safe. "New game" and
"Start again" at the ending replace it with the new game's first page.

Sound effects: after each game step, Sounds.forStep compares the model before
and after and the names go out through the `playSound` port to
public/audio.js, which also plays the quiet background music.

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
import Random
import Rules.Room
import Rules.Travel
import Save exposing (Saved)
import Sounds
import Update
import View
import Views.TitleScreen as TitleScreen


{-| Writes the save to localStorage (public/index.html). -}
port saveGame : Encode.Value -> Cmd msg


{-| Plays one sound effect by name (public/audio.js; names from Sounds). -}
port playSound : String -> Cmd msg


{-| The title screen or game, its last checkpoint and the seed stream supplied
by the browser. Only starting a new run consumes that stream.
-}
type alias App =
    { screen : Screen
    , saved : Maybe Saved
    , nextSeed : Random.Seed
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
        { init = init
        , update = update
        , view = view
        , subscriptions = appSubscriptions
        }


init : Decode.Value -> ( App, Cmd AppMsg )
init flags =
    ( { screen = Title
      , saved = Decode.decodeValue (Decode.field "saved" Decode.value) flags |> Result.toMaybe |> Maybe.andThen Save.decode
      , nextSeed = Decode.decodeValue (Decode.field "seed" Decode.int) flags |> Result.withDefault 0 |> Random.initialSeed
      }
    , Cmd.none
    )


freshRun : App -> ( Model, App )
freshRun app =
    let
        ( runSeed, nextSeed ) =
            Random.step (Random.int Random.minInt Random.maxInt) app.nextSeed
    in
    ( Update.newRun runSeed, { app | nextSeed = nextSeed } )


update : AppMsg -> App -> ( App, Cmd AppMsg )
update msg app =
    case ( msg, app.screen ) of
        ( NewGame, Title ) ->
            -- The old save is replaced straight away by the new game's first page.
            let
                ( model, seededApp ) =
                    freshRun app
            in
            checkpoint { seededApp | screen = Playing model }

        ( Continue, Title ) ->
            case app.saved of
                Just saved ->
                    ( { app | screen = Playing (Save.resume saved) }, Cmd.none )

                Nothing ->
                    ( app, Cmd.none )

        ( Game gameMsg, Playing model ) ->
            let
                ( next, seededApp ) =
                    if gameMsg == StartAgain && model.phase == Ending then
                        freshRun app

                    else
                        ( Update.update gameMsg model, app )

                ( saved, saveCmd ) =
                    checkpoint { seededApp | screen = Playing next }
            in
            ( saved
            , Cmd.batch (saveCmd :: List.map playSound (Sounds.forStep gameMsg model next))
            )

        _ ->
            ( app, Cmd.none )


{-| Saves when the run seed, History or the player's place changes.
Walking, panels and puzzle moves write nothing.
-}
checkpoint : App -> ( App, Cmd AppMsg )
checkpoint app =
    case app.screen of
        Playing model ->
            let
                current =
                    { history = model.history, place = Save.placeOf model, runSeed = model.runSeed }
            in
            if app.saved /= Just current then
                ( { app | saved = Just current }, saveGame (Save.encode current) )

            else
                ( app, Cmd.none )

        Title ->
            ( app, Cmd.none )


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
