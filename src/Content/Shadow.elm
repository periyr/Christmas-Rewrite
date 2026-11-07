module Content.Shadow exposing (cutoutName, scene)

{-| 1973 shadow-story words. Each variant's settings and captions agree with
the scripts in the brief (section 5); the matching itself is Rules.Shadow.
-}

import Domain exposing (Character(..), Cutout(..), Prop(..), Scene(..), ScriptVariant(..), ShadowSceneContent)


cutoutName : Cutout -> String
cutoutName cutout =
    case cutout of
        CharacterCutout Fox ->
            "Fox"

        CharacterCutout Owl ->
            "Owl"

        CharacterCutout Child ->
            "Child"

        PropCutout Lantern ->
            "Lantern"

        PropCutout Key ->
            "Key"

        PropCutout Book ->
            "Book"


{-| `setting` labels a stage panel (it repeats the stage sketch, not the
script). `caption` is read during the successful performance.
-}
scene : ScriptVariant -> Scene -> ShadowSceneContent
scene variant sceneId =
    case ( variant, sceneId ) of
        ( OriginalScript, Scene1 ) ->
            { setting = "The bridge"
            , caption = "Through the dark, the fox carries the lantern across the bridge, lighting the way."
            }

        ( OriginalScript, Scene2 ) ->
            { setting = "The door"
            , caption = "At the door, the owl turns the key, and the door swings open."
            }

        ( OriginalScript, Scene3 ) ->
            { setting = "Home"
            , caption = "Everyone is home at last, and the child opens the book."
            }

        ( NeighboursRetelling, Scene1 ) ->
            { setting = "The gate"
            , caption = "At the gate, the child finds a key half-buried in the snow."
            }

        ( NeighboursRetelling, Scene2 ) ->
            { setting = "Inside"
            , caption = "Inside, by the fire, the owl reads the book aloud."
            }

        ( NeighboursRetelling, Scene3 ) ->
            { setting = "Home"
            , caption = "The fox lifts the lantern and guides everyone home."
            }
