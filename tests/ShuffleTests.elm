module ShuffleTests exposing (suite)

import Expect
import Fuzz
import Rules.Shadow
import Rules.Shuffle as Shuffle
import Test exposing (Test, describe, fuzz, test)


suite : Test
suite =
    describe "Shuffle"
        [ fuzz Fuzz.int "keeps every item exactly once" <|
            \seed ->
                Shuffle.shuffle seed (List.range 1 9)
                    |> List.sort
                    |> Expect.equal (List.range 1 9)
        , fuzz Fuzz.int "the cut-outs never come out in their natural order" <|
            \seed ->
                Shuffle.permute seed Rules.Shadow.allCutouts
                    |> Expect.notEqual Rules.Shadow.allCutouts
        , test "the same seed gives the same order" <|
            \_ ->
                Shuffle.shuffle 12345 (List.range 1 9)
                    |> Expect.equal (Shuffle.shuffle 12345 (List.range 1 9))
        , test "different seeds give different orders" <|
            \_ ->
                List.map (\seed -> Shuffle.shuffle seed (List.range 1 9)) (List.range 1 20)
                    |> List.foldl (\order seen -> if List.member order seen then seen else order :: seen) []
                    |> List.length
                    |> Expect.atLeast 15
        ]
