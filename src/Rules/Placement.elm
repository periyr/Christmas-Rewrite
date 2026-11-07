module Rules.Placement exposing (apply, empty, inTray, itemIn, slotOf)

{-| Click-to-select, click-to-place mechanics shared by every arrangement
(salvage crates, repair board, reopening shelf, shadow stage).

Contains no puzzle-answer rules. Each puzzle passes an `accepts` function
that only says which slots exist for which items (e.g. a prop cannot go into
a character slot).

-}

import Domain exposing (Notice(..), Placement, PlacementAction(..))


empty : Placement item slot
empty =
    { placed = [], selected = Nothing }


slotOf : item -> Placement item slot -> Maybe slot
slotOf item placement =
    placement.placed
        |> List.filter (\( i, _ ) -> i == item)
        |> List.head
        |> Maybe.map Tuple.second


itemIn : slot -> Placement item slot -> Maybe item
itemIn slot placement =
    placement.placed
        |> List.filter (\( _, s ) -> s == slot)
        |> List.head
        |> Maybe.map Tuple.first


{-| Items from `all` that are not in any slot, in the order of `all`. -}
inTray : List item -> Placement item slot -> List item
inTray all placement =
    List.filter (\item -> slotOf item placement == Nothing) all


{-| Apply one placement action. The Maybe Notice is neutral feedback
(full target, wrong kind of slot); it never says anything about correctness.
-}
apply : (item -> slot -> Bool) -> PlacementAction item slot -> Placement item slot -> ( Placement item slot, Maybe Notice )
apply accepts action placement =
    case ( action, placement.selected ) of
        ( SelectItem item, selected ) ->
            if selected == Just item then
                ( { placement | selected = Nothing }, Nothing )

            else
                ( { placement | selected = Just item }, Nothing )

        ( PlaceSelected slot, Just item ) ->
            placeInto accepts item slot placement

        ( PlaceSelectedInGroup slots, Just item ) ->
            let
                alreadyInGroup =
                    case slotOf item placement of
                        Just current ->
                            List.member current slots

                        Nothing ->
                            False

                freeSlot =
                    slots
                        |> List.filter (\s -> accepts item s && itemIn s placement == Nothing)
                        |> List.head
            in
            if alreadyInGroup then
                ( { placement | selected = Nothing }, Nothing )

            else
                case freeSlot of
                    Just slot ->
                        placeInto accepts item slot placement

                    Nothing ->
                        if List.any (accepts item) slots then
                            ( placement, Just TargetFull )

                        else
                            ( placement, Just DoesNotFitThere )

        ( ReturnSelectedToTray, Just item ) ->
            ( { placed = without item placement.placed, selected = Nothing }, Nothing )

        ( ClearSelection, _ ) ->
            ( { placement | selected = Nothing }, Nothing )

        ( _, Nothing ) ->
            ( placement, Nothing )


placeInto : (item -> slot -> Bool) -> item -> slot -> Placement item slot -> ( Placement item slot, Maybe Notice )
placeInto accepts item slot placement =
    if not (accepts item slot) then
        ( placement, Just DoesNotFitThere )

    else
        case itemIn slot placement of
            Nothing ->
                ( { placed = without item placement.placed ++ [ ( item, slot ) ], selected = Nothing }, Nothing )

            Just occupant ->
                if occupant == item then
                    ( { placement | selected = Nothing }, Nothing )

                else
                    let
                        -- Swap when the moving item came from a slot the occupant
                        -- can use; otherwise the occupant goes back to the tray.
                        occupantMovesTo =
                            case slotOf item placement of
                                Just origin ->
                                    if accepts occupant origin then
                                        [ ( occupant, origin ) ]

                                    else
                                        []

                                Nothing ->
                                    []

                        rest =
                            placement.placed |> without item |> without occupant
                    in
                    ( { placed = rest ++ occupantMovesTo ++ [ ( item, slot ) ], selected = Nothing }, Nothing )


without : item -> List ( item, slot ) -> List ( item, slot )
without item =
    List.filter (\( i, _ ) -> i /= item)
