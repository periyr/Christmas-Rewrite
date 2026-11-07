module Views.Labels exposing (dayName, eraYear)

{-| Short interface labels for IDs. Fixed names, not story text. -}

import Domain exposing (Day(..), Era(..))


dayName : Day -> String
dayName day =
    case day of
        Monday ->
            "Monday"

        Tuesday ->
            "Tuesday"

        Wednesday ->
            "Wednesday"

        Thursday ->
            "Thursday"

        Friday ->
            "Friday"


eraYear : Era -> String
eraYear era =
    case era of
        Repairs1950 ->
            "1950"

        Shadows1973 ->
            "1973"

        Search1998 ->
            "1998"
