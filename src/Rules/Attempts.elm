module Rules.Attempts exposing (SubmitResult(..), attemptsUsed, maxAttempts, retry, submit)

{-| The shared two-attempt rule for the three main puzzles.

  - Submitting while first-attempt feedback is open is ignored.
  - An incomplete arrangement spends nothing.
  - A complete submission spends one attempt and is validated.
  - Correct on either attempt: resolved as Succeeded.
  - Wrong on the first attempt: local feedback, retry allowed.
  - Wrong on the second attempt: resolved as Failed.

Only Resolved results become history.

-}

import Domain exposing (Attempts(..), ChapterRecord, Era, FinalSubmission, MainPuzzle, Outcome(..), Violation)


type SubmitResult
    = Ignored
    | Incomplete
    | FirstMistake (List Violation)
    | Resolved ChapterRecord


maxAttempts : Int
maxAttempts =
    2


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

            else if used < maxAttempts then
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
