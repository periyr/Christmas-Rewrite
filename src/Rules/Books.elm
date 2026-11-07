module Rules.Books exposing (allBooks, colour, condition, height, recoverableBooks)

{-| Fixed facts about the 1950 books (brief section 4A).

Height and cover colour are needed both to draw the six recoverable books and
to judge the shelf. The three ruined books have no rule-relevant height or
colour; how they look is a presentation choice.

-}

import Domain exposing (BookId(..), Condition(..), CoverColour(..), RecoverableBook(..), RuinedBook(..))


recoverableBooks : List RecoverableBook
recoverableBooks =
    [ AtlasOfSmallPlaces, BirdsongForBeginners, GardensInWinter, LettersFromTheSea, PocketOfWonders, WinterTales ]


allBooks : List BookId
allBooks =
    List.map Recoverable recoverableBooks
        ++ List.map Ruined [ HarbourTales, MountainPaths, WinterAlmanac ]


condition : BookId -> Condition
condition book =
    case book of
        Recoverable AtlasOfSmallPlaces ->
            Fine

        Recoverable BirdsongForBeginners ->
            NeedsRepair

        Recoverable GardensInWinter ->
            NeedsRepair

        Recoverable LettersFromTheSea ->
            NeedsRepair

        Recoverable PocketOfWonders ->
            Fine

        Recoverable WinterTales ->
            Fine

        Ruined _ ->
            TooFarGone


{-| Height rank, 1 = shortest, 6 = tallest. -}
height : RecoverableBook -> Int
height book =
    case book of
        BirdsongForBeginners ->
            1

        GardensInWinter ->
            2

        PocketOfWonders ->
            3

        AtlasOfSmallPlaces ->
            4

        LettersFromTheSea ->
            5

        WinterTales ->
            6


colour : RecoverableBook -> CoverColour
colour book =
    case book of
        AtlasOfSmallPlaces ->
            Blue

        BirdsongForBeginners ->
            Yellow

        GardensInWinter ->
            Violet

        LettersFromTheSea ->
            Orange

        PocketOfWonders ->
            Green

        WinterTales ->
            Red
