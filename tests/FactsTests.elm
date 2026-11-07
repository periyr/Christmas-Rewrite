module FactsTests exposing (suite)

{-| Rule data cross-checked against the brief's own statements. -}

import Domain exposing (..)
import Expect
import Rules.Books as Books
import Rules.Repair as Repair
import Test exposing (Test, describe, test)


colourRank : CoverColour -> Int
colourRank colour =
    case colour of
        Red ->
            1

        Orange ->
            2

        Yellow ->
            3

        Green ->
            4

        Blue ->
            5

        Violet ->
            6


suite : Test
suite =
    describe "Rule data"
        [ test "three books per salvage crate" <|
            \_ ->
                [ Fine, NeedsRepair, TooFarGone ]
                    |> List.map (\c -> List.length (List.filter (\b -> Books.condition b == c) Books.allBooks))
                    |> Expect.equal [ 3, 3, 3 ]
        , test "height order matches the brief's small-to-tall shelf" <|
            \_ ->
                List.sortBy Books.height Books.recoverableBooks
                    |> Expect.equal [ BirdsongForBeginners, GardensInWinter, PocketOfWonders, AtlasOfSmallPlaces, LettersFromTheSea, WinterTales ]
        , test "colour order matches the brief's rainbow shelf" <|
            \_ ->
                List.sortBy (Books.colour >> colourRank) Books.recoverableBooks
                    |> Expect.equal [ WinterTales, LettersFromTheSea, BirdsongForBeginners, PocketOfWonders, AtlasOfSmallPlaces, GardensInWinter ]
        , test "roof and shelves alone use the whole timber budget" <|
            \_ ->
                (Repair.cost PatchRoof).timber
                    + (Repair.cost BuildShelves).timber
                    |> Expect.equal Repair.budget.timber
        , test "seven task cards fill five days plus two set-aside spaces exactly" <|
            \_ ->
                ( List.length Repair.allTasks, List.length Repair.slots )
                    |> Expect.equal ( 7, 7 )
        ]
