# Christmas Rewrite: submission copy and credits

## Title and tagline

**Christmas Rewrite**

*Every decade has its mistakes. Every diary remembers them.*

## Short description (about 50 words)

On Christmas Eve, Edwin Hale is closing his family's bookshop for good when he finds three old diaries. Step into 1950, 1973 and 1998 to fix the mistakes that brought the shop to this night. You get two tries at each puzzle, and every choice shapes the present.

## Long description (about 150 words)

The Hale family bookshop has lasted four generations, but tonight it closes. Packing up on Christmas Eve, Edwin finds three diaries: his grandfather Walter's, his father Henry's and his own forgotten journal. Each one says the same thing: "I thought we had more time." The clock stops just before midnight, and the oldest diary begins to glow.

- **1950:** plan Walter's repair week on a budget of four planks and £10.
- **1973:** stage a shadow story by torchlight during a power cut.
- **1998:** find the one book a customer's daughter loved, from a picture, a remembered line and an inscription.

The 1950 and 1973 puzzles give you two attempts; the forgotten book in 1998 gives you one. What happens in one decade changes the clues in the next and the shop you return to. Save all three, and the shop opens again at midnight. Any failure leads to a different ending.

A cosy, bittersweet point-and-click puzzle game for the browser. Takes about 10–15 minutes.

## Controls

- **Walk** around the shop as Walter, Henry or Edwin: hold **A**/**D** or the **← →** arrow keys.
- **Use** what's nearby with **E** when its prompt appears. Or **click** an object's label: your character walks there and uses it.
- **Inspect** documents and objects to read them; this never costs anything.
- **To move something:** click to pick it up, then click where it should go. Click a crate or the "Not this week" box to drop it into the first free space. Click the same object again to put it down.
- **To submit a main puzzle:** use its button (**Finish week**, **Perform the story** or **Send this book**). Inspecting and rearranging are free. Each submission uses an attempt: two each in 1950 and 1973, only one in 1998.
- **Continue the story:** in the narration and the slides, press **Enter** (or click the button) to go on.
- **Help:** every puzzle screen has a Help button that explains its controls.
- **Replaying:** after an ending, **Reopen 1950**, **Reopen 1973** or **Reopen 1998** to replay from that chapter, or **Start again**.

## How it's built

Christmas Rewrite is written in [Elm](https://elm-lang.org), with HTML, CSS and SVG for presentation. It needs no server, database or network connection while playing.

- **State never changes in place.** Every action produces a new game state from the old one, through a single pure update function. Clicking during feedback, or double-clicking, can't spend an extra attempt or record a chapter twice.
- **The puzzle checks are pure functions.** Each puzzle has its own validator, separate from the interface. The validator takes a finished arrangement and returns a list of broken rules. The repair board's validator was tested against all 2,520 possible weeks, and it accepts exactly the six valid ones.
- **The world is rebuilt from history.** The only progress stored is the ordered list of finished chapters. Everything else is calculated from that list every time:
  - the present-day shop
  - which version of the 1973 script you get
  - where the 1998 inscription clue comes from
  - the ending

  So the same history always produces the same world.
- **Rewinding clears later chapters.** Reopening a diary removes that chapter and every later one from the history. The world is then rebuilt from what remains. Earlier results stay, and the replayed chapter gets two fresh attempts.
- **Browser events stay at the boundary.** The browser only supplies inputs: key presses, clicks, animation frames and the page being hidden. `Main` turns each one into an ordinary message for the pure update. Walking position, the walking target and every rule live in the model, so the game has no JavaScript rules, timers or second copy of the state.

## Credits

| Role | Name |
|---|---|
| Core logic, rules and integration (Person A) | Avissa Rasoulinia |
| Presentation and interaction (Person B) | Defne Göçken |
| Content, assets and player clarity (Person C) | Peri Yarci |
| Debugging and small implementation details | Ata Karasoy |

- **Writing:** the team. Claude Code was only used to polish the wording.
- **Art:** all made for this project and free to use in this game. See `public/assets/ASSETS.md` for the full list.
  - The room pictures, book and diary covers, damage marks, shadow puppets and mystery books were generated with Google Gemini from the team's prompt and palette, then checked and edited by the team (with help from Claude). `shadow-fox.svg` was redrawn by hand.
  - The four walking characters share one body drawn with Google Gemini from the team's prompt. Each person's look follows Gemini's designs, rebuilt with help from Claude so all four match (`docs/asset-sources/chibi-family.mjs`).
  - The room props are flat SVG made for the team with help from Claude.
  - The family photograph and the handwritten closure notice are SVG made with help from Claude. The photograph reuses the walking characters (`docs/asset-sources/family-photo.mjs`).
- **Fonts:** none bundled. The game uses fonts already installed on the player's system (Palatino or Georgia, and Courier). The handwriting on the closure notice, Walter's diary page, the glass delivery slip, the 1973 shadow-story scripts and stage sketches, and Henry's note on the back of the 1973 photograph is the Caveat font (SIL Open Font License 1.1, The Caveat Project Authors), turned into drawn outlines (`docs/asset-sources/closure-note.mjs`, `docs/asset-sources/handwritten-clues.mjs`, `docs/asset-sources/shadow-clues.mjs`, `docs/asset-sources/archive-photo.mjs`).
- **Sound:** every sound effect and the music are generated in code with the Web Audio API (`public/audio.js`), written with Claude Code. There are no sound files. The music is "Silent Night" (Franz Gruber, 1818, public domain), played as a quiet music box.
- **Software:** Elm 0.19.1 and the packages elm/core, elm/browser, elm/html (BSD-3-Clause); elm-test for testing; Node.js for the build scripts.

**Source:** https://github.com/periyr/Christmas-Rewrite
