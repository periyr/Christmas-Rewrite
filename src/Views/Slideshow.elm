module Views.Slideshow exposing (stageAttributes, view)

{-| The week's playback. The model owns the position: this only draws the slide
it points at and sends Advance.
-}

import Components.Art as Art
import Content.Slides
import Domain exposing (..)
import Html exposing (Attribute, Html, button, text)
import Html.Attributes exposing (attribute, class, type_)
import Html.Events exposing (onClick)
import Timeline
import Views.Common as Common


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
    [ Art.room
    , Common.narration document (button [ type_ "button", class "btn", onClick Advance ] [ text label ])
    ]


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
