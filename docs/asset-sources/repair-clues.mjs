// Builds the pictures for two 1950 repair-board clues (Content.Clues), shown
// above their words:
//
//   clue-repair-notes.svg    RubbleAndShelvesNote: Walter's sketch, shelves where the
//                            rubble is, books waiting in their crates
//   clue-budget.svg          BudgetAllocation: four wood planks and a ten-pound note
//
// Walter's diary page and the glass delivery slip are handwritten pages instead
// (handwritten-clues.mjs).
//
// Each shows only what its words already say, never how to plan the week.
//
//   node docs/asset-sources/repair-clues.mjs
//
// Flat paper-theatre style like the room props: team palette, thin ink lines, 480 x 300.

import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets");

const INK = "#291e1a", CREAM = "#f2e4c9", PAPER = "#fbf6ea", GREY = "#d4d3d1", BROWN = "#5a3428", TAN = "#a6652b", WOOD = "#c49a68";
const C = { olive: "#393e26", vermilion: "#c95937", mustard: "#d9a443", teal: "#496669", periwinkle: "#7687ab", wine: "#893f43", green: "#31542f" };
const W = 480, H = 300;
const FONT = `font-family="Georgia, 'Times New Roman', serif"`;
const HAND = `font-family="'Segoe Print', 'Bradley Hand', 'Comic Sans MS', cursive"`;

const svg = (name, note, body) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- ${name}: ${note}. Built by docs/asset-sources/repair-clues.mjs -->
  <g stroke="${INK}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">
${body}
  </g>
</svg>
`;

// A crate of books seen from the front.
const crate = (x, y) => `    <g>
      <path d="M ${x + 8} ${y} l 12 -26 h 12 l -2 26 Z M ${x + 32} ${y} l 2 -30 h 12 l 0 30 Z M ${x + 50} ${y} l 6 -22 h 12 l -4 22 Z" fill="${C.teal}" stroke-width="1.5" />
      <path d="M ${x + 22} ${y} l 2 -24 h 9 l 0 24 Z M ${x + 64} ${y} l 2 -28 h 10 l 0 28 Z" fill="${C.wine}" stroke-width="1.5" />
      <rect x="${x}" y="${y}" width="84" height="40" fill="${TAN}" />
      <path d="M ${x} ${y + 13} H ${x + 84} M ${x} ${y + 26} H ${x + 84}" fill="none" stroke-width="1.5" />
    </g>
`;

// ── Walter's repair notes: a pencil sketch on squared paper ───────────────
const notes = `    <rect x="0" y="0" width="${W}" height="${H}" fill="${BROWN}" />
    <g transform="rotate(-2 240 150)">
      <rect x="24" y="16" width="432" height="268" fill="${PAPER}" />
      <path d="${Array.from({ length: 13 }, (_, i) => `M 24 ${36 + i * 20} H 456`).join(" ")}" stroke="#c9d7dc" stroke-width="1" />
      <!-- The wall and floor line -->
      <path d="M 50 236 H 430" stroke-width="2.5" />
      <!-- Rubble where the new shelves will go -->
      <path d="M 230 236 l 18 -40 22 18 18 -30 28 30 22 -20 30 42 Z" fill="${GREY}" />
      <path d="M 262 236 l 12 -22 18 12 14 -16 20 26 Z" fill="#b9b6b0" />
      <!-- The new shelves, drawn in dashes over the rubble -->
      <g fill="none" stroke="${C.wine}" stroke-width="2.5" stroke-dasharray="7 5">
        <rect x="222" y="72" width="170" height="164" />
        <path d="M 222 126 H 392 M 222 180 H 392" />
      </g>
      <text x="307" y="62" text-anchor="middle" ${HAND} font-size="15" fill="${C.wine}" stroke="none">new shelves</text>
      <text x="300" y="262" text-anchor="middle" ${HAND} font-size="14" fill="${INK}" stroke="none">rubble out first</text>
      <!-- Books waiting in their crates -->
${crate(70, 196)}
      <text x="112" y="262" text-anchor="middle" ${HAND} font-size="14" fill="${INK}" stroke="none">books wait</text>
      <path d="M 160 176 C 186 140 200 130 214 128" fill="none" stroke="${C.wine}" stroke-width="2" stroke-dasharray="5 5" />
      <path d="M 206 122 L 216 128 L 206 136" fill="none" stroke="${C.wine}" stroke-width="2" />
    </g>
`;

// ── Wood planks and cash ───────────────────────────────────────────────────
const plank = (y, tilt) => `    <g transform="rotate(${tilt} 180 ${y})">
      <rect x="40" y="${y}" width="290" height="22" fill="${WOOD}" />
      <path d="M 70 ${y + 8} C 120 ${y + 4} 170 ${y + 12} 230 ${y + 8} M 120 ${y + 15} C 170 ${y + 12} 230 ${y + 18} 300 ${y + 14}" fill="none" stroke="${TAN}" stroke-width="1.5" />
      <ellipse cx="96" cy="${y + 11}" rx="5" ry="3" fill="none" stroke="${TAN}" stroke-width="1.5" />
    </g>
`;
const budget = `    <rect x="0" y="0" width="${W}" height="${H}" fill="${BROWN}" />
    <rect x="0" y="0" width="${W}" height="${H}" fill="${TAN}" fill-opacity="0.25" stroke="none" />
    <!-- Four wood planks -->
${plank(150, -1)}${plank(176, 0.5)}${plank(202, -0.5)}${plank(228, 1)}
    <text x="186" y="276" text-anchor="middle" ${FONT} font-size="16" font-weight="bold" fill="${CREAM}" stroke="none">4 planks</text>
    <!-- A ten-pound note -->
    <g transform="rotate(-8 360 96)">
      <rect x="276" y="44" width="176" height="96" rx="4" fill="#b7c9b0" />
      <rect x="286" y="54" width="156" height="76" rx="2" fill="none" stroke="${C.green}" stroke-width="1.5" />
      <circle cx="400" cy="92" r="24" fill="#cfdcc7" stroke="${C.green}" stroke-width="1.5" />
      <text x="400" y="101" text-anchor="middle" ${FONT} font-size="24" font-weight="bold" fill="${C.green}" stroke="none">10</text>
      <text x="300" y="80" ${FONT} font-size="15" font-weight="bold" fill="${C.green}" stroke="none">£10</text>
      <text x="300" y="104" ${FONT} font-size="10" fill="${C.green}" stroke="none">TEN POUNDS</text>
    </g>
    <text x="364" y="276" text-anchor="middle" ${FONT} font-size="16" font-weight="bold" fill="${CREAM}" stroke="none">£10</text>
`;

const files = {
  "clue-repair-notes.svg": ["Walter's sketch: new shelves where the rubble is, books waiting in their crates", notes],
  "clue-budget.svg": ["four wood planks and a ten-pound note for the whole week", budget],
};
for (const [name, [note, body]] of Object.entries(files)) {
  writeFileSync(join(OUT, name), svg(name.replace(".svg", ""), note, body));
  console.log("wrote", name);
}
