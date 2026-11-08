module Content.Characters exposing (person)

{-| Who the walking character is, shown when the player hovers over them.

Keyed by the diary being played: `Nothing` is present-day Edwin, `Just era` is
the person whose diary it is. Title: the name. Paragraph: how they're related
to the other two.

Family tree (brief section 2): Walter → Henry → Edwin.

-}

import Domain exposing (Document, Era(..))


person : Maybe Era -> Document
person era =
    case era of
        Nothing ->
            { title = "Edwin Hale"
            , paragraphs = [ "Henry’s son, Walter’s grandson. The shop’s owner today." ]
            }

        Just Repairs1950 ->
            { title = "Walter Hale, 1950"
            , paragraphs = [ "Henry’s dad, Edwin’s grandad." ]
            }

        Just Shadows1973 ->
            { title = "Henry Hale, 1973"
            , paragraphs = [ "Edwin’s dad, Walter’s son." ]
            }

        Just Search1998 ->
            { title = "Edwin Hale, 1998"
            , paragraphs = [ "Henry’s son, Walter’s grandson." ]
            }
