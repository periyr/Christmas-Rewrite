module ChapterFlowTests exposing (suite)

{-| The whole 1950 chapter through Update.update only, starting from a new
game: introduction → present → salvage → repair board → week playback with
the reopening shelf (or the failure consequence) → present, 1973 unlocked.

These drive the real model and actions; they say nothing about visuals.

-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Placement as Placement
import Rules.Repair as Repair
import Rules.Room
import Rules.Salvage as Salvage
import Test exposing (Test, describe, test)
import Timeline
import Update



-- ACTIONS A PLAYER WOULD SEND


send : List Msg -> Model -> Model
send msgs model =
    List.foldl Update.update model msgs


toSalvage : List Msg
toSalvage =
    -- Three intro screens, open the glowing 1950 diary, step into it, skip the trip.
    [ Advance, Advance, Advance, OpenNextDiary, Advance, SkipTravel ]


briefCrates : List ( BookId, Condition )
briefCrates =
    [ ( Recoverable AtlasOfSmallPlaces, Fine )
    , ( Recoverable PocketOfWonders, Fine )
    , ( Recoverable WinterTales, Fine )
    , ( Recoverable BirdsongForBeginners, NeedsRepair )
    , ( Recoverable GardensInWinter, NeedsRepair )
    , ( Recoverable LettersFromTheSea, NeedsRepair )
    , ( Ruined HarbourTales, TooFarGone )
    , ( Ruined MountainPaths, TooFarGone )
    , ( Ruined WinterAlmanac, TooFarGone )
    ]


sortBooks : List ( BookId, Condition ) -> List Msg
sortBooks pairs =
    List.concatMap
        (\( book, crate ) -> [ SalvageMove (SelectItem book), SalvageMove (PlaceSelectedInGroup (Salvage.crateSlots crate)) ])
        pairs


toBoard : List Msg
toBoard =
    toSalvage ++ sortBooks briefCrates ++ [ Advance ]


planWeek : WeekPlan -> List Msg
planWeek week =
    List.concatMap
        (\day -> [ BoardMove (SelectItem (Repair.taskOn day week)), BoardMove (PlaceSelected (OnDay day)) ])
        Repair.days
        ++ List.concatMap
            (\task -> [ BoardMove (SelectItem task), BoardMove (PlaceSelectedInGroup Repair.notThisWeekSlots) ])
            week.notThisWeek


shelveSmallToTall : List Msg
shelveSmallToTall =
    [ BirdsongForBeginners, GardensInWinter, PocketOfWonders, AtlasOfSmallPlaces, LettersFromTheSea, WinterTales ]
        |> List.indexedMap (\i book -> [ ShelfMove (SelectItem book), ShelfMove (PlaceSelected (ShelfPosition (i + 1))) ])
        |> List.concat


atBoard : Model
atBoard =
    send toBoard Update.init


{-| Valid week 2 from the brief: books are shelved on Friday. -}
fridayShelvingWeek : WeekPlan
fridayShelvingWeek =
    { monday = PatchRoof
    , tuesday = ClearRubble
    , wednesday = BuildShelves
    , thursday = ReglazeWindow
    , friday = ShelveBooks
    , notThisWeek = [ PaintSign, BoardUpWindow ]
    }



-- PLAYING THROUGH WHAT FOLLOWS A SUBMISSION


type Seen
    = SawSlide Slide
    | SawShelf
    | SawTear Era
    | SawReturning
    | SawPresent
    | Stuck Phase


{-| Keep pressing Advance (shelving small-to-tall when the shelf appears)
until the present, recording each screen. A loop or a dead end runs out of
fuel and shows up as Stuck.
-}
playToPresent : Int -> Model -> List Seen
playToPresent fuel model =
    if fuel <= 0 then
        [ Stuck model.phase ]

    else
        case model.phase of
            PresentHub ->
                [ SawPresent ]

            ReopeningShelf _ ->
                SawShelf :: playToPresent (fuel - 1) (send (shelveSmallToTall ++ [ Advance ]) model)

            Transition (TearToPresent era _) ->
                -- The tear home plays out on its own frames.
                SawTear era :: playToPresent (fuel - 1) (send (List.repeat 40 (AnimationFrame 50)) model)

            Transition ReturningToPresent ->
                SawReturning :: playToPresent (fuel - 1) (Update.update Advance model)

            Transition (Slideshow era index) ->
                case List.head (List.drop index (Timeline.slides era model.history)) of
                    Just slide ->
                        SawSlide slide :: playToPresent (fuel - 1) (Update.update Advance model)

                    Nothing ->
                        [ Stuck model.phase ]

            other ->
                [ Stuck other ]


boardOf : Model -> Maybe (MainPuzzle (Placement TaskId RepairSlot))
boardOf model =
    case model.phase of
        RepairBoard puzzle ->
            Just puzzle

        _ ->
            Nothing


suite : Test
suite =
    describe "1950 chapter, end to end through Update"
        [ reachingTheBoard
        , afterSuccess
        , afterFailure
        , historyIntegrity
        ]


reachingTheBoard : Test
reachingTheBoard =
    describe "new game to repair board"
        [ test "intro, present, diary, salvage: each screen in order" <|
            \_ ->
                List.foldl (\msg ( m, phases ) -> ( Update.update msg m, phases ++ [ (Update.update msg m).phase ] ))
                    ( Update.init, [] )
                    toSalvage
                    |> Tuple.second
                    |> Expect.equal
                        [ Introduction DiariesFound
                        , Introduction ClockStopped
                        , PresentHub
                        , Transition (OpeningDiary Repairs1950)
                        , Transition (TimeTravel Repairs1950 0)
                        , Salvage Placement.empty
                        ]
        , test "sorting the books and continuing reaches a fresh repair board" <|
            \_ ->
                atBoard
                    |> Expect.equal
                        { history = []
                        , runSeed = Update.init.runSeed
                        , phase = RepairBoard { arrangement = Placement.empty, inspected = [], attempts = NoAttemptUsed }
                        , inspecting = Nothing
                        , notice = Nothing
                        , room = Rules.Room.initialRoom
                        }
        , test "continuing with books still on the table stays in salvage with a notice" <|
            \_ ->
                let
                    partial =
                        send (toSalvage ++ sortBooks (List.take 5 briefCrates)) Update.init
                in
                Update.update Advance partial
                    |> Expect.equal { partial | notice = Just NotSolvedYet }
        , test "continuing with all nine placed but two in the wrong crates stays in salvage" <|
            \_ ->
                let
                    -- Winter Tales and Winter Almanac swap crates; every book is placed.
                    swapWinters ( book, crate ) =
                        if book == Recoverable WinterTales then
                            ( book, TooFarGone )

                        else if book == Ruined WinterAlmanac then
                            ( book, Fine )

                        else
                            ( book, crate )

                    wrong =
                        send (toSalvage ++ sortBooks (List.map swapWinters briefCrates)) Update.init

                    placedCount =
                        case wrong.phase of
                            Salvage placement ->
                                List.length placement.placed

                            _ ->
                                0
                in
                ( placedCount, Update.update Advance wrong )
                    |> Expect.equal ( 9, { wrong | notice = Just NotSolvedYet } )
        , test "unlimited salvage corrections still give the board both attempts" <|
            \_ ->
                let
                    corrections =
                        sortBooks (List.map (\( b, _ ) -> ( b, TooFarGone )) (List.take 3 briefCrates))
                            ++ [ Advance, Advance ]
                            ++ List.concatMap (\( b, _ ) -> [ SalvageMove (SelectItem b), SalvageMove ReturnSelectedToTray ]) (List.take 3 briefCrates)
                            ++ [ Advance ]
                in
                send (toSalvage ++ corrections ++ sortBooks briefCrates ++ [ Advance ]) Update.init
                    |> Expect.equal atBoard
        , test "the next notice-free move clears the warm-up notice" <|
            \_ ->
                send (toSalvage ++ [ Advance, SalvageMove (SelectItem (Ruined HarbourTales)) ]) Update.init
                    |> .notice
                    |> Expect.equal Nothing
        ]


afterSuccess : Test
afterSuccess =
    describe "after a successful week"
        [ test "Thursday shelving: week in order, shelf after Thursday, Friday, Saturday, present" <|
            \_ ->
                atBoard
                    |> send (planWeek Fixtures.validWeek ++ [ Submit ])
                    |> playToPresent 20
                    |> Expect.equal
                        [ SawSlide (WeekdaySlide Monday PatchRoof)
                        , SawSlide (WeekdaySlide Tuesday ClearRubble)
                        , SawSlide (WeekdaySlide Wednesday BuildShelves)
                        , SawSlide (WeekdaySlide Thursday ShelveBooks)
                        , SawShelf
                        , SawSlide (WeekdaySlide Friday ReglazeWindow)
                        , SawSlide ReopeningSaturday
                        , SawTear Repairs1950
                        , SawReturning
                        , SawPresent
                        ]
        , test "Friday shelving: shelf after Friday, then straight to Saturday" <|
            \_ ->
                atBoard
                    |> send (planWeek fridayShelvingWeek ++ [ Submit ])
                    |> playToPresent 20
                    |> Expect.equal
                        [ SawSlide (WeekdaySlide Monday PatchRoof)
                        , SawSlide (WeekdaySlide Tuesday ClearRubble)
                        , SawSlide (WeekdaySlide Wednesday BuildShelves)
                        , SawSlide (WeekdaySlide Thursday ReglazeWindow)
                        , SawSlide (WeekdaySlide Friday ShelveBooks)
                        , SawShelf
                        , SawSlide ReopeningSaturday
                        , SawTear Repairs1950
                        , SawReturning
                        , SawPresent
                        ]
        , test "the present then shows sound premises and unlocks 1973" <|
            \_ ->
                let
                    world =
                        atBoard
                            |> send (planWeek Fixtures.validWeek ++ [ Submit ])
                            |> send (List.repeat 4 Advance ++ shelveSmallToTall ++ List.repeat 4 Advance)
                            |> .history
                            |> Timeline.deriveWorld
                in
                ( world.premises, world.nextDiary, world.scriptVariant )
                    |> Expect.equal ( Established, Just Shadows1973, OriginalScript )
        , test "continuing from an unsorted shelf stays on the shelf with a notice" <|
            \_ ->
                let
                    onShelf =
                        atBoard |> send (planWeek Fixtures.validWeek ++ [ Submit, Advance, Advance, Advance, Advance ])

                    attempt =
                        send [ ShelfMove (SelectItem WinterTales), ShelfMove (PlaceSelected (ShelfPosition 1)), Advance ] onShelf
                in
                ( onShelf.phase == ReopeningShelf Placement.empty, attempt.phase == ReopeningShelf { placed = [ ( WinterTales, ShelfPosition 1 ) ], selected = Nothing }, attempt.notice )
                    |> Expect.equal ( True, True, Just NotSolvedYet )
        ]


afterFailure : Test
afterFailure =
    describe "after a failed week"
        [ test "the consequence is shown, then the present, with no shelf" <|
            \_ ->
                atBoard
                    |> send (planWeek Fixtures.wrongWeek ++ [ Submit, Retry, Submit ])
                    |> playToPresent 20
                    |> Expect.equal
                        [ SawSlide (ConsequenceSlide Repairs1950 (RoofAfterRain Wednesday))
                        , SawTear Repairs1950
                        , SawReturning
                        , SawPresent
                        ]
        , test "the present then shows missing premises and unlocks 1973" <|
            \_ ->
                let
                    world =
                        atBoard
                            |> send (planWeek Fixtures.wrongWeek ++ [ Submit, Retry, Submit, Advance, Advance ])
                            |> .history
                            |> Timeline.deriveWorld
                in
                ( world.premises, world.nextDiary, world.scriptVariant )
                    |> Expect.equal ( Missing, Just Shadows1973, NeighboursRetelling )
        ]


historyIntegrity : Test
historyIntegrity =
    let
        -- Fail the first attempt, fix the week, succeed on the second.
        resolvedOnRetry =
            atBoard
                |> send (planWeek Fixtures.wrongWeek ++ [ Submit, Retry ])
                |> send
                    [ BoardMove (SelectItem PatchRoof)
                    , BoardMove (PlaceSelected (OnDay Monday))
                    , BoardMove (SelectItem ReglazeWindow)
                    , BoardMove (PlaceSelected (OnDay Wednesday))
                    , Submit
                    ]

        recorded =
            resolvedOnRetry.history
    in
    describe "history during and after the shelf"
        [ test "exactly one 1950 record, succeeded on the second attempt" <|
            \_ ->
                List.map (\r -> ( r.era, r.outcome, r.attemptsUsed )) recorded
                    |> Expect.equal [ ( Repairs1950, Succeeded, 2 ) ]
        , test "submits, retries and failed shelf attempts during playback change nothing in history" <|
            \_ ->
                resolvedOnRetry
                    |> send [ Submit, Retry, Advance, Submit ]
                    |> send [ Advance, Advance, Advance, Advance ]
                    |> send [ Submit, Retry, Advance, Advance, ShelfMove (SelectItem WinterTales), ShelfMove (PlaceSelected (ShelfPosition 2)), Advance ]
                    |> .history
                    |> Expect.equal recorded
        , test "back in the present the record is unchanged and nothing was added" <|
            \_ ->
                resolvedOnRetry
                    |> playToPresentModel 20
                    |> Maybe.map .history
                    |> Expect.equal (Just recorded)
        , test "extra Advance and Submit in the present do nothing" <|
            \_ ->
                case playToPresentModel 20 resolvedOnRetry of
                    Just present ->
                        send [ Advance, Submit, Retry ] present |> Expect.equal present

                    Nothing ->
                        Expect.fail "did not reach the present"
        , test "the board has no puzzle state left once the chapter is resolved" <|
            \_ ->
                boardOf resolvedOnRetry |> Expect.equal Nothing
        ]


{-| Same driver as playToPresent, returning the final model. -}
playToPresentModel : Int -> Model -> Maybe Model
playToPresentModel fuel model =
    if fuel <= 0 then
        Nothing

    else
        case model.phase of
            PresentHub ->
                Just model

            ReopeningShelf _ ->
                playToPresentModel (fuel - 1) (send (shelveSmallToTall ++ [ Advance ]) model)

            Transition (TearToPresent _ _) ->
                playToPresentModel (fuel - 1) (Update.update SkipTravel model)

            Transition _ ->
                playToPresentModel (fuel - 1) (Update.update Advance model)

            _ ->
                Nothing
