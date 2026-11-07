module Components.Art exposing (arrows, icon, room)

{-| Inline SVG through the <svg-art> element defined in public/index.html.
Every markup string is built here from fixed text and numbers.
-}

import Html exposing (Html, node)
import Html.Attributes exposing (attribute)


svgArt : String -> Html msg
svgArt markup =
    node "svg-art" [ attribute "markup" markup ] []


{-| The shop. Era colours and props come from [data-era] on an ancestor. -}
room : Html msg
room =
    svgArt "<svg class=\"room\" viewBox=\"0 0 1280 720\" aria-hidden=\"true\"><use href=\"#shop-room\"/></svg>"


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
