module Components.Placement exposing (Config, dragSource, dropTarget, group, slot, tray)

{-| Click-to-select, click-to-place, shared by salvage, the repair board, the
shelf and the shadow stage. Pieces can also be dragged with the mouse: picking
one up selects it, and letting go over a space places it, exactly as the two
clicks would. It only dispatches actions: the arrangement lives in the model
and Rules.Placement decides what each action does. No puzzle answers in here.

Every legal target looks the same, so selecting an item reveals nothing.

-}

import Domain exposing (Placement, PlacementAction(..))
import Html exposing (Html, button, div, section, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled, draggable, type_)
import Html.Events exposing (on, onClick, preventDefaultOn)
import Json.Decode as Decode
import Rules.Placement


type alias Config item slotId msg =
    { toMsg : PlacementAction item slotId -> msg
    , enabled : Bool
    , placement : Placement item slotId
    , items : List item
    , name : item -> String
    , cardClass : item -> String
    , cardBody : item -> List (Html msg)
    , marks : item -> List String
    }


{-| A single space. Clicking it while holding another item swaps them, or sends
the occupant back to the tray if the held item came from the tray.
-}
slot : Config item slotId msg -> String -> slotId -> Html msg
slot config label target =
    case Rules.Placement.itemIn target config.placement of
        Nothing ->
            emptySpace config label (PlaceSelected target)

        Just occupant ->
            if holdingOther config occupant then
                filled config (Just "Swap") (PlaceSelected target) (Just (PlaceSelected target)) occupant

            else
                filled config Nothing (SelectItem occupant) (Just (PlaceSelected target)) occupant


{-| A space inside a grouped target such as a crate. An empty space fills the
group's first free space; an occupant is simply picked up.
-}
group : Config item slotId msg -> String -> List slotId -> slotId -> Html msg
group config label slots target =
    case Rules.Placement.itemIn target config.placement of
        Nothing ->
            emptySpace config label (PlaceSelectedInGroup slots)

        Just occupant ->
            filled config Nothing (SelectItem occupant) (Just (PlaceSelectedInGroup slots)) occupant


{-| Items not on the board. Positions stay fixed, so nothing jumps when one
leaves, and they double as the target for sending a placed item back.
-}
tray : Config item slotId msg -> Html msg
tray config =
    let
        isPlaced item =
            Rules.Placement.slotOf item config.placement /= Nothing

        isTarget =
            config.enabled
                && (config.placement.selected |> Maybe.map isPlaced |> Maybe.withDefault False)

        position item =
            if isPlaced item then
                div [ class "slot" ]
                    [ button
                        [ type_ "button"
                        , class "slot__empty"
                        , attribute "aria-label" "Tray space"
                        , disabled (not isTarget)
                        , onClick (config.toMsg ReturnSelectedToTray)
                        ]
                        [ text
                            (if isTarget then
                                "Back to tray"

                             else
                                ""
                            )
                        ]
                    ]

            else
                filled config Nothing (SelectItem item) Nothing item

        -- Letting a dragged piece go anywhere on the tray sends it back there
        -- (or, if it came from the tray, just puts it down again).
        trayDrop =
            if isTarget then
                ReturnSelectedToTray

            else
                ClearSelection
    in
    section
        ([ classList [ ( "tray", True ), ( "is-target", isTarget ) ], attribute "aria-label" "Tray" ]
            ++ dropTarget config.enabled (config.toMsg trayDrop)
        )
        [ span [ class "tray__label" ] [ text "Tray" ]
        , div [ class "tray__slots" ] (List.map position config.items)
        ]


holdingOther : Config item slotId msg -> item -> Bool
holdingOther config occupant =
    case config.placement.selected of
        Just held ->
            config.enabled && held /= occupant

        Nothing ->
            False


emptySpace : Config item slotId msg -> String -> PlacementAction item slotId -> Html msg
emptySpace config label action =
    let
        canPlace =
            config.enabled && config.placement.selected /= Nothing
    in
    div ([ classList [ ( "slot", True ), ( "is-target", canPlace ) ] ] ++ dropTarget config.enabled (config.toMsg action))
        [ button
            [ type_ "button"
            , class "slot__empty"
            , attribute "aria-label" (label ++ ": empty")
            , disabled (not config.enabled)
            , onClick (config.toMsg action)
            ]
            [ text
                (if canPlace then
                    "Place here"

                 else
                    "Empty"
                )
            ]
        ]


filled : Config item slotId msg -> Maybe String -> PlacementAction item slotId -> Maybe (PlacementAction item slotId) -> item -> Html msg
filled config hint action dropAction item =
    let
        isSelected =
            config.placement.selected == Just item

        marks =
            config.marks item

        hintTag =
            case hint of
                Just words ->
                    [ span [ class "slot__hint" ] [ text words ] ]

                Nothing ->
                    []

        selectedTag =
            if isSelected then
                [ span [ class "book__selected-tag" ] [ text "Selected" ] ]

            else
                []
    in
    div
        ([ classList
            [ ( "slot", True )
            , ( "is-target", hint /= Nothing )
            , ( "is-flagged", not (List.isEmpty marks) )
            ]
         ]
            ++ (case dropAction of
                    Just dropped ->
                        dropTarget config.enabled (config.toMsg dropped)

                    Nothing ->
                        []
               )
        )
        (button
            ([ type_ "button"
            , classList [ ( "book", True ), ( config.cardClass item, True ), ( "is-selected", isSelected ) ]
            , attribute "aria-pressed"
                (if isSelected then
                    "true"

                 else
                    "false"
                )
            , attribute "aria-label" (config.name item)
             , disabled (not config.enabled)
             , onClick (config.toMsg action)
             ]
                ++ dragSource config.enabled
                    (if isSelected then
                        Nothing

                     else
                        Just (config.toMsg (SelectItem item))
                    )
            )
            (config.cardBody item ++ selectedTag)
            :: hintTag
            ++ List.map (\mark -> span [ class "mark" ] [ text mark ]) marks
        )



-- ═══════════════════════════════════════════════════════════════════════
-- DRAGGING
-- ═══════════════════════════════════════════════════════════════════════


{-| A piece that can be dragged. Picking it up selects it (nothing to send if
it is already selected, since selecting it again would put it down).
public/index.html gives every drag the data Firefox needs to start one.
-}
dragSource : Bool -> Maybe msg -> List (Html.Attribute msg)
dragSource enabled pickUp =
    if enabled then
        draggable "true"
            :: (case pickUp of
                    Just msg ->
                        [ on "dragstart" (Decode.succeed msg) ]

                    Nothing ->
                        []
               )

    else
        []


{-| A place a dragged piece can be let go. public/index.html lets a drag hover
over any element marked data-drop; letting go sends the message, and the
browser's own handling of the drop (opening it as a link) is stopped.
-}
dropTarget : Bool -> msg -> List (Html.Attribute msg)
dropTarget enabled drop =
    if enabled then
        [ attribute "data-drop" ""
        , preventDefaultOn "drop" (Decode.succeed ( drop, True ))
        ]

    else
        []
