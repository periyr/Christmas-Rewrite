module Main exposing (main)

{-| Entry point. Pure core: Update.update does all the work; there are no
commands yet (audio ports, if any, get added here later by agreement).
-}

import Browser
import Domain exposing (..)
import Update
import View


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( Update.init, Cmd.none )
        , update = \msg model -> ( Update.update msg model, Cmd.none )
        , view = View.view
        , subscriptions = \_ -> Sub.none
        }
