module Views.BookTable exposing (view)

{-| 1998 main puzzle: four candidate books, presented the same way. Looking
inside a book (its picture, text or dedication) opens a clue sheet. Choosing a
book is a separate button. Nothing here says which book is right: correctness
comes only from puzzle.attempts after "Send this book".
-}

import Components.Art as Art
import Content.Mystery
import Domain exposing (..)
import Html exposing (Html, article, aside, button, div, h3, section, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled, type_)
import Html.Events exposing (onClick)
import Rules.Mystery
import Views.Common as Common


type alias Puzzle =
    MainPuzzle (Maybe CandidateId)


view : World -> Puzzle -> Maybe Notice -> List (Html Msg)
view world puzzle notice =
    let
        reviewing =
            Common.reviewedViolations puzzle.attempts

        numbered =
            Common.numbered reviewing

        isReviewing =
            not (List.isEmpty reviewing)
    in
    [ div [ classList [ ( "board-scene", True ), ( "table-scene", True ), ( "is-reviewing", isReviewing ) ] ]
        [ Common.topbar "1998"
            "The Forgotten Book"
            (Common.attemptsDisplay puzzle.attempts
                :: Common.lastTryNotes "Back to the books" puzzle.attempts
                ++ help
                ++ [ Common.closePanel (not isReviewing) ]
            )
        , section [ class "book-table", attribute "aria-label" "Four candidate books" ]
            (List.map (candidateCard puzzle isReviewing numbered) Rules.Mystery.candidates)
        , aside [ class "side" ]
            [ div [ class "paper-note" ]
                [ h3 [ class "paper-note__title" ] [ text "Ruth’s request" ]
                , div [ class "side-clues" ] (List.map (Common.clueNote world puzzle.inspected) clues)
                ]
            , Common.statusLine notice (hint puzzle isReviewing)
            , Common.primaryButton [ disabled isReviewing, onClick Submit ] "Send this book"
            ]
        , if isReviewing then
            Common.feedback
                { title = "That isn’t Lucy’s book. Here’s what doesn’t match:"
                , note = "You have one more try. Your choice stays as it is until you change it."
                }
                numbered

          else
            text ""
        ]
    ]


clues : List ClueId
clues =
    [ RuthsEmail, RememberedSentence, InscriptionClue ]


help : List (Html Msg)
help =
    Common.helpButton "Back to the books"
        [ "Look inside each book: its picture, its text and its dedication. Looking never costs anything."
        , "Read Ruth’s email and the notes beside it as often as you like."
        , "Choose the book you think is Lucy’s, then press Send this book. You have two attempts."
        ]


{-| Every card has the same parts in the same order, so none stands out. The
chosen card is marked by the player's own choice, never by the rules.
-}
candidateCard : Puzzle -> Bool -> List ( String, Violation ) -> CandidateId -> Html Msg
candidateCard puzzle isReviewing numbered candidate =
    let
        content =
            Content.Mystery.candidate candidate

        isChosen =
            puzzle.arrangement == Just candidate

        marks =
            if isChosen then
                List.map Tuple.first numbered

            else
                []

        tab bookTab label =
            let
                page =
                    CandidatePage candidate bookTab
            in
            button
                [ type_ "button"
                , class "candidate__tab"
                , attribute "aria-label" (label ++ ": " ++ content.label)
                , onClick (Inspect page)
                ]
                (text label
                    :: (if List.member page puzzle.inspected then
                            [ span [ class "clue__read" ] [ text "Read" ] ]

                        else
                            []
                       )
                )
    in
    article
        [ classList [ ( "candidate", True ), ( "is-chosen", isChosen ), ( "is-flagged", not (List.isEmpty marks) ) ]
        , attribute "aria-label" content.label
        ]
        (List.map (\mark -> span [ class "mark" ] [ text mark ]) marks
            ++ [ Art.candidateCover candidate
               , h3 [ class "candidate__title" ] [ text content.label ]
               , div [ class "candidate__tabs", attribute "role" "group", attribute "aria-label" ("Look inside " ++ content.label) ]
                    [ tab CoverTab "Picture"
                    , tab TextTab "Text"
                    , tab DedicationTab "Dedication"
                    ]
               , button
                    [ type_ "button"
                    , class "btn candidate__choose"
                    , attribute "aria-pressed"
                        (if isChosen then
                            "true"

                         else
                            "false"
                        )
                    , disabled isReviewing
                    , onClick (ChooseCandidate candidate)
                    ]
                    [ text
                        (if isChosen then
                            "Chosen"

                         else
                            "Choose this book"
                        )
                    ]
               ]
        )


hint : Puzzle -> Bool -> String
hint puzzle isReviewing =
    if isReviewing then
        "Read the notes below, then try again."

    else
        case puzzle.arrangement of
            Just candidate ->
                "“" ++ (Content.Mystery.candidate candidate).label ++ "” is chosen. Send it when you’re sure."

            Nothing ->
                "Look inside the books, then choose one to send."
