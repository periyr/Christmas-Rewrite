module Content.Frame exposing (arrival, help, hint, mended, notice, pieceName, title)

{-| 1973, after the performance: the broken family photograph (contract v1.7).
In the dark, Henry bumps the wall, the frame falls and its glass breaks. He
fits the pieces back together before going home.
-}

import Domain exposing (Notice(..), Shard(..))


title : String
title =
    "The Broken Frame"


{-| The line under the room while the glass is on the floor. -}
arrival : String
arrival =
    "In the dark after the show, Henry bumps the wall. The family photograph falls and its glass breaks."


help : List String
help =
    [ "Click a piece of glass to pick it up, then click the gap in the frame where it fits."
    , "Every piece has its own shape and size, so it fits only one gap. Try as often as you like: it never costs an attempt."
    ]


{-| What to do next, from what is held and how many pieces are in. -}
hint : Maybe Shard -> Int -> String
hint selected placedCount =
    case selected of
        Just _ ->
            "Now click the gap this piece fits."

        Nothing ->
            if placedCount == 0 then
                "Click a piece of glass, then click where it fits in the frame."

            else
                "Good. Pick up the next piece."


{-| Shown when the glass is whole again. -}
mended : String
mended =
    "The glass is whole again. A few strips of tape will hold it."


{-| Neutral feedback, in the frame's own words. -}
notice : Notice -> String
notice which =
    case which of
        DoesNotFitThere ->
            "That piece is the wrong shape for that gap."

        NotSolvedYet ->
            "Some pieces are still on the floor."

        TargetFull ->
            "That gap is already filled."

        IncompleteSubmission ->
            "Some pieces are still on the floor."


pieceName : Shard -> String
pieceName (Shard n) =
    "Piece of glass " ++ String.fromInt n
