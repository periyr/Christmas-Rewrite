module Views.Shop exposing (ending, introduction, openingDiary, presentHub, returning)

{-| What the room-based screens add to the room: introduction, present hub,
diary openings and endings.
-}

import Components.Art as Art
import Content.Diaries
import Content.Endings
import Content.Intro
import Domain exposing (..)
import Html exposing (Html, button, div, footer, h2, h3, header, p, section, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled, type_)
import Html.Events exposing (onClick)
import Timeline
import Views.Common as Common
import Views.Labels exposing (eraYear)
import Views.Room


advanceButton : String -> Html Msg
advanceButton label =
    button [ type_ "button", class "btn", onClick Advance ] [ text label ]


{-| While packing up the player walks: the box is a hotspot, so the words move to
the top of the room and nothing here advances the story.
-}
introduction : IntroStep -> List (Html Msg)
introduction step =
    let
        narrate buttonLabel =
            [ Common.narration (Content.Intro.step step) (advanceButton buttonLabel) ]
    in
    case step of
        PackingUp ->
            [ Common.roomNote (Content.Intro.step step) ]

        DiariesFound ->
            narrate "Wish for one more chance"

        ClockStopped ->
            narrate "Look at the diaries"


presentHub : World -> History -> Views.Room.Scene
presentHub world history =
    let
        emptyScene =
            Views.Room.emptyScene
    in
    { emptyScene
        | behind = [ div [ class "diaries" ] (List.map (diary world history) Timeline.eras) ]
        , line =
            Just
                (case world.nextDiary of
                    Just era ->
                        "The " ++ eraYear era ++ " diary is glowing on the counter."

                    Nothing ->
                        "All three diaries are closed."
                )
    }


diary : World -> History -> Era -> Html Msg
diary world history era =
    let
        isNext =
            world.nextDiary == Just era

        owner =
            case era of
                Repairs1950 ->
                    "Walter’s diary"

                Shadows1973 ->
                    "Henry’s diary"

                Search1998 ->
                    "Edwin’s journal"

        state =
            if isNext then
                "open"

            else if Timeline.recordFor era history /= Nothing then
                "closed"

            else
                "waiting"
    in
    button
        [ type_ "button"
        , classList [ ( "diary", True ), ( "is-glowing", isNext ) ]
        , attribute "aria-label" (owner ++ ", " ++ eraYear era ++ ": " ++ state)
        , disabled (not isNext)
        , onClick (ApproachHotspot DiarySpot)
        ]
        [ Art.diaryCover era
        , span [ class "diary__year" ] [ text (eraYear era) ]
        ]


openingDiary : World -> Era -> List (Html Msg)
openingDiary world era =
    [ Art.room
    , Common.documentSheet
        { variant = "sheet--diary"
        , document = Content.Diaries.passage world era
        , picture = Nothing
        , buttonLabel = "Step into " ++ eraYear era
        , onPress = Advance
        }
    ]


{-| The contract has no Content function for this moment, so the words live here
for now.
-}
returning : List (Html Msg)
returning =
    [ Common.narration
        { title = "Back to the present"
        , paragraphs = [ "The pages settle. The room changes back around Edwin, and the clock still hasn’t moved." ]
        }
        (advanceButton "Look around the shop")
    ]


{-| The fate of the shop once all three chapters are resolved. A closed shop
lists what each failed chapter left missing, under that chapter's heading; the
saved ending is one document, already titled by the sheet.
-}
ending : World -> List (Html Msg)
ending world =
    let
        documents =
            case world.fate of
                Just (ShopClosed failedEras) ->
                    List.map Content.Endings.missing failedEras

                _ ->
                    [ Content.Endings.saved ]

        section_ document =
            (if document.title == title then
                []

             else
                [ h3 [] [ text document.title ] ]
            )
                ++ List.map (\paragraph -> p [] [ text paragraph ]) document.paragraphs

        title =
            case world.fate of
                Just (ShopClosed _) ->
                    "The shop closes"

                _ ->
                    Content.Endings.saved.title

        reopen era =
            button [ type_ "button", class "btn", onClick (ReopenDiary era) ] [ text ("Reopen " ++ eraYear era) ]
    in
    [ Art.room
    , div [ class "overlay" ]
        [ section [ class "sheet", attribute "role" "dialog", attribute "aria-modal" "true" ]
            [ header [ class "sheet__head" ] [ h2 [ class "sheet__title" ] [ text title ] ]
            , div [ class "sheet__body" ] (List.concatMap section_ documents)
            , footer [ class "sheet__foot sheet__foot--ending" ]
                (List.map reopen Timeline.eras
                    ++ [ button [ type_ "button", class "btn", onClick StartAgain ] [ text "Start again" ] ]
                )
            ]
        ]
    ]
