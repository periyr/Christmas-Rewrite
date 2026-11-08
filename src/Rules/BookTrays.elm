module Rules.BookTrays exposing (candidates, salvage, shelf, tasks)

{-| Tray orders are derived from the run seed. Placement only tracks where
each book is, so taking a book out never changes its reserved tray position.
The 1950 task cards and the 1998 candidate books are laid out in a seeded
order too.
-}

import Domain exposing (BookId, CandidateId, RecoverableBook(..), TaskId)
import Random
import Rules.Books as Books
import Rules.Mystery as Mystery
import Rules.Repair as Repair
import Rules.Shelf as Shelf


salvage : Int -> List BookId
salvage seed =
    shuffle seed Books.allBooks


shelf : Int -> List RecoverableBook
shelf seed =
    let
        shuffled =
            shuffle seed Books.recoverableBooks
    in
    case Shelf.matchedOrder { placed = List.map2 Tuple.pair shuffled Shelf.slots, selected = Nothing } of
        Nothing ->
            shuffled

        Just _ ->
            -- The original tray order is a known unsolved fallback.
            -- No retry loop is needed, even if a seed produces a solution.
            [ LettersFromTheSea, PocketOfWonders, GardensInWinter, WinterTales, AtlasOfSmallPlaces, BirdsongForBeginners ]


{-| The seven 1950 task cards in this game's tray order. The seed is offset so
this order doesn't follow the salvage tray.
-}
tasks : Int -> List TaskId
tasks seed =
    shuffle (seed + 1950) Repair.allTasks


{-| The four 1998 books in this game's order on the table. The seed is offset
so this order doesn't follow the 1950 trays.
-}
candidates : Int -> List CandidateId
candidates seed =
    shuffle (seed + 1998) Mystery.candidates


{-| Insert each item at a uniformly chosen position in the shuffled prefix. -}
shuffle : Int -> List a -> List a
shuffle seed items =
    let
        insert item ( shuffled, current ) =
            let
                ( index, next ) =
                    Random.step (Random.int 0 (List.length shuffled)) current
            in
            ( List.take index shuffled ++ (item :: List.drop index shuffled), next )
    in
    List.foldl insert ( [], Random.initialSeed seed ) items |> Tuple.first
