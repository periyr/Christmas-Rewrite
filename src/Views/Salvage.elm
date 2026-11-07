module Views.Salvage exposing (view)

{-| 1950 warm-up: nine books into three crates. Forgiving, so it is allowed to
show correctness straight away, unlike the repair board.
-}

import Components.Art as Art
import Components.Placement as PlacementUI
import Content.Books
import Domain exposing (..)
import Html exposing (Html, button, div, section, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled, type_)
import Html.Events exposing (onClick)
import Rules.Books
import Rules.Placement
import Rules.Salvage
import Views.Common as Common


view : Placement BookId SalvageSlot -> Maybe Notice -> List (Html Msg)
view placement notice =
    let
        config =
            placementConfig placement
    in
    [ div [ class "salvage-scene" ]
        [ Common.topbar "1950"
            "Salvage the Books"
            (Common.helpButton "Back to the crates"
                [ "Click a book to pick it up, then click a crate to put it in. Click a book in a crate to move it again."
                , "Look at each book’s damage to decide where it belongs. You can correct mistakes as often as you like."
                , "Three books belong in each crate. When they are all sorted, press Continue."
                ]
            )
        , div [ class "crates" ]
            [ crate config Fine "Fine" "No damage at all"
            , crate config NeedsRepair "Needs repair" "Smoke or water damage only"
            , crate config TooFarGone "Too far gone" "Scorched, or pages missing"
            ]
        , PlacementUI.tray config
        , div [ class "scene-foot" ]
            [ Common.statusLine notice (progress placement)
            , Common.primaryButton [ onClick Advance ] "Continue"
            ]
        ]
    ]


{-| No per-book marks: the player is told how many books are misplaced, not which. -}
placementConfig : Placement BookId SalvageSlot -> PlacementUI.Config BookId SalvageSlot Msg
placementConfig placement =
    { toMsg = SalvageMove
    , enabled = True
    , placement = placement
    , items = Rules.Books.allBooks
    , name = \book -> (Content.Books.book book).title
    , cardClass = \_ -> "book--art"
    , cardBody = bookBody
    , marks = \_ -> []
    }


crate : PlacementUI.Config BookId SalvageSlot Msg -> Condition -> String -> String -> Html Msg
crate config condition name description =
    let
        slots =
            Rules.Salvage.crateSlots condition

        holding =
            config.placement.selected /= Nothing
    in
    section [ classList [ ( "crate", True ), ( "is-target", holding ) ], attribute "aria-label" (name ++ " crate") ]
        [ button
            [ type_ "button"
            , class "crate__label"
            , disabled (not holding)
            , onClick (SalvageMove (PlaceSelectedInGroup slots))
            ]
            [ span [ class "crate__name" ] [ text name ]
            , span [ class "crate__description" ] [ text description ]
            ]
        , div [ class "crate__slots" ] (List.map (PlacementUI.group config (name ++ " crate") slots) slots)
        ]


{-| Says how many books are in the wrong crate, never which ones. -}
progress : Placement BookId SalvageSlot -> String
progress placement =
    let
        unsorted =
            List.length (Rules.Placement.inTray Rules.Books.allBooks placement)

        title book =
            "“" ++ (Content.Books.book book).title ++ "”"
    in
    case ( Rules.Salvage.misplaced placement, placement.selected ) of
        ( _ :: [], _ ) ->
            "1 book is in the wrong crate."

        ( _ :: others, _ ) ->
            String.fromInt (List.length others + 1) ++ " books are in the wrong crates."

        ( [], Just book ) ->
            "Click a crate for " ++ title book ++ "."

        ( [], Nothing ) ->
            if unsorted == 0 then
                "Every book is in the right crate. Continue when you’re ready."

            else
                String.fromInt unsorted ++ " still to sort. Click a book, then click a crate."


{-| The cover with its damage drawn on, and the title. Damage isn't written out:
the player reads it from the art.
-}
bookBody : BookId -> List (Html Msg)
bookBody book =
    let
        content =
            Content.Books.book book
    in
    [ Art.bookCover book content.damage
    , span [ class "book__caption" ] [ span [ class "book__title" ] [ text content.title ] ]
    ]
