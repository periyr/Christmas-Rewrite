module PlacementTests exposing (suite)

import Domain exposing (..)
import Expect
import Rules.Placement as Placement
import Rules.Repair
import Rules.Shadow
import Test exposing (Test, describe, test)


anywhere : a -> b -> Bool
anywhere _ _ =
    True


run : List (PlacementAction TaskId RepairSlot) -> Placement TaskId RepairSlot -> ( Placement TaskId RepairSlot, Maybe Notice )
run actions start =
    List.foldl (\action ( p, _ ) -> Placement.apply anywhere action p) ( start, Nothing ) actions


suite : Test
suite =
    describe "Rules.Placement"
        [ test "select then place moves an item from the tray into an empty slot" <|
            \_ ->
                run [ SelectItem PatchRoof, PlaceSelected (OnDay Monday) ] Placement.empty
                    |> Tuple.first
                    |> Expect.equal { placed = [ ( PatchRoof, OnDay Monday ) ], selected = Nothing }
        , test "selecting the same item again deselects it" <|
            \_ ->
                run [ SelectItem PatchRoof, SelectItem PatchRoof ] Placement.empty
                    |> Tuple.first
                    |> .selected
                    |> Expect.equal Nothing
        , test "tray item into an occupied slot sends the occupant back to the tray" <|
            \_ ->
                let
                    ( result, _ ) =
                        run [ SelectItem PatchRoof, PlaceSelected (OnDay Monday), SelectItem ClearRubble, PlaceSelected (OnDay Monday) ] Placement.empty
                in
                Expect.all
                    [ \p -> Placement.itemIn (OnDay Monday) p |> Expect.equal (Just ClearRubble)
                    , \p -> Placement.slotOf PatchRoof p |> Expect.equal Nothing
                    , \p -> Placement.inTray Rules.Repair.allTasks p |> List.member PatchRoof |> Expect.equal True
                    ]
                    result
        , test "slot item into an occupied slot swaps the two" <|
            \_ ->
                let
                    ( result, _ ) =
                        run
                            [ SelectItem PatchRoof
                            , PlaceSelected (OnDay Monday)
                            , SelectItem ClearRubble
                            , PlaceSelected (OnDay Tuesday)
                            , SelectItem PatchRoof
                            , PlaceSelected (OnDay Tuesday)
                            ]
                            Placement.empty
                in
                Expect.all
                    [ \p -> Placement.slotOf PatchRoof p |> Expect.equal (Just (OnDay Tuesday))
                    , \p -> Placement.slotOf ClearRubble p |> Expect.equal (Just (OnDay Monday))
                    , \p -> List.length p.placed |> Expect.equal 2
                    ]
                    result
        , test "moving never duplicates an item" <|
            \_ ->
                run [ SelectItem PatchRoof, PlaceSelected (OnDay Monday), SelectItem PatchRoof, PlaceSelected (OnDay Friday) ] Placement.empty
                    |> Tuple.first
                    |> .placed
                    |> Expect.equal [ ( PatchRoof, OnDay Friday ) ]
        , test "a full group gives the neutral TargetFull notice and changes nothing" <|
            \_ ->
                let
                    ( before, _ ) =
                        run [ SelectItem PaintSign, PlaceSelectedInGroup Rules.Repair.notThisWeekSlots, SelectItem BoardUpWindow, PlaceSelectedInGroup Rules.Repair.notThisWeekSlots, SelectItem PatchRoof ] Placement.empty
                in
                Placement.apply anywhere (PlaceSelectedInGroup Rules.Repair.notThisWeekSlots) before
                    |> Expect.equal ( before, Just TargetFull )
        , test "a prop cannot go into a character slot (neutral notice)" <|
            \_ ->
                let
                    start =
                        { placed = [], selected = Just (PropCutout Lantern) }
                in
                Placement.apply Rules.Shadow.accepts (PlaceSelected (CharacterSlot Scene1)) start
                    |> Expect.equal ( start, Just DoesNotFitThere )
        , test "placing with nothing selected does nothing" <|
            \_ ->
                Placement.apply anywhere (PlaceSelected (OnDay Monday)) Placement.empty
                    |> Expect.equal ( Placement.empty, Nothing )
        ]
