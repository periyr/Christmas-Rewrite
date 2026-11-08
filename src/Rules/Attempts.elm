module Rules.Attempts exposing (SubmitResult(..), attemptsUsed, maxAttempts, maxAttemptsFor, retry, submit)

{-| The shared attempt rule for the three main puzzles. 1950 and 1973 give two
attempts; the 1998 book gives one (the team's change): sending the wrong book
loses that chapter straight away.

  - Submitting while first-attempt feedback is open is ignored.
  - An incomplete arrangement spends nothing.
  - A complete submission spends one attempt and is validated.
  - Correct on any attempt: resolved as Succeeded.
  - Wrong with an attempt left: local feedback, retry allowed.
  - Wrong on the last attempt: resolved as Failed.

Only Resolved results become history.

-}

import Domain exposing (Attempts(..), ChapterRecord, Era(..), FinalSubmission, MainPuzzle, Outcome(..), Violation)


type SubmitResult
    = Ignored
    | Incomplete
    | FirstMistake (List Violation)
    | Resolved ChapterRecord


{-| The usual number of attempts (1950 and 1973). -}
maxAttempts : Int
maxAttempts =
    2


{-| Attempts for each main puzzle: one for the 1998 book, two otherwise. -}
maxAttemptsFor : Era -> Int
maxAttemptsFor era =
    case era of
        Search1998 ->
            1

        _ ->
            maxAttempts


attemptsUsed : Attempts -> Int
attemptsUsed attempts =
    case attempts of
        NoAttemptUsed ->
            0

        ReviewingFirstMistake _ ->
            1

        RetryingAfterMistake _ ->
            1


submit :
    { era : Era
    , complete : arrangement -> Maybe submission
    , validate : submission -> List Violation
    , toFinal : submission -> FinalSubmission
    }
    -> MainPuzzle arrangement
    -> SubmitResult
submit config puzzle =
    case ( puzzle.attempts, config.complete puzzle.arrangement ) of
        ( ReviewingFirstMistake _, _ ) ->
            Ignored

        ( _, Nothing ) ->
            Incomplete

        ( attempts, Just submission ) ->
            let
                violations =
                    config.validate submission

                used =
                    attemptsUsed attempts + 1

                resolve outcome =
                    Resolved
                        { era = config.era
                        , outcome = outcome
                        , attemptsUsed = used
                        , finalSubmission = config.toFinal submission
                        , finalViolations = violations
                        }
            in
            if List.isEmpty violations then
                resolve Succeeded

            else if used < maxAttemptsFor config.era then
                FirstMistake violations

            else
                resolve Failed


{-| Close first-attempt feedback and return to editing, keeping the arrangement. -}
retry : MainPuzzle arrangement -> MainPuzzle arrangement
retry puzzle =
    case puzzle.attempts of
        ReviewingFirstMistake violations ->
            { puzzle | attempts = RetryingAfterMistake violations }

        _ ->
            puzzle
