module AttemptsTests exposing (suite)

{-| The two-attempt rule, checked with a stand-in puzzle so it does not
depend on any real validator: an Int arrangement where 0 is incomplete,
7 is correct and anything else breaks a rule.
-}

import Domain exposing (..)
import Expect
import Rules.Attempts as Attempts exposing (SubmitResult(..))
import Test exposing (Test, describe, test)


config =
    { era = Search1998
    , complete =
        \n ->
            if n == 0 then
                Nothing

            else
                Just n
    , validate =
        \n ->
            if n == 7 then
                []

            else
                [ DetailDoesNotMatch LucyInscription ]
    , toFinal = \_ -> SentBook CandidateA
    }


puzzle : Int -> Attempts -> MainPuzzle Int
puzzle arrangement attempts =
    { arrangement = arrangement, inspected = [], attempts = attempts }


wrong : List Violation
wrong =
    [ DetailDoesNotMatch LucyInscription ]


suite : Test
suite =
    describe "Rules.Attempts"
        [ test "incomplete submission spends no attempt" <|
            \_ ->
                Attempts.submit config (puzzle 0 NoAttemptUsed)
                    |> Expect.equal Incomplete
        , test "incomplete submission on the retry also spends nothing" <|
            \_ ->
                Attempts.submit config (puzzle 0 (RetryingAfterMistake wrong))
                    |> Expect.equal Incomplete
        , test "first wrong submission gives local feedback, not a record" <|
            \_ ->
                Attempts.submit config (puzzle 3 NoAttemptUsed)
                    |> Expect.equal (FirstMistake wrong)
        , test "submitting while first feedback is open is ignored (double click)" <|
            \_ ->
                Attempts.submit config (puzzle 3 (ReviewingFirstMistake wrong))
                    |> Expect.equal Ignored
        , test "second wrong submission fails the chapter" <|
            \_ ->
                Attempts.submit config (puzzle 3 (RetryingAfterMistake wrong))
                    |> Expect.equal
                        (Resolved
                            { era = Search1998
                            , outcome = Failed
                            , attemptsUsed = 2
                            , finalSubmission = SentBook CandidateA
                            , finalViolations = wrong
                            }
                        )
        , test "correct first submission succeeds with one attempt" <|
            \_ ->
                case Attempts.submit config (puzzle 7 NoAttemptUsed) of
                    Resolved record ->
                        Expect.equal ( record.outcome, record.attemptsUsed ) ( Succeeded, 1 )

                    other ->
                        Expect.fail ("expected Resolved, got " ++ Debug.toString other)
        , test "correct second submission succeeds" <|
            \_ ->
                case Attempts.submit config (puzzle 7 (RetryingAfterMistake wrong)) of
                    Resolved record ->
                        Expect.equal ( record.outcome, record.attemptsUsed ) ( Succeeded, 2 )

                    other ->
                        Expect.fail ("expected Resolved, got " ++ Debug.toString other)
        , test "retry keeps the arrangement and the earlier violations" <|
            \_ ->
                Attempts.retry (puzzle 3 (ReviewingFirstMistake wrong))
                    |> Expect.equal (puzzle 3 (RetryingAfterMistake wrong))
        ]
