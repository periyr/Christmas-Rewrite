// Builds two handwritten 1950 clues, shown as pictures (Content.Clues):
//
//   clue-walter-diary.svg   WalterDiaryPage: the entry, written on Walter's ruled diary page
//   clue-glass-slip.svg     GlassDeliverySlip: the supplier's handwritten delivery slip
//
// The handwriting is the Caveat font (SIL Open Font License 1.1, The Caveat
// Project Authors), turned into plain outlines, so the game needs no font file.
// As for closure-note.mjs, install the font and converter in a scratch folder:
//
//   npm install @fontsource/caveat opentype.js        (in <scratch>)
//   node docs/asset-sources/handwritten-clues.mjs <scratch>
//
// The words must match Content.Clues WalterDiaryPage and GlassDeliverySlip.

import { readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scratch = process.argv[2];
if (!scratch) throw new Error("usage: node handwritten-clues.mjs <folder with opentype.js and @fontsource/caveat>");
const require = createRequire(join(resolve(scratch), "noop.js"));
const opentype = require("opentype.js");
const load = (weight) => {
  const file = readFileSync(require.resolve(`@fontsource/caveat/files/caveat-latin-${weight}-normal.woff`));
  return opentype.parse(file.buffer.slice(file.byteOffset, file.byteOffset + file.byteLength));
};
const hand = load(500);
// opentype.js returns NaN for some of this font's kerning pairs and letter
// substitutions, so neither is used.
const NO_KERN = { kerning: false, features: { liga: false, rlig: false, calt: false } };

// Path data from an opentype.js path. Its own toPathData sometimes prints a
// coordinate as NaN, so the numbers are formatted here.
const n = (v) => String(Math.round(v * 10) / 10);
const toD = (path) =>
  path.commands
    .map((c) =>
      c.type === "Z" ? "Z"
      : c.type === "Q" ? `Q${n(c.x1)} ${n(c.y1)} ${n(c.x)} ${n(c.y)}`
      : c.type === "C" ? `C${n(c.x1)} ${n(c.y1)} ${n(c.x2)} ${n(c.y2)} ${n(c.x)} ${n(c.y)}`
      : `${c.type}${n(c.x)} ${n(c.y)}`)
    .join("");

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets");
const INK = "#291e1a", CREAM = "#f2e4c9", RULE = "#a9bccb", MARGIN = "#c98a7a", BUFF = "#efe0b8", WINE = "#893f43", TEAL = "#496669";

// Words wrapped to a width, then drawn as outlines from (x, y), one line per `lead`.
function wrap(text, size, width) {
  const lines = [];
  let line = "";
  for (const word of text.split(" ")) {
    const next = line ? line + " " + word : word;
    if (hand.getAdvanceWidth(next, size, NO_KERN) > width && line) {
      lines.push(line);
      line = word;
    } else {
      line = next;
    }
  }
  if (line) lines.push(line);
  return lines;
}
const wobble = [0.6, -0.8, 0.3, -0.4, 0.9, -0.2, 0.5, -0.7, 0.2, -0.5];
const write = (lines, x, y, size, lead) =>
  lines
    .map((words, i) => `      <path d="${toD(hand.getPath(words, x + wobble[i % wobble.length] * 2, y + i * lead + wobble[(i + 3) % wobble.length], size, NO_KERN))}" />`)
    .join("\n");

// ── Walter's diary page ────────────────────────────────────────────────────
const ENTRY =
  "Four planks and £10 for the whole week. I spent it on a grand new sign for the reopening. It looked wonderful. Then Wednesday’s rain came through the roof onto every book we’d saved.";
{
  const W = 480, size = 30, lead = 38, top = 96;
  const lines = wrap(ENTRY, size, 360);
  const H = top + lines.length * lead + 40;
  const rules = Array.from({ length: lines.length + 1 }, (_, i) => `M 30 ${top + 8 + i * lead} H ${W - 30}`).join(" ");
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- clue-walter-diary: Walter's diary entry in his hand (Caveat, SIL OFL 1.1), built by docs/asset-sources/handwritten-clues.mjs -->
  <g stroke="${INK}" stroke-linejoin="round">
    <!-- The page, a little worn at the corner -->
    <path d="M 20 12 H ${W - 20} V ${H - 30} L ${W - 44} ${H - 12} H 20 Z" fill="${CREAM}" stroke-width="2.5" />
    <path d="M ${W - 20} ${H - 30} L ${W - 44} ${H - 34} L ${W - 44} ${H - 12}" fill="#e2d0ad" stroke-width="2" />
    <!-- Ruled lines and the margin -->
    <path d="${rules}" fill="none" stroke="${RULE}" stroke-width="1.2" />
    <path d="M 62 12 V ${H - 12}" fill="none" stroke="${MARGIN}" stroke-width="1.6" />
    <!-- The ribbon -->
    <path d="M ${W - 70} 12 V 74 L ${W - 60} 64 L ${W - 50} 74 V 12 Z" fill="${TEAL}" stroke-width="1.5" />
    <!-- The entry -->
    <g fill="${INK}" stroke="none">
${write(lines, 76, top, size, lead)}
    </g>
  </g>
</svg>
`;
  writeFileSync(join(OUT, "clue-walter-diary.svg"), svg);
  console.log("wrote clue-walter-diary.svg");
}

// ── The glass delivery slip ────────────────────────────────────────────────
{
  const W = 460, H = 330, size = 31, lead = 40;
  const heading = toD(hand.getPath("Delivery slip", W / 2 - hand.getAdvanceWidth("Delivery slip", 38, NO_KERN) / 2, 66, 38, NO_KERN));
  const body = [
    ...wrap("One pane of window glass for Hale’s Bookshop.", size, 360),
    "",
    ...wrap("Delivery: Wednesday morning. Not available any earlier in the week.", size, 360),
  ];
  const drawn = body
    .map((words, i) => (words ? `      <path d="${toD(hand.getPath(words, 50 + wobble[i] * 2, 120 + i * lead + wobble[i + 2], size, NO_KERN))}" />` : ""))
    .filter(Boolean)
    .join("\n");
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- clue-glass-slip: the supplier's handwritten delivery slip (Caveat, SIL OFL 1.1), built by docs/asset-sources/handwritten-clues.mjs -->
  <g stroke="${INK}" stroke-linejoin="round">
    <!-- A buff slip torn off a pad, a perforated top edge -->
    <path d="M 16 24 H ${W - 16} V ${H - 14} H 16 Z" fill="${BUFF}" stroke-width="2.5" transform="rotate(-1 ${W / 2} ${H / 2})" />
    <path d="M 16 24 H ${W - 16}" fill="none" stroke="${CREAM}" stroke-width="5" stroke-dasharray="2 6" transform="rotate(-1 ${W / 2} ${H / 2})" />
    <g transform="rotate(-1 ${W / 2} ${H / 2})">
      <path d="M 40 86 H ${W - 40}" fill="none" stroke="${WINE}" stroke-width="1.5" />
      <g fill="${WINE}" stroke="none">
        <path d="${heading}" />
      </g>
      <g fill="${INK}" stroke="none">
${drawn}
      </g>
    </g>
  </g>
</svg>
`;
  writeFileSync(join(OUT, "clue-glass-slip.svg"), svg);
  console.log("wrote clue-glass-slip.svg");
}
