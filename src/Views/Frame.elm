module Views.Frame exposing (view)

{-| 1973, after the performance: fit the broken glass back into the family
photograph's frame (contract v1.7).

The frame is on the left, the pieces lie on the bench on the right. Click a
piece, then the gap it fits. A piece only fits its own gap (Rules.Frame), so a
placed piece is always in the right place and stays there.

Every piece and gap is a button clipped to its own shape, so only the glass
itself can be clicked. The drawing is inline SVG through <svg-art>, built here
from fixed numbers only.

-}

import Content.Frame
import Domain exposing (..)
import Html exposing (Html, aside, button, div, node, p, section, span, text)
import Html.Attributes exposing (attribute, class, classList, style, type_)
import Html.Events exposing (onClick)
import Rules.Frame
import Rules.Shuffle as Shuffle
import Rules.Placement as Placement
import Views.Common as Common


view : Int -> Placement Shard FrameGap -> Maybe Notice -> List (Html Msg)
view seed placement notice =
    let
        solved =
            Rules.Frame.isSolved placement

        layout =
            benchLayout seed
    in
    [ div [ class "board-scene frame-scene" ]
        [ Common.topbar "1973"
            Content.Frame.title
            (Common.helpButton "Back to the frame" Content.Frame.help ++ [ Common.closePanel True ])
        , section [ class "frame-bench", attribute "aria-label" "The frame and the broken glass" ]
            (frame placement :: List.filterMap (benchPiece layout placement) Rules.Frame.shards)
        , aside [ class "side" ]
            [ if solved then
                p [ class "celebration", attribute "role" "status" ] [ text Content.Frame.mended ]

              else
                case notice of
                    Just which ->
                        p [ class "status", attribute "role" "status" ]
                            [ span [] [ text (Content.Frame.notice which) ]
                            , button [ type_ "button", class "status__dismiss", attribute "aria-label" "Dismiss message", onClick DismissNotice ] [ text "×" ]
                            ]

                    Nothing ->
                        p [ class "status", attribute "role" "status" ]
                            [ span [] [ text (Content.Frame.hint placement.selected (List.length placement.placed)) ] ]
            , Common.primaryButton [ onClick Advance ] "Hang it back up"
            ]
        ]
    ]



-- THE FRAME


{-| The photo with its gaps. Empty gaps are dark and can be clicked; a piece
put back shows as glass with its cracks.
-}
frame : Placement Shard FrameGap -> Html Msg
frame placement =
    let
        filled n =
            Placement.itemIn (FrameGap n) placement /= Nothing

        drawing =
            "<svg class=\"frame__glass\" viewBox=\"0 0 480 330\" aria-hidden=\"true\">"
                ++ String.concat
                    (List.map
                        (\( n, points ) ->
                            if filled n then
                                "<polygon class=\"glass glass--placed\" points=\"" ++ pointsAttr points ++ "\"/>"

                            else
                                "<polygon class=\"glass glass--gap\" points=\"" ++ pointsAttr points ++ "\"/>"
                        )
                        pieces
                    )
                ++ "</svg>"

        gap ( n, points ) =
            if filled n then
                Nothing

            else
                Just
                    (button
                        (type_ "button"
                            :: class "frame__gap"
                            :: attribute "aria-label" ("Gap " ++ String.fromInt n ++ " in the frame")
                            :: onClick (FrameMove (PlaceSelected (FrameGap n)))
                            :: shapeStyle percentOfPhoto points
                        )
                        []
                    )
    in
    div [ class "frame" ]
        [ div [ class "frame__photo" ]
            (svgArt drawing :: List.filterMap gap pieces)
        ]



-- THE BENCH


{-| A piece still on the bench, at its own spot. Held, it is outlined. -}
benchPiece : List ( Int, ( Float, Float ) ) -> Placement Shard FrameGap -> Shard -> Maybe (Html Msg)
benchPiece layout placement shard =
    let
        (Shard n) =
            shard

        isHeld =
            placement.selected == Just shard
    in
    case ( Placement.slotOf shard placement, lookup n pieces, lookup n layout ) of
        ( Nothing, Just points, Just ( left, top ) ) ->
            let
                box =
                    bounds points

                drawing =
                    "<svg viewBox=\""
                        ++ String.join " " (List.map String.fromFloat [ box.minX - 3, box.minY - 3, box.width + 6, box.height + 6 ])
                        ++ "\" aria-hidden=\"true\"><polygon class=\"glass glass--loose\" points=\""
                        ++ pointsAttr points
                        ++ "\"/><polyline class=\"glass__shine\" points=\""
                        ++ shine box
                        ++ "\"/></svg>"
            in
            Just
                (button
                    [ type_ "button"
                    , classList [ ( "frame__piece", True ), ( "is-held", isHeld ) ]
                    , attribute "aria-label" (Content.Frame.pieceName shard)
                    , attribute "aria-pressed"
                        (if isHeld then
                            "true"

                         else
                            "false"
                        )
                    , style "left" (rem left)
                    , style "top" (rem top)
                    , style "width" (rem ((box.width + 6) * scale))
                    , style "height" (rem ((box.height + 6) * scale))
                    , style "clip-path" (clipTo { box | minX = box.minX - 3, minY = box.minY - 3, width = box.width + 6, height = box.height + 6 } points)
                    , onClick (FrameMove (SelectItem shard))
                    ]
                    [ svgArt drawing ]
                )

        _ ->
            Nothing


{-| A short white glint across the top left of a piece. -}
shine : { minX : Float, minY : Float, width : Float, height : Float } -> String
shine box =
    let
        x =
            box.minX + box.width * 0.42

        y =
            box.minY + box.height * 0.42
    in
    String.join " " (List.map String.fromFloat [ x - 14, y + 6, x, y, x + 14, y - 6 ])



-- GEOMETRY


{-| The nine pieces of glass, in photo units (the photo is 480 x 330). They
meet at the point the glass hit the floor, near (300, 150). Same numbers as
docs/asset-sources/family-photo.mjs, whose taped glass follows these cracks.
-}
pieces : List ( Int, List ( Float, Float ) )
pieces =
    [ ( 1, [ ( 237, 105 ), ( 90, 0 ), ( 260, 0 ), ( 291, 117 ) ] )
    , ( 2, [ ( 291, 117 ), ( 260, 0 ), ( 480, 0 ), ( 480, 90 ), ( 350, 133 ) ] )
    , ( 3, [ ( 350, 133 ), ( 480, 90 ), ( 480, 280 ), ( 336, 176 ) ] )
    , ( 4, [ ( 336, 176 ), ( 480, 280 ), ( 480, 330 ), ( 330, 330 ), ( 309, 204 ) ] )
    , ( 5, [ ( 309, 204 ), ( 330, 330 ), ( 120, 330 ), ( 255, 195 ) ] )
    , ( 6, [ ( 255, 195 ), ( 120, 330 ), ( 0, 330 ), ( 0, 250 ), ( 246, 168 ) ] )
    , ( 7, [ ( 246, 168 ), ( 0, 250 ), ( 0, 60 ), ( 219, 126 ) ] )
    , ( 8, [ ( 219, 126 ), ( 0, 60 ), ( 0, 0 ), ( 90, 0 ), ( 237, 105 ) ] )
    , ( 9, [ ( 237, 105 ), ( 291, 117 ), ( 350, 133 ), ( 336, 176 ), ( 309, 204 ), ( 255, 195 ), ( 246, 168 ), ( 219, 126 ) ] )
    ]


{-| The bench spots (top left, in rem) and the hand-made way of filling them,
mixed up so neighbours in the frame are not neighbours here. Each game deals
the pieces out to these spots in a new order (benchLayout); this one is the
fallback.
-}
benchSpots : List ( Int, ( Float, Float ) )
benchSpots =
    [ ( 1, ( 2, 1 ) )
    , ( 9, ( 18, 1.5 ) )
    , ( 5, ( 6, 31.8 ) )
    , ( 6, ( 32, 0.8 ) )
    , ( 8, ( 32, 11.5 ) )
    , ( 7, ( 32.5, 21.5 ) )
    , ( 3, ( 49.5, 1.5 ) )
    , ( 4, ( 47.5, 15.5 ) )
    , ( 2, ( 45, 30 ) )
    ]


{-| Which piece lies at which bench spot this game. The pieces are dealt to the
spots in a seeded random order, keeping only deals where every piece stays on
the bench, clear of the frame, and overlaps its neighbours no more than the
hand-made layout does (pieces are cut to shape, so their boxes may touch).
-}
benchLayout : Int -> List ( Int, ( Float, Float ) )
benchLayout seed =
    let
        spots =
            List.map Tuple.second benchSpots

        -- Biggest pieces first, so the search settles quickly.
        order =
            List.sortBy (\( n, _ ) -> negate (area n)) pieces |> List.map Tuple.first

        area n =
            let
                ( w, h ) =
                    pieceSize n
            in
            w * h

        deal salt remaining free placed =
            case remaining of
                [] ->
                    Just (List.reverse placed)

                n :: rest ->
                    tryEach n rest free placed (Shuffle.shuffle (salt + n * 7919) free) salt

        tryEach n rest free placed candidates salt =
            case candidates of
                [] ->
                    Nothing

                spot :: others ->
                    if fits n spot placed then
                        case deal (Shuffle.next salt) rest (List.filter ((/=) spot) free) (( n, spot ) :: placed) of
                            Just layout ->
                                Just layout

                            Nothing ->
                                tryEach n rest free placed others salt

                    else
                        tryEach n rest free placed others salt
    in
    deal seed order spots [] |> Maybe.withDefault benchSpots


{-| The bench limits, the frame's box on it, and the most two pieces' boxes
overlap in the hand-made layout (in rem and square rem).
-}
benchWidth : Float
benchWidth =
    58.4


benchHeight : Float
benchHeight =
    40.2


frameBox : Box
frameBox =
    { left = 1, top = 9, right = 31.1, bottom = 30.7 }


allowedOverlap : Float
allowedOverlap =
    4.3


type alias Box =
    { left : Float, top : Float, right : Float, bottom : Float }


pieceSize : Int -> ( Float, Float )
pieceSize n =
    case lookup n pieces of
        Just points ->
            let
                box =
                    bounds points
            in
            ( (box.width + 6) * scale, (box.height + 6) * scale )

        Nothing ->
            ( 0, 0 )


boxAt : Int -> ( Float, Float ) -> Box
boxAt n ( left, top ) =
    let
        ( w, h ) =
            pieceSize n
    in
    { left = left, top = top, right = left + w, bottom = top + h }


overlap : Box -> Box -> Float
overlap a b =
    max 0 (min a.right b.right - max a.left b.left) * max 0 (min a.bottom b.bottom - max a.top b.top)


fits : Int -> ( Float, Float ) -> List ( Int, ( Float, Float ) ) -> Bool
fits n spot placed =
    let
        box =
            boxAt n spot
    in
    box.right <= benchWidth
        && box.bottom <= benchHeight
        && overlap box frameBox == 0
        && List.all (\( m, other ) -> overlap box (boxAt m other) <= allowedOverlap) placed


{-| rem per photo unit: the photo is drawn 480 x 330 units at 27 x 18.5625 rem. -}
scale : Float
scale =
    27 / 480


bounds : List ( Float, Float ) -> { minX : Float, minY : Float, width : Float, height : Float }
bounds points =
    let
        xs =
            List.map Tuple.first points

        ys =
            List.map Tuple.second points

        lo =
            Maybe.withDefault 0 << List.minimum

        hi =
            Maybe.withDefault 0 << List.maximum
    in
    { minX = lo xs, minY = lo ys, width = hi xs - lo xs, height = hi ys - lo ys }


{-| Place a gap over the photo (in % of it) and clip it to its shape. -}
shapeStyle : (List ( Float, Float ) -> { left : Float, top : Float, width : Float, height : Float }) -> List ( Float, Float ) -> List (Html.Attribute msg)
shapeStyle place points =
    let
        spot =
            place points
    in
    [ style "left" (percent spot.left)
    , style "top" (percent spot.top)
    , style "width" (percent spot.width)
    , style "height" (percent spot.height)
    , style "clip-path" (clipTo (bounds points) points)
    ]


{-| A CSS clip-path for a shape, in % of the box it is drawn in. -}
clipTo : { minX : Float, minY : Float, width : Float, height : Float } -> List ( Float, Float ) -> String
clipTo box points =
    let
        relative ( x, y ) =
            percent ((x - box.minX) / box.width) ++ " " ++ percent ((y - box.minY) / box.height)
    in
    "polygon(" ++ String.join ", " (List.map relative points) ++ ")"


percentOfPhoto : List ( Float, Float ) -> { left : Float, top : Float, width : Float, height : Float }
percentOfPhoto points =
    let
        box =
            bounds points
    in
    { left = box.minX / 480, top = box.minY / 330, width = box.width / 480, height = box.height / 330 }


pointsAttr : List ( Float, Float ) -> String
pointsAttr points =
    String.join " " (List.map (\( x, y ) -> String.fromFloat x ++ "," ++ String.fromFloat y) points)


lookup : Int -> List ( Int, a ) -> Maybe a
lookup n list =
    list |> List.filter (\( k, _ ) -> k == n) |> List.head |> Maybe.map Tuple.second


percent : Float -> String
percent fraction =
    String.fromFloat (fraction * 100) ++ "%"


rem : Float -> String
rem value =
    String.fromFloat value ++ "rem"


svgArt : String -> Html msg
svgArt markup =
    node "svg-art" [ attribute "markup" markup ] []
