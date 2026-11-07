# One More Christmas: submission copy and credits

Fill in the `[brackets]` before submitting.

## Title and tagline

**One More Christmas**

*Every decade has its mistakes. Every diary remembers them.*

## Short description (about 50 words)

On Christmas Eve, Edwin Hale is closing his family's bookshop for good when he finds three old diaries. Step into 1950, 1973 and 1998 to fix the mistakes that brought the shop to this night. You get two tries at each puzzle, and every choice shapes the present.

## Long description (about 150 words)

The Hale family bookshop has lasted four generations, but tonight it closes. Packing up on Christmas Eve, Edwin finds three diaries: his grandfather Walter's, his father Henry's and his own forgotten journal. Each one says the same thing: "I thought we had more time." The clock stops just before midnight, and the oldest diary begins to glow.

- **1950:** plan Walter's repair week on a budget of four planks and £10.
- **1973:** stage a shadow story by torchlight during a power cut.
- **1998:** find the one book a customer's daughter loved, from a picture, a remembered line and an inscription.

Each main puzzle gives you two attempts. What happens in one decade changes the clues in the next and the shop you return to. Save all three, and the shop opens again at midnight. Any failure leads to a different ending.

A cosy, bittersweet point-and-click puzzle game for the browser. Takes about 10–15 minutes.

## Controls

- **Walking (planned, not yet in the game):** move Walter, Henry or Edwin around the shop to reach things. [Fill in the real controls once B builds this, e.g. click a spot on the floor or use the arrow keys.]
- **Click objects and documents** to inspect them.
- **To move something:** click to pick it up, then click where it should go. Click a crate or the "Not this week" box to drop it into the first free space. Click the same object again to put it down.
- **To submit a main puzzle:** use its button (**Finish week**, **Perform the story** or **Send this book**). Inspecting and rearranging are free. Each submission uses one of two attempts.
- **Help:** the Help button explains the controls. [Check that every puzzle screen has one before submitting.]
- **Replaying:** after an ending, **Reopen a diary** to replay a chapter, or **Start again**.

## How it's built

One More Christmas is written in [Elm](https://elm-lang.org), with HTML, CSS and SVG for presentation. It needs no server, database or network connection while playing.

- **State never changes in place.** Every action produces a new game state from the old one, through a single pure update function. Clicking during feedback, or double-clicking, can't spend an extra attempt or record a chapter twice.
- **The puzzle checks are pure functions.** Each puzzle has its own validator, separate from the interface. The validator takes a finished arrangement and returns a list of broken rules. The repair board's validator was tested against all 2,520 possible weeks, and it accepts exactly the six valid ones.
- **The world is rebuilt from history.** The only progress stored is the ordered list of finished chapters. Everything else is calculated from that list every time:
  - the present-day shop
  - which version of the 1973 script you get
  - where the 1998 inscription clue comes from
  - the ending

  So the same history always produces the same world.
- **Rewinding clears later chapters.** Reopening a diary removes that chapter and every later one from the history. The world is then rebuilt from what remains. Earlier results stay, and the replayed chapter gets two fresh attempts.

## Credits

| Role | Name |
|---|---|
| Core logic, rules and integration (Person A) | [name] |
| Presentation and interaction (Person B) | [name] |
| Content, assets and player clarity (Person C) | Peri Yarci [confirm] |

- **Writing:** the team. Text drafted with help from Claude (Anthropic), then edited by the team.
- **Art:** all made for this project and free to use in this game. See `public/assets/ASSETS.md` for the full list.
  - The room pictures, book and diary covers, damage marks, shadow puppets and mystery books were generated with Google Gemini from the team's prompt and palette, then checked and edited by the team (with help from Claude). `shadow-fox.svg` was redrawn by hand.
  - The walking characters and room props are flat SVG made for the team with help from Claude. The characters come from a small generator script in `docs/asset-sources/`.
- **Fonts:** none bundled. The game uses fonts already installed on the player's system (Palatino or Georgia, and Courier).
- **Sound:** none.
- **Software:** Elm 0.19.1 and the packages elm/core, elm/browser, elm/html (BSD-3-Clause); elm-test for testing; Node.js for the build scripts.

**Source:** [repository link, if required]

## What is verified so far (update before submitting)

Remove this section from the public copy. It keeps the claims above honest.

| Feature | Status (7 November) |
|---|---|
| 1950 rules: repair board, salvage, shelf | Built and tested (`npm test`, including all 2,520 weeks) |
| All game text (`src/Content`) | Built; compiles; word counts checked |
| 1973 and 1998 validators | **Not built yet** (`Debug.todo`); expected results are in `docs/test-examples-for-A.md` |
| Walking characters | Sprites drawn and checked for alignment; **walking is not in the game yet** |
| Room props (roof, window, timber, torch, sheet, computer, parcels) | Drawn; **not placed in the rooms yet** |
| Help button on every screen | Only the 1950 screens so far |

## Screenshots to take

1. The present-day shop with the 1950 diary glowing.
2. The 1950 planning board, partly filled in.
3. A 1973 shadow-story scene during the performance.
4. The 1998 book comparison, with a tab open.
5. The saved ending.
