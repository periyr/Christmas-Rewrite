module Rules.Repair exposing
    ( accepts, allTasks, budget, complete, cost, days, notThisWeekSlots, remaining, slots, spent, taskOn
    , dayOf, validate
    )

{-| 1950 repair planning board: rule data, resource arithmetic,
structural completeness and the submission validator.

The costs and budget here are the single source of truth for the numbers
shown on cards and in the spent/remaining display.

While arranging, views may show `spent`/`remaining` and use `complete` to
enable the button. `validate` is for submission only (via Update).

-}

import Domain exposing (Day(..), Placement, ReopeningGoal(..), RepairSlot(..), Resources, TaskId(..), Violation(..), WeekPlan)
import Rules.Placement as Placement


allTasks : List TaskId
allTasks =
    [ PatchRoof, ClearRubble, BuildShelves, ShelveBooks, ReglazeWindow, PaintSign, BoardUpWindow ]


days : List Day
days =
    [ Monday, Tuesday, Wednesday, Thursday, Friday ]


notThisWeekSlots : List RepairSlot
notThisWeekSlots =
    [ NotThisWeek 1, NotThisWeek 2 ]


slots : List RepairSlot
slots =
    List.map OnDay days ++ notThisWeekSlots


accepts : TaskId -> RepairSlot -> Bool
accepts _ slot =
    List.member slot slots


budget : Resources
budget =
    { timber = 4, pounds = 10 }


cost : TaskId -> Resources
cost task =
    case task of
        PatchRoof ->
            { timber = 2, pounds = 0 }

        ClearRubble ->
            { timber = 0, pounds = 0 }

        BuildShelves ->
            { timber = 2, pounds = 0 }

        ShelveBooks ->
            { timber = 0, pounds = 0 }

        ReglazeWindow ->
            { timber = 0, pounds = 6 }

        PaintSign ->
            { timber = 1, pounds = 6 }

        BoardUpWindow ->
            { timber = 1, pounds = 0 }


{-| Resources used by cards placed on days. Cards in the tray or in
"Not this week" cost nothing. Plain arithmetic: may exceed the budget.
-}
spent : Placement TaskId RepairSlot -> Resources
spent placement =
    placement.placed
        |> List.filterMap
            (\( task, slot ) ->
                case slot of
                    OnDay _ ->
                        Just task

                    NotThisWeek _ ->
                        Nothing
            )
        |> totalCost


totalCost : List TaskId -> Resources
totalCost tasks =
    List.foldl
        (\task acc ->
            let
                c =
                    cost task
            in
            { timber = acc.timber + c.timber, pounds = acc.pounds + c.pounds }
        )
        { timber = 0, pounds = 0 }
        tasks


{-| Budget minus spent. Negative when overspent; no judgement attached. -}
remaining : Placement TaskId RepairSlot -> Resources
remaining placement =
    let
        s =
            spent placement
    in
    { timber = budget.timber - s.timber, pounds = budget.pounds - s.pounds }


{-| Structural completeness only, never correctness.

Just a WeekPlan when the board is exactly one card per day and two cards in
"Not this week", with each of the seven cards used exactly once and no
unknown slots. Anything else (cards still in the tray, a card listed twice,
two cards in one slot, a slot like NotThisWeek 3) is Nothing, and
submitting it spends no attempt.

-}
complete : Placement TaskId RepairSlot -> Maybe WeekPlan
complete placement =
    let
        placed =
            placement.placed

        occurrences match =
            List.length (List.filter match placed)

        wellFormed =
            (List.length placed == List.length slots)
                && List.all (\slot -> occurrences (\( _, s ) -> s == slot) == 1) slots
                && List.all (\task -> occurrences (\( t, _ ) -> t == task) == 1) allTasks

        at slot =
            Placement.itemIn slot placement
    in
    if not wellFormed then
        Nothing

    else
        case ( List.map (at << OnDay) days, List.filterMap at notThisWeekSlots ) of
            ( [ Just mon, Just tue, Just wed, Just thu, Just fri ], [ asideA, asideB ] ) ->
                Just
                    { monday = mon
                    , tuesday = tue
                    , wednesday = wed
                    , thursday = thu
                    , friday = fri
                    , notThisWeek = [ asideA, asideB ]
                    }

            _ ->
                Nothing


taskOn : Day -> WeekPlan -> TaskId
taskOn day week =
    case day of
        Monday ->
            week.monday

        Tuesday ->
            week.tuesday

        Wednesday ->
            week.wednesday

        Thursday ->
            week.thursday

        Friday ->
            week.friday


{-| The day a task is scheduled, or Nothing if it is in "Not this week". -}
dayOf : TaskId -> WeekPlan -> Maybe Day
dayOf task week =
    days
        |> List.filter (\day -> taskOn day week == task)
        |> List.head


dayIndex : Day -> Int
dayIndex day =
    case day of
        Monday ->
            1

        Tuesday ->
            2

        Wednesday ->
            3

        Thursday ->
            4

        Friday ->
            5


{-| Judge a complete week against the actual rules (brief section 4B).
Call only on submission, never while the player is arranging.

Returns every broken rule (empty list = valid week), ordered by consequence:
roof, window, shelves, books, timber, money. The first one drives the
failure slideshow.

Each problem is reported once, by its root cause:

  - A deferred essential task gives one GoalMissing for its goal: roof →
    WatertightRoof, shelves → UsableShelves, books → AllBooksShelved, and
    neither glazing nor boarding → SealedWindow.
  - A mistimed scheduled task gives its timing rule instead: RoofAfterRain
    (Wednesday or later) or GlassNotYetDelivered (before Wednesday).
  - MustComeBefore a b is reported when b is scheduled but a is not on an
    earlier day (a later or deferred). Clearing rubble has no goal of its own,
    so its absence shows up this way. Books are not blamed for shelves that
    are already reported missing.
  - TimberOverspent / MoneyOverspent carry the total spent by scheduled tasks.

-}
validate : WeekPlan -> List Violation
validate week =
    let
        on task =
            dayOf task week

        scheduled task =
            on task /= Nothing

        beforeWednesday day =
            dayIndex day < dayIndex Wednesday

        isBefore first second =
            case ( on first, on second ) of
                ( Just a, Just b ) ->
                    dayIndex a < dayIndex b

                _ ->
                    False

        roof =
            case on PatchRoof of
                Nothing ->
                    [ GoalMissing WatertightRoof ]

                Just day ->
                    if beforeWednesday day then
                        []

                    else
                        [ RoofAfterRain day ]

        window =
            case on ReglazeWindow of
                Just day ->
                    if beforeWednesday day then
                        [ GlassNotYetDelivered day ]

                    else
                        []

                Nothing ->
                    if scheduled BoardUpWindow then
                        []

                    else
                        [ GoalMissing SealedWindow ]

        shelves =
            if not (scheduled BuildShelves) then
                [ GoalMissing UsableShelves ]

            else if isBefore ClearRubble BuildShelves then
                []

            else
                [ MustComeBefore ClearRubble BuildShelves ]

        books =
            if not (scheduled ShelveBooks) then
                [ GoalMissing AllBooksShelved ]

            else if not (scheduled BuildShelves) || isBefore BuildShelves ShelveBooks then
                []

            else
                [ MustComeBefore BuildShelves ShelveBooks ]

        total =
            totalCost (List.map (\day -> taskOn day week) days)

        timber =
            if total.timber > budget.timber then
                [ TimberOverspent total.timber ]

            else
                []

        money =
            if total.pounds > budget.pounds then
                [ MoneyOverspent total.pounds ]

            else
                []
    in
    List.concat [ roof, window, shelves, books, timber, money ]
