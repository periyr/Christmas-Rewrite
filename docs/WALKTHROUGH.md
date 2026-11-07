# One More Christmas: walkthrough

**Spoilers:** every solution is below. Playtesters should play once without this guide first.

## The basics

- **Controls:** click an object to pick it up, then click where it should go. Click a crate or the "Not this week" box to drop it into the first free space. Click a placed object to move it again. Click the same object again to put it down.
- **Clues:** click documents and objects in the scene to read them. Reading never costs anything.
- **Main puzzles** (1950 planning board, 1973 shadow story, 1998 forgotten book) give **two attempts**.
  - An incomplete submission is refused and costs nothing.
  - A first wrong answer shows which rules were broken, and you keep your arrangement to fix it.
  - A second wrong answer fails the chapter, and the story carries on.
- **Warm-ups** (sorting the books, arranging the shelf) never fail. Correct them as often as you like.

## Introduction (present day, Christmas Eve)

1. Read the closure notice and the family photographs, then open the box under the counter.
2. Edwin finds three diaries, and the clock stops just before midnight.
3. In the shop, the 1950 diary glows. Open it.

## 1950: the repair week (Walter)

### Sorting the books (warm-up)

Damage shows condition, not cover colour. **Smoke or water can be repaired. Scorching or missing pages cannot.**

| Crate | Books | Why |
|---|---|---|
| Fine | Atlas of Small Places, Pocket of Wonders, Winter Tales | No damage |
| Needs repair | Birdsong for Beginners, Gardens in Winter, Letters from the Sea | Smoke and/or water only |
| Too far gone | Harbour Tales, Mountain Paths, Winter Almanac | Scorched edges and/or missing pages |

### The planning board (main puzzle, "Finish week")

Clues: Walter's diary page (rain on Wednesday), the glass delivery slip (Wednesday), Walter's repair notes (rubble → shelves → books), and the timber licence (4 planks, £10).

**Rules:**
- **Patch the roof:** Monday or Tuesday, because the rain comes on Wednesday.
- **Clear the rubble:** before Build shelves.
- **Build shelves:** before Shelve the books.
- **Re-glaze the window:** Wednesday or later, when the glass arrives.
- **Budget:** 4 timber and £10 in total.

| Card | Cost |
|---|---|
| Patch the roof | 2 timber |
| Clear the rubble | free |
| Build shelves | 2 timber |
| Shelve the books | free |
| Re-glaze the window | £6 |
| Paint a grand new sign | £6 + 1 timber |
| Board up the window | 1 timber |

**The reasoning:**
1. The roof and shelves are essential, and together they use all 4 timber.
2. That leaves nothing for boarding up the window, so the window has to be re-glazed (£6).
3. The sign then can't fit either: it needs timber, and there's only £4 left.
4. So "Not this week" holds **Paint a grand new sign** and **Board up the window**.

**The six valid weeks** (any one succeeds):

| | Mon | Tue | Wed | Thu | Fri |
|---|---|---|---|---|---|
| 1 | Roof | Rubble | Shelves | Books | Glaze |
| 2 | Roof | Rubble | Shelves | Glaze | Books |
| 3 | Roof | Rubble | Glaze | Shelves | Books |
| 4 | Rubble | Roof | Shelves | Books | Glaze |
| 5 | Rubble | Roof | Shelves | Glaze | Books |
| 6 | Rubble | Roof | Glaze | Shelves | Books |

**What happens next:**
- **On success,** the week plays day by day. Wednesday's rain arrives and the roof holds. On shelving day you arrange the shelf, then Saturday's reopening follows.
- **On failure,** one slide shows what went wrong, and you return to the present. The shelf scene is skipped.

### The reopening shelf (warm-up)

The plaque reads "Small to tall / rainbow / A–Z". Any one of these orders works:

| Order | Left to right |
|---|---|
| Small to tall | Birdsong, Gardens, Pocket, Atlas, Letters, Winter Tales |
| Rainbow | Winter Tales (red), Letters (orange), Birdsong (yellow), Pocket (green), Atlas (blue), Gardens (violet) |
| A–Z | Atlas, Birdsong, Gardens, Letters, Pocket, Winter Tales |

## 1973: the shadow story (Henry)

Clues: the script, the stage sketch and the box of cut-outs. Each scene takes one character and one prop, and every cut-out is used once. The script lists who does what. The sketch gives the scene order.

The puzzle depends on how 1950 went.

**1950 succeeded:** Walter's original script survived.

| Scene | Setting | Character | Prop |
|---|---|---|---|
| 1 | The bridge | Fox | Lantern |
| 2 | The door | Owl | Key |
| 3 | Home | Child | Book |

**1950 failed:** the script was lost, and the neighbours retell it.

| Scene | Setting | Character | Prop |
|---|---|---|---|
| 1 | The gate | Child | Key |
| 2 | Inside | Owl | Book |
| 3 | Home | Fox | Lantern |

Press **Perform the story**.
- **On success,** three silhouette scenes play and the Christmas shadow story becomes a yearly tradition.
- **On failure,** the families drift home and the tradition never starts.
- After a first wrong attempt, the feedback names the scenes that don't match the script. A wrong staging always breaks at least two scenes.

## 1998: the forgotten book (Edwin)

Ruth asks for the copy of a book her daughter Lucy loved. Three facts identify it:

1. **Picture:** a fox carrying a lantern beneath a stone bridge. This comes from Ruth's email.
2. **Line:** "The lantern stayed lit until the last traveller came home." This is the line Lucy remembers.
3. **Inscription:** "For Lucy, love Mum."
   - If 1973 succeeded, this comes from the shop archive photo.
   - If 1973 failed, it comes from Ruth's second email.

Check each book's picture, text and dedication tabs:

| Book | Picture | Line | Inscription |
|---|---|---|---|
| **A: Fox and Lantern, illustrated edition** | ✓ | ✓ | ✓ |
| B: Fox and Lantern, school edition | ✓ | ✓ | ✗ "For Peter, love Dad" |
| C: River Stories, anthology | ✓ | ✗ different passage | ✓ |
| D: Fox and Lantern, plain edition | ✗ snowy wood, no bridge | ✓ | ✓ |

**Answer: A.** It's the only book that matches all three facts. Each of the others fails exactly one, so you need every clue.

Press **Send this book**.
- **On success,** the shop starts an online book-finding service.
- **On failure,** the wrong copy is sent and the idea goes no further.

## Endings

| Outcome | Ending |
|---|---|
| All three chapters succeed | **Saved:** at midnight Edwin turns the sign to OPEN, and Ruth returns with Lucy and Lucy's daughter. |
| Any chapter fails (7 of the 8 combinations) | **Closed:** the shop closes, with one short explanation for each failed chapter. |

A failed chapter stays failed for that run. Succeeding later doesn't undo it.

**Saved ending:** use any valid week, the matching shadow script, and book A.

**Closed endings:** submit a wrong answer twice in any chapter you want to fail.

**Replaying:**
- After either ending, **Reopen a diary** replays that chapter and every later one, each with two fresh attempts. Earlier chapters keep their results. Reopening 1950 starts again from the book sorting.
- **Start again** begins a new run.
- Reopening 1950 can switch the 1973 script version. Reopening 1973 can switch where the 1998 inscription clue comes from.
