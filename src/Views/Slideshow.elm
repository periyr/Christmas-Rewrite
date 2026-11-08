module Views.Slideshow exposing (atShelvingPause, lights, stageAttributes, view)

{-| The week's playback. The model owns the position: this only draws the slide
it points at and sends Advance.
-}

import Components.Art as Art
import Components.Props as Props
import Content.Slides
import Domain exposing (..)
import Html exposing (Attribute, Html, button, text)
import Html.Attributes exposing (attribute, class, type_)
import Html.Events exposing (onClick)
import Timeline
import Views.Common as Common
import Views.Labels exposing (eraYear)


view : World -> History -> Era -> Int -> List (Html Msg)
view world history era index =
    let
        slides =
            Timeline.slides era history

        isLast =
            index + 1 >= List.length slides

        current =
            List.head (List.drop index slides)

        label =
            case current of
                Just (WeekdaySlide _ ShelveBooks) ->
                    "Shelve the books"

                Just (WeekdaySlide _ _) ->
                    "Next day"

                _ ->
                    if isLast then
                        "Return to the present"

                    else
                        "Continue"

        document =
            current
                |> Maybe.map (Content.Slides.slide world)
                |> Maybe.withDefault { title = "", paragraphs = [] }
    in
    Art.room
        :: (current |> Maybe.map (Props.forSlide Props.Animated world.scriptVariant) |> Maybe.withDefault [])
        ++ [ Common.yearBadge (eraYear era)
           , Common.narration document (button [ type_ "button", class "btn", onClick Advance ] [ text label ])
           ]


{-| The house lights go down for the shadow performance, so the torch-lit sheet
shows. Taken from the slide being shown.
-}
lights : History -> Era -> Int -> List (Attribute msg)
lights history era index =
    case List.head (List.drop index (Timeline.slides era history)) of
        Just (PerformanceSlide _ _) ->
            [ attribute "data-lights" "down" ]

        _ ->
            []


{-| The room at the shelving pause: everything done up to that day stays done,
and the books aren't up yet.
-}
atShelvingPause : History -> List (Attribute msg)
atShelvingPause history =
    let
        isShelving ( _, slide ) =
            case slide of
                WeekdaySlide _ ShelveBooks ->
                    True

                _ ->
                    False

        index =
            Timeline.slides Repairs1950 history
                |> List.indexedMap Tuple.pair
                |> List.filter isShelving
                |> List.head
                |> Maybe.map Tuple.first
                |> Maybe.withDefault 0
    in
    stageAttributes history Repairs1950 index


{-| The room changes as the week's work gets done. The tasks come from the
slides already shown, so a failed week keeps its damage.
-}
stageAttributes : History -> Era -> Int -> List (Attribute msg)
stageAttributes history era index =
    let
        slides =
            Timeline.slides era history

        shown =
            List.take (index + 1) slides

        doneIn soFar task =
            List.any
                (\slide ->
                    case slide of
                        WeekdaySlide _ shownTask ->
                            shownTask == task

                        _ ->
                            False
                )
                soFar

        done =
            doneIn shown

        isRaining =
            case List.head (List.reverse shown) of
                Just (WeekdaySlide Wednesday _) ->
                    True

                _ ->
                    False

        flag condition name value =
            if condition then
                [ attribute name value ]

            else
                []
    in
    flag (done PatchRoof) "data-roof" "patched"
        ++ flag (done ClearRubble) "data-rubble" "cleared"
        ++ flag (done BuildShelves) "data-shelves" "built"
        ++ flag (done ReglazeWindow) "data-window" "glazed"
        -- The shelving slide only leads to the shelf scene: the books are up after it.
        ++ flag (doneIn (List.take index slides) ShelveBooks) "data-books" "shelved"
        ++ flag isRaining "data-weather" "rain"
