module Rules.Shelf exposing (accepts, matchedOrder, order, slots)

{-| 1950 reopening shelf: arrange the six recovered books in any of four
orders (small to tall, tall to small, rainbow, A–Z). Unlimited corrections, never spends attempts, never changes
the recorded 1950 outcome.
-}

import Domain exposing (Placement, RecoverableBook(..), ShelfOrder(..), ShelfSlot(..))
import Rules.Placement as Placement


slots : List ShelfSlot
slots =
    List.map ShelfPosition [ 1, 2, 3, 4, 5, 6 ]


accepts : RecoverableBook -> ShelfSlot -> Bool
accepts _ slot =
    List.member slot slots


{-| The four accepted left-to-right orders (brief section 4C, plus tall to
small). Height and colour agree with Rules.Books.height / colour (checked in
tests).
-}
order : ShelfOrder -> List RecoverableBook
order shelfOrder =
    case shelfOrder of
        ByHeight ->
            [ BirdsongForBeginners, GardensInWinter, PocketOfWonders, AtlasOfSmallPlaces, LettersFromTheSea, WinterTales ]

        TallToSmall ->
            List.reverse (order ByHeight)

        ByColour ->
            [ WinterTales, LettersFromTheSea, BirdsongForBeginners, PocketOfWonders, AtlasOfSmallPlaces, GardensInWinter ]

        Alphabetical ->
            [ AtlasOfSmallPlaces, BirdsongForBeginners, GardensInWinter, LettersFromTheSea, PocketOfWonders, WinterTales ]


{-| The order a full, well-formed shelf matches, if any.

Nothing while any position is empty, a book is listed twice, two books share
a position, or the arrangement is not one of the four orders. Safe to show
at any time: this is the celebration scene's immediate local feedback.

-}
matchedOrder : Placement RecoverableBook ShelfSlot -> Maybe ShelfOrder
matchedOrder placement =
    let
        wellFormed =
            (List.length placement.placed == List.length slots)
                && List.all (\slot -> List.length (List.filter (\( _, s ) -> s == slot) placement.placed) == 1) slots

        leftToRight =
            List.filterMap (\slot -> Placement.itemIn slot placement) slots
    in
    if wellFormed then
        [ ByHeight, TallToSmall, ByColour, Alphabetical ]
            |> List.filter (\candidate -> order candidate == leftToRight)
            |> List.head

    else
        Nothing
