# Christmas-Rewrite

**Christmas Rewrite**: an Elm puzzle adventure in a side-view bookshop, with a walking character.


- Game brief (source of truth): [one-more-christmas-shared-plan.md](one-more-christmas-shared-plan.md)
- Walking character and visible room update: [visual-and-movement-update.md](visual-and-movement-update.md)
- Code contract and team handoff: [CONTRACT.md](CONTRACT.md)

## Run it (Mac and Windows, Node.js 18+)

```
npm install      # once
npm start        # preview at http://localhost:8000, reload to rebuild
npm run build    # static build into build/
npm test         # Elm tests
npm run release  # optimized, checked build for submission into release/christmas-rewrite/
```

## Release

Run `npm test`, then `npm run release`. Upload the *contents* of `release/christmas-rewrite/` (zip them so `index.html` is at the top level). To play the release locally, open `release/christmas-rewrite/index.html` in a browser or serve that folder with any static file server. Details are in [CONTRACT.md](CONTRACT.md#release-build).

## Continuous integration and GitHub Pages

`.github/workflows/ci.yml` runs `npm test` and `npm run release` on every push to `main` and on every pull request. A push to `main` also publishes `release/christmas-rewrite/` to GitHub Pages.

One-time setup: in the repository on GitHub, open **Settings → Pages** and set **Source** to **GitHub Actions**. The game is then at `https://periyr.github.io/Christmas-Rewrite/`.
