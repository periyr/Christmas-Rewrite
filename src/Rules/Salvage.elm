module Rules.Salvage exposing (accepts, crateSlots, isSolved, misplaced, slots)

{-| 1950 salvage warm-up: nine books into three crates of three.
Unlimited corrections, immediate local feedback, never spends attempts.

Only the final classification matters: which crate each book ends up in.
The order of moves and the space used inside a crate are irrelevant.

-}

import Domain exposing (BookId, Condition(..), Placement, SalvageSlot(..))
import Rules.Books as Books


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


{-| Books currently sitting in a crate that does not match their condition,
in Rules.Books.allBooks order. Books still in the tray are not listed.
Safe to show at any time: this is the warm-up's immediate local feedback.
-}
misplaced : Placement BookId SalvageSlot -> List BookId
misplaced placement =
    let
        isWrong book =
            List.any
                (\( placedBook, InCrate crate _ ) -> placedBook == book && crate /= Books.condition book)
                placement.placed
    in
    List.filter isWrong Books.allBooks


{-| Every one of the nine books is in exactly one valid crate space, no space
holds two books, and none is misplaced.
-}
isSolved : Placement BookId SalvageSlot -> Bool
isSolved placement =
    let
        placed =
            placement.placed

        occurrences match =
            List.length (List.filter match placed)
    in
    (List.length placed == List.length Books.allBooks)
        && List.all (\book -> occurrences (\( b, _ ) -> b == book) == 1) Books.allBooks
        && List.all (\slot -> occurrences (\( _, s ) -> s == slot) <= 1) slots
        && List.all (\( _, slot ) -> List.member slot slots) placed
        && List.isEmpty (misplaced placement)
