module Views.Shelf exposing (view)

{-| 1950 celebration: arrange the six recovered books in any accepted order.
Forgiving, so a matched order is celebrated as soon as it appears.
-}

import Components.Placement as PlacementUI
import Domain exposing (..)
import Html exposing (Html, aside, button, div, h3, p, section, span, text)
import Html.Attributes exposing (attribute, class, type_)
import Html.Events exposing (onClick)
import Rules.Books
import Rules.Shelf
import Views.Common as Common
import Views.TempContent as Content


view : World -> Placement RecoverableBook ShelfSlot -> Maybe Notice -> List (Html Msg)
view world placement notice =
    let
        config =
            placementConfig placement

        matched =
            Rules.Shelf.matchedOrder placement

        plaque =
            Content.clue world ShelfPlaque

        position index slot =
            PlacementUI.slot config ("Shelf position " ++ String.fromInt (index + 1)) slot
    in
    [ div [ class "board-scene shelf-scene" ]
        [ Common.topbar "1950"
            "The Reopening Shelf"
            (Common.helpButton "Back to the shelf"
                [ "Click a book to pick it up, then click a space on the shelf. Click a filled space to swap."
                , "Fill the shelf in any order the plaque suggests. You can rearrange as often as you like, and it never costs an attempt."
                ]
            )
        , section [ class "shelf", attribute "aria-label" "Reopening shelf" ]
            [ div [ class "shelf__slots" ] (List.indexedMap position Rules.Shelf.slots) ]
        , aside [ class "side" ]
            [ button [ type_ "button", class "paper-note plaque", onClick (Inspect ShelfPlaque) ]
                (h3 [ class "paper-note__title" ] [ text plaque.title ]
                    :: List.map (\line -> p [ class "plaque__line" ] [ text line ]) plaque.paragraphs
                )
            , case matched of
                Just order ->
                    p [ class "celebration", attribute "role" "status" ] [ text (Content.shelfMatched order) ]

                Nothing ->
                    Common.statusLine notice (hint placement)
            , Common.primaryButton [ onClick Advance ] "Continue"
            ]
        , PlacementUI.tray config
        ]
    ]


hint : Placement RecoverableBook ShelfSlot -> String
hint placement =
    case placement.selected of
        Just book ->
            "Click a space for “" ++ (Content.book (Recoverable book)).title ++ "”."

        Nothing ->
            if List.length placement.placed == List.length Rules.Shelf.slots then
                "The shelf is full, but this isn’t one of the plaque’s orders yet."

            else
                "Click a book, then click a space on the shelf."


placementConfig : Placement RecoverableBook ShelfSlot -> PlacementUI.Config RecoverableBook ShelfSlot Msg
placementConfig placement =
    { toMsg = ShelfMove
    , enabled = True
    , placement = placement
    , items = Rules.Books.recoverableBooks
    , name = \book -> (Content.book (Recoverable book)).title
    , cardClass = cover
    , cardBody = bookBody
    , marks = \_ -> []
    }


bookBody : RecoverableBook -> List (Html Msg)
bookBody book =
    [ span [ class "book__label" ]
        [ span [ class "book__title" ] [ text (Content.book (Recoverable book)).title ] ]
    , span [ class "book__cost" ] [ text (colourName (Rules.Books.colour book)) ]
    ]


{-| Height is drawn, and the colour is also named, so it isn't the only signal. -}
cover : RecoverableBook -> String
cover book =
    colourClass (Rules.Books.colour book) ++ " book--h" ++ String.fromInt (Rules.Books.height book)


colourClass : CoverColour -> String
colourClass colour =
    "book--" ++ String.toLower (colourName colour)


colourName : CoverColour -> String
colourName colour =
    case colour of
        Red ->
            "Red"

        Orange ->
            "Orange"

        Yellow ->
            "Yellow"

        Green ->
            "Green"

        Blue ->
            "Blue"

        Violet ->
            "Violet"
