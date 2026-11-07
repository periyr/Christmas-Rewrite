module Components.Placement exposing (Config, group, slot, tray)

{-| Click-to-select, click-to-place, shared by salvage, the repair board and
the shelf. It only dispatches actions: the arrangement lives in the model and
Rules.Placement decides what each action does. No puzzle answers in here.

Every legal target looks the same, so selecting an item reveals nothing.

-}

import Domain exposing (Placement, PlacementAction(..))
import Html exposing (Html, button, div, section, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled, type_)
import Html.Events exposing (onClick)
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
                filled config (Just "Swap") (PlaceSelected target) occupant

            else
                filled config Nothing (SelectItem occupant) occupant


{-| A space inside a grouped target such as a crate. An empty space fills the
group's first free space; an occupant is simply picked up.
-}
group : Config item slotId msg -> String -> List slotId -> slotId -> Html msg
group config label slots target =
    case Rules.Placement.itemIn target config.placement of
        Nothing ->
            emptySpace config label (PlaceSelectedInGroup slots)

        Just occupant ->
            filled config Nothing (SelectItem occupant) occupant


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
                filled config Nothing (SelectItem item) item
    in
    section [ classList [ ( "tray", True ), ( "is-target", isTarget ) ], attribute "aria-label" "Tray" ]
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
    div [ classList [ ( "slot", True ), ( "is-target", canPlace ) ] ]
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


filled : Config item slotId msg -> Maybe String -> PlacementAction item slotId -> item -> Html msg
filled config hint action item =
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
        [ classList
            [ ( "slot", True )
            , ( "is-target", hint /= Nothing )
            , ( "is-flagged", not (List.isEmpty marks) )
            ]
        ]
        (button
            [ type_ "button"
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
            (config.cardBody item ++ selectedTag)
            :: hintTag
            ++ List.map (\mark -> span [ class "mark" ] [ text mark ]) marks
        )
