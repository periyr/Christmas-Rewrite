module Views.Shelf exposing (view)

{-| 1950 celebration: arrange the six recovered books in any accepted order.
Forgiving, so a matched order is celebrated as soon as it appears.
-}

import Components.Art as Art
import Components.Placement as PlacementUI
import Content.Books
import Content.Clues
import Content.Shelf
import Domain exposing (..)
import Html exposing (Html, aside, button, div, h3, p, section, span, text)
import Html.Attributes exposing (attribute, class, style, type_)
import Html.Events exposing (onClick)
import Rules.Books
import Rules.Shelf
import Views.Common as Common


view : World -> Placement RecoverableBook ShelfSlot -> Maybe Notice -> List (Html Msg)
view world placement notice =
    let
        config =
            placementConfig placement

        matched =
            Rules.Shelf.matchedOrder placement

        plaque =
            Content.Clues.clue world ShelfPlaque

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
                    ++ [ span [ class "plaque__swatches" ] (List.map swatch rainbow) ]
                )
            , case matched of
                Just order ->
                    p [ class "celebration", attribute "role" "status" ] [ text (Content.Shelf.matched order) ]

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
            "Click a space for “" ++ (Content.Books.book (Recoverable book)).title ++ "”."

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
    , name = \book -> (Content.Books.book (Recoverable book)).title
    , cardClass = \_ -> "book--art"
    , cardBody = bookBody
    , marks = \_ -> []
    }


{-| Clean covers: the books have been repaired by now. Height is drawn, and the
colour is also named, so it isn't the only signal.
-}
bookBody : RecoverableBook -> List (Html Msg)
bookBody book =
    [ Art.bookCover (Recoverable book) []
    , span [ class "book__caption" ]
        [ span [ class "book__title" ] [ text (Content.Books.book (Recoverable book)).title ]
        , span [ class "book__damage" ] [ text (colourName (Rules.Books.colour book)) ]
        ]
    ]


{-| The plaque's colour guide, in C's exact order and shades (ASSETS.md). -}
rainbow : List ( String, String )
rainbow =
    [ ( "Red", "#893f43" )
    , ( "Orange", "#c95937" )
    , ( "Yellow", "#d9a443" )
    , ( "Green", "#748b2c" )
    , ( "Blue", "#496669" )
    , ( "Violet", "#7687ab" )
    ]


swatch : ( String, String ) -> Html msg
swatch ( name, colour ) =
    span [ class "plaque__swatch", style "background" colour, attribute "title" name ] []


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
