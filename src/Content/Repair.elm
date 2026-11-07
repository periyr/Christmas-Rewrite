module Content.Repair exposing (goal, taskCard)

{-| Words on the 1950 repair board. Costs are never written here: they come
from Rules.Repair.cost. Notes restate each card's own rule; none says which
cards to leave out.
-}

import Domain exposing (ReopeningGoal(..), TaskCardContent, TaskId(..))


taskCard : TaskId -> TaskCardContent
taskCard task =
    case task of
        PatchRoof ->
            { title = "Patch the roof"
            , note = "Must be done before Wednesday’s rain."
            }

        ClearRubble ->
            { title = "Clear the rubble"
            , note = "The new shelves go where the rubble is now."
            }

        BuildShelves ->
            { title = "Build shelves"
            , note = "Only once the rubble is cleared. The books wait for these."
            }

        ShelveBooks ->
            { title = "Shelve the books"
            , note = "Only once the new shelves are built."
            }

        ReglazeWindow ->
            { title = "Re-glaze the window"
            , note = "The new glass is delivered on Wednesday."
            }

        PaintSign ->
            { title = "Paint a grand new sign"
            , note = "Something to catch every eye on reopening day."
            }

        BoardUpWindow ->
            { title = "Board up the window"
            , note = "Seals the broken window with planks."
            }


goal : ReopeningGoal -> String
goal reopeningGoal =
    case reopeningGoal of
        WatertightRoof ->
            "A watertight roof"

        SealedWindow ->
            "A sealed window"

        UsableShelves ->
            "Usable shelves"

        AllBooksShelved ->
            "Every recovered book on a shelf"
