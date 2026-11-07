module Views.Room exposing (Scene, emptyScene, view)

{-| The walking room: the shop, the player, the hotspots and whichever panel is
open. Positions, reach and what is usable all come from Rules.Room. Nothing here
stores a position or moves anyone: clicks only send A's messages.
-}

import Components.Actor as Actor
import Components.Art as Art
import Components.Props as Props
import Content.Room
import Domain exposing (..)
import Html exposing (Html, button, div, p, span, text)
import Html.Attributes exposing (attribute, class, classList, style, type_)
import Html.Events exposing (onClick)
import Rules.Room
import Views.Labels exposing (eraYear)


{-| What a phase adds to the room. `behind` is on the furniture, so the player
walks in front of it. `front` is narration. `line` sits with the walking hint.
-}
type alias Scene =
    { behind : List (Html Msg)
    , front : List (Html Msg)
    , line : Maybe String
    , panel : List (Html Msg)
    }


emptyScene : Scene
emptyScene =
    { behind = [], front = [], line = Nothing, panel = [] }


view : World -> Model -> Scene -> List (Html Msg)
view world model scene =
    Art.room
        :: Props.forPhase world model.phase
        ++ scene.behind
        ++ [ Actor.view (person model.phase) model.room.player
           , hotspots world model
           , bottomBar model scene.line
           ]
        ++ scene.front
        ++ (if model.room.panelOpen then
                [ div [ class "panel" ] scene.panel ]

            else
                []
           )


{-| The year the room is in, for the corner badge. -}
yearLabel : Phase -> String
yearLabel phase =
    case phase of
        Salvage _ ->
            eraYear Repairs1950

        RepairBoard _ ->
            eraYear Repairs1950

        ReopeningShelf _ ->
            eraYear Repairs1950

        ShadowPuzzle _ ->
            eraYear Shadows1973

        BookMystery _ ->
            eraYear Search1998

        _ ->
            "Present day"


person : Phase -> Actor.Person
person phase =
    case phase of
        Salvage _ ->
            Actor.Walter

        RepairBoard _ ->
            Actor.Walter

        ReopeningShelf _ ->
            Actor.Walter

        ShadowPuzzle _ ->
            Actor.Henry

        BookMystery _ ->
            Actor.EdwinYoung

        _ ->
            Actor.EdwinPresent


{-| Hidden whenever walking is paused, so nothing under a panel or clue can be
reached with Tab. The wrapper stays, so the page's structure doesn't jump.
-}
hotspots : World -> Model -> Html Msg
hotspots world model =
    let
        near =
            Rules.Room.nearby model

        shown =
            if Rules.Room.canWalk model then
                List.filter (isShown world near) (Rules.Room.hotspots model.phase)

            else
                []
    in
    div [ class "room-hotspots" ]
        (List.map (\spot -> hotspot (near == Just spot) spot) shown
            ++ [ p [ class "visually-hidden", attribute "role" "status" ]
                    [ text (Maybe.withDefault "" (Maybe.map (\spot -> "Press E: " ++ Content.Room.label spot) near)) ]
               ]
        )


{-| The diaries on the counter already mark the diary spot, so its label only
appears as the prompt, and only while a diary is waiting to be opened.
-}
isShown : World -> Maybe Hotspot -> Hotspot -> Bool
isShown world near spot =
    case spot of
        DiarySpot ->
            near == Just DiarySpot && world.nextDiary /= Nothing

        _ ->
            True


{-| A label on the object. Within reach it becomes the proximity prompt, with
the E key showing, and sits above the player's head so it never covers the face.
Clicking always sends the player there to use it.
-}
hotspot : Bool -> Hotspot -> Html Msg
hotspot isNear spot =
    let
        anchor =
            Rules.Room.position spot

        ( left, top ) =
            if isNear then
                -- 112 and 1168 keep the wider prompt inside the room.
                ( clamp 112 1168 anchor.x, min anchor.y 335 )

            else
                ( anchor.x, anchor.y )
    in
    button
        [ type_ "button"
        , classList [ ( "hotspot", True ), ( "is-near", isNear ) ]
        , style "left" (String.fromFloat (left / 16) ++ "rem")
        , style "top" (String.fromFloat (top / 16) ++ "rem")
        , onClick (ApproachHotspot spot)
        ]
        ((if isNear then
            [ span [ class "hotspot__key", attribute "aria-hidden" "true" ] [ text "E" ] ]

          else
            []
         )
            ++ [ span [] [ text (Content.Room.label spot) ] ]
        )


{-| Only in rooms the player can walk around, and not under a panel (which shows
its own year). Starts with the year the room is in.
-}
bottomBar : Model -> Maybe String -> Html Msg
bottomBar model line =
    if List.isEmpty (Rules.Room.hotspots model.phase) || model.room.panelOpen then
        text ""

    else
        div [ class "room-bar" ]
            [ span [ class "era-tag room-bar__year" ] [ text (yearLabel model.phase) ]
            , div [ class "room-bar__text" ]
                ((case line of
                    Just words ->
                        [ p [ class "room-bar__line" ] [ text words ] ]

                    Nothing ->
                        []
                 )
                    ++ [ p [ class "room-bar__hint" ] [ text "A/D or ←/→ to walk · E to use · or click a label" ] ]
                )
            ]
