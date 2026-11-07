module Content.Diaries exposing (passage)

{-| Diary passages read in the present. Each era has an original version
(NotRevisited, the history Edwin starts with) and versions for a replayed
chapter that failed or succeeded. Later diaries mention earlier outcomes.

Variants follow Timeline.deriveWorld: an unrevisited earlier chapter counts as
the original, failed history.

-}

import Domain exposing (Document, Era(..), Foundation(..), World)


passage : World -> Era -> Document
passage world era =
    case era of
        Repairs1950 ->
            { title = "Walter’s diary, 1950"
            , paragraphs = walter world.premises
            }

        Shadows1973 ->
            { title = "Henry’s diary, 1973"
            , paragraphs = [ henry world.tradition, henryScript world.premises ]
            }

        Search1998 ->
            { title = "Edwin’s journal, 1998"
            , paragraphs = [ edwin world.onlineService, edwinReading world.tradition ]
            }



-- 1950


walter : Foundation -> List String
walter premises =
    case premises of
        NotRevisited ->
            [ "Christmas Eve, 1950. Five years since the war ended, and the shop is still a mess. The licence for wood planks finally came through. Four planks and £10 for the whole week. I spent it on a grand new sign for the reopening. It looked wonderful. Then Wednesday’s rain came through the roof onto every book we’d saved."
            , "I thought we had more time."
            ]

        Missing ->
            [ "Christmas Eve, 1950. Five years since the war ended, and the shop is still not right. Four planks and £10 for the whole week. I planned every day of it, and still one job tangled into the next. We opened on Saturday half-ready, and the damp crept into the back room where the old papers are kept."
            , "I thought we had more time."
            ]

        Established ->
            [ "Christmas Eve, 1950. Five years since the war ended, and at last the shop looks like a shop. Four planks and £10 for the whole week, so I spent them on what mattered. The roof was patched before Wednesday’s rain, and not a drop reached the books. New shelves, a whole window, and every book we saved back where it belongs."
            , "The sign can wait. We had time after all."
            ]



-- 1973


henry : Foundation -> String
henry tradition =
    case tradition of
        NotRevisited ->
            "Christmas Eve, 1973. Another power cut. The lights went out halfway through the children’s reading, and I sent everyone home. What could we do in the dark? Ruth had brought her little girl, Lucy. I watched them go. I thought we had more time."

        Missing ->
            "Christmas Eve, 1973. The lights went out during the reading, so we tried a shadow story with a torch and a sheet. The scenes came out muddled, and one by one the families drifted home. Ruth and Lucy stayed to the end, kindly. We never tried it again."

        Established ->
            "Christmas Eve, 1973. The lights went out during the reading, so we made a stage from a torch, a sheet and some cardboard. Scene by scene, the story came alive. Nobody went home early. Lucy, Ruth’s little girl, asked if we could do it again next year. We will."


henryScript : Foundation -> String
henryScript premises =
    case premises of
        Established ->
            "Dad’s roof has kept the back room dry since 1950, so his old shadow-story script is still safe in its tin."

        _ ->
            "Dad’s old shadow-story script was spoiled by the damp after 1950. The neighbours still know the story, though they tell it their own way."



-- 1998


edwin : Foundation -> String
edwin onlineService =
    case onlineService of
        NotRevisited ->
            "December 1998. Everyone says the internet will finish shops like ours. Maybe they’re right. Today an email asked us to find one particular old book. It would take days of searching, so I left it unanswered. I thought we had more time."

        Missing ->
            "December 1998. Ruth asked us to find a book her daughter Lucy once loved. I searched the shelves and sent one, and it was the wrong copy. Ruth wrote back kindly. I never offered to look again, and the idea went no further."

        Established ->
            "December 1998. Ruth asked us to find a book her daughter Lucy once loved, and we found it: the right picture, the right line, the right inscription. Dad and I put a page on the web the next day. The emails haven’t stopped."


edwinReading : Foundation -> String
edwinReading tradition =
    case tradition of
        Established ->
            "Dad still puts on the shadow story every Christmas, as he has since 1973. Half the town grew up on it."

        _ ->
            "There has been no Christmas reading here since the lights went out in 1973, and the children’s corner is a storeroom now."
