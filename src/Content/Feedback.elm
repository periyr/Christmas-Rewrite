module Content.Feedback exposing (notice, violation)

{-| One sentence per broken rule, shown only after a submission. Each names
the rule that was broken, never the full answer. Numbers come from
Rules.Repair.budget so they cannot disagree with the rules.
-}

import Content.Repair as Repair
import Content.Words exposing (dayName, sceneName)
import Domain exposing (Day(..), Notice(..), ReopeningGoal(..), RememberedDetail(..), TaskId(..), Violation(..))
import Rules.Repair


violation : Violation -> String
violation broken =
    case broken of
        RoofAfterRain Wednesday ->
            "The roof is patched on Wednesday, but the rain comes that same day."

        RoofAfterRain day ->
            "Wednesday’s rain comes before the roof is patched on " ++ dayName day ++ "."

        GlassNotYetDelivered day ->
            "The new glass isn’t delivered until Wednesday, so it can’t be fitted on " ++ dayName day ++ "."

        MustComeBefore ClearRubble BuildShelves ->
            "The shelves go where the rubble is, so the rubble must be cleared on an earlier day."

        MustComeBefore BuildShelves ShelveBooks ->
            "The books need somewhere to stand, so the shelves must be built on an earlier day."

        MustComeBefore first second ->
            "“" ++ (Repair.taskCard first).title ++ "” must happen on an earlier day than “" ++ (Repair.taskCard second).title ++ "”."

        TimberOverspent total ->
            "This week uses " ++ String.fromInt total ++ " wood planks, but the licence allows only " ++ String.fromInt Rules.Repair.budget.timber ++ "."

        MoneyOverspent total ->
            "This week costs £" ++ String.fromInt total ++ ", but there is only £" ++ String.fromInt Rules.Repair.budget.pounds ++ " to spend."

        GoalMissing WatertightRoof ->
            "The roof is left for another week, so the shop can’t reopen watertight."

        GoalMissing SealedWindow ->
            "Nothing done this week seals the broken window."

        GoalMissing UsableShelves ->
            "No shelves are built this week, so the books have nowhere to go."

        GoalMissing AllBooksShelved ->
            "The recovered books are never put on the shelves this week."

        SceneConflictsWithScript scene ->
            sceneName scene ++ " doesn’t match what the story says happens there."

        DetailDoesNotMatch FoxLanternIllustration ->
            "This book’s picture isn’t the fox carrying a lantern beneath a stone bridge."

        DetailDoesNotMatch LanternSentence ->
            "This book doesn’t contain the line Lucy remembers."

        DetailDoesNotMatch LucyInscription ->
            "The inscription in this book isn’t the one Ruth wrote."


{-| Neutral messages. None of them says anything about correctness. -}
notice : Notice -> String
notice shown =
    case shown of
        IncompleteSubmission ->
            "This isn’t finished yet: fill every space, or choose a book, first."

        TargetFull ->
            "That space is full. Move something out of it first."

        DoesNotFitThere ->
            "That piece doesn’t go in that kind of space."

        NotSolvedYet ->
            "Not quite yet. Keep arranging."
