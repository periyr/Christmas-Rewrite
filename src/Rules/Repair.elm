module Rules.Repair exposing
    ( accepts, allTasks, budget, complete, cost, days, notThisWeekSlots, remaining, slots, spent, taskOn
    , validate
    )

{-| 1950 repair planning board: rule data, resource arithmetic, completeness.

The costs and budget here are the single source of truth for the numbers
shown on cards and in the spent/remaining display.

-}

import Domain exposing (Day(..), Placement, RepairSlot(..), Resources, TaskId(..), Violation, WeekPlan)
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
                        Just (cost task)

                    NotThisWeek _ ->
                        Nothing
            )
        |> List.foldl (\c acc -> { timber = acc.timber + c.timber, pounds = acc.pounds + c.pounds }) { timber = 0, pounds = 0 }


{-| Budget minus spent. Negative when overspent; no judgement attached. -}
remaining : Placement TaskId RepairSlot -> Resources
remaining placement =
    let
        s =
            spent placement
    in
    { timber = budget.timber - s.timber, pounds = budget.pounds - s.pounds }


{-| A WeekPlan once every card is assigned (five days plus two set aside). -}
complete : Placement TaskId RepairSlot -> Maybe WeekPlan
complete placement =
    let
        at slot =
            Placement.itemIn slot placement
    in
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


{-| NOT IMPLEMENTED YET — next Person A task.
Must accept exactly the six valid weeks in the brief (section 4B) and
report every broken rule otherwise. Calling it before then crashes on purpose.
-}
validate : WeekPlan -> List Violation
validate _ =
    Debug.todo "Rules.Repair.validate is not implemented yet (next Person A task)"
