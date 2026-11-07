module Content.Words exposing (dayName, sceneName)

{-| Small wording helpers shared by the Content modules. Words only, no rules.
-}

import Domain exposing (Day(..), Scene(..))


dayName : Day -> String
dayName day =
    case day of
        Monday ->
            "Monday"

        Tuesday ->
            "Tuesday"

        Wednesday ->
            "Wednesday"

        Thursday ->
            "Thursday"

        Friday ->
            "Friday"


sceneName : Scene -> String
sceneName scene =
    case scene of
        Scene1 ->
            "Scene 1"

        Scene2 ->
            "Scene 2"

        Scene3 ->
            "Scene 3"
