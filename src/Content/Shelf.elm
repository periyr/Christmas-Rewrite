module Content.Shelf exposing (matched)

{-| Celebration line once the reopening shelf matches one of the three orders. -}

import Domain exposing (ShelfOrder(..))


matched : ShelfOrder -> String
matched order =
    case order of
        ByHeight ->
            "Small to tall, like steps up a hill. The shelf is ready for the reopening."

        TallToSmall ->
            "Tall to small, like steps down a hill. The shelf is ready for the reopening."

        ByColour ->
            "A rainbow, red to violet, right across the shelf. The shelf is ready for the reopening."

        Alphabetical ->
            "A to Z, neat as a catalogue. The shelf is ready for the reopening."
