module Rules.Salvage exposing (accepts, crateSlots, isSolved, misplaced, slots)

{-| 1950 salvage warm-up: nine books into three crates of three.
Unlimited corrections, immediate local feedback, never spends attempts.
-}

import Domain exposing (BookId, Condition(..), Placement, SalvageSlot(..))


{-| The three spaces of one crate, for PlaceSelectedInGroup. -}
crateSlots : Condition -> List SalvageSlot
crateSlots crate =
    List.map (InCrate crate) [ 1, 2, 3 ]


slots : List SalvageSlot
slots =
    List.concatMap crateSlots [ Fine, NeedsRepair, TooFarGone ]


accepts : BookId -> SalvageSlot -> Bool
accepts _ slot =
    List.member slot slots


{-| NOT IMPLEMENTED YET — Person A, hours 7–11.
Placed books whose crate differs from Rules.Books.condition.
-}
misplaced : Placement BookId SalvageSlot -> List BookId
misplaced _ =
    Debug.todo "Rules.Salvage.misplaced is not implemented yet"


{-| NOT IMPLEMENTED YET — Person A, hours 7–11.
All nine books placed and none misplaced (move order irrelevant).
-}
isSolved : Placement BookId SalvageSlot -> Bool
isSolved _ =
    Debug.todo "Rules.Salvage.isSolved is not implemented yet"
