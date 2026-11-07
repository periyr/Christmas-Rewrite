module Content.Slides exposing (slide)

{-| Slideshow text after a chapter resolves (see Timeline.slides).

  - WeekdaySlide: one per day of a successful 1950 week, in submitted order.
    Wednesday always adds the rain. Every TaskId is covered, though only the
    five essential jobs appear in a valid week.
  - ReopeningSaturday, PerformanceSlide, ServiceFoundedSlide: success.
  - ConsequenceSlide: the first recorded violation of a failed chapter.

-}

import Content.Shadow as Shadow
import Content.Words exposing (dayName, sceneName)
import Domain exposing (Day(..), Document, Era(..), ReopeningGoal(..), RememberedDetail(..), Scene(..), Slide(..), TaskId(..), Violation(..), World)


slide : World -> Slide -> Document
slide world shown =
    case shown of
        WeekdaySlide day task ->
            { title = dayName day
            , paragraphs =
                weekday day task
                    :: (if day == Wednesday then
                            [ "In the afternoon the rain comes, hard and cold. The roof holds. Not a drop reaches the books." ]

                        else
                            []
                       )
            }

        ReopeningSaturday ->
            { title = "Saturday: reopening day"
            , paragraphs =
                [ "The door opens at nine. Neighbours come in out of the cold to a dry roof, a whole window and full shelves."
                , "A man from the newspaper photographs a little girl called Ruth, curled up in the window seat with a book."
                , "That night Walter writes: we had just enough time."
                ]
            }

        PerformanceSlide scene _ ->
            { title = sceneName scene ++ ": " ++ (Shadow.scene world.scriptVariant scene).setting
            , paragraphs =
                (Shadow.scene world.scriptVariant scene).caption
                    :: (if scene == Scene3 then
                            [ "The torch clicks off. In the dark the children cheer, and Ruth’s daughter Lucy asks if they can do it again next Christmas. Henry promises they will." ]

                        else
                            []
                       )
            }

        ServiceFoundedSlide ->
            { title = "Lucy’s book"
            , paragraphs =
                [ "The parcel reaches Ruth in time for Christmas. Lucy knows her mother’s handwriting at once."
                , "In the new year, Henry and Edwin put a page on the web: tell us the book you remember, and we’ll find it. The first orders arrive within a week."
                ]
            }

        ConsequenceSlide era broken ->
            consequence era broken



-- 1950 WEEK


weekday : Day -> TaskId -> String
weekday day task =
    case task of
        PatchRoof ->
            "Walter hammers planks over the hole in the roof. By dusk it is patched tight."

        ClearRubble ->
            "Barrow after barrow of rubble goes out of the back door. The floor is clear at last."

        BuildShelves ->
            "New shelves go up where the rubble used to be, straight and solid."

        ShelveBooks ->
            "Shelving day. The saved books come out of their crates, ready for their new home."

        ReglazeWindow ->
            if day == Wednesday then
                "The glass arrives this morning, and by noon the window is whole again."

            else
                "The glass delivered on Wednesday goes into the window. No more draught."

        PaintSign ->
            "Walter paints a grand new sign for the front of the shop."

        BoardUpWindow ->
            "Planks go over the broken window. It isn’t pretty, but it keeps the weather out."



-- FAILURE CONSEQUENCES


consequence : Era -> Violation -> Document
consequence era broken =
    case era of
        Repairs1950 ->
            { title = "The week goes wrong"
            , paragraphs =
                [ repairConsequence broken
                , "On Saturday the shop opens half-ready. The damp creeps into the back room, where the family’s old papers are kept."
                ]
            }

        Shadows1973 ->
            { title = "The lights stay out"
            , paragraphs =
                [ case broken of
                    SceneConflictsWithScript scene ->
                        sceneName scene ++ " doesn’t follow the story, and the children lose the thread. One by one, the families head home into the dark."

                    _ ->
                        "The scenes don’t follow the story, and the children lose the thread. One by one, the families head home into the dark."
                , "There is no shadow story the next Christmas, or the one after."
                ]
            }

        Search1998 ->
            { title = "The wrong copy"
            , paragraphs =
                [ case broken of
                    DetailDoesNotMatch FoxLanternIllustration ->
                        "The parcel reaches Ruth, but its fox walks through a wood, not beneath a bridge. It isn’t Lucy’s copy."

                    DetailDoesNotMatch LanternSentence ->
                        "The parcel reaches Ruth, but the line Lucy remembers isn’t in it. It isn’t Lucy’s copy."

                    DetailDoesNotMatch LucyInscription ->
                        "The parcel reaches Ruth, but the inscription is for someone else. It isn’t Lucy’s copy."

                    _ ->
                        "The parcel reaches Ruth, but it isn’t Lucy’s copy."
                , "Ruth writes a kind thank-you. The idea of finding lost books for people goes no further."
                ]
            }


repairConsequence : Violation -> String
repairConsequence broken =
    case broken of
        RoofAfterRain day ->
            "Wednesday’s rain pours through the roof onto the saved books. Patching it on " ++ dayName day ++ " is too late."

        GoalMissing WatertightRoof ->
            "Wednesday’s rain pours through the unpatched roof onto the saved books."

        GlassNotYetDelivered day ->
            "On " ++ dayName day ++ " there is no glass to fit. The window stands open, and the wind drives the rain inside."

        GoalMissing SealedWindow ->
            "The broken window is never sealed. All week the wind drives the rain inside."

        MustComeBefore ClearRubble BuildShelves ->
            "The shelves can’t go up while the rubble is still there. The planks lie unused on the floor."

        GoalMissing UsableShelves ->
            "No shelves go up, so the saved books stay stacked in damp crates."

        MustComeBefore BuildShelves ShelveBooks ->
            "On shelving day there are no shelves yet. The books end up in damp piles on the floor."

        MustComeBefore _ _ ->
            "The jobs come in the wrong order, and one can’t start until another is done."

        GoalMissing AllBooksShelved ->
            "The saved books never leave their crates, and the damp gets into them."

        TimberOverspent _ ->
            "The wood planks run out mid-week, with a job left half-built."

        MoneyOverspent _ ->
            "The money runs out mid-week, with a job left half-done."

        SceneConflictsWithScript _ ->
            "The week doesn’t go to plan."

        DetailDoesNotMatch _ ->
            "The week doesn’t go to plan."
