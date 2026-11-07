module Rules.Shelf exposing (accepts, matchedOrder, slots)

{-| 1950 reopening shelf: arrange the six recovered books in any of three
ascending orders. Unlimited corrections, never spends attempts, never changes
the recorded 1950 outcome.
-}

import Domain exposing (Placement, RecoverableBook, ShelfOrder, ShelfSlot(..))


slots : List ShelfSlot
slots =
    List.map ShelfPosition [ 1, 2, 3, 4, 5, 6 ]


accepts : RecoverableBook -> ShelfSlot -> Bool
accepts _ slot =
    List.member slot slots


{-| NOT IMPLEMENTED YET — Person A, hours 7–11.
Just the order matched by a full shelf (height, colour or A–Z), else Nothing.
-}
matchedOrder : Placement RecoverableBook ShelfSlot -> Maybe ShelfOrder
matchedOrder _ =
    Debug.todo "Rules.Shelf.matchedOrder is not implemented yet"
