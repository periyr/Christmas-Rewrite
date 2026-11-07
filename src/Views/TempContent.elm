module Views.TempContent exposing
    ( book, clue, diaryPassage, goal, introStep, notice, returningToPresent, shelfMatched, slide, taskCard, violation
    )

{-| TEMPORARY stand-in for Person C’s Content modules, which don’t exist yet.

Delete this file when they land. The functions match the signatures proposed in
CONTRACT.md, so views only need their imports changed:

    book               -> Content.Books.book
    clue               -> Content.Clues.clue
    diaryPassage       -> Content.Diaries.passage
    goal               -> Content.Repair.goal
    introStep          -> Content.Intro.step
    notice             -> Content.Feedback.notice
    shelfMatched       -> Content.Shelf.matched
    slide              -> Content.Slides.slide
    taskCard           -> Content.Repair.taskCard
    violation          -> Content.Feedback.violation

`returningToPresent` has no proposed Content function yet.

Wording follows the shared brief where the brief has it (Walter’s diary is exact).
Screens show a "Draft text" tag while they read from this module.

-}

import Domain exposing (..)
import Views.Labels exposing (dayName, eraYear)


introStep : IntroStep -> Document
introStep step =
    case step of
        PackingUp ->
            { title = "Christmas Eve"
            , paragraphs = [ "Edwin Hale is packing up the shop for the last time. There is one box left, beneath the counter." ]
            }

        DiariesFound ->
            { title = "Three diaries"
            , paragraphs = [ "Inside are three diaries: Walter’s, Henry’s and Edwin’s own. Each contains the same sentence: “I thought we had more time.”" ]
            }

        ClockStopped ->
            { title = "Just before midnight"
            , paragraphs = [ "Edwin wishes for one more chance. The clock stops just before midnight, and the oldest diary begins to glow." ]
            }


diaryPassage : World -> Era -> Document
diaryPassage _ era =
    case era of
        Repairs1950 ->
            { title = "Walter’s diary"
            , paragraphs = [ walterDiary ]
            }

        Shadows1973 ->
            { title = "Henry’s diary"
            , paragraphs = [ "1973. The power went out during the Christmas reading. I sent the children home, because I thought nothing could be done without lights." ]
            }

        Search1998 ->
            { title = "Edwin’s journal"
            , paragraphs = [ "1998. I keep thinking the internet will make a shop like ours irrelevant. An email came in with a request that seemed too difficult, and I dismissed it." ]
            }


walterDiary : String
walterDiary =
    "“Christmas Eve, 1950. Five years since the war ended, and the shop is still a mess. The timber licence finally came through. Four planks and £10 for the whole week. I spent it on a grand new sign for the reopening. It looked wonderful. Then Wednesday’s rain came through the roof onto every book we’d saved.”"


clue : World -> ClueId -> Document
clue world clueId =
    case clueId of
        ClosureNotice ->
            { title = "Closure notice"
            , paragraphs = [ "Hale’s Bookshop will close its doors for the last time this Christmas." ]
            }

        FamilyPhotograph ->
            { title = "Family photograph"
            , paragraphs = [ "Four generations of the Hale family outside the shop: the founder, Walter, Henry and a young Edwin." ]
            }

        HubProp RoofAndShelves ->
            { title = "Roof and shelves"
            , paragraphs =
                [ case world.premises of
                    NotRevisited ->
                        "The old stain on the ceiling, and shelves that have never quite recovered from the war."

                    Established ->
                        "The roof has held since 1950, and the shelves Walter built are still in use."

                    Missing ->
                        "The ceiling still shows where Wednesday’s rain came through in 1950. The stock never fully recovered."
                ]
            }

        HubProp CommunityWall ->
            { title = "Community wall"
            , paragraphs = [ "A bare patch of wall. Nothing has been pinned here for years." ]
            }

        HubProp OrderDesk ->
            { title = "Order desk"
            , paragraphs = [ "A tidy desk with no parcels waiting." ]
            }

        WalterDiaryPage ->
            { title = "Walter’s diary", paragraphs = [ walterDiary ] }

        GlassDeliverySlip ->
            { title = "Glass delivery slip"
            , paragraphs =
                [ "Goods: window glass, 1 pane."
                , "To: Hale’s Bookshop."
                , "Delivery day: Wednesday. Cannot be delivered earlier in the week."
                ]
            }

        RubbleAndShelvesNote ->
            { title = "Repair notes"
            , paragraphs =
                [ "The new shelves go where the rubble is now, so it has to be cleared before they can be built."
                , "The books can’t go back until there are shelves to put them on."
                ]
            }

        BudgetAllocation ->
            { title = "Timber licence"
            , paragraphs = [ "Allowed for the whole week: 4 planks of timber and £10. Anything left over may stay unspent." ]
            }

        ShelfPlaque ->
            { title = "Shelf plaque"
            , paragraphs =
                [ "Small to tall / rainbow / A–Z."
                , "Rainbow runs red, orange, yellow, green, blue, violet."
                ]
            }

        _ ->
            { title = "Not written yet", paragraphs = [ "This clue belongs to a later chapter." ] }


taskCard : TaskId -> TaskCardContent
taskCard task =
    case task of
        PatchRoof ->
            { title = "Patch the roof", note = "" }

        ClearRubble ->
            { title = "Clear the rubble", note = "" }

        BuildShelves ->
            { title = "Build shelves", note = "" }

        ShelveBooks ->
            { title = "Shelve the books", note = "" }

        ReglazeWindow ->
            { title = "Re-glaze the window", note = "" }

        PaintSign ->
            { title = "Paint a grand new sign", note = "" }

        BoardUpWindow ->
            { title = "Board up the window", note = "" }


goal : ReopeningGoal -> String
goal reopeningGoal =
    case reopeningGoal of
        WatertightRoof ->
            "A watertight roof"

        SealedWindow ->
            "A sealed window"

        UsableShelves ->
            "Usable shelves"

        AllBooksShelved ->
            "All recovered books shelved"


{-| The damage lists are placeholder data that C needs to confirm. -}
book : BookId -> BookContent
book bookId =
    case bookId of
        Recoverable AtlasOfSmallPlaces ->
            { title = "Atlas of Small Places", damage = [] }

        Recoverable BirdsongForBeginners ->
            { title = "Birdsong for Beginners", damage = [ SmokeStains ] }

        Recoverable GardensInWinter ->
            { title = "Gardens in Winter", damage = [ WaterStains ] }

        Recoverable LettersFromTheSea ->
            { title = "Letters from the Sea", damage = [ SmokeStains, WaterStains ] }

        Recoverable PocketOfWonders ->
            { title = "Pocket of Wonders", damage = [] }

        Recoverable WinterTales ->
            { title = "Winter Tales", damage = [] }

        Ruined HarbourTales ->
            { title = "Harbour Tales", damage = [ ScorchedEdges, MissingPages ] }

        Ruined MountainPaths ->
            { title = "Mountain Paths", damage = [ WaterStains, MissingPages ] }

        Ruined WinterAlmanac ->
            { title = "Winter Almanac", damage = [ ScorchedEdges, MissingPages ] }


shelfMatched : ShelfOrder -> String
shelfMatched order =
    case order of
        ByHeight ->
            "Small to tall! The shelf rises like a little staircase."

        ByColour ->
            "A rainbow! The whole shop looks brighter for it."

        Alphabetical ->
            "A to Z! Any customer could find their book now."


violation : Violation -> String
violation broken =
    case broken of
        RoofAfterRain Wednesday ->
            "The roof came too late. Patching it on Wednesday didn’t beat the rain."

        RoofAfterRain day ->
            "The roof came too late. " ++ dayName day ++ " is after Wednesday’s rain."

        GlassNotYetDelivered day ->
            "The glass wasn’t here. It can’t be fitted on " ++ dayName day ++ ", before it’s delivered."

        MustComeBefore ClearRubble BuildShelves ->
            "Rubble in the way. Build shelves needs Clear the rubble on an earlier day."

        MustComeBefore BuildShelves ShelveBooks ->
            "Nowhere to put the books. Shelve the books needs Build shelves on an earlier day."

        MustComeBefore _ _ ->
            "These jobs are in the wrong order."

        TimberOverspent total ->
            "Too much timber. This week uses " ++ String.fromInt total ++ ", and the licence allows 4."

        MoneyOverspent total ->
            "Too much money. This week costs £" ++ String.fromInt total ++ ", and you have £10."

        GoalMissing WatertightRoof ->
            "The roof was never patched, so it won’t be watertight."

        GoalMissing SealedWindow ->
            "The window is still open. Nothing in this week seals it."

        GoalMissing UsableShelves ->
            "No shelves. Nothing in this week builds them."

        GoalMissing AllBooksShelved ->
            "The recovered books never made it back onto the shelves."

        SceneConflictsWithScript _ ->
            "This scene doesn’t match the script."

        DetailDoesNotMatch _ ->
            "This book doesn’t match what was remembered."


notice : Notice -> String
notice shown =
    case shown of
        IncompleteSubmission ->
            "Some cards still need a place. Give every card a place, then finish the week."

        TargetFull ->
            "That’s full. Move something out first."

        DoesNotFitThere ->
            "That doesn’t fit there."

        NotSolvedYet ->
            "Not quite yet. Keep arranging."


slide : World -> Slide -> Document
slide _ shown =
    case shown of
        WeekdaySlide day task ->
            { title = dayName day
            , paragraphs =
                [ weekdayLine task ]
                    ++ (if day == Wednesday then
                            [ "The rain arrives, just as Walter feared, and the roof holds." ]

                        else
                            []
                       )
            }

        ReopeningSaturday ->
            { title = "Saturday"
            , paragraphs = [ "The doors open. Neighbours come in out of the cold, and the shop smells of new timber and old paper." ]
            }

        ConsequenceSlide era broken ->
            { title = "The week is over"
            , paragraphs =
                [ consequenceLine broken
                , eraYear era ++ " closes. There are other years to read."
                ]
            }

        _ ->
            { title = "Not written yet", paragraphs = [ "This slide belongs to a later chapter." ] }


weekdayLine : TaskId -> String
weekdayLine task =
    case task of
        PatchRoof ->
            "Walter patches the roof with two good planks."

        ClearRubble ->
            "The rubble goes out by the barrowload, and the floor appears again."

        BuildShelves ->
            "New shelves go up along the cleared wall."

        ShelveBooks ->
            "Today the recovered books are ready to go back on the shelves."

        ReglazeWindow ->
            "The glass has come, and the window is whole again."

        PaintSign ->
            "A grand new sign goes up."

        BoardUpWindow ->
            "Boards go over the broken window."


consequenceLine : Violation -> String
consequenceLine broken =
    case broken of
        RoofAfterRain _ ->
            "Wednesday’s rain came through the roof before anyone reached it, and the shop did not open on Saturday as Walter had hoped."

        GoalMissing WatertightRoof ->
            "Nobody patched the roof. Wednesday’s rain came through onto the books they had saved."

        GlassNotYetDelivered _ ->
            "The day set aside for the window came before the glass did, and the cold came in all week."

        GoalMissing SealedWindow ->
            "The window stayed open to the weather, and the damp reached the stock."

        MustComeBefore _ _ ->
            "The jobs fell over one another, and the week ran out with the shop still in pieces."

        GoalMissing UsableShelves ->
            "With no shelves, the books stayed in crates, and customers had nothing to browse."

        GoalMissing AllBooksShelved ->
            "The books stayed in their crates, and the reopening felt like a shop with nothing to sell."

        TimberOverspent _ ->
            "The timber ran out before the work did, and the last job was left half-done."

        MoneyOverspent _ ->
            "The money ran out before the work did, and the last job was left half-done."

        _ ->
            "The week didn’t hold."


returningToPresent : Document
returningToPresent =
    { title = "Back to the present"
    , paragraphs = [ "The pages settle. The room changes back around Edwin, and the clock still hasn’t moved." ]
    }
