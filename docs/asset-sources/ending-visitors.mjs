// Builds public/assets/ending-visitors.svg: the saved ending (Content.Endings
// saved). Ruth comes in out of the snow, slower now, with Lucy beside her and
// Lucy's daughter holding a fox-and-lantern book.
//
//   node docs/asset-sources/ending-visitors.mjs
//
// The three are drawn on the same body as the player sprites
// (chibi-family.mjs), so they match everyone else in the game. Ruth keeps the
// blue coat and red scarf from the 1973 photo, now with grey hair and a stick;
// Lucy keeps her fair hair; her daughter has plaits like Lucy's in 1973.

import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { MIRROR, CREAM, INK, SKIN, CHEEK, HAIR, CLOTH, p, c, rect, eyes, el, figure } from "./chibi-family.mjs";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets", "ending-visitors.svg");
const TORSO = "M 32,74 C 48,82 64,74 66,114 C 48,122 30,114 32,74 Z";
const FAIR = CLOTH.mustard;
const smile = p("M 54.4,60.6 Q 57.6,63.6 60.8,60.6", "none", { "stroke-width": 2 });

// A long coat: the body, and a skirt that falls over the top of the legs.
const coat = (colour) => [p(TORSO, colour), p("M 33,104 C 46,110 56,110 66,104 L 70,134 C 54,140 44,140 30,134 Z", colour)];

const ruth = {
  sleeve: CLOTH.periwinkle, forearm: CLOTH.periwinkle, trousers: CLOTH.olive, shoes: HAIR.brown,
  torso: [
    ...coat(CLOTH.periwinkle),
    p("M 48,90 L 48,132", "none", { "stroke-width": 1.6 }),
    c(52, 98, 1.8, CREAM), c(52, 110, 1.8, CREAM), c(52, 122, 1.8, CREAM),
    // The red scarf she wore in 1973.
    p("M 35,73 C 43,79.5 54,79.5 62,72 L 62.5,79.5 C 54,86.5 43,86.5 34.5,80.5 Z", CLOTH.vermilion),
    p("M 54,80 L 61,80 L 62,100 L 55,100 Z", CLOTH.vermilion),
  ],
  torsoLabel: "Torso (blue coat and red scarf)",
  behindHead: [c(28, 30, 9, HAIR.grey)],
  face: [
    ...eyes(CLOTH.teal),
    smile,
    // Reading glasses, and the lines of a smile.
    c(46, 46, 8, "none", { "stroke-width": 1.4 }),
    c(65, 46, 8, "none", { "stroke-width": 1.4 }),
    p("M 54,45 L 57,45 M 38,45 L 28,43", "none", { "stroke-width": 1.4 }),
  ],
  topLabel: "Grey hair in a bun",
  top: [p("M 18,44 C 16,22 30,13 48,13 C 66,13 80,22 79,38 C 70,30 58,27 48,28 C 38,29 28,34 24,42 C 22,44 20,45 18,44 Z", HAIR.grey)],
};

const lucy = {
  sleeve: CLOTH.wine, forearm: CLOTH.wine, trousers: CLOTH.teal, shoes: INK,
  torso: [
    ...coat(CLOTH.wine),
    p("M 35,73 C 43,79.5 54,79.5 62,72 L 62.5,79.5 C 54,86.5 43,86.5 34.5,80.5 Z", CLOTH.green),
    p("M 53,80 L 60,80 L 61,98 L 54,98 Z", CLOTH.green),
    p("M 54,86 L 60,86 M 54,92 L 60.5,92", "none", { stroke: FAIR, "stroke-width": 1.6 }),
  ],
  torsoLabel: "Torso (wine coat, green scarf)",
  behindHead: [p("M 18,34 C 10,50 12,70 26,78 L 34,74 L 30,40 Z", FAIR)],
  face: [...eyes(CLOTH.periwinkle), smile],
  topLabel: "Fair hair, shoulder length",
  top: [p("M 18,46 C 14,22 30,12 50,12 C 70,12 82,24 80,40 C 72,32 60,27 50,27 C 40,28 30,34 26,42 L 24,56 C 22,58 19,56 18,46 Z", FAIR)],
};

const daughter = {
  sleeve: CLOTH.vermilion, forearm: CLOTH.vermilion, trousers: CLOTH.olive, shoes: CLOTH.wine,
  torso: [...coat(CLOTH.vermilion), p("M 40,90 L 56,90", "none", { stroke: CREAM, "stroke-width": 2 })],
  torsoLabel: "Torso (red duffle coat)",
  behindHead: [],
  face: [...eyes(HAIR.brown), c(41, 57, 3.6, CHEEK, { stroke: "none" }), p("M 53,59.6 Q 57.6,65 62.2,59.6", "none", { "stroke-width": 2 })],
  topLabel: "Brown hair in plaits, a bobble hat",
  top: [
    p("M 22,58 C 16,64 18,74 24,76 M 76,56 C 82,62 80,72 74,74", "none", { stroke: HAIR.brown, "stroke-width": 6 }),
    p("M 16,40 C 14,16 32,8 50,8 C 68,8 84,16 82,40 C 70,34 30,34 16,40 Z", CLOTH.teal),
    p("M 16,40 C 30,34 70,34 82,40 L 82,46 C 70,40 30,40 16,46 Z", CREAM),
    c(50, 6, 6, CREAM),
  ],
};

// Ruth's walking stick, in her front hand (sprite units, mirrored with the arms).
const stick = `  <g transform="${MIRROR}" stroke="${INK}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">
${[
  p("M 24.5,110 L 21,152 L 25,152 L 28.5,110 Z", HAIR.brown, { "stroke-width": 2.4 }),
  p("M 28,112 C 28,102 16,100 14,108 L 17.5,109 C 19,104 24.5,105 24.5,112 Z", HAIR.brown, { "stroke-width": 2.4 }),
  c(25, 111, 4, SKIN),
].map((x) => "    " + el(x)).join("\n")}
  </g>`;

// The fox-and-lantern book, held up in both hands.
const book = `  <g stroke="${INK}" stroke-width="2.4" stroke-linejoin="round">
${[
  rect(30, 88, 40, 30, 2, CLOTH.green),
  p("M 40,110 C 42,104 48,102 52,105 L 55,99 L 56,105 C 59,107 58,111 54,111 Z", CLOTH.vermilion, { "stroke-width": 1.4 }),
  rect(58, 100, 5, 7, 1, CLOTH.mustard),
  c(31, 113, 4, SKIN),
  c(69, 113, 4, SKIN),
].map((x) => "    " + el(x)).join("\n")}
  </g>`;

const W = 420, H = 380, FLOOR = 346;
const place = (person, x, scale, { flip = false, extra = "" } = {}) => {
  const tx = flip ? x + 48 * scale : x - 48 * scale;
  return `  <g transform="translate(${tx} ${FLOOR - 152 * scale}) scale(${flip ? -scale : scale} ${scale})">
${figure(person, "idle")}
${extra}
  </g>`;
};
const snow = Array.from({ length: 44 }, (_, i) => {
  const x = 96 + ((i * 53) % 228), y = 30 + ((i * 37 + (i % 5) * 19) % 250);
  return `<circle cx="${x}" cy="${y}" r="${1.6 + (i % 3) * 0.7}" />`;
}).join("");

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- ending-visitors: Ruth, Lucy and Lucy's daughter come in out of the snow on Christmas morning. Built by docs/asset-sources/ending-visitors.mjs -->
  <!-- Inside: the shop wall and floor, warm -->
  <rect x="0" y="0" width="${W}" height="${H}" fill="#e9d6ae" />
  <rect x="0" y="${FLOOR - 6}" width="${W}" height="${H - FLOOR + 6}" fill="${HAIR.brown}" />
  <!-- The open doorway and the snowy night outside -->
  <rect x="90" y="20" width="240" height="${FLOOR - 26}" fill="#2e3b52" />
  <g fill="#f6eedb" stroke="none">${snow}</g>
  <path d="M 90 ${FLOOR - 26} C 150 ${FLOOR - 40} 260 ${FLOOR - 36} 330 ${FLOOR - 28} L 330 ${FLOOR - 6} L 90 ${FLOOR - 6} Z" fill="#f6eedb" />
  <g fill="none" stroke="${INK}" stroke-width="3"><rect x="90" y="20" width="240" height="${FLOOR - 26}" /></g>
  <rect x="78" y="10" width="264" height="14" fill="${CLOTH.wine}" stroke="${INK}" stroke-width="2.5" />
  <!-- The door, swung open, its sign turned to OPEN -->
  <path d="M 330 20 L 392 34 L 392 ${FLOOR + 8} L 330 ${FLOOR - 6} Z" fill="${CLOTH.wine}" stroke="${INK}" stroke-width="2.5" stroke-linejoin="round" />
  <g transform="rotate(12.7 362 116)">
    <rect x="340" y="104" width="44" height="24" rx="2" fill="${CREAM}" stroke="${INK}" stroke-width="1.6" />
    <text x="362" y="121" text-anchor="middle" font-family="Georgia, 'Times New Roman', serif" font-size="12" font-weight="bold" fill="${INK}">OPEN</text>
  </g>
  <!-- Ruth, slower now, with her stick -->
${place(ruth, 150, 1.32, { extra: stick })}
  <!-- Lucy, beside her mother -->
${place(lucy, 288, 1.36, { flip: true })}
  <!-- Lucy's daughter in front, holding the fox-and-lantern book -->
${place(daughter, 218, 0.92, { extra: book })}
  <!-- A little snow on their shoulders -->
  <g fill="#f6eedb" stroke="none"><circle cx="118" cy="216" r="3" /><circle cx="176" cy="220" r="2.5" /><circle cx="262" cy="214" r="3" /><circle cx="314" cy="220" r="2.5" /><circle cx="205" cy="262" r="2" /></g>
</svg>
`;
writeFileSync(OUT, svg);
console.log("wrote", OUT);
