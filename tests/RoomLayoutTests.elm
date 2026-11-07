module RoomLayoutTests exposing (suite)

{-| The shared room layout (contract v1.3): every hotspot is reachable, the
ones usable together never overlap, and only room phases are walkable.
-}

import Domain exposing (..)
import Expect
import Fixtures
import Rules.Placement as Placement
import Rules.Room as Room
import Test exposing (Test, describe, test)


roomPhases : List ( String, Phase )
roomPhases =
    [ ( "introduction (packing up)", Introduction PackingUp )
    , ( "present hub", PresentHub )
    , ( "salvage", Salvage Placement.empty )
    , ( "repair board", Fixtures.repairBoardInProgress.phase )
    , ( "reopening shelf", ReopeningShelf Placement.empty )
    , ( "shadow puzzle", ShadowPuzzle { arrangement = Placement.empty, inspected = [], attempts = NoAttemptUsed } )
    , ( "book mystery", BookMystery { arrangement = Nothing, inspected = [], attempts = NoAttemptUsed } )
    ]


nonRoomPhases : List ( String, Phase )
nonRoomPhases =
    [ ( "diaries found", Introduction DiariesFound )
    , ( "clock stopped", Introduction ClockStopped )
    , ( "opening a diary", Transition (OpeningDiary Repairs1950) )
    , ( "slideshow", Transition (Slideshow Repairs1950 0) )
    , ( "returning", Transition ReturningToPresent )
    , ( "ending", Ending )
    ]


withPhase : Phase -> Model
withPhase phase =
    let
        model =
            Fixtures.initialModel
    in
    { model | phase = phase }


standingAt : Float -> Model -> Model
standingAt x model =
    let
        room =
            model.room

        player =
            room.player
    in
    { model | room = { room | player = { player | x = x } } }


gaps : List Float -> List Float
gaps xs =
    List.map2 (-) (List.drop 1 xs) xs


suite : Test
suite =
    describe "Room layout"
        [ describe "coordinates"
            [ test "the room is 1280 × 720 with the floor at 650 and bounds 72..1208" <|
                \_ ->
                    ( ( Room.width, Room.height, Room.floorY ), ( Room.minX, Room.maxX ) )
                        |> Expect.equal ( ( 1280, 720, 650 ), ( 72, 1208 ) )
            , test "the player starts at x = 160, facing right, standing still" <|
                \_ ->
                    Fixtures.initialModel.room
                        |> Expect.equal
                            { player = { x = 160, facing = FacingRight, walking = False, held = [], target = Nothing }
                            , panelOpen = False
                            }
            , test "every usable hotspot can be reached inside the bounds" <|
                \_ ->
                    roomPhases
                        |> List.concatMap (\( _, phase ) -> Room.hotspots phase)
                        |> List.filter (\spot -> (Room.position spot).x < Room.minX || (Room.position spot).x > Room.maxX)
                        |> Expect.equal []
            , test "every hotspot is drawn inside the room" <|
                \_ ->
                    roomPhases
                        |> List.concatMap (\( _, phase ) -> Room.hotspots phase)
                        |> List.filter
                            (\spot ->
                                let
                                    p =
                                        Room.position spot
                                in
                                p.x < 0 || p.x > Room.width || p.y < 0 || p.y > Room.height
                            )
                        |> Expect.equal []
            ]
        , describe "hotspots per phase" <|
            List.map
                (\( name, phase ) ->
                    test (name ++ ": listed left to right, more than twice the interaction distance apart") <|
                        \_ ->
                            Room.hotspots phase
                                |> List.map (\spot -> (Room.position spot).x)
                                |> gaps
                                |> List.filter (\gap -> gap <= 2 * Room.interactionDistance)
                                |> Expect.equal []
                )
                roomPhases
                ++ [ test "each room phase with a puzzle panel has exactly one station that opens it" <|
                        \_ ->
                            roomPhases
                                |> List.map
                                    (\( name, phase ) ->
                                        ( name
                                        , Room.hasPanel phase
                                        , Room.hotspots phase
                                            |> List.filter (\spot -> List.member spot [ CratesSpot, BoardSpot, ShelfSpot, StageSpot, BookTableSpot ])
                                            |> List.length
                                        )
                                    )
                                |> Expect.equal
                                    [ ( "introduction (packing up)", False, 0 )
                                    , ( "present hub", False, 0 )
                                    , ( "salvage", True, 1 )
                                    , ( "repair board", True, 1 )
                                    , ( "reopening shelf", True, 1 )
                                    , ( "shadow puzzle", True, 1 )
                                    , ( "book mystery", True, 1 )
                                    ]
                   , test "1950 stations follow the chapter: crates, then board, then shelf" <|
                        \_ ->
                            [ Room.hotspots (Salvage Placement.empty)
                            , Room.hotspots Fixtures.repairBoardInProgress.phase
                            , Room.hotspots (ReopeningShelf Placement.empty)
                            ]
                                |> List.map (List.filter (\spot -> List.member spot [ CratesSpot, BoardSpot, ShelfSpot ]))
                                |> Expect.equal [ [ CratesSpot ], [ BoardSpot ], [ ShelfSpot ] ]
                   , test "the repair clues are in the room while the board is the station" <|
                        \_ ->
                            Room.hotspots Fixtures.repairBoardInProgress.phase
                                |> Expect.equal
                                    [ ClueSpot GlassDeliverySlip, ClueSpot BudgetAllocation, ClueSpot WalterDiaryPage, BoardSpot, ClueSpot RubbleAndShelvesNote ]
                   ]
        , describe "where the player can walk" <|
            List.map
                (\( name, phase ) ->
                    test ("walkable: " ++ name) <|
                        \_ -> Room.canWalk (withPhase phase) |> Expect.equal True
                )
                roomPhases
                ++ List.map
                    (\( name, phase ) ->
                        test ("not walkable: " ++ name) <|
                            \_ -> Room.canWalk (withPhase phase) |> Expect.equal False
                    )
                    nonRoomPhases
                ++ [ test "not walkable with a panel open, a clue open, a notice, or first-attempt feedback" <|
                        \_ ->
                            let
                                board =
                                    Fixtures.repairBoardInProgress

                                room =
                                    board.room
                            in
                            [ { board | room = { room | panelOpen = True } }
                            , { board | inspecting = Just GlassDeliverySlip }
                            , { board | notice = Just TargetFull }
                            , Fixtures.repairFirstAttemptFailed
                            ]
                                |> List.map Room.canWalk
                                |> Expect.equal [ False, False, False, False ]
                   ]
        , describe "nearby (what E would use)"
            [ test "the closest usable hotspot within reach" <|
                \_ ->
                    Fixtures.repairBoardInProgress
                        |> standingAt (640 - Room.interactionDistance)
                        |> Room.nearby
                        |> Expect.equal (Just BoardSpot)
            , test "nothing just out of reach" <|
                \_ ->
                    Fixtures.repairBoardInProgress
                        |> standingAt (640 - Room.interactionDistance - 1)
                        |> Room.nearby
                        |> Expect.equal Nothing
            , test "only hotspots of the current phase: no shelf during the repair board" <|
                \_ ->
                    Fixtures.repairBoardInProgress
                        |> standingAt (Room.position ShelfSpot).x
                        |> Room.nearby
                        |> Expect.equal Nothing
            , test "nothing while a panel is open" <|
                \_ ->
                    let
                        board =
                            Fixtures.repairBoardInProgress |> standingAt 640

                        room =
                            board.room
                    in
                    { board | room = { room | panelOpen = True } }
                        |> Room.nearby
                        |> Expect.equal Nothing
            ]
        ]
