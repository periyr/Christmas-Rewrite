module Content.Books exposing (book)

{-| Salvage book titles and visible damage. Damage lists match the agreed
table in public/assets/ASSETS.md: smoke or water can be repaired, scorching
or missing pages cannot. Condition itself lives in Rules.Books.condition.
-}

import Domain exposing (BookContent, BookId(..), Damage(..), RecoverableBook(..), RuinedBook(..))


book : BookId -> BookContent
book bookId =
    case bookId of
        Recoverable AtlasOfSmallPlaces ->
            { title = "Atlas of Small Places", damage = [] }

        Recoverable BirdsongForBeginners ->
            { title = "Birdsong for Beginners", damage = [ SmokeStains ] }

        Recoverable GardensInWinter ->
            { title = "Gardens in Winter", damage = [ WaterStains ] }

        Recoverable LettersFromTheSea ->
            { title = "Letters from the Sea", damage = [ WaterStains, SmokeStains ] }

        Recoverable PocketOfWonders ->
            { title = "Pocket of Wonders", damage = [] }

        Recoverable WinterTales ->
            { title = "Winter Tales", damage = [] }

        Ruined HarbourTales ->
            { title = "Harbour Tales", damage = [ ScorchedEdges, MissingPages ] }

        Ruined MountainPaths ->
            { title = "Mountain Paths", damage = [ ScorchedEdges ] }

        Ruined WinterAlmanac ->
            { title = "Winter Almanac", damage = [ MissingPages, WaterStains ] }
