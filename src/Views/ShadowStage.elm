module Views.ShadowStage exposing (view)

{-| 1973 main puzzle: three numbered scene panels, each with a character slot and
a prop slot, and the six cut-outs in the tray. Before a submission this shows
the arrangement only. Everything about correctness comes from puzzle.attempts,
never from calling the validator or the script.
-}

import Components.Art as Art
import Components.Placement as PlacementUI
import Content.Shadow
import Content.Words exposing (sceneName)
import Domain exposing (..)
import Html exposing (Html, aside, div, h3, header, section, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled)
import Html.Events exposing (onClick)
import Rules.Placement
import Rules.Shadow
import Views.Common as Common


type alias Puzzle =
    MainPuzzle (Placement Cutout ShadowSlot)


view : World -> Puzzle -> Maybe Notice -> List (Html Msg)
view world puzzle notice =
    let
        reviewing =
            Common.reviewedViolations puzzle.attempts

        numbered =
            Common.numbered reviewing

        isReviewing =
            not (List.isEmpty reviewing)

        config =
            placementConfig puzzle isReviewing
    in
    [ div [ class "board-scene stage-scene" ]
        [ Common.topbar "1973"
            "The Shadow Story"
            (Common.attemptsDisplay puzzle.attempts
                :: Common.lastTryNotes "Back to the stage" puzzle.attempts
                ++ help
                ++ [ Common.closePanel (not isReviewing) ]
            )
        , section [ class "story-stage", attribute "aria-label" "Shadow stage" ]
            (List.map (scenePanel world config numbered) Rules.Shadow.scenes)
        , aside [ class "side" ]
            [ div [ class "paper-note" ]
                [ h3 [ class "paper-note__title" ] [ text "Before the show" ]
                , div [ class "side-clues" ] (List.map (Common.clueNote world puzzle.inspected) clues)
                ]
            , Common.statusLine notice (hint puzzle isReviewing)
            , Common.primaryButton [ disabled isReviewing, onClick Submit ] "Perform the story"
            ]
        , if isReviewing then
            Common.feedback
                { title = "The story didn’t hold together. Here’s what went wrong:"
                , note = "You have one more try. Your cut-outs stay where they are."
                }
                numbered

          else
            PlacementUI.tray config
        ]
    ]


clues : List ClueId
clues =
    [ ShadowScript, StageSketch, CutoutBox ]


help : List (Html Msg)
help =
    Common.helpButton "Back to the stage"
        [ "Click a cut-out to pick it up, then click a space in a scene. Click a filled space to swap."
        , "Each scene takes one character and one prop, and every cut-out is used once."
        , "Read the script, the sketch and the box as often as you like. Looking and rearranging never costs an attempt."
        , "When every space is filled, press Perform the story. You have two attempts."
        ]


placementConfig : Puzzle -> Bool -> PlacementUI.Config Cutout ShadowSlot Msg
placementConfig puzzle isReviewing =
    { toMsg = StageMove
    , enabled = not isReviewing
    , placement = puzzle.arrangement
    , items = Rules.Shadow.allCutouts
    , name = Content.Shadow.cutoutName
    , cardClass = \_ -> "cutout"
    , cardBody = cutoutBody
    , marks = \_ -> []
    }


cutoutBody : Cutout -> List (Html Msg)
cutoutBody cutout =
    [ Art.cutout cutout
    , span [ class "cutout__name" ] [ text (Content.Shadow.cutoutName cutout) ]
    ]


{-| The setting is the stage sketch's label for the panel. The performance
captions belong to the slideshow, so they never show while arranging. Marks
appear only after a submission, on the scenes the feedback names.
-}
scenePanel : World -> PlacementUI.Config Cutout ShadowSlot Msg -> List ( String, Violation ) -> Scene -> Html Msg
scenePanel world config numbered scene =
    let
        setting =
            (Content.Shadow.scene world.scriptVariant scene).setting

        marks =
            List.filterMap
                (\( mark, violation ) ->
                    if violation == SceneConflictsWithScript scene then
                        Just mark

                    else
                        Nothing
                )
                numbered

        space kind slotId =
            div [ class "story-panel__space" ]
                [ span [ class "story-panel__kind" ] [ text kind ]
                , PlacementUI.slot config (sceneName scene ++ ", " ++ String.toLower kind) slotId
                ]
    in
    section
        [ classList [ ( "story-panel", True ), ( "is-flagged", not (List.isEmpty marks) ) ]
        , attribute "aria-label" (sceneName scene ++ ": " ++ setting)
        ]
        [ header [ class "story-panel__head" ]
            (List.map (\mark -> span [ class "mark mark--inline" ] [ text mark ]) marks
                ++ [ span [ class "story-panel__number" ] [ text (sceneName scene) ]
                   , span [ class "story-panel__setting" ] [ text setting ]
                   ]
            )
        , div [ class "story-panel__sheet" ]
            [ space "Character" (CharacterSlot scene)
            , space "Prop" (PropSlot scene)
            ]
        ]


hint : Puzzle -> Bool -> String
hint puzzle isReviewing =
    let
        unplaced =
            List.length (Rules.Placement.inTray Rules.Shadow.allCutouts puzzle.arrangement)
    in
    if isReviewing then
        "Read the notes below, then try again."

    else
        case puzzle.arrangement.selected of
            Just cutout ->
                "Click a space for the " ++ String.toLower (Content.Shadow.cutoutName cutout) ++ "."

            Nothing ->
                if unplaced == 0 then
                    "Every cut-out has a place. Perform the story when you’re ready."

                else
                    String.fromInt unplaced ++ " in the tray. Click a cut-out, then click a space in a scene."
