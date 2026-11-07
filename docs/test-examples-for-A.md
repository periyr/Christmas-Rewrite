# Expected examples for the 1973 and 1998 validators (from Person C)

For `Rules.Shadow.validate` and `Rules.Mystery.validate`, which are still `Debug.todo`. Every example comes from the brief (sections 5 and 6) and agrees with the text in `src/Content/`. The tests are A's to write; these are the expected inputs and outputs.

**Assumption to confirm:** a scene conflicts when its character **or** its prop differs from the script. Violations are listed in scene order, one per conflicting scene.

## 1973 shadow story: `Rules.Shadow.validate variant staging`

A useful property: because each cut-out is used exactly once, a wrong staging always has **at least two** conflicting scenes. Moving anything out of its correct scene moves something else in. So a test expecting exactly one `SceneConflictsWithScript` can never pass.

### `OriginalScript` (1950 succeeded): Fox + Lantern, Owl + Key, Child + Book

| Case | Scene 1 | Scene 2 | Scene 3 | Expected |
|---|---|---|---|---|
| Correct | Fox + Lantern | Owl + Key | Child + Book | `[]` |
| Retelling's answer used by mistake | Child + Key | Owl + Book | Fox + Lantern | `[ SceneConflictsWithScript Scene1, SceneConflictsWithScript Scene2, SceneConflictsWithScript Scene3 ]` |
| Right pairs, wrong order (sketch ignored) | Owl + Key | Fox + Lantern | Child + Book | `[ SceneConflictsWithScript Scene1, SceneConflictsWithScript Scene2 ]` |
| Props swapped between scenes 1 and 2 | Fox + Key | Owl + Lantern | Child + Book | `[ SceneConflictsWithScript Scene1, SceneConflictsWithScript Scene2 ]` |
| Characters swapped between scenes 2 and 3 | Fox + Lantern | Child + Key | Owl + Book | `[ SceneConflictsWithScript Scene2, SceneConflictsWithScript Scene3 ]` |

### `NeighboursRetelling` (1950 failed): Child + Key, Owl + Book, Fox + Lantern

| Case | Scene 1 | Scene 2 | Scene 3 | Expected |
|---|---|---|---|---|
| Correct | Child + Key | Owl + Book | Fox + Lantern | `[]` |
| Original's answer used by mistake | Fox + Lantern | Owl + Key | Child + Book | `[ SceneConflictsWithScript Scene1, SceneConflictsWithScript Scene2, SceneConflictsWithScript Scene3 ]` |
| Right pairs, wrong order | Fox + Lantern | Owl + Book | Child + Key | `[ SceneConflictsWithScript Scene1, SceneConflictsWithScript Scene3 ]` |
| Props swapped between scenes 1 and 3 | Child + Lantern | Owl + Book | Fox + Key | `[ SceneConflictsWithScript Scene1, SceneConflictsWithScript Scene3 ]` |
| Characters swapped between scenes 1 and 2 | Owl + Key | Child + Book | Fox + Lantern | `[ SceneConflictsWithScript Scene1, SceneConflictsWithScript Scene2 ]` |

### Whole-space checks (like the 2,520 enumeration for 1950)

- There are 3! × 3! × 3! = 216 complete stagings. For each variant, exactly **one** is valid.
- The two valid stagings are different, so the same staging never passes under both variants.

### Through history (variant chosen from 1950)

- History `[ repairsSucceeded ]`: the original script's correct staging succeeds, and the retelling's fails.
- History `[ repairsFailed ]`: the reverse.
- With no history, `deriveWorld` gives `NeighboursRetelling`. Not reachable in play, but worth pinning down.

## 1998 forgotten book: `Rules.Mystery.validate candidate`

Remembered details: `FoxLanternIllustration`, `LanternSentence`, `LucyInscription`.

| Candidate | Expected |
|---|---|
| `CandidateA` (illustrated edition) | `[]` |
| `CandidateB` (school edition, “For Peter, love Dad”) | `[ DetailDoesNotMatch LucyInscription ]` |
| `CandidateC` (River Stories, different passage) | `[ DetailDoesNotMatch LanternSentence ]` |
| `CandidateD` (plain edition, snowy wood, no bridge) | `[ DetailDoesNotMatch FoxLanternIllustration ]` |

- Exactly one candidate (A) is valid.
- Each wrong candidate fails exactly one detail, and each detail rules out exactly one candidate. So all three clues are needed: dropping any one leaves two books that fit.
- The answer must not depend on history. A is correct under both `FamilyArchive` and `FollowUpEmail` (1973 succeeded or failed). Only where the inscription clue comes from changes.
- If A ever reports several details for one book, the expected order is illustration, sentence, inscription. No current candidate fails more than one.

## Two-attempt flow examples

These are the same as for 1950. For each puzzle:

- A wrong answer, then the correct one, records `Succeeded` with `attemptsUsed = 2`.
- Two wrong answers record `Failed`, with the second submission's violations.

Mystery example: choose B then A, which succeeds on attempt 2. Choose C then D, which fails, with `finalViolations = [ DetailDoesNotMatch FoxLanternIllustration ]`.
