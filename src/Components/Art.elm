module Components.Art exposing (arrows, bookCover, diaryCover, icon, room)

{-| The game's pictures. Room photos and C's covers are plain files in
public/assets. Inline SVG goes through the <svg-art> element defined in
public/index.html, and every markup string is built here from fixed text and
numbers.
-}

import Domain exposing (BookId(..), Damage(..), Era(..), RecoverableBook(..), RuinedBook(..))
import Html exposing (Html, div, img, node, span)
import Html.Attributes exposing (alt, attribute, class, src)


svgArt : String -> Html msg
svgArt markup =
    node "svg-art" [ attribute "markup" markup ] []


{-| The shop. CSS picks the picture from [data-era] on an ancestor. The overlay
adds what changes inside a room: the stain, the rubble and the clock's hands.
-}
room : Html msg
room =
    div [ class "room-art" ]
        [ svgArt "<svg class=\"room\" viewBox=\"0 0 1280 720\" aria-hidden=\"true\"><use href=\"#room-overlays\"/></svg>" ]


{-| A book cover with any damage overlays on top. Bottoms line up when the
caller gives every cover the same width, which shows the heights.
-}
bookCover : BookId -> List Damage -> Html msg
bookCover book damage =
    span [ class "book__art" ]
        (img [ class "book__cover", src ("assets/book-" ++ bookFile book ++ ".svg"), alt "" ] []
            :: List.map
                (\mark -> img [ class "book__overlay", src ("assets/damage-" ++ damageFile mark ++ ".svg"), alt "" ] [])
                damage
        )


bookFile : BookId -> String
bookFile book =
    case book of
        Recoverable AtlasOfSmallPlaces ->
            "atlas-of-small-places"

        Recoverable BirdsongForBeginners ->
            "birdsong-for-beginners"

        Recoverable GardensInWinter ->
            "gardens-in-winter"

        Recoverable LettersFromTheSea ->
            "letters-from-the-sea"

        Recoverable PocketOfWonders ->
            "pocket-of-wonders"

        Recoverable WinterTales ->
            "winter-tales"

        Ruined HarbourTales ->
            "harbour-tales"

        Ruined MountainPaths ->
            "mountain-paths"

        Ruined WinterAlmanac ->
            "winter-almanac"


damageFile : Damage -> String
damageFile damage =
    case damage of
        ScorchedEdges ->
            "scorched-edges"

        WaterStains ->
            "water-stains"

        SmokeStains ->
            "smoke-stains"

        MissingPages ->
            "missing-pages"


diaryCover : Era -> Html msg
diaryCover era =
    img
        [ class "diary__cover"
        , src
            (case era of
                Repairs1950 ->
                    "assets/diary-walter-1950.svg"

                Shadows1973 ->
                    "assets/diary-henry-1973.svg"

                Search1998 ->
                    "assets/diary-edwin-1998.svg"
            )
        , alt ""
        ]
        []


icon : String -> Html msg
icon name =
    svgArt ("<svg class=\"book__icon\" viewBox=\"0 0 24 24\" aria-hidden=\"true\"><use href=\"#i-" ++ name ++ "\"/></svg>")


{-| Prerequisite arrows over the cork board, from one day column to another.
Columns count from 0. The coordinates are the cork's size in tenths of a rem.
-}
arrows : List ( Int, Int ) -> Html msg
arrows pairs =
    let
        centre column =
            69 + (107.5 * toFloat column)

        num =
            String.fromFloat

        arrow ( from, to ) =
            let
                x1 =
                    num (centre from)

                x2 =
                    centre to
            in
            "<path d=\"M"
                ++ x1
                ++ " 122 C "
                ++ x1
                ++ " 140, "
                ++ num x2
                ++ " 140, "
                ++ num x2
                ++ " 128\"/><polygon class=\"arrow-head\" points=\""
                ++ num x2
                ++ ",119 "
                ++ num (x2 - 6)
                ++ ",130 "
                ++ num (x2 + 6)
                ++ ",130\"/>"
    in
    svgArt ("<svg class=\"board-arrows\" viewBox=\"0 0 568 275.5\" aria-hidden=\"true\">" ++ String.concat (List.map arrow pairs) ++ "</svg>")
