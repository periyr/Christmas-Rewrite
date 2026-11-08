// Builds public/assets/clue-closure-notice.svg: Edwin's handwritten closure
// notice, taped to the shop window (Content.Clues ClosureNotice).
//
// The handwriting is the Caveat font (SIL Open Font License 1.1, The Caveat
// Project Authors), turned into plain outlines, so the game needs no font file.
// The font and the converter are not project dependencies. Install them in any
// scratch folder and point the script at it:
//
//   npm install @fontsource/caveat opentype.js        (in <scratch>)
//   node docs/asset-sources/closure-note.mjs <scratch>
//
// The words must match Content.Clues ClosureNotice.

import { readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scratch = process.argv[2];
if (!scratch) throw new Error("usage: node closure-note.mjs <folder with opentype.js and @fontsource/caveat>");
const require = createRequire(join(resolve(scratch), "noop.js"));
const opentype = require("opentype.js");
const fontFile = readFileSync(require.resolve("@fontsource/caveat/files/caveat-latin-600-normal.woff"));
const font = opentype.parse(fontFile.buffer.slice(fontFile.byteOffset, fontFile.byteOffset + fontFile.byteLength));

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets", "clue-closure-notice.svg");
const CREAM = "#f2e4c9", INK = "#291e1a", MUSTARD = "#d9a443", WINE = "#893f43";

const W = 480, H = 440;
const LINES = [
  ["After four generations,", 0],
  ["Hale’s Bookshop closes its doors", 0],
  ["for the last time", 0],
  ["this Christmas Eve.", 0],
  ["", 0],
  ["Thank you to everyone", 0],
  ["who ever came in", 0],
  ["out of the cold.", 0],
];
const SIZE = 33, LEAD = 37, TOP = 128;
// opentype.js returns NaN for some of this font's kerning pairs, so no kerning.
const NO_KERN = { kerning: false };

// Each line centred, with a small wobble so it reads as written by hand.
const wobble = [-1.2, 0.8, -0.4, 1.1, 0, -0.9, 0.6, -0.3];
const text = LINES.map(([words], i) => {
  if (!words) return "";
  const width = font.getAdvanceWidth(words, SIZE, NO_KERN);
  const x = W / 2 - width / 2 + wobble[i] * 3;
  const y = TOP + i * LEAD + wobble[i];
  return `    <path d="${font.getPath(words, x, y, SIZE, NO_KERN).toPathData(1)}" />`;
}).filter(Boolean).join("\n");

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- clue-closure-notice: handwritten in Caveat (SIL OFL 1.1), outlined by docs/asset-sources/closure-note.mjs -->
  <g transform="rotate(-1.5 ${W / 2} ${H / 2})">
    <!-- Paper, with a slightly uneven edge -->
    <path d="M 46,34 L 250,30 L 436,36 L 440,170 L 436,300 L 442,404 L 240,410 L 40,406 L 44,260 L 38,120 Z" fill="${CREAM}" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round" />
    <!-- Tape at the two top corners -->
    <rect x="22" y="18" width="70" height="24" fill="${MUSTARD}" opacity="0.75" transform="rotate(-24 57 30)" />
    <rect x="388" y="18" width="70" height="24" fill="${MUSTARD}" opacity="0.75" transform="rotate(22 423 30)" />
    <!-- Heading -->
    <g fill="${WINE}">
      <path d="${font.getPath("Closing", W / 2 - font.getAdvanceWidth("Closing", 46, NO_KERN) / 2, 78, 46, NO_KERN).toPathData(1)}" />
    </g>
    <path d="M 180,88 C 220,84 262,92 300,86" fill="none" stroke="${WINE}" stroke-width="2.5" stroke-linecap="round" />
    <!-- Notice (Content.Clues ClosureNotice) -->
    <g fill="${INK}">
${text}
    </g>
    <!-- A small holly sprig in the corner -->
    <g stroke="${INK}" stroke-width="2" stroke-linejoin="round">
      <path d="M 372,376 C 382,362 396,362 404,372 C 394,372 388,380 390,390 C 382,382 376,384 372,376 Z" fill="#31542f" />
      <path d="M 404,372 C 416,362 430,366 432,380 C 424,374 414,378 412,388 C 410,380 406,378 404,372 Z" fill="#31542f" />
      <circle cx="400" cy="384" r="5" fill="#c95937" />
      <circle cx="409" cy="389" r="5" fill="#c95937" />
    </g>
  </g>
</svg>
`;
writeFileSync(OUT, svg);
console.log("wrote", OUT);
