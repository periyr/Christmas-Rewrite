module RepairTests exposing (suite)

{-| The 1950 repair board: validator, structural completeness, resources. -}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Repair as Repair
import Test exposing (Test, describe, test)



-- BUILDING WEEKS


{-| A week from five tasks in Monday–Friday order; the rest are deferred. -}
week : List TaskId -> WeekPlan
week scheduled =
    case scheduled of
        [ mon, tue, wed, thu, fri ] ->
            { monday = mon
            , tuesday = tue
            , wednesday = wed
            , thursday = thu
            , friday = fri
            , notThisWeek = List.filter (\t -> not (List.member t scheduled)) Repair.allTasks
            }

        _ ->
            -- Only used with five tasks below; an obviously broken week if misused.
            { monday = PaintSign, tuesday = PaintSign, wednesday = PaintSign, thursday = PaintSign, friday = PaintSign, notThisWeek = [] }


schedule : WeekPlan -> List TaskId
schedule plan =
    List.map (\day -> Repair.taskOn day plan) Repair.days


{-| Every ordered choice of `k` distinct items. -}
orderedSelections : Int -> List a -> List (List a)
orderedSelections k items =
    if k == 0 then
        [ [] ]

    else
        List.concatMap
            (\item -> List.map ((::) item) (orderedSelections (k - 1) (List.filter ((/=) item) items)))
            items


allWeeks : List WeekPlan
allWeeks =
    List.map week (orderedSelections 5 Repair.allTasks)


acceptedSchedules : List (List TaskId)
acceptedSchedules =
    allWeeks
        |> List.filter (\plan -> List.isEmpty (Repair.validate plan))
        |> List.map schedule


{-| The six valid weeks listed in the brief, section 4B. -}
briefSchedules : List (List TaskId)
briefSchedules =
    [ [ PatchRoof, ClearRubble, BuildShelves, ShelveBooks, ReglazeWindow ]
    , [ PatchRoof, ClearRubble, BuildShelves, ReglazeWindow, ShelveBooks ]
    , [ PatchRoof, ClearRubble, ReglazeWindow, BuildShelves, ShelveBooks ]
    , [ ClearRubble, PatchRoof, BuildShelves, ShelveBooks, ReglazeWindow ]
    , [ ClearRubble, PatchRoof, BuildShelves, ReglazeWindow, ShelveBooks ]
    , [ ClearRubble, PatchRoof, ReglazeWindow, BuildShelves, ShelveBooks ]
    ]


{-| True when a violation describes the plan it came from accurately,
i.e. never contradicts where the cards actually are.
-}
describesPlan : WeekPlan -> Violation -> Bool
describesPlan plan violation =
    let
        on task =
            Repair.dayOf task plan

        deferred task =
            on task == Nothing

        dayNumber day =
            Repair.days
                |> List.indexedMap Tuple.pair
                |> List.filter (\( _, d ) -> d == day)
                |> List.map Tuple.first
                |> List.sum

        isBefore first second =
            case ( on first, on second ) of
                ( Just a, Just b ) ->
                    dayNumber a < dayNumber b

                _ ->
                    False
    in
    case violation of
        RoofAfterRain day ->
            on PatchRoof == Just day && List.member day [ Wednesday, Thursday, Friday ]

        GlassNotYetDelivered day ->
            on ReglazeWindow == Just day && List.member day [ Monday, Tuesday ]

        MustComeBefore first second ->
            -- The dependent task is scheduled, the prerequisite is not earlier,
            -- and it is not about shelves already reported as missing.
            not (deferred second)
                && not (isBefore first second)
                && not (deferred first && first == BuildShelves)

        TimberOverspent n ->
            n > Repair.budget.timber

        MoneyOverspent n ->
            n > Repair.budget.pounds

        GoalMissing WatertightRoof ->
            deferred PatchRoof

        GoalMissing SealedWindow ->
            deferred ReglazeWindow && deferred BoardUpWindow

        GoalMissing UsableShelves ->
            deferred BuildShelves

        GoalMissing AllBooksShelved ->
            deferred ShelveBooks

        _ ->
            False



-- TESTS


suite : Test
suite =
    describe "Rules.Repair"
        [ enumeration
        , rules
        , completeness
        , resources
        ]


enumeration : Test
enumeration =
    describe "all complete schedules"
        [ test "there are exactly 2,520 complete schedules" <|
            \_ ->
                List.length allWeeks |> Expect.equal 2520
        , test "exactly six are accepted" <|
            \_ ->
                List.length acceptedSchedules |> Expect.equal 6
        , test "every schedule from the brief is accepted" <|
            \_ ->
                List.filter (\s -> not (List.member s acceptedSchedules)) briefSchedules
                    |> Expect.equal []
        , test "nothing outside the brief's six is accepted" <|
            \_ ->
                List.filter (\s -> not (List.member s briefSchedules)) acceptedSchedules
                    |> Expect.equal []
        , test "every violation of every schedule matches where the cards actually are" <|
            \_ ->
                allWeeks
                    |> List.filter (\plan -> not (List.all (describesPlan plan) (Repair.validate plan)))
                    |> List.map schedule
                    |> Expect.equal []
        , test "no schedule reports the same violation twice" <|
            \_ ->
                allWeeks
                    |> List.filter
                        (\plan ->
                            let
                                vs =
                                    Repair.validate plan
                            in
                            List.any (\v -> List.length (List.filter ((==) v) vs) > 1) vs
                        )
                    |> List.length
                    |> Expect.equal 0
        ]


rules : Test
rules =
    describe "individual rules"
        [ test "Wednesday is too late for the roof" <|
            \_ ->
                Repair.validate (week [ ClearRubble, BuildShelves, PatchRoof, ShelveBooks, ReglazeWindow ])
                    |> Expect.equal [ RoofAfterRain Wednesday ]
        , test "Friday is too late for the roof" <|
            \_ ->
                Repair.validate (week [ ClearRubble, BuildShelves, ShelveBooks, ReglazeWindow, PatchRoof ])
                    |> Expect.equal [ RoofAfterRain Friday ]
        , test "glazing before Wednesday is invalid" <|
            \_ ->
                Repair.validate (week [ PatchRoof, ReglazeWindow, ClearRubble, BuildShelves, ShelveBooks ])
                    |> Expect.equal [ GlassNotYetDelivered Tuesday ]
        , test "rubble must be cleared before building shelves" <|
            \_ ->
                Repair.validate (week [ PatchRoof, BuildShelves, ClearRubble, ShelveBooks, ReglazeWindow ])
                    |> Expect.equal [ MustComeBefore ClearRubble BuildShelves ]
        , test "shelves must be built before shelving the books" <|
            \_ ->
                Repair.validate (week [ PatchRoof, ClearRubble, ShelveBooks, BuildShelves, ReglazeWindow ])
                    |> Expect.equal [ MustComeBefore BuildShelves ShelveBooks ]
        , test "deferring rubble breaks the shelves prerequisite" <|
            \_ ->
                Repair.validate (week [ PatchRoof, BuildShelves, ShelveBooks, ReglazeWindow, BoardUpWindow ])
                    |> Expect.equal [ MustComeBefore ClearRubble BuildShelves, TimberOverspent 5 ]
        , test "boarding instead of glazing overspends timber" <|
            \_ ->
                Repair.validate (week [ PatchRoof, ClearRubble, BuildShelves, ShelveBooks, BoardUpWindow ])
                    |> Expect.equal [ TimberOverspent 5 ]
        , test "glazing plus the sign overspends money" <|
            \_ ->
                Repair.validate (week [ ClearRubble, BuildShelves, ReglazeWindow, ShelveBooks, PaintSign ])
                    |> Expect.equal [ GoalMissing WatertightRoof, MoneyOverspent 12 ]
        , test "a deferred roof is a missing goal, not a late roof" <|
            \_ ->
                Repair.validate (week [ ClearRubble, BuildShelves, ShelveBooks, PaintSign, BoardUpWindow ])
                    |> Expect.equal [ GoalMissing WatertightRoof ]
        , test "neither glazing nor boarding leaves the window unsealed" <|
            \_ ->
                Repair.validate (week [ PatchRoof, ClearRubble, BuildShelves, ShelveBooks, PaintSign ])
                    |> Expect.equal [ GoalMissing SealedWindow, TimberOverspent 5 ]
        , test "deferred shelves are reported once; books are not blamed for them" <|
            \_ ->
                Repair.validate (week [ PatchRoof, ClearRubble, ReglazeWindow, ShelveBooks, BoardUpWindow ])
                    |> Expect.equal [ GoalMissing UsableShelves ]
        , test "deferred books are a missing goal" <|
            \_ ->
                Repair.validate (week [ PatchRoof, ClearRubble, BuildShelves, ReglazeWindow, BoardUpWindow ])
                    |> Expect.equal [ GoalMissing AllBooksShelved, TimberOverspent 5 ]
        , test "all broken rules are reported together, most consequential first" <|
            \_ ->
                Repair.validate (week [ PaintSign, ReglazeWindow, BuildShelves, PatchRoof, ClearRubble ])
                    |> Expect.equal
                        [ RoofAfterRain Thursday
                        , GlassNotYetDelivered Tuesday
                        , MustComeBefore ClearRubble BuildShelves
                        , GoalMissing AllBooksShelved
                        , TimberOverspent 5
                        , MoneyOverspent 12
                        ]
        , test "the fixture's wrong week: late roof, unsealed window, too much timber" <|
            \_ ->
                Repair.validate Fixtures.wrongWeek
                    |> Expect.equal [ RoofAfterRain Wednesday, GoalMissing SealedWindow, TimberOverspent 5 ]
        , test "the fixture's valid week has no violations" <|
            \_ ->
                Repair.validate Fixtures.validWeek |> Expect.equal []
        ]


completeness : Test
completeness =
    let
        validBoard =
            Fixtures.boardFor Fixtures.validWeek

        replaceSlot from to placement =
            { placement
                | placed =
                    List.map
                        (\( t, s ) ->
                            if s == from then
                                ( t, to )

                            else
                                ( t, s )
                        )
                        placement.placed
            }
    in
    describe "structural completeness (never correctness)"
        [ test "a fully assigned board gives its week" <|
            \_ ->
                Repair.complete validBoard |> Expect.equal (Just Fixtures.validWeek)
        , test "a complete but wrong board is still complete" <|
            \_ ->
                Repair.complete (Fixtures.boardFor Fixtures.wrongWeek) |> Expect.equal (Just Fixtures.wrongWeek)
        , test "an empty board is incomplete" <|
            \_ ->
                Repair.complete { placed = [], selected = Nothing } |> Expect.equal Nothing
        , test "a card left in the tray is incomplete" <|
            \_ ->
                Repair.complete { validBoard | placed = List.filter (\( t, _ ) -> t /= BoardUpWindow) validBoard.placed }
                    |> Expect.equal Nothing
        , test "five days filled but nothing deferred is incomplete" <|
            \_ ->
                Repair.complete { validBoard | placed = List.filter (\( _, s ) -> not (List.member s Repair.notThisWeekSlots)) validBoard.placed }
                    |> Expect.equal Nothing
        , test "a card placed twice is incomplete" <|
            \_ ->
                Repair.complete
                    { validBoard
                        | placed =
                            List.map
                                (\( t, s ) ->
                                    if t == BoardUpWindow then
                                        ( PatchRoof, s )

                                    else
                                        ( t, s )
                                )
                                validBoard.placed
                    }
                    |> Expect.equal Nothing
        , test "two cards in one slot is incomplete" <|
            \_ ->
                Repair.complete (replaceSlot (NotThisWeek 2) (OnDay Monday) validBoard) |> Expect.equal Nothing
        , test "an unknown slot is incomplete" <|
            \_ ->
                Repair.complete (replaceSlot (NotThisWeek 2) (NotThisWeek 3) validBoard) |> Expect.equal Nothing
        ]


resources : Test
resources =
    describe "spent and remaining"
        [ test "deferred cards cost nothing" <|
            \_ ->
                Repair.spent
                    { placed = [ ( PaintSign, NotThisWeek 1 ), ( BoardUpWindow, NotThisWeek 2 ), ( PatchRoof, OnDay Monday ) ]
                    , selected = Nothing
                    }
                    |> Expect.equal { timber = 2, pounds = 0 }
        , test "cards in the tray cost nothing" <|
            \_ ->
                Repair.spent { placed = [], selected = Just PaintSign } |> Expect.equal { timber = 0, pounds = 0 }
        , test "every valid week uses all timber and leaves £4" <|
            \_ ->
                allWeeks
                    |> List.filter (\plan -> List.isEmpty (Repair.validate plan))
                    |> List.map (Fixtures.boardFor >> Repair.remaining)
                    |> Expect.equal (List.repeat 6 { timber = 0, pounds = 4 })
        , test "overspending shows as negative remaining, not an error" <|
            \_ ->
                Repair.remaining (Fixtures.boardFor Fixtures.wrongWeek)
                    |> Expect.equal { timber = -1, pounds = 4 }
        ]
