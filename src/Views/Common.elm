module Views.Common exposing (attemptsDisplay, closePanel, clueNote, documentSheet, feedback, helpButton, lastTryNotes, narration, numbered, popoverSheet, popoverToggle, primaryButton, reviewedViolations, roomNote, statusLine, topbar, yearBadge)

{-| Pieces shared by several screens. -}

import Content.Clues
import Content.Feedback
import Domain exposing (Attempts(..), ClueId(..), Document, Msg(..), Notice, Violation, World)
import Html exposing (Attribute, Html, button, div, footer, h2, h3, header, img, li, p, section, span, text, ul)
import Html.Attributes exposing (alt, attribute, class, classList, disabled, id, src, type_)
import Html.Events exposing (onClick)
import Rules.Attempts


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
                [ span [] [ text (Content.Feedback.notice shown) ]
                , button [ type_ "button", class "status__dismiss", attribute "aria-label" "Dismiss message", onClick DismissNotice ] [ text "×" ]
                ]

        Nothing ->
            p [ class "status", attribute "role" "status" ] [ span [] [ text hint ] ]


primaryButton : List (Attribute msg) -> String -> Html msg
primaryButton attributes label =
    button (type_ "button" :: class "btn btn--primary" :: attributes) [ text label ]


{-| A document on paper over the current screen, with an optional picture above
the words (a 1998 book's illustration). The words stay real text.
-}
documentSheet : { variant : String, document : Document, picture : Maybe String, buttonLabel : String, onPress : msg } -> Html msg
documentSheet { variant, document, picture, buttonLabel, onPress } =
    div [ class "overlay" ]
        [ section [ class ("sheet " ++ variant), attribute "role" "dialog", attribute "aria-modal" "true", attribute "aria-labelledby" "sheet-title" ]
            [ header [ class "sheet__head" ]
                [ h2 [ class "sheet__title", id "sheet-title" ] [ text document.title ] ]
            , div [ class "sheet__body" ]
                ((case picture of
                    Just file ->
                        [ img [ class "sheet__picture", src file, alt "" ] [] ]

                    Nothing ->
                        []
                 )
                    ++ List.map (\paragraph -> p [] [ text paragraph ]) document.paragraphs
                )
            , footer [ class "sheet__foot" ]
                [ button [ type_ "button", class "btn", onClick onPress ] [ text buttonLabel ] ]
            ]
        ]


{-| Scene text along the bottom of the room, with one action. -}
narration : Document -> Html msg -> Html msg
narration document action =
    div [ class "narration" ]
        [ div [ class "narration__text" ]
            (h2 [ class "narration__title" ] [ text document.title ]
                :: List.map (\paragraph -> p [] [ text paragraph ]) document.paragraphs
            )
        , action
        ]


{-| Scene text at the top of the room, for a phase the player walks around in. -}
roomNote : Document -> Html msg
roomNote document =
    div [ class "narration narration--top" ]
        [ div [ class "narration__text" ]
            (h2 [ class "narration__title" ] [ text document.title ]
                :: List.map (\paragraph -> p [] [ text paragraph ]) document.paragraphs
            )
        ]


{-| Back to the room from a panel. The answer and attempts stay as they are. Off
while first-attempt feedback is showing, when the player presses Retry first.
-}
closePanel : Bool -> Html Msg
closePanel canClose =
    button [ type_ "button", class "btn", disabled (not canClose), onClick ClosePanel ] [ text "Back to the room" ]


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



-- MAIN PUZZLES: shared by the 1950 board, the 1973 stage and the 1998 books.


{-| The violations to show while the first mistake is being reviewed. -}
reviewedViolations : Attempts -> List Violation
reviewedViolations attempts =
    case attempts of
        ReviewingFirstMistake violations ->
            violations

        _ ->
            []


{-| Violations numbered from 1, for the marks and the feedback list. -}
numbered : List Violation -> List ( String, Violation )
numbered =
    List.indexedMap (\index violation -> ( String.fromInt (index + 1), violation ))


{-| After Retry the arrangement can change, so the marks go and the earlier
violations stay available as plain text.
-}
lastTryNotes : String -> Attempts -> List (Html msg)
lastTryNotes closeLabel attempts =
    case attempts of
        RetryingAfterMistake violations ->
            [ popoverToggle "last-try" "Last try’s notes"
            , popoverSheet "last-try"
                "What went wrong last time"
                closeLabel
                [ ul [] (List.map (\violation -> li [] [ text (Content.Feedback.violation violation) ]) violations) ]
            ]

        _ ->
            []


{-| The first-mistake strip: every violation, numbered to match its marks, and
Retry. Only shown after a submission.
-}
feedback : { title : String, note : String } -> List ( String, Violation ) -> Html Msg
feedback words numberedViolations =
    section [ class "feedback", attribute "role" "alert", attribute "aria-label" "What went wrong" ]
        [ div []
            [ h3 [ class "feedback__title" ] [ text words.title ]
            , ul [ class "feedback__list" ]
                (List.map
                    (\( mark, violation ) ->
                        li [ class "feedback__item" ]
                            [ span [ class "mark mark--inline" ] [ text mark ]
                            , span [] [ text (Content.Feedback.violation violation) ]
                            ]
                    )
                    numberedViolations
                )
            ]
        , div [ class "feedback__aside" ]
            [ p [ class "feedback__note" ] [ text words.note ]
            , button [ type_ "button", class "btn", onClick Retry ] [ text "Try again" ]
            ]
        ]


{-| A clue pinned beside a puzzle. Its title follows the history-derived world,
and it shows "Read" once opened.
-}
clueNote : World -> List ClueId -> ClueId -> Html Msg
clueNote world inspected clue =
    button
        [ type_ "button"
        , classList [ ( "clue", True ), ( "clue--slip", clue == GlassDeliverySlip ) ]
        , onClick (Inspect clue)
        ]
        (text (Content.Clues.clue world clue).title
            :: (if List.member clue inspected then
                    [ span [ class "clue__read" ] [ text "Read" ] ]

                else
                    []
               )
        )


{-| The year the scene is in, top left, in the same badge the panels use.
Shown on slides, where there is no walking bar.
-}
yearBadge : String -> Html msg
yearBadge year =
    div [ class "room-bar room-bar--year" ] [ span [ class "era-tag room-bar__year" ] [ text year ] ]
