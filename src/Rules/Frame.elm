module Rules.Frame exposing (accepts, gaps, isSolved, shards)

{-| 1973, after the performance: in the dark, the family photograph fell and
its glass broke. Fit the nine pieces back into the frame (contract v1.7).

Like the 1950 warm-ups: unlimited moves, never spends attempts. Each piece has
its own shape, so it only fits its own gap (anything else is DoesNotFitThere).

-}

import Domain exposing (FrameGap(..), Placement, Shard(..))


count : Int
count =
    9


shards : List Shard
shards =
    List.map Shard (List.range 1 count)


gaps : List FrameGap
gaps =
    List.map FrameGap (List.range 1 count)


accepts : Shard -> FrameGap -> Bool
accepts (Shard piece) (FrameGap gap) =
    piece == gap && piece >= 1 && piece <= count


{-| Every piece is in its own gap. -}
isSolved : Placement Shard FrameGap -> Bool
isSolved placement =
    List.all (\(Shard n) -> List.member ( Shard n, FrameGap n ) placement.placed) shards
        && List.length placement.placed
        == count
