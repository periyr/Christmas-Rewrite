module Rules.Mystery exposing (candidates, complete, details, matches, validate)

{-| 1998 forgotten book: choose one of four candidates.

Which remembered details each candidate has (brief section 6):

    A illustrated edition: picture yes, sentence yes, inscription yes
    B school edition:      picture yes, sentence yes, inscription no ("For Peter, love Dad")
    C River Stories:       picture yes, sentence no (different passage), inscription yes
    D plain edition:       picture no (snowy wood), sentence yes, inscription yes

Only A has all three. Each wrong candidate lacks exactly one detail, and each
detail rules out exactly one candidate, so every clue is needed. The answer
does not depend on history; only where the inscription clue comes from does.

-}

import Domain exposing (CandidateId(..), RememberedDetail(..), Violation(..))


candidates : List CandidateId
candidates =
    [ CandidateA, CandidateB, CandidateC, CandidateD ]


{-| The three remembered details, in the order violations are reported. -}
details : List RememberedDetail
details =
    [ FoxLanternIllustration, LanternSentence, LucyInscription ]


{-| A submission once a candidate is chosen. -}
complete : Maybe CandidateId -> Maybe CandidateId
complete chosen =
    chosen


{-| Whether this candidate shows that remembered detail. -}
matches : CandidateId -> RememberedDetail -> Bool
matches candidate detail =
    case ( candidate, detail ) of
        ( CandidateB, LucyInscription ) ->
            False

        ( CandidateC, LanternSentence ) ->
            False

        ( CandidateD, FoxLanternIllustration ) ->
            False

        _ ->
            True


{-| One DetailDoesNotMatch per remembered detail the candidate lacks, in the
order illustration, sentence, inscription.
-}
validate : CandidateId -> List Violation
validate candidate =
    details
        |> List.filter (not << matches candidate)
        |> List.map DetailDoesNotMatch
