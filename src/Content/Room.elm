module Content.Room exposing (label)

{-| Short verb phrases for the walking room (contract v1.3): the proximity
prompt ("E: Read the closure notice") and each hotspot's accessible name.

Every hotspot has its own phrase, clue spots included. `label` takes no World,
so it can't reuse clue titles that change with history; these phrases read
the same under every history. None of them hints at an answer.

-}

import Content.Mystery as Mystery
import Domain exposing (BookTab(..), ClueId(..), Hotspot(..), HubProp(..))


label : Hotspot -> String
label hotspot =
    case hotspot of
        ClueSpot clue ->
            clueLabel clue

        BoxSpot ->
            "Open the box beneath the counter"

        DiarySpot ->
            "Open the glowing diary"

        CratesSpot ->
            "Sort the salvaged books"

        BoardSpot ->
            "Plan the repair week"

        ShelfSpot ->
            "Arrange the reopening shelf"

        StageSpot ->
            "Set up the shadow stage"

        BookTableSpot ->
            "Compare the four books"

        BrokenGlassSpot ->
            "Pick up the broken glass"


clueLabel : ClueId -> String
clueLabel clue =
    case clue of
        ClosureNotice ->
            "Read the closure notice"

        FamilyPhotograph ->
            "Look at the family photograph"

        HubProp RoofAndShelves ->
            "Look up at the roof and shelves"

        HubProp CommunityWall ->
            "Look at the community wall"

        HubProp OrderDesk ->
            "Look at the order desk"

        WalterDiaryPage ->
            "Read Walter's diary page"

        GlassDeliverySlip ->
            "Read the glass delivery slip"

        RubbleAndShelvesNote ->
            "Read Walter's repair notes"

        BudgetAllocation ->
            "Check the wood planks and cash"

        ShelfPlaque ->
            "Read the shelf plaque"

        ShadowScript ->
            "Read the shadow-story script"

        StageSketch ->
            "Look at the stage sketch"

        CutoutBox ->
            "Look in the box of cut-outs"

        RuthsEmail ->
            "Read Ruth's email"

        RememberedSentence ->
            "Read the line Lucy remembers"

        InscriptionClue ->
            "Check the note about the inscription"

        CandidatePage candidate tab ->
            tabVerb tab ++ (Mystery.candidate candidate).label


tabVerb : BookTab -> String
tabVerb tab =
    case tab of
        CoverTab ->
            "Look at the picture in "

        TextTab ->
            "Read the text of "

        DedicationTab ->
            "Read the dedication in "
