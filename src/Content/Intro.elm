module Content.Intro exposing (step)

{-| The opening sequence, in short beats (about 120 words across all three steps).
-}

import Domain exposing (Document, IntroStep(..))


step : IntroStep -> Document
step introStep =
    case introStep of
        PackingUp ->
            { title = "Christmas Eve"
            , paragraphs =
                [ "Snow at the window. Hale’s Bookshop is nearly empty."
                , "Edwin Hale tapes up another box. After four generations, the shop closes for good tonight."
                , "The closure notice is already in the window. The family photograph still hangs on the wall."
                , "One box is left, beneath the counter."
                ]
            }

        DiariesFound ->
            { title = "Three diaries"
            , paragraphs =
                [ "Inside are three diaries."
                , "Walter’s, from 1950. Henry’s, from 1973. And Edwin’s own journal from 1998, which he had forgotten he ever kept."
                , "Each one, in a different hand, says the same thing: “I thought we had more time.”"
                ]
            }

        ClockStopped ->
            { title = "Just before midnight"
            , paragraphs =
                [ "“Just one more chance,” Edwin says to the empty shop."
                , "The clock stops a minute before midnight."
                , "On the counter, the oldest diary begins to glow."
                ]
            }
