// Release build for submission (Mac/Windows/Linux). Only uses Node's standard library.
//
//   npm run release   -> release/one-more-christmas/ (optimized, self-contained static site)
//
// The folder is separate from build/ on purpose: `npm start` rebuilds build/ as a
// debug build on every page load, so an optimized build there can be replaced
// without anyone noticing. release/ is git-ignored and recreated every time.
//
// After building, it checks the folder: every asset the page, the styles and the
// compiled Elm refer to exists, and every path is relative, so the folder works
// from any web host or sub-folder.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { build, outDir } from "./build.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const releaseDir = path.join(root, "release", "one-more-christmas");

function fail(message) {
  console.error("\nRelease check failed: " + message);
  process.exit(1);
}

const { ok, output } = build({ optimize: true });
process.stdout.write(output);
if (!ok) fail("the optimized build did not compile (see above).");

fs.rmSync(path.join(root, "release"), { recursive: true, force: true });
fs.mkdirSync(releaseDir, { recursive: true });
fs.cpSync(outDir, releaseDir, { recursive: true });

const read = (file) => fs.readFileSync(path.join(releaseDir, file), "utf8");
const files = ["index.html", "styles.css", "elm.js"];
for (const file of files) {
  if (!fs.existsSync(path.join(releaseDir, file))) fail(`${file} is missing.`);
}

const assetFiles = fs.readdirSync(path.join(releaseDir, "assets"));
const problems = [];
let checked = 0;

for (const file of files) {
  const text = read(file);
  if (/localhost|127\.0\.0\.1/.test(text)) problems.push(`${file} mentions localhost.`);
  if (/(["'(=]\s*)\/assets\//.test(text)) problems.push(`${file} uses an absolute /assets/ path.`);
  for (const [reference] of text.matchAll(/assets\/[A-Za-z0-9._-]*/g)) {
    const name = reference.slice("assets/".length);
    checked++;
    // Elm builds some names from parts ("assets/book-" ++ name ++ ".svg"): a part must start a real file.
    const complete = /\.(svg|jpg|png|webp)$/.test(name);
    const found = complete ? assetFiles.includes(name) : assetFiles.some((asset) => asset.startsWith(name));
    if (!found) problems.push(`${file} refers to assets/${name}, which is not in the release.`);
  }
}
// No Debug check needed: `elm make --optimize` refuses to compile any use of Debug.
if (problems.length > 0) fail("\n  " + [...new Set(problems)].join("\n  "));

const size = (dir) =>
  fs.readdirSync(dir, { withFileTypes: true }).reduce(
    (total, entry) => total + (entry.isDirectory() ? size(path.join(dir, entry.name)) : fs.statSync(path.join(dir, entry.name)).size),
    0
  );

console.log(`\nRelease ready in release/one-more-christmas/ (${(size(releaseDir) / 1024 / 1024).toFixed(1)} MB).`);
console.log(`Checked ${checked} asset references: all present, all relative.`);
console.log("Open release/one-more-christmas/index.html, or upload the folder's contents with index.html at the top.");
