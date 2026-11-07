module Content.Endings exposing (missing, saved)

{-| The two endings. `saved` when all three foundations hold; otherwise one
`missing` document per failed era (ShopClosed lists them in era order).
Each missing document stands on its own and keeps the shop's good work in view.
-}

import Domain exposing (Document, Era(..))


saved : Document
saved =
    { title = "One more Christmas"
    , paragraphs =
        [ "The clock starts again. Midnight."
        , "Walter’s roof still holds. The wall is crowded with decades of shadow-story posters. The order desk is stacked with parcels for tomorrow."
        , "Edwin turns the sign on the door to OPEN."
        , "The bell rings. Ruth comes in out of the snow, slower now, with Lucy beside her and Lucy’s daughter holding a fox-and-lantern book."
        , "There was time after all."
        ]
    }


missing : Era -> Document
missing era =
    case era of
        Repairs1950 ->
            { title = "The repair week, 1950"
            , paragraphs =
                [ "The roof and shelves were never put right, and the damp took the family archive. Hale’s carried on for years on uncertain ground."
                , "Still, a whole town learned to read on its crooked shelves."
                ]
            }

        Shadows1973 ->
            { title = "The shadow story, 1973"
            , paragraphs =
                [ "The Christmas shadow story never became a tradition. The children who might have grown up with the shop grew up somewhere else."
                , "Some of them still remember the night the lights went out, and the shop that tried."
                ]
            }

        Search1998 ->
            { title = "The forgotten book, 1998"
            , paragraphs =
                [ "Hale’s never learned to find books for people far away. The shop stayed only as big as its front door, and in the end that wasn’t enough."
                , "Ruth never forgot that someone at Hale’s had tried."
                ]
            }
