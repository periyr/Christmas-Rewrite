// Builds public/assets/clue-archive-photo.svg: the 1998 inscription clue from
// the shop archive (Content.Clues inscription FamilyArchive). The photograph's
// front (exactly clue-ruth-lucy-photo.svg, the photo on the community wall) and
// its back, with Henry's note in his handwriting.
//
// Run hub-props.mjs first (it writes the front), then:
//
//   npm install @fontsource/caveat opentype.js        (in <scratch>)
//   node docs/asset-sources/archive-photo.mjs <scratch>
//
// The note must match Content.Clues inscription FamilyArchive. The handwriting
// is the Caveat font (SIL Open Font License 1.1), turned into outlines.

import { readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scratch = process.argv[2];
if (!scratch) throw new Error("usage: node archive-photo.mjs <folder with opentype.js and @fontsource/caveat>");
const require = createRequire(join(resolve(scratch), "noop.js"));
const opentype = require("opentype.js");
const file = readFileSync(require.resolve("@fontsource/caveat/files/caveat-latin-500-normal.woff"));
const hand = opentype.parse(file.buffer.slice(file.byteOffset, file.byteOffset + file.byteLength));
const NO_KERN = { kerning: false };
// opentype.js's toPathData sometimes prints a coordinate as NaN, so the numbers
// are formatted here.
const n = (v) => String(Math.round(v * 10) / 10);
const toD = (path) =>
  path.commands
    .map((c) =>
      c.type === "Z" ? "Z"
      : c.type === "Q" ? `Q${n(c.x1)} ${n(c.y1)} ${n(c.x)} ${n(c.y)}`
      : c.type === "C" ? `C${n(c.x1)} ${n(c.y1)} ${n(c.x2)} ${n(c.y2)} ${n(c.x)} ${n(c.y)}`
      : `${c.type}${n(c.x)} ${n(c.y)}`)
    .join("");
const width = (words, size) => hand.getAdvanceWidth(words, size, NO_KERN);
function wrap(words, size, max) {
  const lines = [];
  let line = "";
  for (const word of words.split(" ")) {
    const next = line ? line + " " + word : word;
    if (width(next, size) > max && line) {
      lines.push(line);
      line = word;
    } else line = next;
  }
  return line ? [...lines, line] : lines;
}

const ASSETS = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets");
const INK = "#291e1a", BACK = "#efe6d2", PENCIL = "#5d5a55", BLUE_INK = "#2f3f63";

// The front: the wall's photo file, drawn in as it is.
const front = readFileSync(join(ASSETS, "clue-ruth-lucy-photo.svg"), "utf8");
const frontView = front.match(/viewBox="([^"]+)"/)[1];
const frontInner = front.replace(/^[\s\S]*?<svg[^>]*>/, "").replace(/<\/svg>\s*$/, "");
const [, , FW, FH] = frontView.split(" ").map(Number);

// The back: the same card (156 x 122 at three times the size), plain, with
// Henry's note.
const NOTE = "Ruth writes ‘For Lucy, love Mum’ in every book she gives her.";
const BW = 468, BH = 366, size = 44, lead = 54;
const lines = wrap(NOTE, size, BW - 90);
const noteTop = BH / 2 - ((lines.length - 1) * lead) / 2 + 10;
const note = lines
  .map((line, i) => `<path d="${toD(hand.getPath(line, BW / 2 - width(line, size) / 2 + (i % 2 ? 6 : -4), noteTop + i * lead, size, NO_KERN))}" />`)
  .join("\n        ");
const year = toD(hand.getPath("1973", BW - 110, 58, 34, NO_KERN));

const GAP = 60, W = FW + GAP + BW + 40, H = Math.max(FH, BH + 40);
const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- clue-archive-photo: the 1973 photograph of Ruth and Lucy, front (as on the community wall) and back (Henry's note, Caveat SIL OFL 1.1). Built by docs/asset-sources/archive-photo.mjs -->
  <!-- Front -->
  <svg x="0" y="${(H - FH) / 2}" width="${FW}" height="${FH}" viewBox="${frontView}">${frontInner}</svg>
  <!-- Back -->
  <g transform="translate(${FW + GAP} ${(H - BH) / 2}) rotate(-3 ${BW / 2} ${BH / 2})">
    <rect x="0" y="0" width="${BW}" height="${BH}" fill="${BACK}" stroke="${INK}" stroke-width="3.6" />
    <g fill="${PENCIL}">
      <path d="${year}" />
    </g>
    <g fill="${BLUE_INK}">
        ${note}
    </g>
    <path d="M ${BW / 2 - 70} ${noteTop + (lines.length - 1) * lead + 26} C ${BW / 2 - 30} ${noteTop + (lines.length - 1) * lead + 20} ${BW / 2 + 30} ${noteTop + (lines.length - 1) * lead + 32} ${BW / 2 + 70} ${noteTop + (lines.length - 1) * lead + 24}" fill="none" stroke="${BLUE_INK}" stroke-width="2.4" stroke-linecap="round" />
  </g>
</svg>
`;
writeFileSync(join(ASSETS, "clue-archive-photo.svg"), svg);
console.log("wrote clue-archive-photo.svg");
