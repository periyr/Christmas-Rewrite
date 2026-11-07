module Views.Labels exposing (eraYear)

{-| Short interface labels for IDs. Fixed names, not story text. -}

import Domain exposing (Era(..))


eraYear : Era -> String
eraYear era =
    case era of
        Repairs1950 ->
            "1950"

        Shadows1973 ->
            "1973"

        Search1998 ->
            "1998"
