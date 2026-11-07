module Components.Props exposing (forPhase, forSlide)

{-| The objects each chapter adds to the room, from C's room-* and puppet files.
Every one is placed at A's hotspot for it (Rules.Room.position), at player scale
(2 logical px per unit, ASSETS.md), and stands just behind the walking strip.
What shows follows the phase, the slide and the recorded history only.
-}

import Domain exposing (..)
import Html exposing (Html, div, img)
import Html.Attributes exposing (alt, attribute, class, src, style)
import Rules.Room


{-| In the walking room. -}
forPhase : World -> Phase -> List (Html msg)
forPhase world phase =
    case phase of
        ShadowPuzzle _ ->
            shadowRoom Nothing

        BookMystery _ ->
            [ computer, bookStacks ]

        _ ->
            if world.onlineService == Established then
                [ parcels ]

            else
                []


{-| During a chapter's playback. A successful 1973 performance puts each scene's
recorded character and prop on the lit sheet.
-}
forSlide : Slide -> List (Html msg)
forSlide slide =
    case slide of
        PerformanceSlide _ cast ->
            shadowRoom (Just cast)

        ConsequenceSlide Shadows1973 _ ->
            shadowRoom Nothing

        ServiceFoundedSlide ->
            [ computer, bookStacks, parcelsOnCounter ]

        ConsequenceSlide Search1998 _ ->
            [ computer, bookStacks ]

        _ ->
            []



-- 1973


{-| The bedsheet hung across the window, the box of cut-outs by the door and the
torch on the counter. With a cast, the torch is on and the puppets are up.
-}
shadowRoom : Maybe SceneCast -> List (Html msg)
shadowRoom performing =
    let
        sheetX =
            (Rules.Room.position StageSpot).x

        -- room-story-sheet.svg is 170 x 124 units, its line at the top.
        sheet =
            { left = sheetX - 170, top = 214, width = 340, height = 248 }

        boxX =
            (Rules.Room.position (ClueSpot CutoutBox)).x
    in
    case performing of
        Just cast ->
            -- The beam goes behind the sheet so it lights the sheet, not the puppets.
            [ prop "assets/room-torch-beam.svg" "prop--beam" torchBeam
            , prop "assets/room-story-sheet.svg" "prop--sheet" sheet
            , prop "assets/room-cutout-box.svg" "" (standing boxX 64 56 50.5)
            , prop (puppetFile (CharacterCutout cast.character)) "prop--puppet" { left = sheetX - 150, top = 262, width = 150, height = 150 }
            , prop (puppetFile (PropCutout cast.prop)) "prop--puppet" { left = sheetX + 18, top = 300, width = 96, height = 96 }
            , prop "assets/room-torch.svg" "prop--torch is-on" torch
            ]

        Nothing ->
            [ prop "assets/room-story-sheet.svg" "prop--sheet" sheet
            , prop "assets/room-cutout-box.svg" "" (standing boxX 64 56 50.5)
            , prop "assets/room-torch.svg" "prop--torch" torch
            ]


{-| room-torch.svg is 44 x 18 units with its lens at (42, 9). It lies on the
counter top (y 470). When it is on, CSS props its lens end up by 25 degrees on
its tail, which lifts the lens to about (464, 425).
-}
torch : Box
torch =
    { left = 392, top = 440, width = 88, height = 36 }


{-| room-torch-beam.svg is 240 x 120 units with its origin at (0, 60). The
origin sits on the raised lens and CSS turns the beam up at the sheet.
-}
torchBeam : Box
torchBeam =
    { left = 464, top = 305, width = 480, height = 240 }


puppetFile : Cutout -> String
puppetFile cutout =
    case cutout of
        CharacterCutout Fox ->
            "assets/shadow-fox.svg"

        CharacterCutout Owl ->
            "assets/shadow-owl.svg"

        CharacterCutout Child ->
            "assets/shadow-child.svg"

        PropCutout Lantern ->
            "assets/prop-lantern.svg"

        PropCutout Key ->
            "assets/prop-key.svg"

        PropCutout Book ->
            "assets/prop-book.svg"



-- 1998


{-| The beige computer on the counter where Ruth's email is read. Its base
(y 56 of 58 units) rests on the counter top at y 470.
-}
computer : Html msg
computer =
    let
        x =
            (Rules.Room.position (ClueSpot RuthsEmail)).x
    in
    prop "assets/room-crt-computer.svg" "prop--computer" { left = x - 64, top = 470 - 112, width = 128, height = 116 }


{-| The four candidate books on the floor at the book table spot. -}
bookStacks : Html msg
bookStacks =
    prop "assets/room-book-stacks.svg" "" (standing (Rules.Room.position BookTableSpot).x 80 48 42.5)


{-| Parcels for the online service. In the present they stand in front of the
counter, since the diaries are on it.
-}
parcels : Html msg
parcels =
    prop "assets/room-parcels.svg" "" (standing 300 68 54 52)


{-| In 1998 they wait on the counter beside the computer, above the slide text.
They rest on y 52 of their 54 units.
-}
parcelsOnCounter : Html msg
parcelsOnCounter =
    prop "assets/room-parcels.svg" "" { left = 352, top = 470 - 104, width = 136, height = 108 }



-- PLACING


type alias Box =
    { left : Float, top : Float, width : Float, height : Float }


{-| A floor prop centred on x, at 2 logical px per unit, whose resting line
(in its own units) sits on the floor just behind the walking strip.
-}
standing : Float -> Float -> Float -> Float -> Box
standing x width height restsOn =
    { left = x - width, top = floorBehindStrip - 2 * restsOn, width = 2 * width, height = 2 * height }


{-| The painted floor directly behind the strip that starts at y 640. -}
floorBehindStrip : Float
floorBehindStrip =
    636


prop : String -> String -> Box -> Html msg
prop file extraClass box =
    div
        [ class ("prop " ++ extraClass)
        , attribute "aria-hidden" "true"
        , style "left" (rem box.left)
        , style "top" (rem box.top)
        , style "width" (rem box.width)
        , style "height" (rem box.height)
        ]
        [ img [ src file, alt "" ] [] ]


rem : Float -> String
rem logical =
    String.fromFloat (logical / 16) ++ "rem"
