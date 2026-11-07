module Views.Shop exposing (introduction, openingDiary, presentHub, returning, unbuiltChapter, ending)

{-| The room-based screens: introduction, present hub, diary openings, and the
temporary screens for chapters that aren't built yet.
-}

import Components.Art as Art
import Domain exposing (..)
import Html exposing (Attribute, Html, button, div, h2, p, span, text)
import Html.Attributes exposing (class, classList, disabled, style, type_)
import Html.Events exposing (onClick)
import Timeline
import Views.Common as Common
import Views.Labels exposing (eraYear)
import Views.TempContent as Content


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
            hotspot position (Content.clue world clue).title (Inspect clue)
    in
    [ Art.room
    , clueSpot ( "50rem", "9rem" ) ClosureNotice
    , clueSpot ( "8.5rem", "9rem" ) FamilyPhotograph
    , Common.narration (Content.introStep step)
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
            hotspot position (Content.clue world (HubProp prop)).title (Inspect (HubProp prop))

        line =
            case world.nextDiary of
                Just era ->
                    "The " ++ eraYear era ++ " diary is glowing on the counter."

                Nothing ->
                    "All three diaries are closed."
    in
    [ Art.room
    , propSpot ( "8.5rem", "9rem" ) RoofAndShelves
    , propSpot ( "29rem", "9rem" ) CommunityWall
    , propSpot ( "57rem", "21rem" ) OrderDesk
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
                    "Walter"

                Shadows1973 ->
                    "Henry"

                Search1998 ->
                    "Edwin"

        state =
            if isNext then
                "Open"

            else if Timeline.recordFor era history /= Nothing then
                "Closed"

            else
                "Waiting"
    in
    button
        [ type_ "button"
        , classList [ ( "diary", True ), ( "is-glowing", isNext ) ]
        , disabled (not isNext)
        , onClick OpenNextDiary
        ]
        [ span [ class "diary__owner" ] [ text owner ]
        , span [ class "diary__year" ] [ text (eraYear era) ]
        , span [ class "diary__state" ] [ text state ]
        ]


openingDiary : World -> Era -> List (Html Msg)
openingDiary world era =
    [ Art.room
    , Common.documentSheet
        { variant = "sheet--diary"
        , document = Content.diaryPassage world era
        , buttonLabel = "Step into " ++ eraYear era
        , onPress = Advance
        }
    ]


returning : List (Html Msg)
returning =
    [ Art.room
    , Common.narration Content.returningToPresent (advanceButton "Look around the shop")
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


{-| Development only. Not reachable until 1973 and 1998 can be resolved. -}
ending : World -> List (Html Msg)
ending world =
    let
        title =
            case world.fate of
                Just ShopSaved ->
                    "The shop is saved"

                _ ->
                    "The shop closes"

        reopen era =
            button [ type_ "button", class "btn", onClick (ReopenDiary era) ] [ text ("Reopen " ++ eraYear era) ]
    in
    [ Art.room
    , div [ class "overlay" ]
        [ div [ class "sheet" ]
            [ div [ class "sheet__head" ]
                [ h2 [ class "sheet__title" ] [ text title ]
                , span [ class "sample-tag" ] [ text "Development placeholder" ]
                ]
            , div [ class "sheet__foot" ]
                (List.map reopen Timeline.eras
                    ++ [ button [ type_ "button", class "btn", onClick StartAgain ] [ text "Start again" ] ]
                )
            ]
        ]
    ]
