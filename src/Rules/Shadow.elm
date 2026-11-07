module Rules.Shadow exposing (accepts, allCutouts, complete, scenes, slots, validate)

{-| 1973 shadow story: three panels, each one character and one prop.
-}

import Domain exposing (Character(..), Cutout(..), Placement, Prop(..), Scene(..), ScriptVariant, ShadowSlot(..), Staging, Violation)
import Rules.Placement as Placement


allCutouts : List Cutout
allCutouts =
    List.map CharacterCutout [ Fox, Owl, Child ] ++ List.map PropCutout [ Lantern, Key, Book ]


scenes : List Scene
scenes =
    [ Scene1, Scene2, Scene3 ]


slots : List ShadowSlot
slots =
    List.concatMap (\scene -> [ CharacterSlot scene, PropSlot scene ]) scenes


{-| Characters go in character slots, props in prop slots. -}
accepts : Cutout -> ShadowSlot -> Bool
accepts cutout slot =
    case ( cutout, slot ) of
        ( CharacterCutout _, CharacterSlot _ ) ->
            True

        ( PropCutout _, PropSlot _ ) ->
            True

        _ ->
            False


{-| A Staging once all six slots are filled. -}
complete : Placement Cutout ShadowSlot -> Maybe Staging
complete placement =
    let
        cast scene =
            case ( Placement.itemIn (CharacterSlot scene) placement, Placement.itemIn (PropSlot scene) placement ) of
                ( Just (CharacterCutout character), Just (PropCutout prop) ) ->
                    Just { character = character, prop = prop }

                _ ->
                    Nothing
    in
    Maybe.map3 Staging (cast Scene1) (cast Scene2) (cast Scene3)


{-| NOT IMPLEMENTED YET — Person A, hours 3.5–7.
Compare each scene to the script variant derived from history (brief section 5).
-}
validate : ScriptVariant -> Staging -> List Violation
validate _ _ =
    Debug.todo "Rules.Shadow.validate is not implemented yet"
