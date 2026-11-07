# Christmas-Rewrite

**One More Christmas**: an Elm puzzle adventure in a side-view bookshop, with a walking character.

- Game brief (source of truth): [one-more-christmas-shared-plan.md](one-more-christmas-shared-plan.md)
- Walking character and visible room update: [visual-and-movement-update.md](visual-and-movement-update.md)
- Code contract and team handoff: [CONTRACT.md](CONTRACT.md)

## Run it (Mac and Windows, Node.js 18+)

```
npm install      # once
npm start        # preview at http://localhost:8000, reload to rebuild
npm run build    # static build into build/
npm test         # Elm tests
npm run release  # optimized, checked build for submission into release/one-more-christmas/
```

## Release

Run `npm test`, then `npm run release`. Upload the *contents* of `release/one-more-christmas/` (zip them so `index.html` is at the top level). To play the release locally, open `release/one-more-christmas/index.html` in a browser or serve that folder with any static file server. Details are in [CONTRACT.md](CONTRACT.md#release-build).
