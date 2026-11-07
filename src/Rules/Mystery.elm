module Rules.Mystery exposing (candidates, complete, validate)

{-| 1998 forgotten book: choose one of four candidates.
-}

import Domain exposing (CandidateId(..), Violation)


candidates : List CandidateId
candidates =
    [ CandidateA, CandidateB, CandidateC, CandidateD ]


{-| A submission once a candidate is chosen. -}
complete : Maybe CandidateId -> Maybe CandidateId
complete chosen =
    chosen


{-| NOT IMPLEMENTED YET — Person A, hours 3.5–7.
One DetailDoesNotMatch per remembered detail the candidate lacks (brief section 6).
-}
validate : CandidateId -> List Violation
validate _ =
    Debug.todo "Rules.Mystery.validate is not implemented yet"
