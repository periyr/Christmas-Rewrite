// Builds the pictures for the three 1973 shadow-story clues (Content.Clues):
//
//   clue-cutout-box.svg            CutoutBox: the six cut-outs (the real cut-out art)
//                                  standing in their cardboard box
//   clue-script-original.svg       ShadowScript, OriginalScript: Walter's handwritten parts
//   clue-script-retelling.svg      ShadowScript, NeighboursRetelling: the neighbours' parts,
//                                  in another hand on notebook paper
//   clue-sketch-original.svg       StageSketch, OriginalScript: three pencil panels
//   clue-sketch-retelling.svg      StageSketch, NeighboursRetelling: three pencil panels
//
// Each shows only what its words say. The scripts keep the clue's order and are
// not numbered, so the picture never gives the scene order.
//
// The handwriting is the Caveat font (SIL Open Font License 1.1, The Caveat
// Project Authors), turned into outlines. As for closure-note.mjs:
//
//   npm install @fontsource/caveat opentype.js        (in <scratch>)
//   node docs/asset-sources/shadow-clues.mjs <scratch>
//
// The script and sketch words must match Content.Clues shadowScript and stageSketch.

import { readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scratch = process.argv[2];
if (!scratch) throw new Error("usage: node shadow-clues.mjs <folder with opentype.js and @fontsource/caveat>");
const require = createRequire(join(resolve(scratch), "noop.js"));
const opentype = require("opentype.js");
const load = (weight) => {
  const file = readFileSync(require.resolve(`@fontsource/caveat/files/caveat-latin-${weight}-normal.woff`));
  return opentype.parse(file.buffer.slice(file.byteOffset, file.byteOffset + file.byteLength));
};
const hand = load(500);
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
const text = (words, x, y, size) => `<path d="${toD(hand.getPath(words, x, y, size, NO_KERN))}" />`;
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
const INK = "#291e1a", CREAM = "#f2e4c9", PAPER = "#fbf6ea", TAN = "#a6652b", CARD = "#c49a68", BROWN = "#5a3428";
const BLUE_INK = "#2f3f63", RULE = "#a9bccb", MARGIN = "#c98a7a", PENCIL = "#5d5a55";
const write = (name, svg) => {
  writeFileSync(join(ASSETS, name), svg);
  console.log("wrote", name);
};

// ── The box of cut-outs ────────────────────────────────────────────────────
// Each cut-out file drawn inside this picture at its own place and size.
function cutout(file, x, y, size) {
  const src = readFileSync(join(ASSETS, file), "utf8");
  const viewBox = src.match(/viewBox="([^"]+)"/)[1];
  const inner = src.replace(/^[\s\S]*?<svg[^>]*>/, "").replace(/<\/svg>\s*$/, "");
  return `    <svg x="${x}" y="${y}" width="${size}" height="${size}" viewBox="${viewBox}">${inner}</svg>\n`;
}
{
  const W = 480, H = 300;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- clue-cutout-box: the six cut-outs (shadow-*.svg, prop-*.svg) in their box. Built by docs/asset-sources/shadow-clues.mjs -->
  <rect x="0" y="0" width="${W}" height="${H}" fill="${CREAM}" />
  <rect x="0" y="252" width="${W}" height="48" fill="${BROWN}" />
  <g stroke="${INK}" stroke-width="2" stroke-linejoin="round">
    <!-- Back flaps of the box -->
    <path d="M 60 170 L 40 120 L 236 120 L 240 170 Z" fill="${TAN}" />
    <path d="M 240 170 L 244 116 L 440 124 L 420 170 Z" fill="${TAN}" />
    <rect x="60" y="160" width="360" height="20" fill="#3f2c1c" />
  </g>
  <!-- The cut-outs, characters on the left, props on the right -->
${cutout("shadow-fox.svg", 20, 4, 184)}${cutout("shadow-owl.svg", 108, -8, 184)}${cutout("shadow-child.svg", 186, -2, 184)}${cutout("prop-lantern.svg", 262, 50, 116)}${cutout("prop-key.svg", 318, 56, 116)}${cutout("prop-book.svg", 360, 54, 116)}
  <g stroke="${INK}" stroke-width="2" stroke-linejoin="round">
    <!-- Front of the box -->
    <path d="M 56 176 L 424 176 L 412 266 L 68 266 Z" fill="${CARD}" />
    <path d="M 56 176 L 424 176" fill="none" stroke-width="3" />
    <rect x="186" y="198" width="108" height="40" fill="${PAPER}" stroke-width="1.5" transform="rotate(-2 240 218)" />
  </g>
  <g fill="${INK}">
    ${text("Cut-outs", 240 - width("Cut-outs", 30) / 2, 228, 30)}
  </g>
</svg>
`;
  write("clue-cutout-box.svg", svg);
}

// ── The scripts ────────────────────────────────────────────────────────────
const SCRIPTS = {
  original: {
    parts: ["The child opens the book when everyone is home.", "The fox carries the lantern across the bridge.", "The owl uses the key at the door."],
    paper: CREAM, ink: INK, ruled: false, note: "Walter's handwritten parts",
  },
  retelling: {
    parts: ["The child finds the key at the gate.", "The fox carries the lantern to guide everyone home.", "The owl reads the book inside."],
    paper: PAPER, ink: BLUE_INK, ruled: true, note: "the neighbours' handwritten parts, on notebook paper",
  },
};
for (const [key, script] of Object.entries(SCRIPTS)) {
  const W = 480, size = 30, lead = 38, top = 70, left = 70;
  const lines = script.parts.flatMap((part, i) => [...wrap(part, size, 350).map((l, j) => (j === 0 ? "– " + l : "   " + l)), ...(i < script.parts.length - 1 ? [""] : [])]);
  const H = top + lines.length * (lead - 6) + 50;
  let y = top;
  const drawn = lines
    .map((line) => {
      const here = y;
      y += line ? lead : lead - 18;
      return line ? text(line, left + (line.startsWith("   ") ? 8 : 0), here, size) : "";
    })
    .filter(Boolean)
    .join("\n      ");
  const rules = script.ruled
    ? `<path d="${Array.from({ length: Math.ceil((H - 40) / 34) }, (_, i) => `M 22 ${44 + i * 34} H ${W - 22}`).join(" ")}" fill="none" stroke="${RULE}" stroke-width="1.2" />
    <path d="M 56 14 V ${H - 14}" fill="none" stroke="${MARGIN}" stroke-width="1.6" />`
    : `<path d="M 22 14 L ${W - 22} 14" fill="none" />`;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- clue-script-${key}: ${script.note} (Caveat, SIL OFL 1.1). Built by docs/asset-sources/shadow-clues.mjs -->
  <g stroke="${INK}" stroke-linejoin="round">
    <path d="M 16 12 H ${W - 16} V ${H - 12} H 16 Z" fill="${script.paper}" stroke-width="2.5" transform="rotate(${key === "original" ? -1 : 1} ${W / 2} ${H / 2})" />
    <g transform="rotate(${key === "original" ? -1 : 1} ${W / 2} ${H / 2})">
    ${rules}
    <g fill="${script.ink}" stroke="none">
      ${drawn}
    </g>
    </g>
  </g>
</svg>
`;
  write(`clue-script-${key}.svg`, svg);
}

// ── The stage sketches: three pencil panels ────────────────────────────────
// Little pencil drawings of each setting, in a 120 x 110 panel.
const DRAW = {
  bridge: `<path d="M 10 82 Q 60 30 110 82" /><path d="M 10 82 H 110 M 22 70 V 82 M 40 58 V 82 M 60 52 V 82 M 80 58 V 82 M 98 70 V 82" /><path d="M 4 96 C 30 90 50 100 76 94 C 92 90 104 96 116 94" />`,
  door: `<rect x="38" y="20" width="44" height="76" /><rect x="44" y="28" width="32" height="26" /><circle cx="74" cy="64" r="3" /><path d="M 30 96 H 90" />`,
  home: `<path d="M 24 56 L 60 24 L 96 56" /><rect x="32" y="56" width="56" height="40" /><rect x="40" y="64" width="16" height="14" /><rect x="64" y="70" width="14" height="26" /><path d="M 78 38 V 24 H 86 V 46" />`,
  gate: `<path d="M 20 96 V 40 M 100 96 V 40 M 30 50 H 90 M 30 86 H 90 M 30 50 V 86 M 45 50 V 86 M 60 50 V 86 M 75 50 V 86 M 90 50 V 86 M 30 86 L 90 50" /><path d="M 4 96 H 116" />`,
  inside: `<path d="M 8 96 H 112 M 8 24 V 96 M 112 24 V 96" /><path d="M 30 96 V 70 Q 30 56 44 56 H 64 Q 78 56 78 70 V 96 M 24 76 H 84" /><path d="M 96 96 V 60 M 88 60 H 104 L 100 48 H 92 Z" />`,
};
const SKETCHES = {
  original: [["bridge", "the bridge"], ["door", "the door"], ["home", "home"]],
  retelling: [["gate", "the gate"], ["inside", "inside"], ["home", "home"]],
};
for (const [key, scenes] of Object.entries(SKETCHES)) {
  const W = 480, H = 268;
  const panels = scenes
    .map(([drawing, label], i) => {
      const x = 24 + i * 148;
      const scene = `Scene ${i + 1}:`;
      return `    <rect x="${x}" y="44" width="136" height="150" fill="none" stroke-width="2" />
    <g transform="translate(${x + 8} 62)" fill="none" stroke-width="1.8">${DRAW[drawing]}</g>
    <g fill="${PENCIL}" stroke="none">${text(scene, x + 68 - width(scene, 24) / 2, 222, 24)}${text(label, x + 68 - width(label, 24) / 2, 248, 24)}</g>
    <g fill="${PENCIL}" stroke="none">${text(String(i + 1), x + 10, 38, 26)}</g>`;
    })
    .join("\n");
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- clue-sketch-${key}: three stage panels sketched and numbered in pencil (Caveat, SIL OFL 1.1). Built by docs/asset-sources/shadow-clues.mjs -->
  <rect x="0" y="0" width="${W}" height="${H}" fill="${PAPER}" />
  <g stroke="${PENCIL}" stroke-linejoin="round" stroke-linecap="round">
${panels}
  </g>
</svg>
`;
  write(`clue-sketch-${key}.svg`, svg);
}
