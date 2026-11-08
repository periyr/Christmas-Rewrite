module Rules.Travel exposing
    ( duration, bookOpen, arrival, returnDuration
    , step, isComplete, hasArrived, hasReturned
    , yearsBack, yearAt
    , isTravelling, wantsFrames
    )

{-| The trips between the present and the past: into a diary when it is
entered (contract v1.5), and back through a tear in the page after a chapter's
last slide (contract v1.6).

All timing lives here and in Update, driven by animation frames: the view only
draws `TimeTravel era elapsed`. Three stages, in milliseconds:

  - 0 to bookOpen: the shop darkens and the diary opens.
  - bookOpen to arrival: pages turn back and the years count down.
  - arrival to duration: the destination year stays, the room behind becomes
    the destination era, and everything fades to reveal it.

-}

import Domain exposing (..)
import Rules.Room
import Timeline


duration : Float
duration =
    2500


bookOpen : Float
bookOpen =
    500


arrival : Float
arrival =
    1800


{-| The way back to the present after a chapter: the tear opens and widens
until the present fills the screen, then the "Back to the present" narration.
-}
returnDuration : Float
returnDuration =
    1800


{-| The elapsed time after one animation frame. Frame deltas are clamped like
walking (Rules.Room.maxFrameDelta), so coming back to a hidden tab never jumps.
-}
step : Float -> Float -> Float
step delta elapsed =
    elapsed + clamp 0 Rules.Room.maxFrameDelta delta


isComplete : Float -> Bool
isComplete elapsed =
    elapsed >= duration


hasReturned : Float -> Bool
hasReturned elapsed =
    elapsed >= returnDuration


{-| From here on the destination is reached: its year stays, and the room
behind the fading book is the destination era.
-}
hasArrived : Float -> Bool
hasArrived elapsed =
    elapsed >= arrival


{-| The years shown on the way back, starting from the present (Nothing):
1998 is Present, 1998; 1973 is Present, 1998, 1973; 1950 is Present, 1998,
1973, 1950.
-}
yearsBack : Era -> List (Maybe Era)
yearsBack era =
    Nothing :: List.map Just (List.reverse (fromEra era Timeline.eras))


fromEra : Era -> List Era -> List Era
fromEra era eras =
    case eras of
        [] ->
            []

        first :: rest ->
            if first == era then
                eras

            else
                fromEra era rest


{-| The year on the open book at `elapsed`: the present until the pages start
turning, then each year in turn, then the destination from arrival on.
-}
yearAt : Era -> Float -> Maybe Era
yearAt era elapsed =
    let
        years =
            yearsBack era

        count =
            List.length years

        slot =
            (arrival - bookOpen) / toFloat count

        index =
            if elapsed < bookOpen then
                0

            else
                min (count - 1) (floor ((elapsed - bookOpen) / slot))
    in
    List.drop index years
        |> List.head
        |> Maybe.withDefault (Just era)


isTravelling : Phase -> Bool
isTravelling phase =
    case phase of
        Transition (TimeTravel _ _) ->
            True

        Transition (TearToPresent _ _) ->
            True

        _ ->
            False


{-| Whether Main needs animation frames: while walking, and during either trip. -}
wantsFrames : Model -> Bool
wantsFrames model =
    Rules.Room.isMoving model || isTravelling model.phase
