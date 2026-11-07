module MovementTests exposing (suite)

{-| The walking player (contract v1.3), through Update.update only: bounds,
stopping, frame-rate independence, E and click-to-approach, panels, pausing,
clearing held keys, and that walking never touches history or attempts.
-}

import Domain exposing (..)
import Expect
import Fixtures
import Fuzz exposing (Fuzzer)
import Rules.Placement as Placement
import Rules.Repair as Repair
import Rules.Room as Room
import Rules.Salvage as Salvage
import Test exposing (Test, describe, fuzz, test)
import Timeline
import Update



-- HELPERS


send : List Msg -> Model -> Model
send msgs model =
    List.foldl Update.update model msgs


{-| `n` animation frames of `ms` milliseconds each. -}
frames : Int -> Float -> List Msg
frames n ms =
    List.repeat n (AnimationFrame ms)


{-| Click a hotspot and keep the frames coming until long after arrival
(frames are ignored once the player stops).
-}
walkTo : Hotspot -> List Msg
walkTo hotspot =
    ApproachHotspot hotspot :: frames 400 16


standingAt : Float -> Model -> Model
standingAt x model =
    let
        room =
            model.room

        player =
            room.player
    in
    { model | room = { room | player = { player | x = x } } }


withPanelOpen : Model -> Model
withPanelOpen model =
    let
        room =
            model.room
    in
    { model | room = { room | panelOpen = True } }


playerOf : Model -> Player
playerOf model =
    model.room.player


{-| The x positions after each message, to check for overshooting. -}
trail : List Msg -> Model -> List Float
trail msgs model =
    msgs
        |> List.foldl (\msg ( m, xs ) -> let next = Update.update msg m in ( next, next.room.player.x :: xs )) ( model, [] )
        |> Tuple.second
        |> List.reverse


salvageRoom : Model
salvageRoom =
    send [ Advance, SkipTravel ] { initModel | phase = Transition (OpeningDiary Repairs1950) }


initModel : Model
initModel =
    Fixtures.initialModel


boardRoom : Model
boardRoom =
    Fixtures.repairBoardInProgress


boardArrangement : Model -> Maybe (MainPuzzle (Placement TaskId RepairSlot))
boardArrangement model =
    case model.phase of
        RepairBoard puzzle ->
            Just puzzle

        _ ->
            Nothing


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


sortBooks : List Msg
sortBooks =
    List.concatMap
        (\( book, crate ) -> [ SalvageMove (SelectItem book), SalvageMove (PlaceSelectedInGroup (Salvage.crateSlots crate)) ])
        briefCrates


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


wrongWeekViolations : List Violation
wrongWeekViolations =
    Repair.validate Fixtures.wrongWeek


allHotspots : List Hotspot
allHotspots =
    [ ClueSpot ClosureNotice
    , ClueSpot FamilyPhotograph
    , ClueSpot (HubProp OrderDesk)
    , ClueSpot (HubProp CommunityWall)
    , ClueSpot (HubProp RoofAndShelves)
    , ClueSpot GlassDeliverySlip
    , ClueSpot BudgetAllocation
    , ClueSpot WalterDiaryPage
    , ClueSpot RubbleAndShelvesNote
    , ClueSpot ShadowScript
    , ClueSpot StageSketch
    , ClueSpot CutoutBox
    , ClueSpot RuthsEmail
    , ClueSpot RememberedSentence
    , ClueSpot InscriptionClue
    , BoxSpot
    , DiarySpot
    , CratesSpot
    , BoardSpot
    , ShelfSpot
    , StageSpot
    , BookTableSpot
    ]


{-| Only room messages: what a player can do by walking and pressing E. -}
roomMsg : Fuzzer Msg
roomMsg =
    Fuzz.oneOf
        [ Fuzz.map WalkKeyDown (Fuzz.oneOfValues [ WalkLeft, WalkRight ])
        , Fuzz.map WalkKeyUp (Fuzz.oneOfValues [ WalkLeft, WalkRight ])
        , Fuzz.map AnimationFrame (Fuzz.floatRange -20 2000)
        , Fuzz.constant InteractNearby
        , Fuzz.map ApproachHotspot (Fuzz.oneOfValues allHotspots)
        , Fuzz.constant ClosePanel
        , Fuzz.map PageVisibilityChanged Fuzz.bool
        ]


suite : Test
suite =
    describe "Walking player"
        [ walking
        , interacting
        , pausing
        , clearing
        , panels
        , unchanged
        , keyboard
        , walkableChapter
        , fixtures
        ]


fixtures : Test
fixtures =
    describe "room fixtures"
        [ test "salvageWalking arrives at the crates and opens the salvage panel" <|
            \_ ->
                send (frames 100 16) Fixtures.salvageWalking
                    |> .room
                    |> (\room -> ( room.player.x, room.panelOpen ))
                    |> Expect.equal ( 400, True )
        , test "repairBoardPanelOpen is the board fixture with its panel open and walking paused" <|
            \_ ->
                ( Fixtures.repairBoardPanelOpen.phase == Fixtures.repairBoardInProgress.phase
                , Room.canWalk Fixtures.repairBoardPanelOpen
                , Fixtures.repairBoardPanelOpen.room.panelOpen
                )
                    |> Expect.equal ( True, False, True )
        ]



-- WALKING


walking : Test
walking =
    describe "walking"
        [ test "holding D for one second walks 300 px to the right, facing right" <|
            \_ ->
                send (WalkKeyDown WalkRight :: frames 60 (1000 / 60)) boardRoom
                    |> playerOf
                    |> (\p -> ( round p.x, p.facing, p.walking ))
                    |> Expect.equal ( 460, FacingRight, True )
        , test "the distance depends on time, not on the frame rate (30, 60 and 144 fps)" <|
            \_ ->
                [ 30, 60, 144 ]
                    |> List.map (\fps -> send (WalkKeyDown WalkRight :: frames fps (1000 / toFloat fps)) boardRoom |> playerOf |> .x)
                    |> List.map (\x -> abs (x - 460) < 0.0001)
                    |> Expect.equal [ True, True, True ]
        , test "a huge frame delta (a stalled tab) moves only 50 ms worth" <|
            \_ ->
                send [ WalkKeyDown WalkRight, AnimationFrame 5000 ] boardRoom
                    |> playerOf
                    |> .x
                    |> Expect.within (Expect.Absolute 0.0001) (160 + 15)
        , test "a negative frame delta does not move the player" <|
            \_ ->
                send [ WalkKeyDown WalkRight, AnimationFrame -40 ] boardRoom
                    |> playerOf
                    |> .x
                    |> Expect.equal 160
        , test "holding A stops exactly at the left bound and stops walking there" <|
            \_ ->
                send (WalkKeyDown WalkLeft :: frames 200 16) boardRoom
                    |> playerOf
                    |> (\p -> ( p.x, p.facing, p.walking ))
                    |> Expect.equal ( 72, FacingLeft, False )
        , test "holding D stops exactly at the right bound" <|
            \_ ->
                send (WalkKeyDown WalkRight :: frames 400 16) boardRoom
                    |> playerOf
                    |> (\p -> ( p.x, p.walking ))
                    |> Expect.equal ( 1208, False )
        , test "the player never leaves the bounds" <|
            \_ ->
                trail (WalkKeyDown WalkLeft :: frames 100 50 ++ [ WalkKeyUp WalkLeft, WalkKeyDown WalkRight ] ++ frames 300 50) boardRoom
                    |> List.filter (\x -> x < Room.minX || x > Room.maxX)
                    |> Expect.equal []
        , test "releasing the key stops the player at once, and later frames do nothing" <|
            \_ ->
                let
                    released =
                        send (WalkKeyDown WalkRight :: frames 10 16 ++ [ WalkKeyUp WalkRight ]) boardRoom
                in
                ( released.room.player.walking, send (frames 30 16) released == released )
                    |> Expect.equal ( False, True )
        , test "the most recent key wins; releasing it hands back to the other" <|
            \_ ->
                let
                    bothHeld =
                        send ([ WalkKeyDown WalkRight, WalkKeyDown WalkLeft ] ++ frames 10 20) (boardRoom |> standingAt 600)

                    leftReleased =
                        send (WalkKeyUp WalkLeft :: frames 10 20) bothHeld
                in
                ( ( round bothHeld.room.player.x, bothHeld.room.player.facing )
                , ( round leftReleased.room.player.x, leftReleased.room.player.facing )
                )
                    |> Expect.equal ( ( 540, FacingLeft ), ( 600, FacingRight ) )
        , test "a key faces the player that way even at the wall" <|
            \_ ->
                send [ WalkKeyDown WalkLeft, AnimationFrame 16 ] (boardRoom |> standingAt Room.minX)
                    |> playerOf
                    |> (\p -> ( p.x, p.facing, p.walking ))
                    |> Expect.equal ( 72, FacingLeft, False )
        ]



-- INTERACTING


interacting : Test
interacting =
    describe "using hotspots"
        [ test "E near the crates opens the salvage panel and stops the player" <|
            \_ ->
                let
                    after =
                        send [ WalkKeyDown WalkRight, InteractNearby ] (salvageRoom |> standingAt 380)
                in
                ( after.room.panelOpen, after.room.player.held, after.room.player.walking )
                    |> Expect.equal ( True, [], False )
        , test "E with nothing in reach does nothing" <|
            \_ ->
                send [ InteractNearby ] (salvageRoom |> standingAt 160)
                    |> Expect.equal (salvageRoom |> standingAt 160)
        , test "clicking the board walks there, stops exactly on it and opens the panel" <|
            \_ ->
                let
                    after =
                        send (walkTo BoardSpot) boardRoom
                in
                ( ( after.room.player.x, after.room.panelOpen ), ( after.room.player.target, after.room.player.walking ) )
                    |> Expect.equal ( ( 640, True ), ( Nothing, False ) )
        , test "while walking to a clicked hotspot, nothing opens yet" <|
            \_ ->
                send (ApproachHotspot BoardSpot :: frames 5 16) boardRoom
                    |> .room
                    |> (\room -> ( room.panelOpen, room.player.target, room.player.walking ))
                    |> Expect.equal ( False, Just BoardSpot, True )
        , test "the walk never overshoots, even with the largest frames" <|
            \_ ->
                trail (ApproachHotspot BoardSpot :: frames 100 50) (boardRoom |> standingAt 161)
                    |> List.filter (\x -> x > 640)
                    |> Expect.equal []
        , test "the last large step lands exactly on the hotspot" <|
            \_ ->
                send (ApproachHotspot BoardSpot :: frames 100 50) (boardRoom |> standingAt 161)
                    |> playerOf
                    |> .x
                    |> Expect.equal 640
        , test "walking left to a hotspot faces left" <|
            \_ ->
                send (ApproachHotspot (ClueSpot GlassDeliverySlip) :: frames 3 16) (boardRoom |> standingAt 900)
                    |> playerOf
                    |> .facing
                    |> Expect.equal FacingLeft
        , test "clicking a hotspot already in reach uses it at once, without walking" <|
            \_ ->
                send [ ApproachHotspot BoardSpot ] (boardRoom |> standingAt 600)
                    |> .room
                    |> (\room -> ( room.panelOpen, room.player.x, room.player.facing ))
                    |> Expect.equal ( True, 600, FacingRight )
        , test "a clue in the room opens that clue and counts as inspected" <|
            \_ ->
                let
                    after =
                        send (walkTo (ClueSpot GlassDeliverySlip)) (Fixtures.repairBoard Placement.empty NoAttemptUsed |> clearInspected)
                in
                ( after.inspecting, Maybe.map .inspected (boardArrangement after) )
                    |> Expect.equal ( Just GlassDeliverySlip, Just [ GlassDeliverySlip ] )
        , test "hotspots of other phases are ignored: no board or shelf during salvage" <|
            \_ ->
                send [ ApproachHotspot BoardSpot, ApproachHotspot ShelfSpot ] salvageRoom
                    |> Expect.equal salvageRoom
        , test "a walk key cancels the walk to a clicked hotspot" <|
            \_ ->
                let
                    after =
                        send (ApproachHotspot BoardSpot :: frames 10 16 ++ [ WalkKeyDown WalkLeft ] ++ frames 10 16 ++ [ WalkKeyUp WalkLeft ] ++ frames 200 16) boardRoom
                in
                ( after.room.panelOpen, after.room.player.target, after.room.player.x < 640 )
                    |> Expect.equal ( False, Nothing, True )
        , test "introduction: the box beneath the counter is the same as Advance" <|
            \_ ->
                send (walkTo BoxSpot) initModel
                    |> .phase
                    |> Expect.equal (Introduction DiariesFound)
        , test "present: E at the counter opens the glowing 1950 diary" <|
            \_ ->
                send [ InteractNearby ] ({ initModel | phase = PresentHub } |> standingAt 430)
                    |> .phase
                    |> Expect.equal (Transition (OpeningDiary Repairs1950))
        ]


clearInspected : Model -> Model
clearInspected model =
    case model.phase of
        RepairBoard puzzle ->
            { model | phase = RepairBoard { puzzle | inspected = [] } }

        _ ->
            model



-- PAUSING


pausing : Test
pausing =
    describe "walking pauses during panels, clues, feedback and transitions"
        [ test "with a panel open, keys, E, clicks and frames change nothing" <|
            \_ ->
                let
                    open =
                        withPanelOpen (boardRoom |> standingAt 600)
                in
                send [ WalkKeyDown WalkRight, AnimationFrame 16, InteractNearby, ApproachHotspot (ClueSpot WalterDiaryPage), AnimationFrame 16 ] open
                    |> Expect.equal open
        , test "with a clue open, the player does not walk" <|
            \_ ->
                let
                    reading =
                        send [ InteractNearby ] (boardRoom |> standingAt 430)
                in
                send (WalkKeyDown WalkRight :: frames 20 16) reading
                    |> playerOf
                    |> .x
                    |> Expect.equal 430
        , test "after closing the clue, walking works again" <|
            \_ ->
                send ([ InteractNearby, CloseInspection, WalkKeyDown WalkRight ] ++ frames 20 16) (boardRoom |> standingAt 430)
                    |> playerOf
                    |> .x
                    |> (\x -> x > 430)
                    |> Expect.equal True
        , test "during the week slideshow, keys are not even held" <|
            \_ ->
                send [ Submit, WalkKeyDown WalkRight, AnimationFrame 16 ] Fixtures.repairBoardReady
                    |> playerOf
                    |> (\p -> ( p.held, p.x ))
                    |> Expect.equal ( [], 160 )
        , test "with a notice showing, walking is paused" <|
            \_ ->
                let
                    noticed =
                        { boardRoom | notice = Just TargetFull }
                in
                send (WalkKeyDown WalkRight :: frames 5 16) noticed
                    |> Expect.equal noticed
        , test "first-attempt feedback cannot be closed away; after Retry the panel closes" <|
            \_ ->
                let
                    feedback =
                        withPanelOpen Fixtures.repairFirstAttemptFailed
                in
                ( send [ ClosePanel ] feedback |> .room |> .panelOpen
                , send [ Retry, ClosePanel ] feedback |> .room |> .panelOpen
                )
                    |> Expect.equal ( True, False )
        , test "narration screens of the introduction are not walkable" <|
            \_ ->
                let
                    narration =
                        { initModel | phase = Introduction DiariesFound }
                in
                send (WalkKeyDown WalkRight :: frames 5 16) narration
                    |> Expect.equal narration
        ]



-- CLEARING HELD KEYS AND TARGETS


clearing : Test
clearing =
    describe "held keys and walking targets are cleared"
        [ test "hiding the page clears held keys and stops the player" <|
            \_ ->
                let
                    hidden =
                        send (WalkKeyDown WalkRight :: frames 5 16 ++ [ PageVisibilityChanged False ]) boardRoom
                in
                ( ( hidden.room.player.held, hidden.room.player.walking ), send (frames 20 16) hidden == hidden )
                    |> Expect.equal ( ( [], False ), True )
        , test "hiding the page clears a walking target" <|
            \_ ->
                send (ApproachHotspot BoardSpot :: frames 5 16 ++ [ PageVisibilityChanged False ] ++ frames 200 16) boardRoom
                    |> .room
                    |> (\room -> ( room.player.target, room.panelOpen ))
                    |> Expect.equal ( Nothing, False )
        , test "the page becoming visible again changes nothing" <|
            \_ ->
                let
                    walkingRight =
                        send (WalkKeyDown WalkRight :: frames 5 16) boardRoom
                in
                send [ PageVisibilityChanged True ] walkingRight
                    |> Expect.equal walkingRight
        , test "a phase change clears held keys (the box opened from the narration button)" <|
            \_ ->
                send (WalkKeyDown WalkRight :: frames 5 16 ++ [ Advance ]) initModel
                    |> playerOf
                    |> (\p -> ( p.held, p.target, p.walking ))
                    |> Expect.equal ( [], Nothing, False )
        , test "solving salvage closes its panel and leaves the player where they stood" <|
            \_ ->
                let
                    after =
                        send (walkTo CratesSpot ++ sortBooks ++ [ Advance ]) salvageRoom
                in
                ( ( after.room.panelOpen, after.room.player.x ), Room.hotspots after.phase |> List.member BoardSpot )
                    |> Expect.equal ( ( False, 400 ), True )
        , test "entering a diary puts the player back at the start, facing right" <|
            \_ ->
                send [ OpenNextDiary, Advance, SkipTravel ] ({ initModel | phase = PresentHub } |> standingAt 900)
                    |> playerOf
                    |> Expect.equal Room.initialPlayer
        , test "returning to the present puts the player back at the start" <|
            \_ ->
                send [ Advance ] ({ initModel | history = [ Fixtures.repairsSucceeded ], phase = Transition ReturningToPresent } |> standingAt 900)
                    |> (\m -> ( m.phase, m.room ))
                    |> Expect.equal ( PresentHub, Room.initialRoom )
        ]



-- PANELS


panels : Test
panels =
    describe "closing a panel keeps its contents"
        [ test "the board: arrangement, selection and attempts survive closing, walking away and reopening" <|
            \_ ->
                let
                    before =
                        send (walkTo BoardSpot ++ planWeek Fixtures.wrongWeek ++ [ BoardMove (SelectItem PaintSign) ]) boardRoom

                    after =
                        send ([ ClosePanel ] ++ walkTo (ClueSpot WalterDiaryPage) ++ [ CloseInspection ] ++ walkTo BoardSpot) before
                in
                ( Maybe.map .arrangement (boardArrangement after), Maybe.map .attempts (boardArrangement after), after.room.panelOpen )
                    |> Expect.equal ( Maybe.map .arrangement (boardArrangement before), Maybe.map .attempts (boardArrangement before), True )
        , test "the board after a first mistake and Retry: the final attempt survives closing" <|
            \_ ->
                let
                    retrying =
                        send [ Retry ] (withPanelOpen Fixtures.repairFirstAttemptFailed)
                in
                send ([ ClosePanel ] ++ walkTo (ClueSpot BudgetAllocation) ++ [ CloseInspection ] ++ walkTo BoardSpot) retrying
                    |> .phase
                    |> Expect.equal retrying.phase
        , test "salvage: sorted books stay sorted after closing the panel" <|
            \_ ->
                let
                    sorted =
                        send (walkTo CratesSpot ++ List.take 6 sortBooks) salvageRoom
                in
                send ([ ClosePanel ] ++ WalkKeyDown WalkLeft :: frames 30 16 ++ [ WalkKeyUp WalkLeft ] ++ walkTo CratesSpot) sorted
                    |> .phase
                    |> Expect.equal sorted.phase
        , test "closing the panel clears a neutral notice" <|
            \_ ->
                send (walkTo CratesSpot ++ [ Advance, ClosePanel ]) salvageRoom
                    |> (\m -> ( m.notice, m.room.panelOpen ))
                    |> Expect.equal ( Nothing, False )
        , test "ClosePanel with no panel open does nothing" <|
            \_ ->
                send [ ClosePanel ] boardRoom
                    |> Expect.equal boardRoom
        ]



-- WALKING NEVER CHANGES OUTCOMES


unchanged : Test
unchanged =
    describe "walking never spends attempts or changes history"
        [ fuzz (Fuzz.listOfLengthBetween 0 80 roomMsg) "the final attempt's arrangement, attempts and history survive any walking" <|
            \msgs ->
                let
                    board =
                        Fixtures.repairBoard (Fixtures.boardFor Fixtures.wrongWeek) (RetryingAfterMistake wrongWeekViolations)

                    after =
                        send msgs board
                in
                ( after.history
                , Maybe.map (\p -> ( p.arrangement, p.attempts )) (boardArrangement after)
                )
                    |> Expect.equal
                        ( board.history
                        , Maybe.map (\p -> ( p.arrangement, p.attempts )) (boardArrangement board)
                        )
        , fuzz (Fuzz.listOfLengthBetween 0 80 roomMsg) "a resolved 1950 stays recorded exactly once, whatever happens in the present" <|
            \msgs ->
                send msgs Fixtures.hubAfterRepairs
                    |> .history
                    |> Expect.equal [ Fixtures.repairsSucceeded ]
        , fuzz (Fuzz.listOfLengthBetween 0 80 roomMsg) "the player stays inside the bounds whatever the input" <|
            \msgs ->
                trail msgs (Fixtures.repairBoard Placement.empty NoAttemptUsed)
                    |> List.filter (\x -> x < Room.minX || x > Room.maxX)
                    |> Expect.equal []
        ]



-- KEYBOARD


keyboard : Test
keyboard =
    describe "keys"
        [ test "A, D, the arrows and E (either case) are the game keys on keydown" <|
            \_ ->
                [ "a", "A", "ArrowLeft", "d", "D", "ArrowRight", "e", "E", "w", " ", "Enter", "Escape" ]
                    |> List.map Room.keyDown
                    |> Expect.equal
                        [ Just (WalkKeyDown WalkLeft)
                        , Just (WalkKeyDown WalkLeft)
                        , Just (WalkKeyDown WalkLeft)
                        , Just (WalkKeyDown WalkRight)
                        , Just (WalkKeyDown WalkRight)
                        , Just (WalkKeyDown WalkRight)
                        , Just InteractNearby
                        , Just InteractNearby
                        , Nothing
                        , Nothing
                        , Nothing
                        , Nothing
                        ]
        , test "only walk keys matter on keyup" <|
            \_ ->
                [ "a", "ArrowLeft", "D", "ArrowRight", "e" ]
                    |> List.map Room.keyUp
                    |> Expect.equal
                        [ Just (WalkKeyUp WalkLeft)
                        , Just (WalkKeyUp WalkLeft)
                        , Just (WalkKeyUp WalkRight)
                        , Just (WalkKeyUp WalkRight)
                        , Nothing
                        ]
        , test "a repeated keydown (key held) keeps one held key" <|
            \_ ->
                send [ WalkKeyDown WalkRight, WalkKeyDown WalkRight, WalkKeyDown WalkRight ] boardRoom
                    |> playerOf
                    |> .held
                    |> Expect.equal [ WalkRight ]
        , test "holding E opens a clue once; the repeats are ignored while it is open" <|
            \_ ->
                send [ InteractNearby, InteractNearby, InteractNearby ] (boardRoom |> standingAt 430)
                    |> .inspecting
                    |> Expect.equal (Just WalterDiaryPage)
        , test "animation frames are only wanted while the player is moving" <|
            \_ ->
                [ boardRoom
                , send [ WalkKeyDown WalkRight ] boardRoom
                , send [ ApproachHotspot BoardSpot ] boardRoom
                , send (walkTo BoardSpot) boardRoom
                ]
                    |> List.map Room.isMoving
                    |> Expect.equal [ False, True, True, False ]
        ]



-- THE WALKABLE 1950 CHAPTER


walkableChapter : Test
walkableChapter =
    let
        toSalvage =
            -- Walk to the box, two narration screens, the diary on the counter, then
            -- step in and let the trip back play out on its own frames.
            walkTo BoxSpot ++ [ Advance, Advance ] ++ walkTo DiarySpot ++ [ Advance ] ++ frames 200 16

        toBoard =
            toSalvage ++ walkTo CratesSpot ++ sortBooks ++ [ Advance ]

        atBoard =
            send (toBoard ++ walkTo (ClueSpot GlassDeliverySlip) ++ [ CloseInspection ] ++ walkTo BoardSpot) Update.init
    in
    describe "the 1950 chapter played by walking"
        [ test "intro, present, salvage and the board are all reached through the room" <|
            \_ ->
                ( atBoard.room.panelOpen, Maybe.map .attempts (boardArrangement atBoard), atBoard.room.player.x )
                    |> Expect.equal ( True, Just NoAttemptUsed, 640 )
        , test "success: the week pauses for the shelf, the player walks to it, and 1973 unlocks" <|
            \_ ->
                let
                    submitted =
                        send (planWeek Fixtures.validWeek ++ [ Submit ]) atBoard

                    -- Monday to Wednesday, then the Thursday shelving slide pauses for the shelf.
                    atShelfPause =
                        send [ Advance, Advance, Advance, Advance ] submitted

                    shelved =
                        send (walkTo ShelfSpot ++ shelveSmallToTall ++ [ Advance ]) atShelfPause

                    home =
                        send [ Advance, Advance, Advance ] shelved
                in
                Expect.all
                    [ \_ -> ( submitted.phase, submitted.room.panelOpen ) |> Expect.equal ( Transition (Slideshow Repairs1950 0), False )
                    , \_ -> ( isShelf atShelfPause.phase, atShelfPause.room.panelOpen, Room.hotspots atShelfPause.phase ) |> Expect.equal ( True, False, [ ShelfSpot ] )
                    , \_ -> ( shelved.phase, home.phase, home.room.player ) |> Expect.equal ( Transition (Slideshow Repairs1950 4), PresentHub, Room.initialPlayer )
                    , \_ -> ( Timeline.outcomeOf Repairs1950 home.history, (Timeline.deriveWorld home.history).nextDiary ) |> Expect.equal ( Just Succeeded, Just Shadows1973 )
                    ]
                    ()
        , test "final failure: both attempts kept through closing the panel, no shelf, and 1973 still unlocks" <|
            \_ ->
                let
                    firstMistake =
                        send (planWeek Fixtures.wrongWeek ++ [ Submit, Submit, ClosePanel ]) atBoard

                    walkedAway =
                        send ([ Retry, ClosePanel ] ++ walkTo (ClueSpot WalterDiaryPage) ++ [ CloseInspection ] ++ walkTo BoardSpot) firstMistake

                    failed =
                        send [ Submit, Submit ] walkedAway

                    home =
                        send [ Advance, Advance ] failed
                in
                Expect.all
                    [ \_ -> ( Maybe.map .attempts (boardArrangement firstMistake), firstMistake.room.panelOpen ) |> Expect.equal ( Just (ReviewingFirstMistake wrongWeekViolations), True )
                    , \_ -> ( Maybe.map .attempts (boardArrangement walkedAway), walkedAway.room.panelOpen ) |> Expect.equal ( Just (RetryingAfterMistake wrongWeekViolations), True )
                    , \_ -> Timeline.recordFor Repairs1950 failed.history |> Maybe.map (\r -> ( r.outcome, r.attemptsUsed )) |> Expect.equal (Just ( Failed, 2 ))
                    , \_ -> Timeline.slides Repairs1950 failed.history |> Expect.equal [ ConsequenceSlide Repairs1950 (RoofAfterRain Wednesday) ]
                    , \_ -> ( home.phase, List.length home.history, (Timeline.deriveWorld home.history).nextDiary ) |> Expect.equal ( PresentHub, 1, Just Shadows1973 )
                    ]
                    ()
        ]


isShelf : Phase -> Bool
isShelf phase =
    case phase of
        ReopeningShelf _ ->
            True

        _ ->
            False
