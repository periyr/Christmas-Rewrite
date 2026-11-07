module Views.RepairBoard exposing (view)

{-| 1950 main puzzle. Before a submission this shows arithmetic only. Everything
about correctness comes from puzzle.attempts, never from calling the validator.
-}

import Components.Art as Art
import Components.Placement as PlacementUI
import Domain exposing (..)
import Html exposing (Html, aside, button, div, h3, li, p, section, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, disabled, type_)
import Html.Events exposing (onClick)
import Rules.Placement
import Rules.Repair
import Views.Common as Common
import Views.Labels exposing (dayName)
import Views.TempContent as Content


type alias Puzzle =
    MainPuzzle (Placement TaskId RepairSlot)


view : World -> Puzzle -> Maybe Notice -> List (Html Msg)
view world puzzle notice =
    let
        placement =
            puzzle.arrangement

        reviewing =
            reviewedViolations puzzle.attempts

        numbered =
            List.indexedMap (\index violation -> ( String.fromInt (index + 1), violation )) reviewing

        config =
            placementConfig puzzle numbered

        isReviewing =
            not (List.isEmpty reviewing)
    in
    [ div [ class "board-scene" ]
        [ Common.topbar "1950"
            "The Repair Week"
            (Common.attemptsDisplay puzzle.attempts :: lastTryNotes puzzle.attempts ++ help)
        , section [ class "cork", attribute "aria-label" "Planning board" ]
            [ div [ class "days" ] (List.map (dayColumn config) Rules.Repair.days)
            , div [ class "cork__lower" ]
                [ notThisWeek config
                , div [ class "clues" ] (List.map (clueNote world puzzle) clues)
                ]
            , if isReviewing then
                Art.arrows (List.filterMap (arrowFor placement) reviewing)

              else
                text ""
            ]
        , aside [ class "side" ]
            [ ledger placement numbered
            , goals numbered isReviewing
            , Common.statusLine notice (hint puzzle isReviewing)
            , Common.primaryButton [ disabled isReviewing, onClick Submit ] "Finish week"
            ]
        , if isReviewing then
            feedback numbered

          else
            PlacementUI.tray config
        ]
    ]


reviewedViolations : Attempts -> List Violation
reviewedViolations attempts =
    case attempts of
        ReviewingFirstMistake violations ->
            violations

        _ ->
            []


placementConfig : Puzzle -> List ( String, Violation ) -> PlacementUI.Config TaskId RepairSlot Msg
placementConfig puzzle numbered =
    { toMsg = BoardMove
    , enabled =
        case puzzle.attempts of
            ReviewingFirstMistake _ ->
                False

            _ ->
                True
    , placement = puzzle.arrangement
    , items = Rules.Repair.allTasks
    , name = \task -> (Content.taskCard task).title
    , cardClass = cover
    , cardBody = cardBody
    , marks = \task -> List.filterMap (\( mark, violation ) -> markIf (blamedTask violation == Just task) mark) numbered
    }


markIf : Bool -> String -> Maybe String
markIf condition mark =
    if condition then
        Just mark

    else
        Nothing


help : List (Html Msg)
help =
    Common.helpButton "Back to the board"
        [ "Click a card to pick it up, then click where it should go. Click a filled space to swap."
        , "Read anything pinned to the board as often as you like. Looking and rearranging never costs an attempt."
        , "When every card has a place, press Finish week. You have two attempts."
        ]


{-| After Retry the board can change, so the marks go and the earlier
violations stay available as plain text.
-}
lastTryNotes : Attempts -> List (Html Msg)
lastTryNotes attempts =
    case attempts of
        RetryingAfterMistake violations ->
            [ Common.popoverToggle "last-try" "Last try’s notes"
            , Common.popoverSheet "last-try"
                "What went wrong last time"
                "Back to the board"
                [ ul [] (List.map (\violation -> li [] [ text (Content.violation violation) ]) violations) ]
            ]

        _ ->
            []


hint : Puzzle -> Bool -> String
hint puzzle isReviewing =
    let
        unplaced =
            List.length (Rules.Placement.inTray Rules.Repair.allTasks puzzle.arrangement)
    in
    if isReviewing then
        "Read the notes below, then try again."

    else
        case puzzle.arrangement.selected of
            Just task ->
                "Click where “" ++ (Content.taskCard task).title ++ "” should go."

            Nothing ->
                if Rules.Repair.complete puzzle.arrangement /= Nothing then
                    "Every card has a place. Finish the week when you’re ready."

                else
                    String.fromInt unplaced ++ " in the tray. Click a card, then click where it should go."


dayColumn : PlacementUI.Config TaskId RepairSlot Msg -> Day -> Html Msg
dayColumn config day =
    div [ class "day" ]
        [ span [ class "day__label" ] [ text (dayName day) ]
        , PlacementUI.slot config (dayName day) (OnDay day)
        ]


notThisWeek : PlacementUI.Config TaskId RepairSlot Msg -> Html Msg
notThisWeek config =
    let
        holding =
            config.enabled && config.placement.selected /= Nothing

        space index slot =
            PlacementUI.slot config ("Not this week, space " ++ String.fromInt (index + 1)) slot
    in
    div [ class "not-this-week" ]
        [ button
            [ type_ "button"
            , class "not-this-week__label"
            , disabled (not holding)
            , onClick (BoardMove (PlaceSelectedInGroup Rules.Repair.notThisWeekSlots))
            ]
            [ text "Not this week" ]
        , div [ class "not-this-week__slots" ] (List.indexedMap space Rules.Repair.notThisWeekSlots)
        ]


clues : List ClueId
clues =
    [ WalterDiaryPage, GlassDeliverySlip, RubbleAndShelvesNote, BudgetAllocation ]


clueNote : World -> Puzzle -> ClueId -> Html Msg
clueNote world puzzle clue =
    button
        [ type_ "button"
        , classList [ ( "clue", True ), ( "clue--slip", clue == GlassDeliverySlip ) ]
        , onClick (Inspect clue)
        ]
        (text (Content.clue world clue).title
            :: (if List.member clue puzzle.inspected then
                    [ span [ class "clue__read" ] [ text "Read" ] ]

                else
                    []
               )
        )


cardBody : TaskId -> List (Html Msg)
cardBody task =
    [ span [ class "book__label" ]
        [ Art.icon (iconName task)
        , span [ class "book__title" ] [ text (Content.taskCard task).title ]
        ]
    , span [ class "book__cost" ] [ text (costText (Rules.Repair.cost task)) ]
    ]


costText : Resources -> String
costText cost =
    case ( cost.pounds > 0, cost.timber > 0 ) of
        ( True, True ) ->
            "£" ++ String.fromInt cost.pounds ++ " + " ++ String.fromInt cost.timber ++ " timber"

        ( True, False ) ->
            "£" ++ String.fromInt cost.pounds

        ( False, True ) ->
            String.fromInt cost.timber ++ " timber"

        ( False, False ) ->
            "Free"


iconName : TaskId -> String
iconName task =
    case task of
        PatchRoof ->
            "roof"

        ClearRubble ->
            "rubble"

        BuildShelves ->
            "shelves"

        ShelveBooks ->
            "books"

        ReglazeWindow ->
            "glass"

        PaintSign ->
            "sign"

        BoardUpWindow ->
            "boards"


cover : TaskId -> String
cover task =
    case task of
        PatchRoof ->
            "book--navy"

        ClearRubble ->
            "book--umber"

        BuildShelves ->
            "book--forest"

        ShelveBooks ->
            "book--plum"

        ReglazeWindow ->
            "book--teal"

        PaintSign ->
            "book--ochre"

        BoardUpWindow ->
            "book--slate"


ledger : Placement TaskId RepairSlot -> List ( String, Violation ) -> Html Msg
ledger placement numbered =
    let
        spent =
            Rules.Repair.spent placement

        left =
            Rules.Repair.remaining placement

        timberMark =
            List.filterMap
                (\( mark, violation ) ->
                    case violation of
                        TimberOverspent _ ->
                            Just mark

                        _ ->
                            Nothing
                )
                numbered

        moneyMark =
            List.filterMap
                (\( mark, violation ) ->
                    case violation of
                        MoneyOverspent _ ->
                            Just mark

                        _ ->
                            Nothing
                )
                numbered
    in
    div [ class "paper-note" ]
        [ h3 [ class "paper-note__title" ] [ text "This week’s allowance" ]
        , resource "Timber" "" timberMark spent.timber left.timber Rules.Repair.budget.timber
        , resource "Money" "£" moneyMark spent.pounds left.pounds Rules.Repair.budget.pounds
        ]


resource : String -> String -> List String -> Int -> Int -> Int -> Html Msg
resource name unit marks spent left budget =
    let
        signed amount =
            if amount < 0 then
                "−" ++ unit ++ String.fromInt (abs amount)

            else
                unit ++ String.fromInt amount

        pip index =
            span
                [ classList
                    [ ( "pip", True )
                    , ( "is-spent", index < spent && index < budget )
                    , ( "is-over", index >= budget )
                    ]
                ]
                []
    in
    div [ classList [ ( "resource", True ), ( "is-flagged", not (List.isEmpty marks) ) ] ]
        [ div [ class "resource__line" ]
            (List.map (\mark -> span [ class "mark mark--inline" ] [ text mark ]) marks
                ++ [ span [ class "resource__name" ] [ text name ]
                   , span [ class "resource__figure" ]
                        [ text (signed spent ++ " spent · ")
                        , Html.b [] [ text (signed left) ]
                        , text " left"
                        ]
                   ]
            )
        , div [ class "resource__pips", attribute "aria-hidden" "true" ]
            (List.map pip (List.range 0 (max spent budget - 1)))
        ]


allGoals : List ReopeningGoal
allGoals =
    [ WatertightRoof, SealedWindow, UsableShelves, AllBooksShelved ]


goals : List ( String, Violation ) -> Bool -> Html Msg
goals numbered isReviewing =
    let
        goalRow goal =
            let
                marks =
                    List.filterMap (\( mark, violation ) -> markIf (affectedGoal violation == Just goal) mark) numbered

                unmet =
                    not (List.isEmpty marks)
            in
            li
                [ classList
                    [ ( "goal", True )
                    , ( "is-met", isReviewing && not unmet )
                    , ( "is-unmet", unmet )
                    ]
                ]
                (span []
                    (text (Content.goal goal)
                        :: (if isReviewing then
                                [ span [ class "visually-hidden" ]
                                    [ text
                                        (if unmet then
                                            " (not met)"

                                         else
                                            " (met)"
                                        )
                                    ]
                                ]

                            else
                                []
                           )
                    )
                    :: List.map (\mark -> span [ class "mark mark--inline mark--goal" ] [ text mark ]) marks
                )
    in
    div [ class "paper-note" ]
        [ h3 [ class "paper-note__title" ] [ text "Reopening goals" ]
        , ul [ class "goals" ] (List.map goalRow allGoals)
        ]


feedback : List ( String, Violation ) -> Html Msg
feedback numbered =
    section [ class "feedback", attribute "role" "alert", attribute "aria-label" "What went wrong" ]
        [ div []
            [ h3 [ class "feedback__title" ] [ text "The week didn’t hold. Here’s what went wrong:" ]
            , ul [ class "feedback__list" ]
                (List.map
                    (\( mark, violation ) ->
                        li [ class "feedback__item" ]
                            [ span [ class "mark mark--inline" ] [ text mark ]
                            , span [] [ text (Content.violation violation) ]
                            ]
                    )
                    numbered
                )
            ]
        , div [ class "feedback__aside" ]
            [ p [ class "feedback__note" ] [ text "You have one more try. Your cards stay where they are." ]
            , button [ type_ "button", class "btn", onClick Retry ] [ text "Try again" ]
            ]
        ]


{-| Which card a violation's mark sits on. Presentation only: the violation
itself comes from the model.
-}
blamedTask : Violation -> Maybe TaskId
blamedTask violation =
    case violation of
        RoofAfterRain _ ->
            Just PatchRoof

        GlassNotYetDelivered _ ->
            Just ReglazeWindow

        MustComeBefore _ second ->
            Just second

        _ ->
            Nothing


affectedGoal : Violation -> Maybe ReopeningGoal
affectedGoal violation =
    case violation of
        RoofAfterRain _ ->
            Just WatertightRoof

        GlassNotYetDelivered _ ->
            Just SealedWindow

        GoalMissing goal ->
            Just goal

        MustComeBefore ClearRubble _ ->
            Just UsableShelves

        MustComeBefore _ ShelveBooks ->
            Just AllBooksShelved

        _ ->
            Nothing


{-| An arrow needs both cards on days. A deferred prerequisite gets only its mark. -}
arrowFor : Placement TaskId RepairSlot -> Violation -> Maybe ( Int, Int )
arrowFor placement violation =
    case violation of
        MustComeBefore first second ->
            Maybe.map2 Tuple.pair (dayColumnOf first placement) (dayColumnOf second placement)

        _ ->
            Nothing


dayColumnOf : TaskId -> Placement TaskId RepairSlot -> Maybe Int
dayColumnOf task placement =
    case Rules.Placement.slotOf task placement of
        Just (OnDay day) ->
            Rules.Repair.days
                |> List.indexedMap Tuple.pair
                |> List.filter (\( _, candidate ) -> candidate == day)
                |> List.head
                |> Maybe.map Tuple.first

        _ ->
            Nothing
