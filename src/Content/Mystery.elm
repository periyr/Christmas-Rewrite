module Content.Mystery exposing (candidate)

{-| The four 1998 candidate books. Every tab describes the book plainly, and
no candidate is written up as more special than the others.

Which clues each one matches (brief section 6):

    A illustrated edition: picture yes, sentence yes, inscription yes
    B school edition:      picture yes, sentence yes, “For Peter, love Dad”
    C River Stories:       picture yes, different passage, inscription yes
    D plain edition:       snowy wood, sentence yes, inscription yes

The illustration wording matches public/assets: A, B and C share
illustration-fox-bridge.svg, D uses illustration-fox-wood.svg.

-}

import Domain exposing (CandidateContent, CandidateId(..))


candidate : CandidateId -> CandidateContent
candidate candidateId =
    case candidateId of
        CandidateA ->
            { label = "Fox and Lantern, illustrated edition"
            , cover = "Cloth cover, its gilt title rubbed thin. Inside is a full-page picture: a fox carrying a lantern beneath a stone bridge."
            , text = "“…so the fox walked on through the falling snow. The lantern stayed lit until the last traveller came home.”"
            , dedication = "Handwritten in blue ink inside the front cover: “For Lucy, love Mum.”"
            }

        CandidateB ->
            { label = "Fox and Lantern, school edition"
            , cover = "Stiff card cover with a library stamp. Inside is a full-page picture: a fox carrying a lantern beneath a stone bridge."
            , text = "“…so the fox walked on through the falling snow. The lantern stayed lit until the last traveller came home.” Below it: Questions for the class."
            , dedication = "Handwritten in blue ink inside the front cover: “For Peter, love Dad.”"
            }

        CandidateC ->
            { label = "River Stories, anthology"
            , cover = "A thick collection with a faded spine. One story has a full-page picture: a fox carrying a lantern beneath a stone bridge."
            , text = "“…the river ran high that night, so the fox sat by the water and waited for morning.”"
            , dedication = "Handwritten in blue ink inside the front cover: “For Lucy, love Mum.”"
            }

        CandidateD ->
            { label = "Fox and Lantern, plain edition"
            , cover = "Paper cover, corners soft with use. Inside is a full-page picture: a fox carrying a lantern through a snowy wood."
            , text = "“…so the fox walked on through the falling snow. The lantern stayed lit until the last traveller came home.”"
            , dedication = "Handwritten in blue ink inside the front cover: “For Lucy, love Mum.”"
            }
