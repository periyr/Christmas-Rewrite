module Content.Clues exposing (clue)

{-| Every inspectable clue. Text that depends on history reads the World:

  - HubProp text follows premises / tradition / onlineService.
  - ShadowScript and StageSketch follow scriptVariant.
  - RuthsEmail and InscriptionClue follow inscriptionSource.

Each variant carries every fact its puzzle needs. Clues state facts; none
says whether an arrangement is right.

-}

import Content.Mystery as Mystery
import Domain exposing (BookTab(..), CandidateId(..), ClueId(..), Document, Foundation(..), HubProp(..), InscriptionSource(..), ScriptVariant(..), World)
import Rules.Repair


clue : World -> ClueId -> Document
clue world clueId =
    case clueId of
        -- Introduction
        ClosureNotice ->
            { title = "Closure notice"
            , paragraphs =
                [ "After four generations, Hale’s Bookshop closes its doors for the last time this Christmas Eve."
                , "Thank you to everyone who ever came in out of the cold."
                ]
            }

        FamilyPhotograph ->
            { title = "Family photographs"
            , paragraphs =
                [ "Four photographs in one frame, each taken outside the shop: the founder in his apron, Walter with a hammer, Henry with an armful of books, and a young Edwin squinting into the sun."
                ]
            }

        -- Present hub
        HubProp prop ->
            hubProp world prop

        -- 1950 repair board
        WalterDiaryPage ->
            { title = "Walter’s diary"
            , paragraphs =
                [ "“Four planks and £10 for the whole week. I spent it on a grand new sign for the reopening. It looked wonderful. Then Wednesday’s rain came through the roof onto every book we’d saved.”"
                ]
            }

        GlassDeliverySlip ->
            { title = "Glass delivery slip"
            , paragraphs =
                [ "One pane of window glass for Hale’s Bookshop."
                , "Delivery: Wednesday morning. Not available any earlier in the week."
                ]
            }

        RubbleAndShelvesNote ->
            { title = "Walter’s repair notes"
            , paragraphs =
                [ "The new shelves go where the rubble is now, so the rubble must be cleared first."
                , "The books stay in their crates until there are shelves to put them on."
                ]
            }

        BudgetAllocation ->
            { title = "Wood planks and cash"
            , paragraphs =
                [ "For the whole week: "
                    ++ String.fromInt Rules.Repair.budget.timber
                    ++ " wood planks and £"
                    ++ String.fromInt Rules.Repair.budget.pounds
                    ++ "."
                , "Every job done this week comes out of this. Anything left over can stay unspent."
                ]
            }

        -- 1950 reopening shelf
        ShelfPlaque ->
            { title = "Shelf plaque"
            , paragraphs =
                [ "Small to tall / rainbow / A–Z."
                , "Rainbow runs red, orange, yellow, green, blue, violet. Any one of the three orders will do."
                ]
            }

        -- 1973
        ShadowScript ->
            shadowScript world.scriptVariant

        StageSketch ->
            stageSketch world.scriptVariant

        CutoutBox ->
            { title = "Box of cut-outs"
            , paragraphs =
                [ "Six cardboard cut-outs: a fox, an owl and a child; a lantern, a key and a book."
                , "Each scene needs one character and one prop. Every cut-out is used once."
                ]
            }

        -- 1998
        RuthsEmail ->
            ruthsEmail world.inscriptionSource

        RememberedSentence ->
            { title = "A remembered line"
            , paragraphs =
                [ "Ruth adds that Lucy can still say one line from the book by heart:"
                , "“The lantern stayed lit until the last traveller came home.”"
                ]
            }

        InscriptionClue ->
            inscription world.inscriptionSource

        CandidatePage candidateId tab ->
            candidatePage candidateId tab



-- PRESENT HUB


hubProp : World -> HubProp -> Document
hubProp world prop =
    case prop of
        RoofAndShelves ->
            { title = "Roof and shelves"
            , paragraphs =
                [ case world.premises of
                    NotRevisited ->
                        "A brown water stain has spread across the ceiling since 1950. The shelves sag, and the back-room archive smells of damp."

                    Missing ->
                        "The 1950 repairs never quite held. The ceiling is stained, the shelves are makeshift, and the old archive in the back room was lost to damp long ago."

                    Established ->
                        "The roof Walter patched in 1950 is still sound. His shelves stand straight, and the back-room archive is dry and full."
                ]
            }

        CommunityWall ->
            { title = "Community wall"
            , paragraphs =
                [ case world.tradition of
                    NotRevisited ->
                        "A bare patch of wall by the children’s corner. A few old pin holes, nothing pinned. The shop stopped doing Christmas readings long ago."

                    Missing ->
                        "One faded poster: “Christmas Reading, 1973.” Nothing after it. The shadow story was never tried again."

                    Established ->
                        "Decades of posters for the Christmas shadow story, children’s drawings of a fox with a lantern, and a 1973 photograph of Ruth with little Lucy in the front row."
                ]
            }

        OrderDesk ->
            { title = "Order desk"
            , paragraphs =
                [ case world.onlineService of
                    NotRevisited ->
                        "An empty desk and an old computer. No parcels, no orders. The shop never sold a book beyond its own front door."

                    Missing ->
                        "In the drawer, one printed email from 1998 about a book that was never quite found. No parcels waiting."

                    Established ->
                        "Parcel labels for three countries, a printer full of orders, and a framed first email from 1998: “You found Lucy’s book!”"
                ]
            }



-- 1973


shadowScript : ScriptVariant -> Document
shadowScript variant =
    case variant of
        OriginalScript ->
            { title = "The shadow-story script"
            , paragraphs =
                [ "Walter’s script, kept dry in the back room since 1950. The parts:"
                , "The child opens the book when everyone is home."
                , "The fox carries the lantern across the bridge."
                , "The owl uses the key at the door."
                ]
            }

        NeighboursRetelling ->
            { title = "The neighbours’ retelling"
            , paragraphs =
                [ "Walter’s script was lost, so the neighbours wrote down the story as they remember it. The parts:"
                , "The child finds the key at the gate."
                , "The fox carries the lantern to guide everyone home."
                , "The owl reads the book inside."
                ]
            }


stageSketch : ScriptVariant -> Document
stageSketch variant =
    case variant of
        OriginalScript ->
            { title = "Stage sketch"
            , paragraphs =
                [ "Three panels, numbered in pencil:"
                , "Scene 1: the bridge. Scene 2: the door. Scene 3: home."
                ]
            }

        NeighboursRetelling ->
            { title = "Stage sketch"
            , paragraphs =
                [ "Three panels, numbered in pencil:"
                , "Scene 1: the gate. Scene 2: inside. Scene 3: home."
                ]
            }



-- 1998


ruthsEmail : InscriptionSource -> Document
ruthsEmail source =
    case source of
        FamilyArchive ->
            { title = "Email from Ruth"
            , paragraphs =
                [ "Dear Hales, years ago we gave you Lucy’s books. She still talks about your 1973 shadow story."
                , "Her favourite showed a fox carrying a lantern beneath a stone bridge. Could you find that copy for her daughter this Christmas? Ruth"
                ]
            }

        FollowUpEmail ->
            { title = "Email from Ruth"
            , paragraphs =
                [ "Dear Hales, years ago we gave you Lucy’s books."
                , "Her favourite showed a fox carrying a lantern beneath a stone bridge. Could you find that copy for her daughter this Christmas? Ruth"
                ]
            }


inscription : InscriptionSource -> Document
inscription source =
    case source of
        FamilyArchive ->
            { title = "From the shop archive"
            , paragraphs =
                [ "A photograph from the 1973 shadow story: Ruth and Lucy in the front row."
                , "Henry’s note on the back: “Ruth writes ‘For Lucy, love Mum’ in every book she gives her.”"
                ]
            }

        FollowUpEmail ->
            { title = "Ruth’s second email"
            , paragraphs =
                [ "I forgot to say: I wrote inside the front cover, as I did in all her books, “For Lucy, love Mum.” Ruth"
                ]
            }


candidatePage : CandidateId -> BookTab -> Document
candidatePage candidateId tab =
    let
        content =
            Mystery.candidate candidateId
    in
    case tab of
        CoverTab ->
            { title = content.label ++ ": cover and picture", paragraphs = [ content.cover ] }

        TextTab ->
            { title = content.label ++ ": text", paragraphs = [ content.text ] }

        DedicationTab ->
            { title = content.label ++ ": dedication", paragraphs = [ content.dedication ] }
