# Required update: a walking character and visible bookshop

This update supersedes the original no-walking scope. Keep Elm, all puzzle rules, the two-attempt system, history, and rewind. Add movement and visual presentation around the working puzzle core. Do not restart the project.

## Player experience

The game is a fixed-camera, side-view 2D bookshop with a visible human character. Move left/right with A/D or arrow keys; press E near an object to interact. Clicking a hotspot also walks the character there and interacts on arrival. Use one horizontal floor strip with left/right bounds and furniture behind it.

At a station, open the existing clue/puzzle panel. Walking pauses during panels, feedback, and transitions. Closing an ordinary panel preserves the answer and attempts. The existing chapter progression remains authoritative. There is no gameplay countdown.

Use one base paper-cutout human with a two-to-four-pose walk cycle, left/right facing, and simple age/clothing variants for Walter, Henry, young Edwin, and present-day Edwin. CSS/SVG artwork is acceptable. The character must visibly walk and idle.

## Required room changes

- Present: dusty shelves, packing boxes, closure notice, cold lighting.
- 1950: damaged window and roof, rubble, timber, book crates. Show repair effects during the submitted week and filled shelves after shelving.
- 1973: dark room, torch beam, sheet, and visible projected story silhouettes.
- 1998: CRT computer glow, book stacks, and parcels.
- Returning present: repaired premises, event photos, and order props appear according to chapter history.

## Work split

**A:** Keep a checkpoint of the working game. Define the small additive player/interaction contract using the existing project types. Implement pure movement updates, bounds, approach/interaction logic, keyboard subscriptions, and animation-frame ticks. Use one shared coordinate system for actor and hotspots. Clamp large deltas and clear held keys on entering panels, changing chapter, or hiding the page. Keep cosmetic movement separate from chapter history and attempts. Publish the updated contract before B connects the scene. Coordinate Main.elm ownership.

**B:** Build the illustrated side-view room, player rendering/walk cycle, hotspots, proximity prompts, and puzzle overlays against A's contract. Preserve the working puzzle components and rule helpers. Render the player position from A's model. Do not create another movement store or rewrite validators. Room and prop changes should follow the actual day/phase/history, not always appear repaired from the start.

**C:** Finish the required clue/content integration, then prepare consistent human character poses/era variants and room props. Coordinate stable asset filenames with B. Reuse one body design and simple shapes. Keep important clue text in the interface. Do not alter puzzle solutions to accommodate art.

## First milestone

Only upgrade 1950 first: walk to crates, solve salvage, walk to the repair board, submit a plan, see the week visibly change the room, walk to the shelf when playback pauses, complete shelving, then return to the present. Preserve the failure route and both attempts. Once that works, reuse the scene system for 1973 and 1998.

The existing 22-hour estimate does not restart. Prioritise this visible, playable room over optional audio, elaborate page turns, and decorative effects. Do not add jumping, pathfinding, physics, extra rooms, or another puzzle during this update.

## Checks

The character moves smoothly within bounds, faces correctly, and stops when keys are released. Hotspots open the correct panels. Movement pauses during overlays. Closing a panel preserves progress. Moving never spends attempts or changes history. Existing tests still pass. Verify the real browser experience, including one successful 1950 run and one final-failure run.
