module Rules.Shadow exposing (accepts, allCutouts, complete, scenes, script, slots, validate)

{-| 1973 shadow story: three numbered panels, each one character and one prop.

The scenes are fixed slots, so a complete staging is one way of giving the
three characters and the three props to Scene 1, 2 and 3: 3! × 3! = 36
stagings. Each script variant accepts exactly one of them.

-}

import Domain exposing (Character(..), Cutout(..), Placement, Prop(..), Scene(..), ScriptVariant(..), ShadowSlot(..), Staging, Violation(..))
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


{-| A Staging once the stage is structurally complete: all six slots filled,
each with the right kind of cut-out, and every cut-out used exactly once.
Anything less is an incomplete submission, which spends no attempt.
This is never a correctness signal.
-}
complete : Placement Cutout ShadowSlot -> Maybe Staging
complete placement =
    let
        placed =
            placement.placed

        occurrences match =
            List.length (List.filter match placed)

        wellFormed =
            (List.length placed == List.length slots)
                && List.all (\slot -> occurrences (\( _, s ) -> s == slot) == 1) slots
                && List.all (\cutout -> occurrences (\( c, _ ) -> c == cutout) == 1) allCutouts

        cast scene =
            case ( Placement.itemIn (CharacterSlot scene) placement, Placement.itemIn (PropSlot scene) placement ) of
                ( Just (CharacterCutout character), Just (PropCutout prop) ) ->
                    Just { character = character, prop = prop }

                _ ->
                    Nothing
    in
    if wellFormed then
        Maybe.map3 Staging (cast Scene1) (cast Scene2) (cast Scene3)

    else
        Nothing


{-| The staging each script describes (brief section 5). The original script
is used when 1950 succeeded, the neighbours' retelling when it failed.
-}
script : ScriptVariant -> Staging
script variant =
    case variant of
        OriginalScript ->
            { scene1 = { character = Fox, prop = Lantern }
            , scene2 = { character = Owl, prop = Key }
            , scene3 = { character = Child, prop = Book }
            }

        NeighboursRetelling ->
            { scene1 = { character = Child, prop = Key }
            , scene2 = { character = Owl, prop = Book }
            , scene3 = { character = Fox, prop = Lantern }
            }


{-| One SceneConflictsWithScript per scene whose character or prop differs
from the script, in scene order. Because every cut-out is used exactly once,
a wrong staging always conflicts in at least two scenes.
-}
validate : ScriptVariant -> Staging -> List Violation
validate variant staging =
    let
        expected =
            script variant

        check scene castOf =
            if castOf staging == castOf expected then
                []

            else
                [ SceneConflictsWithScript scene ]
    in
    List.concat
        [ check Scene1 .scene1
        , check Scene2 .scene2
        , check Scene3 .scene3
        ]
