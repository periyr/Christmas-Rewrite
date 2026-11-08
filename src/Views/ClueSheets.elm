module Views.ClueSheets exposing (custom)

{-| Clues drawn as the thing they are, rather than as plain text: Ruth's email
as an email on the 1998 computer, and the remembered line as the last page of
a book. The words all come from Content.Clues, so the facts never differ from
the plain-text version.
-}

import Domain exposing (ClueId(..), Document)
import Html exposing (Html, div, dl, dd, dt, p, span, text)
import Html.Attributes exposing (attribute, class)


{-| The body for clues that have their own look, or Nothing for the rest. -}
custom : ClueId -> Document -> Maybe ( String, List (Html msg) )
custom clue document =
    case clue of
        RuthsEmail ->
            Just ( "sheet--email", email document )

        RememberedSentence ->
            Just ( "sheet--book-end", bookEnding document )

        _ ->
            Nothing



-- ═══════════════════════════════════════════════════════════════════════
-- RUTH'S EMAIL
-- ═══════════════════════════════════════════════════════════════════════


{-| A plain late-90s mail window: a title bar, the From / To / Subject lines,
and the message, with Ruth's name set as her sign-off.
-}
email : Document -> List (Html msg)
email document =
    let
        ( message, signature ) =
            signOff document.paragraphs
    in
    [ div [ class "email" ]
        [ div [ class "email__bar" ]
            [ span [ class "email__bar-title" ] [ text "New message" ]
            , span [ class "email__bar-buttons", attribute "aria-hidden" "true" ] [ span [] [], span [] [], span [] [] ]
            ]
        , dl [ class "email__fields" ]
            [ dt [] [ text "From:" ]
            , dd [] [ text "Ruth" ]
            , dt [] [ text "To:" ]
            , dd [] [ text "Hale’s Bookshop" ]
            , dt [] [ text "Subject:" ]
            , dd [] [ text "Lucy’s books" ]
            ]
        , div [ class "email__message" ]
            (List.map (\paragraph -> p [] [ text paragraph ]) message
                ++ (case signature of
                        Just name ->
                            [ p [ class "email__signature" ] [ text name ] ]

                        Nothing ->
                            []
                   )
            )
        ]
    ]


{-| The email's last paragraph ends with Ruth's name; it goes on its own line. -}
signOff : List String -> ( List String, Maybe String )
signOff paragraphs =
    case List.reverse paragraphs of
        last :: earlier ->
            if String.endsWith " Ruth" last then
                ( List.reverse (String.dropRight 5 last :: earlier), Just "Ruth" )

            else
                ( paragraphs, Nothing )

        [] ->
            ( paragraphs, Nothing )



-- ═══════════════════════════════════════════════════════════════════════
-- THE REMEMBERED LINE
-- ═══════════════════════════════════════════════════════════════════════


{-| Ruth's lead-in above, then an open book at its last page: the left page
and the top of the right one are faded lines of story, and the remembered
sentence closes it above "The End".
-}
bookEnding : Document -> List (Html msg)
bookEnding document =
    let
        ( lead, line ) =
            case document.paragraphs of
                first :: second :: _ ->
                    ( [ p [ class "book-end__lead" ] [ text first ] ], unquote second )

                [ only ] ->
                    ( [], unquote only )

                [] ->
                    ( [], "" )

        faded count =
            List.map (\i -> span [ class ("book-end__faded book-end__faded--" ++ String.fromInt (modBy 4 i)) ] []) (List.range 1 count)
    in
    lead
        ++ [ div [ class "book-end" ]
                [ div [ class "book-end__page book-end__page--left", attribute "aria-hidden" "true" ] (faded 11)
                , div [ class "book-end__page book-end__page--right" ]
                    (faded 3
                        ++ [ p [ class "book-end__line" ] [ text line ]
                           , p [ class "book-end__the-end" ] [ text "The End" ]
                           ]
                    )
                ]
           ]


unquote : String -> String
unquote s =
    s |> String.replace "“" "" |> String.replace "”" ""
