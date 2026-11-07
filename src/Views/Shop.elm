module Views.Shop exposing (ending, introduction, openingDiary, presentHub, returning, unbuiltChapter)

{-| The room-based screens: introduction, present hub, diary openings, endings,
and the temporary screen for chapters that aren't built yet.
-}

import Components.Art as Art
import Content.Clues
import Content.Diaries
import Content.Endings
import Content.Intro
import Domain exposing (..)
import Html exposing (Attribute, Html, button, div, footer, h2, h3, header, p, section, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled, style, type_)
import Html.Events exposing (onClick)
import Timeline
import Views.Common as Common
import Views.Labels exposing (eraYear)


{-| A labelled button placed over the room. Labels are always visible, so no
clue depends on pixel-hunting.
-}
hotspot : ( String, String ) -> String -> Msg -> Html Msg
hotspot ( left, top ) label msg =
    button [ type_ "button", class "hotspot", at left top, onClick msg ] [ text label ]


at : String -> String -> Attribute msg
at left top =
    style "inset" (top ++ " auto auto " ++ left)


advanceButton : String -> Html Msg
advanceButton label =
    button [ type_ "button", class "btn", onClick Advance ] [ text label ]


introduction : World -> IntroStep -> List (Html Msg)
introduction world step =
    let
        clueSpot position clue =
            hotspot position (Content.Clues.clue world clue).title (Inspect clue)
    in
    [ Art.room
    , clueSpot ( "3.5rem", "27.5rem" ) ClosureNotice
    , clueSpot ( "66rem", "23.25rem" ) FamilyPhotograph
    , Common.narration (Content.Intro.step step)
        (advanceButton
            (case step of
                PackingUp ->
                    "Open the box"

                DiariesFound ->
                    "Wish for one more chance"

                ClockStopped ->
                    "Look at the diaries"
            )
        )
    ]


presentHub : World -> History -> List (Html Msg)
presentHub world history =
    let
        propSpot position prop =
            hotspot position (Content.Clues.clue world (HubProp prop)).title (Inspect (HubProp prop))

        line =
            case world.nextDiary of
                Just era ->
                    "The " ++ eraYear era ++ " diary is glowing on the counter."

                Nothing ->
                    "All three diaries are closed."
    in
    [ Art.room
    , propSpot ( "11rem", "7.5rem" ) RoofAndShelves
    , propSpot ( "34.25rem", "29.5rem" ) CommunityWall
    , propSpot ( "11rem", "20rem" ) OrderDesk
    , div [ class "diaries" ] (List.map (diary world history) Timeline.eras)
    , div [ class "narration" ] [ p [] [ text line ] ]
    ]


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
        , onClick OpenNextDiary
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
        , buttonLabel = "Step into " ++ eraYear era
        , onPress = Advance
        }
    ]


{-| The contract has no Content function for this moment, so the words live here
for now.
-}
returning : List (Html Msg)
returning =
    [ Art.room
    , Common.narration
        { title = "Back to the present"
        , paragraphs = [ "The pages settle. The room changes back around Edwin, and the clock still hasn’t moved." ]
        }
        (advanceButton "Look around the shop")
    ]


{-| Development only. Deliberately offers no Submit, because the 1973 and 1998
validators are still stubs that would stop the app.
-}
unbuiltChapter : Era -> List (Html Msg)
unbuiltChapter era =
    [ Art.room
    , div [ class "overlay" ]
        [ div [ class "sheet" ]
            [ div [ class "sheet__head" ]
                [ h2 [ class "sheet__title" ] [ text (eraYear era ++ " isn’t built yet") ]
                , span [ class "sample-tag" ] [ text "Development placeholder" ]
                ]
            , div [ class "sheet__body" ]
                [ p [] [ text "This chapter’s screen comes in a later milestone." ]
                , p [] [ text "Reload the page to start a new game." ]
                ]
            ]
        ]
    ]


{-| Not reachable until the 1973 and 1998 chapters can be resolved. -}
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
            h3 [] [ text document.title ]
                :: List.map (\paragraph -> p [] [ text paragraph ]) document.paragraphs

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
