module Rules.Shuffle exposing (next, permute, shuffle)

{-| A small seeded shuffle, so a puzzle's pieces can be laid out in a new
order each time the game is played without the core needing elm/random.

The seed is the run seed (model.runSeed), set for every new game and kept in
the save. Same seed, same order, so the layout holds still while one game is
played, survives Continue, and only changes for the next game.

-}


{-| The next number in a simple linear congruential sequence (the classic
Numerical Recipes constants), kept within 32 bits.
-}
next : Int -> Int
next seed =
    modBy 4294967296 (seed * 1664525 + 1013904223)


{-| A Fisher-Yates shuffle driven by `next`. -}
shuffle : Int -> List a -> List a
shuffle seed items =
    let
        go s remaining acc =
            case remaining of
                [] ->
                    List.reverse acc

                _ ->
                    let
                        s2 =
                            next s

                        index =
                            modBy (List.length remaining) (s2 // 65536)

                        picked =
                            List.drop index remaining |> List.head

                        rest =
                            List.take index remaining ++ List.drop (index + 1) remaining
                    in
                    case picked of
                        Just item ->
                            go s2 rest (item :: acc)

                        Nothing ->
                            List.reverse acc ++ remaining
    in
    go (next seed) items []


{-| A shuffle that never gives back the original order, so a list whose
natural order gives away an answer (characters then props, in script order)
always comes out mixed.
-}
permute : Int -> List a -> List a
permute seed items =
    let
        shuffled =
            shuffle seed items
    in
    if shuffled == items && List.length items > 1 then
        List.drop 1 items ++ List.take 1 items

    else
        shuffled
