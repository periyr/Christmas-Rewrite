module Views.Common exposing (attemptsDisplay, documentSheet, draftTag, helpButton, narration, popoverSheet, popoverToggle, primaryButton, statusLine, topbar)

{-| Pieces shared by several screens. -}

import Domain exposing (Attempts, Document, Msg(..), Notice)
import Html exposing (Attribute, Html, button, div, footer, h2, header, p, section, span, text)
import Html.Attributes exposing (attribute, class, classList, id, type_)
import Html.Events exposing (onClick)
import Rules.Attempts
import Views.TempContent as Content


{-| Marks text from Views.TempContent. Remove with that module. -}
draftTag : Html msg
draftTag =
    span [ class "sample-tag" ] [ text "Draft text" ]


topbar : String -> String -> List (Html msg) -> Html msg
topbar era title extras =
    header [ class "topbar" ]
        (span [ class "era-tag" ] [ text era ]
            :: h2 [ class "topbar__title" ] [ text title ]
            :: extras
        )


attemptsDisplay : Attempts -> Html msg
attemptsDisplay attempts =
    let
        used =
            Rules.Attempts.attemptsUsed attempts

        total =
            Rules.Attempts.maxAttempts

        figure =
            String.fromInt (total - used) ++ " of " ++ String.fromInt total

        token index =
            span [ classList [ ( "attempts__token", True ), ( "is-spent", index < used ) ] ] []
    in
    div [ class "attempts", attribute "aria-label" ("Attempts remaining: " ++ figure) ]
        [ span [ attribute "aria-hidden" "true" ] [ text "Attempts remaining" ]
        , span [ class "attempts__tokens", attribute "aria-hidden" "true" ] (List.map token (List.range 0 (total - 1)))
        , span [ attribute "aria-hidden" "true" ] [ text figure ]
        ]


{-| The status line: a neutral notice if there is one, otherwise the hint. -}
statusLine : Maybe Notice -> String -> Html Msg
statusLine notice hint =
    case notice of
        Just shown ->
            p [ class "status", attribute "role" "status" ]
                [ span [] [ text (Content.notice shown) ]
                , button [ type_ "button", class "status__dismiss", attribute "aria-label" "Dismiss message", onClick DismissNotice ] [ text "×" ]
                ]

        Nothing ->
            p [ class "status", attribute "role" "status" ] [ span [] [ text hint ] ]


primaryButton : List (Attribute msg) -> String -> Html msg
primaryButton attributes label =
    button (type_ "button" :: class "btn btn--primary" :: attributes) [ text label ]


{-| A document on paper over the current screen. -}
documentSheet : { variant : String, document : Document, buttonLabel : String, onPress : msg } -> Html msg
documentSheet { variant, document, buttonLabel, onPress } =
    div [ class "overlay" ]
        [ section [ class ("sheet " ++ variant), attribute "role" "dialog", attribute "aria-modal" "true", attribute "aria-labelledby" "sheet-title" ]
            [ header [ class "sheet__head" ]
                [ h2 [ class "sheet__title", id "sheet-title" ] [ text document.title ]
                , draftTag
                ]
            , div [ class "sheet__body" ] (List.map (\paragraph -> p [] [ text paragraph ]) document.paragraphs)
            , footer [ class "sheet__foot" ]
                [ button [ type_ "button", class "btn", onClick onPress ] [ text buttonLabel ] ]
            ]
        ]


{-| Scene text along the bottom of the room, with one action. -}
narration : Document -> Html msg -> Html msg
narration document action =
    div [ class "narration" ]
        [ div [ class "narration__text" ]
            (h2 [ class "narration__title" ] [ text document.title, text " ", draftTag ]
                :: List.map (\paragraph -> p [] [ text paragraph ]) document.paragraphs
            )
        , action
        ]


{-| Help and reference sheets need no game state, so they use the browser's
popover instead of a Msg. Opening one can't touch the model.
-}
popoverToggle : String -> String -> Html msg
popoverToggle popoverId label =
    button [ type_ "button", class "btn", attribute "popovertarget" popoverId ] [ text label ]


popoverSheet : String -> String -> String -> List (Html msg) -> Html msg
popoverSheet popoverId title closeLabel body =
    div [ class "overlay overlay--popover", id popoverId, attribute "popover" "auto" ]
        [ section [ class "sheet", attribute "role" "dialog", attribute "aria-labelledby" (popoverId ++ "-title") ]
            [ header [ class "sheet__head" ]
                [ h2 [ class "sheet__title", id (popoverId ++ "-title") ] [ text title ] ]
            , div [ class "sheet__body" ] body
            , footer [ class "sheet__foot" ]
                [ button
                    [ type_ "button"
                    , class "btn"
                    , attribute "popovertarget" popoverId
                    , attribute "popovertargetaction" "hide"
                    ]
                    [ text closeLabel ]
                ]
            ]
        ]


{-| The Help button and its sheet. -}
helpButton : String -> List String -> List (Html msg)
helpButton closeLabel paragraphs =
    [ popoverToggle "help" "Help"
    , popoverSheet "help" "How to play" closeLabel (List.map (\paragraph -> p [] [ text paragraph ]) paragraphs)
    ]
