module Rules.Room exposing
    ( width, height, floorY, minX, maxX, startX, walkSpeed, interactionDistance, maxFrameDelta
    , position, hotspots
    , canWalk, nearby, hasPanel
    , initialRoom, initialPlayer
    )

{-| The room: one shared coordinate system for the walking player and every
hotspot (contract v1.3).

Coordinates are logical pixels in a 1280 × 720 room, origin top left. The
stage is 80rem × 45rem, so 1rem is 16 logical pixels and a view can place
anything at `left: x / 16 rem; top: y / 16 rem` (or as a percentage of the
room). Views draw these positions; they never keep their own layout map.

The player walks along one horizontal strip: the feet are always at floorY,
and only x changes, between minX and maxX.

-}

import Domain exposing (..)



-- ROOM GEOMETRY


width : Float
width =
    1280


height : Float
height =
    720


{-| The y of the player's feet. -}
floorY : Float
floorY =
    650


{-| The leftmost x the centre of the player can reach. -}
minX : Float
minX =
    72


{-| The rightmost x the centre of the player can reach. -}
maxX : Float
maxX =
    1208


{-| Where the player stands on entering a room (facing right). -}
startX : Float
startX =
    160


{-| Logical pixels per second. Crossing the whole room takes under 4 seconds. -}
walkSpeed : Float
walkSpeed =
    300


{-| A hotspot can be used (E, or a click) when the player's x is at most this
far from the hotspot's x. Hotspots usable at the same time are always more
than twice this apart, so there is never a tie.
-}
interactionDistance : Float
interactionDistance =
    64


{-| Animation-frame deltas above this many milliseconds count as this much,
so a stalled or backgrounded tab never makes the player jump.
-}
maxFrameDelta : Float
maxFrameDelta =
    50



-- HOTSPOTS


{-| Where each hotspot is. `x` is where the player stands to use it; `y` is
the height of the object itself (a notice on the door, a board on the wall),
for drawing the object, its highlight and its prompt.

Every x is inside minX..maxX. The positions follow the room pictures in
public/assets (the door on the left, the counter and till, the cork board
under the window, the right-hand bookcase, the photograph on the right wall).

-}
position : Hotspot -> { x : Float, y : Float }
position hotspot =
    case hotspot of
        -- Introduction (present day)
        ClueSpot ClosureNotice ->
            { x = 100, y = 540 }

        BoxSpot ->
            { x = 470, y = 625 }

        ClueSpot FamilyPhotograph ->
            { x = 1200, y = 315 }

        -- Present hub
        ClueSpot (HubProp OrderDesk) ->
            { x = 235, y = 410 }

        DiarySpot ->
            { x = 430, y = 465 }

        ClueSpot (HubProp CommunityWall) ->
            { x = 640, y = 555 }

        ClueSpot (HubProp RoofAndShelves) ->
            { x = 880, y = 180 }

        -- 1950
        ClueSpot GlassDeliverySlip ->
            { x = 100, y = 420 }

        ClueSpot BudgetAllocation ->
            { x = 235, y = 410 }

        CratesSpot ->
            { x = 400, y = 615 }

        ClueSpot WalterDiaryPage ->
            { x = 430, y = 465 }

        BoardSpot ->
            { x = 640, y = 555 }

        ClueSpot RubbleAndShelvesNote ->
            { x = 820, y = 560 }

        ShelfSpot ->
            { x = 980, y = 300 }

        ClueSpot ShelfPlaque ->
            { x = 980, y = 300 }

        -- 1973
        ClueSpot CutoutBox ->
            { x = 170, y = 610 }

        ClueSpot ShadowScript ->
            { x = 330, y = 465 }

        StageSpot ->
            { x = 640, y = 380 }

        ClueSpot StageSketch ->
            { x = 840, y = 560 }

        -- 1998
        ClueSpot RuthsEmail ->
            { x = 240, y = 410 }

        ClueSpot InscriptionClue ->
            { x = 440, y = 465 }

        BookTableSpot ->
            { x = 820, y = 590 }

        ClueSpot (CandidatePage _ _) ->
            { x = 820, y = 590 }

        ClueSpot RememberedSentence ->
            { x = 1180, y = 560 }


{-| The hotspots that can be used in this phase, left to right. An empty list
means the player cannot walk in this phase (narration, transitions, endings).

The chapter phases stay in charge: after salvage the board is the station,
and during the shelving-day pause the shelf is.

-}
hotspots : Phase -> List Hotspot
hotspots phase =
    case phase of
        Introduction PackingUp ->
            [ ClueSpot ClosureNotice, BoxSpot, ClueSpot FamilyPhotograph ]

        Introduction _ ->
            []

        PresentHub ->
            [ ClueSpot (HubProp OrderDesk), DiarySpot, ClueSpot (HubProp CommunityWall), ClueSpot (HubProp RoofAndShelves) ]

        Salvage _ ->
            [ CratesSpot ]

        RepairBoard _ ->
            [ ClueSpot GlassDeliverySlip, ClueSpot BudgetAllocation, ClueSpot WalterDiaryPage, BoardSpot, ClueSpot RubbleAndShelvesNote ]

        ReopeningShelf _ ->
            [ ShelfSpot ]

        ShadowPuzzle _ ->
            [ ClueSpot CutoutBox, ClueSpot ShadowScript, StageSpot, ClueSpot StageSketch ]

        BookMystery _ ->
            [ ClueSpot RuthsEmail, ClueSpot InscriptionClue, BookTableSpot, ClueSpot RememberedSentence ]

        Transition _ ->
            []

        Ending ->
            []


{-| Whether this phase has a puzzle panel that a station hotspot opens. -}
hasPanel : Phase -> Bool
hasPanel phase =
    case phase of
        Salvage _ ->
            True

        RepairBoard _ ->
            True

        ReopeningShelf _ ->
            True

        ShadowPuzzle _ ->
            True

        BookMystery _ ->
            True

        _ ->
            False



-- WALKING


{-| The player can walk only in the room itself: a phase with hotspots, no
open panel, no clue overlay, no notice, and no first-attempt feedback.
-}
canWalk : Model -> Bool
canWalk model =
    not model.room.panelOpen
        && (model.inspecting == Nothing)
        && (model.notice == Nothing)
        && not (reviewingFeedback model.phase)
        && not (List.isEmpty (hotspots model.phase))


{-| The hotspot E would use now: the closest usable one within
interactionDistance. Nothing while the player cannot walk. Use it for the
proximity prompt.
-}
nearby : Model -> Maybe Hotspot
nearby model =
    if canWalk model then
        let
            distance hotspot =
                abs ((position hotspot).x - model.room.player.x)
        in
        hotspots model.phase
            |> List.filter (\hotspot -> distance hotspot <= interactionDistance)
            |> List.sortBy distance
            |> List.head

    else
        Nothing


reviewingFeedback : Phase -> Bool
reviewingFeedback phase =
    let
        reviewing attempts =
            case attempts of
                ReviewingFirstMistake _ ->
                    True

                _ ->
                    False
    in
    case phase of
        RepairBoard puzzle ->
            reviewing puzzle.attempts

        ShadowPuzzle puzzle ->
            reviewing puzzle.attempts

        BookMystery puzzle ->
            reviewing puzzle.attempts

        _ ->
            False



-- INITIAL STATE


initialPlayer : Player
initialPlayer =
    { x = startX
    , facing = FacingRight
    , walking = False
    , held = []
    , target = Nothing
    }


initialRoom : Room
initialRoom =
    { player = initialPlayer
    , panelOpen = False
    }
