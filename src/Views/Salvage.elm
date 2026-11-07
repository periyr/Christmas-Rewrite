module Views.Salvage exposing (view)

{-| 1950 warm-up: nine books into three crates. Forgiving, so it is allowed to
show correctness straight away, unlike the repair board.
-}

import Components.Placement as PlacementUI
import Domain exposing (..)
import Html exposing (Html, button, div, section, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled, type_)
import Html.Events exposing (onClick)
import Rules.Books
import Rules.Placement
import Rules.Salvage
import Views.Common as Common
import Views.TempContent as Content


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
                , "Look at each book's damage to decide where it belongs. You can correct mistakes as often as you like."
                , "Three books belong in each crate. When they are all sorted, press Continue."
                ]
            )
        , div [ class "crates" ]
            [ crate config Fine "Fine" "Sound and ready to shelve"
            , crate config NeedsRepair "Needs repair" "Smoke or water damage, still recoverable"
            , crate config TooFarGone "Too far gone" "Pages lost for good"
            ]
        , PlacementUI.tray config
        , div [ class "scene-foot" ]
            [ Common.statusLine notice (progress placement)
            , Common.primaryButton [ onClick Advance ] "Continue"
            ]
        ]
    ]


placementConfig : Placement BookId SalvageSlot -> PlacementUI.Config BookId SalvageSlot Msg
placementConfig placement =
    let
        misplaced =
            Rules.Salvage.misplaced placement
    in
    { toMsg = SalvageMove
    , enabled = True
    , placement = placement
    , items = Rules.Books.allBooks
    , name = \book -> (Content.book book).title
    , cardClass = cover
    , cardBody = bookBody
    , marks =
        \book ->
            if List.member book misplaced then
                [ "!" ]

            else
                []
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


{-| Hints mention only books in the wrong crate, as the brief allows here. -}
progress : Placement BookId SalvageSlot -> String
progress placement =
    let
        unsorted =
            List.length (Rules.Placement.inTray Rules.Books.allBooks placement)

        title book =
            "“" ++ (Content.book book).title ++ "”"
    in
    case ( Rules.Salvage.misplaced placement, placement.selected ) of
        ( book :: [], _ ) ->
            title book ++ " is in the wrong crate."

        ( _ :: others, _ ) ->
            String.fromInt (List.length others + 1) ++ " books marked ! are in the wrong crates."

        ( [], Just book ) ->
            "Click a crate for " ++ title book ++ "."

        ( [], Nothing ) ->
            if unsorted == 0 then
                "Every book is in the right crate. Continue when you’re ready."

            else
                String.fromInt unsorted ++ " still to sort. Click a book, then click a crate."


bookBody : BookId -> List (Html Msg)
bookBody book =
    let
        content =
            Content.book book
    in
    [ span [ class "book__label" ]
        (span [ class "book__title" ] [ text content.title ]
            :: (case content.damage of
                    [] ->
                        [ span [ class "book__damage" ] [ text "No damage" ] ]

                    marks ->
                        List.map (\damage -> span [ class "book__damage" ] [ text (damageName damage) ]) marks
               )
        )
    ]


damageName : Damage -> String
damageName damage =
    case damage of
        ScorchedEdges ->
            "Scorched edges"

        WaterStains ->
            "Water stains"

        SmokeStains ->
            "Smoke stains"

        MissingPages ->
            "Missing pages"


{-| Damage is drawn on the cover as well as named, separately from its colour. -}
cover : BookId -> String
cover book =
    let
        base =
            case book of
                Recoverable recoverable ->
                    colourClass (Rules.Books.colour recoverable)

                Ruined HarbourTales ->
                    "book--slate"

                Ruined MountainPaths ->
                    "book--forest"

                Ruined WinterAlmanac ->
                    "book--plum"

        damageClass damage =
            case damage of
                ScorchedEdges ->
                    "book--scorched"

                WaterStains ->
                    "book--stained"

                SmokeStains ->
                    "book--smoked"

                MissingPages ->
                    "book--torn"
    in
    String.join " " (base :: List.map damageClass (Content.book book).damage)


colourClass : CoverColour -> String
colourClass colour =
    case colour of
        Red ->
            "book--red"

        Orange ->
            "book--orange"

        Yellow ->
            "book--yellow"

        Green ->
            "book--green"

        Blue ->
            "book--blue"

        Violet ->
            "book--violet"
