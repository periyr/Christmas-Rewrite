module WarmUpTests exposing (suite)

{-| 1950 warm-ups: salvage classification and reopening shelf orders.
Expected answers are written out from the brief, not read from Rules.*.
-}

import Domain exposing (..)
import Expect
import Rules.Books as Books
import Rules.Placement as Placement
import Rules.Salvage as Salvage
import Rules.Shelf as Shelf
import Test exposing (Test, describe, test)



-- SALVAGE HELPERS


{-| The brief's classification (section 4A). -}
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


salvage : List (PlacementAction BookId SalvageSlot) -> Placement BookId SalvageSlot -> Placement BookId SalvageSlot
salvage actions start =
    List.foldl (\action p -> Tuple.first (Placement.apply Salvage.accepts action p)) start actions


{-| Click each book, then click its crate. -}
sortInto : List ( BookId, Condition ) -> List (PlacementAction BookId SalvageSlot)
sortInto pairs =
    List.concatMap (\( book, crate ) -> [ SelectItem book, PlaceSelectedInGroup (Salvage.crateSlots crate) ]) pairs


sorted : Placement BookId SalvageSlot
sorted =
    salvage (sortInto briefCrates) Placement.empty


nextCrate : Condition -> Condition
nextCrate crate =
    case crate of
        Fine ->
            NeedsRepair

        NeedsRepair ->
            TooFarGone

        TooFarGone ->
            Fine


slotOfBook : BookId -> Placement BookId SalvageSlot -> SalvageSlot
slotOfBook book placement =
    Placement.slotOf book placement |> Maybe.withDefault (InCrate Fine 99)


replaceEntry : (( BookId, SalvageSlot ) -> ( BookId, SalvageSlot )) -> Placement BookId SalvageSlot -> Placement BookId SalvageSlot
replaceEntry f placement =
    { placement | placed = List.map f placement.placed }



-- SHELF HELPERS


shelfOf : List RecoverableBook -> Placement RecoverableBook ShelfSlot
shelfOf books =
    { placed = List.indexedMap (\i book -> ( book, ShelfPosition (i + 1) )) books, selected = Nothing }


byHeight : List RecoverableBook
byHeight =
    [ BirdsongForBeginners, GardensInWinter, PocketOfWonders, AtlasOfSmallPlaces, LettersFromTheSea, WinterTales ]


byRainbow : List RecoverableBook
byRainbow =
    [ WinterTales, LettersFromTheSea, BirdsongForBeginners, PocketOfWonders, AtlasOfSmallPlaces, GardensInWinter ]


byAlphabet : List RecoverableBook
byAlphabet =
    [ AtlasOfSmallPlaces, BirdsongForBeginners, GardensInWinter, LettersFromTheSea, PocketOfWonders, WinterTales ]


permutations : List a -> List (List a)
permutations items =
    case items of
        [] ->
            [ [] ]

        _ ->
            List.concatMap (\x -> List.map ((::) x) (permutations (List.filter ((/=) x) items))) items



-- TESTS


suite : Test
suite =
    describe "1950 warm-ups"
        [ salvageTests
        , shelfTests
        ]


salvageTests : Test
salvageTests =
    describe "Rules.Salvage"
        [ test "the brief's classification agrees with the book facts" <|
            \_ ->
                List.map (Tuple.first >> Books.condition) briefCrates
                    |> Expect.equal (List.map Tuple.second briefCrates)
        , test "sorting into the brief's crates solves it" <|
            \_ ->
                ( Salvage.isSolved sorted, Salvage.misplaced sorted )
                    |> Expect.equal ( True, [] )
        , test "the order of moves does not matter" <|
            \_ ->
                let
                    -- One book from each crate in turn: Atlas, Birdsong, Harbour, Pocket, …
                    interleaved =
                        List.indexedMap Tuple.pair briefCrates
                            |> List.sortBy (\( i, _ ) -> modBy 3 i * 10 + i)
                            |> List.map Tuple.second
                in
                [ briefCrates
                , List.reverse briefCrates
                , interleaved
                , List.drop 4 briefCrates ++ List.take 4 briefCrates
                ]
                    |> List.map (\order -> Salvage.isSolved (salvage (sortInto order) Placement.empty))
                    |> Expect.equal [ True, True, True, True ]
        , test "which space inside a crate is used does not matter" <|
            \_ ->
                let
                    rankInCrate book crate =
                        briefCrates
                            |> List.filter (\( _, c ) -> c == crate)
                            |> List.indexedMap (\i ( b, _ ) -> ( i, b ))
                            |> List.filter (\( _, b ) -> b == book)
                            |> List.map Tuple.first
                            |> List.sum

                    -- Fill each crate from space 3 down to space 1.
                    explicitSlots =
                        List.concatMap
                            (\( book, crate ) -> [ SelectItem book, PlaceSelected (InCrate crate (3 - rankInCrate book crate)) ])
                            briefCrates

                    result =
                        salvage explicitSlots Placement.empty
                in
                ( Placement.slotOf (Recoverable AtlasOfSmallPlaces) result, Salvage.isSolved result )
                    |> Expect.equal ( Just (InCrate Fine 3), True )
        , test "every book in the wrong crate, then corrected, is solved" <|
            \_ ->
                let
                    allWrong =
                        salvage (sortInto (List.map (\( b, c ) -> ( b, nextCrate c )) briefCrates)) Placement.empty

                    returned =
                        salvage (List.concatMap (\( b, _ ) -> [ SelectItem b, ReturnSelectedToTray ]) briefCrates) allWrong
                in
                Expect.all
                    [ \_ -> List.length (Salvage.misplaced allWrong) |> Expect.equal 9
                    , \_ -> Salvage.isSolved allWrong |> Expect.equal False
                    , \_ -> Salvage.isSolved (salvage (sortInto briefCrates) returned) |> Expect.equal True
                    ]
                    ()
        , test "two swapped books are both misplaced, and swapping back solves it" <|
            \_ ->
                let
                    atlas =
                        Recoverable AtlasOfSmallPlaces

                    birdsong =
                        Recoverable BirdsongForBeginners

                    swapped =
                        salvage [ SelectItem atlas, PlaceSelected (slotOfBook birdsong sorted) ] sorted

                    swappedBack =
                        salvage [ SelectItem birdsong, PlaceSelected (slotOfBook atlas swapped) ] swapped
                in
                Expect.all
                    [ \_ -> Salvage.misplaced swapped |> Expect.equal [ atlas, birdsong ]
                    , \_ -> Salvage.isSolved swapped |> Expect.equal False
                    , \_ -> Salvage.isSolved swappedBack |> Expect.equal True
                    ]
                    ()
        , test "a book left out is unsolved but not misplaced" <|
            \_ ->
                let
                    missing =
                        salvage [ SelectItem (Ruined MountainPaths), ReturnSelectedToTray ] sorted
                in
                ( Salvage.isSolved missing, Salvage.misplaced missing )
                    |> Expect.equal ( False, [] )
        , test "a book listed twice is unsolved even if both are in its crate" <|
            \_ ->
                sorted
                    |> replaceEntry
                        (\( b, s ) ->
                            if b == Recoverable PocketOfWonders then
                                ( Recoverable AtlasOfSmallPlaces, s )

                            else
                                ( b, s )
                        )
                    |> Salvage.isSolved
                    |> Expect.equal False
        , test "two books in one space is unsolved" <|
            \_ ->
                let
                    atlasSlot =
                        slotOfBook (Recoverable AtlasOfSmallPlaces) sorted
                in
                sorted
                    |> replaceEntry
                        (\( b, s ) ->
                            if b == Recoverable PocketOfWonders then
                                ( b, atlasSlot )

                            else
                                ( b, s )
                        )
                    |> Salvage.isSolved
                    |> Expect.equal False
        , test "a book in an unknown space is unsolved" <|
            \_ ->
                sorted
                    |> replaceEntry
                        (\( b, s ) ->
                            if b == Recoverable WinterTales then
                                ( b, InCrate Fine 4 )

                            else
                                ( b, s )
                        )
                    |> Salvage.isSolved
                    |> Expect.equal False
        ]


shelfTests : Test
shelfTests =
    describe "Rules.Shelf"
        [ test "small to tall is accepted" <|
            \_ ->
                Shelf.matchedOrder (shelfOf byHeight) |> Expect.equal (Just ByHeight)
        , test "rainbow is accepted" <|
            \_ ->
                Shelf.matchedOrder (shelfOf byRainbow) |> Expect.equal (Just ByColour)
        , test "tall to small is accepted" <|
            \_ ->
                Shelf.matchedOrder (shelfOf (List.reverse byHeight)) |> Expect.equal (Just TallToSmall)
        , test "A–Z is accepted" <|
            \_ ->
                Shelf.matchedOrder (shelfOf byAlphabet) |> Expect.equal (Just Alphabetical)
        , test "of all 720 arrangements, exactly the four orders are accepted" <|
            \_ ->
                permutations byAlphabet
                    |> List.filter (\books -> Shelf.matchedOrder (shelfOf books) /= Nothing)
                    |> Expect.equal (List.filter (\p -> List.member p [ byHeight, List.reverse byHeight, byRainbow, byAlphabet ]) (permutations byAlphabet))
        , test "there are 720 arrangements and 4 accepted" <|
            \_ ->
                ( List.length (permutations byAlphabet)
                , List.length (List.filter (\books -> Shelf.matchedOrder (shelfOf books) /= Nothing) (permutations byAlphabet))
                )
                    |> Expect.equal ( 720, 4 )
        , test "two neighbours swapped is not accepted" <|
            \_ ->
                Shelf.matchedOrder (shelfOf [ GardensInWinter, BirdsongForBeginners, PocketOfWonders, AtlasOfSmallPlaces, LettersFromTheSea, WinterTales ])
                    |> Expect.equal Nothing
        , test "an incomplete shelf is not accepted" <|
            \_ ->
                ( Shelf.matchedOrder (shelfOf (List.take 5 byHeight)), Shelf.matchedOrder Placement.empty )
                    |> Expect.equal ( Nothing, Nothing )
        , test "a book listed twice is not accepted" <|
            \_ ->
                Shelf.matchedOrder (shelfOf [ BirdsongForBeginners, GardensInWinter, PocketOfWonders, AtlasOfSmallPlaces, LettersFromTheSea, LettersFromTheSea ])
                    |> Expect.equal Nothing
        , test "two books in one position is not accepted" <|
            \_ ->
                Shelf.matchedOrder
                    { placed = List.map (\( b, s ) -> ( b, if s == ShelfPosition 6 then ShelfPosition 5 else s )) (shelfOf byHeight).placed
                    , selected = Nothing
                    }
                    |> Expect.equal Nothing
        , test "placing by clicks in any order, with corrections, is accepted" <|
            \_ ->
                let
                    clicks =
                        -- Fill right to left, first putting Winter Tales in the wrong place.
                        [ SelectItem WinterTales, PlaceSelected (ShelfPosition 1) ]
                            ++ List.concatMap (\( i, book ) -> [ SelectItem book, PlaceSelected (ShelfPosition i) ])
                                (List.reverse (List.indexedMap (\i b -> ( i + 1, b )) byHeight))
                in
                List.foldl (\action p -> Tuple.first (Placement.apply Shelf.accepts action p)) Placement.empty clicks
                    |> Shelf.matchedOrder
                    |> Expect.equal (Just ByHeight)
        , test "the height and colour orders agree with the book facts" <|
            \_ ->
                ( Shelf.order ByHeight == List.sortBy Books.height Books.recoverableBooks
                , Shelf.order TallToSmall == List.sortBy (negate << Books.height) Books.recoverableBooks
                , List.map Books.colour (Shelf.order ByColour)
                )
                    |> Expect.equal ( True, True, [ Red, Orange, Yellow, Green, Blue, Violet ] )
        ]
