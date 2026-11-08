module BookTrayTests exposing (suite)

import Content.Books
import Domain exposing (..)
import Expect exposing (Expectation)
import Fixtures
import Fuzz
import Html.Attributes exposing (attribute)
import Rules.BookTrays as Trays
import Rules.Books as Books
import Rules.Placement as Placement
import Rules.Room as Room
import Rules.Shelf as Shelf
import Save
import Test exposing (Test, describe, fuzz, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector exposing (class, tag)
import Update
import View


suite : Test
suite =
    describe "1950 book trays"
        [ fuzz Fuzz.int "each seed preserves both inventories without duplicates" <|
            \seed ->
                Expect.all
                    [ \_ -> expectInventory Books.allBooks (Trays.salvage seed)
                    , \_ -> expectInventory Books.recoverableBooks (Trays.shelf seed)
                    ]
                    ()
        , test "both trays vary across seeds" <|
            \_ ->
                Expect.all
                    [ \_ -> varied (List.map Trays.salvage (List.range 0 20))
                    , \_ -> varied (List.map Trays.shelf (List.range 0 20))
                    ]
                    ()
        , test "copying the shelf tray left to right never gives an accepted order" <|
            \_ ->
                List.range -512 512
                    |> List.filter
                        (\seed ->
                            Shelf.matchedOrder
                                { placed = List.map2 Tuple.pair (Trays.shelf seed) Shelf.slots, selected = Nothing }
                                /= Nothing
                        )
                    |> Expect.equal []
        , test "a seeded new run enters salvage with empty crates and an assigned tray" <|
            \_ ->
                let
                    model =
                        Update.newRun 73
                            |> send [ Advance, Advance, Advance, OpenNextDiary, Advance, SkipTravel ]
                in
                Expect.all
                    [ .phase >> Expect.equal (Salvage Placement.empty)
                    , openStation CratesSpot >> expectTray (List.map title (Trays.salvage 73))
                    ]
                    model
        , test "resuming a checkpoint or replaying 1950 reproduces its tray order" <|
            \_ ->
                let
                    start =
                        Update.newRun -2147483648

                    saved =
                        { history = [], place = Save.placeOf { start | phase = Salvage Placement.empty }, runSeed = start.runSeed }

                    tray =
                        List.map title (Trays.salvage start.runSeed)

                    resumed =
                        Save.encode saved |> Save.decode |> Maybe.map Save.resume

                    replayed =
                        { start | phase = Ending }
                            |> send [ ReopenDiary Repairs1950, Advance, SkipTravel ]
                in
                case resumed of
                    Just model ->
                        Expect.all
                            [ \_ -> expectTray tray (openStation CratesSpot model)
                            , \_ -> expectTray tray (openStation CratesSpot replayed)
                            ]
                            ()

                    Nothing ->
                        Expect.fail "The seeded save did not load."
        , test "salvage reserves a book's tray position after placing it in a crate" <|
            \_ ->
                let
                    start =
                        Update.newRun 491

                    open =
                        openStation CratesSpot { start | phase = Salvage Placement.empty }
                in
                checkReturnPosition title (Trays.salvage start.runSeed) SalvageMove
                    (\book -> InCrate (Books.condition book) 1)
                    [ ClosePanel, ApproachHotspot CratesSpot ]
                    open
        , test "the shelving pause starts empty and preserves tray positions across the plaque and panel" <|
            \_ ->
                let
                    start =
                        Update.newRun 492

                    shelvingDay =
                        { start | history = [ Fixtures.repairsSucceeded ], phase = Transition (Slideshow Repairs1950 3) }

                    atShelf =
                        Update.update Advance shelvingDay
                in
                Expect.all
                    [ .phase >> Expect.equal (ReopeningShelf Placement.empty)
                    , openStation ShelfSpot
                        >> checkReturnPosition (Recoverable >> title) (Trays.shelf start.runSeed) ShelfMove
                            (always (ShelfPosition 1))
                            [ Inspect ShelfPlaque, CloseInspection, ClosePanel, ApproachHotspot ShelfSpot ]
                    ]
                    atShelf
        ]


expectInventory : List a -> List a -> Expectation
expectInventory inventory actual =
    Expect.equal
        ( List.length inventory, List.repeat (List.length inventory) 1 )
        ( List.length actual, List.map (\item -> List.length (List.filter ((==) item) actual)) inventory )


varied : List (List a) -> Expectation
varied orders =
    List.filter (\order -> Just order /= List.head orders) orders
        |> List.isEmpty
        |> Expect.equal False


title : BookId -> String
title book =
    (Content.Books.book book).title


send : List Msg -> Model -> Model
send messages model =
    List.foldl Update.update model messages


openStation : Hotspot -> Model -> Model
openStation hotspot model =
    let
        player =
            Room.initialPlayer
    in
    { model | room = { player = { player | x = (Room.position hotspot).x }, panelOpen = False } }
        |> Update.update (ApproachHotspot hotspot)


checkReturnPosition :
    (book -> String)
    -> List book
    -> (PlacementAction book slot -> Msg)
    -> (book -> slot)
    -> List Msg
    -> Model
    -> Expectation
checkReturnPosition name books move slot reopen model =
    case books of
        first :: rest ->
            let
                placed =
                    model |> send [ move (SelectItem first), move (PlaceSelected (slot first)) ] |> send reopen

                returned =
                    placed |> send [ move (SelectItem first), move ReturnSelectedToTray ]
            in
            Expect.all
                [ \_ -> expectTray ("Tray space" :: List.map name rest) placed
                , \_ -> expectTray (List.map name books) returned
                ]
                ()

        [] ->
            Expect.fail "Expected a starting tray with books."


expectTray : List String -> Model -> Expectation
expectTray names model =
    let
        buttons =
            View.view model |> Query.fromHtml |> Query.find [ class "tray" ] |> Query.findAll [ tag "button" ]
    in
    Expect.all
        (Query.count (Expect.equal (List.length names))
            :: List.indexedMap (\index name -> Query.index index >> Query.has [ Selector.attribute (attribute "aria-label" name) ]) names
        )
        buttons
