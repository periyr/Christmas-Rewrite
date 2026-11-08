// Builds public/assets/clue-family-photographs.svg: the four photographs in one
// frame that hang behind the counter (Content.Clues FamilyPhotograph).
//
//   node docs/asset-sources/family-photo.mjs
//
// Each photo is taken outside the shop and uses the same bodies as the player
// sprites (chibi-family.mjs): the founder in his apron, Walter with a hammer,
// Henry with an armful of books, and young Edwin squinting into the sun.
// Older photos get a warmer, faded tint.

import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { PEOPLE, CREAM, INK, SKIN, CHEEK, HAIR, CLOTH, p, c, rect, eyes, el, figure } from "./chibi-family.mjs";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets", "clue-family-photographs.svg");

// ── the founder: Walter's body, shirt sleeves, a long apron, bow tie ──────
const founder = {
  sleeve: CREAM, forearm: SKIN, rolledCuff: CREAM, trousers: CLOTH.olive, shoes: INK,
  torso: [
    p("M 32,74 C 48,82 64,74 66,114 C 48,122 30,114 32,74 Z", CREAM),
    // Apron: bib on the chest, skirt down over the legs.
    p("M 38,86 L 60,86 L 63,112 L 66,134 C 54,138 42,138 30,134 L 34,112 Z", CLOTH.mustard),
    p("M 38,86 L 41,78 M 60,86 L 57,78", "none", { stroke: CLOTH.mustard, "stroke-width": 2.4 }),
    p("M 41,98 L 57,98 L 57,106 L 41,106 Z", "none", { "stroke-width": 1.6 }),
    // Bow tie.
    p("M 48,79 L 42,75.5 L 42,82.5 Z M 48,79 L 54,75.5 L 54,82.5 Z", CLOTH.wine, { "stroke-width": 1.8 }),
  ],
  torsoLabel: "Torso (shirt, apron and bow tie)",
  behindHead: [p("M 16,30 C 12,40 16,54 26,56 L 30,46 Z", HAIR.grey), p("M 26,52 C 24,62 28,68 34,68 L 34,52 Z", HAIR.grey)],
  face: [
    ...eyes(CLOTH.teal),
    // Big walrus moustache.
    p("M 46.6,62 C 47.4,53.6 67.8,53.6 68.6,62 C 66,60.8 63,60.2 60.2,61 C 59,59.8 56.4,59.8 55.2,61 C 52,60.2 49.2,60.8 46.6,62 Z", HAIR.grey, { "stroke-width": 2 }),
  ],
  topLabel: "Thinning grey hair",
  top: [
    p("M 22,38 C 22,24 34,18 46,18 C 40,22 34,26 30,34 C 28,38 25,40 22,38 Z", HAIR.grey),
    p("M 56,18.5 C 66,19 74,24 77,32 C 72,28 64,24 56,22 Z", HAIR.grey),
  ],
};

// Young Edwin with screwed-up eyes against the sun.
const squinting = {
  ...PEOPLE["edwin-young"],
  face: [
    c(41, 57, 3.6, CHEEK, { stroke: "none" }),
    c(71, 57, 3.6, CHEEK, { stroke: "none" }),
    p("M 40.6,44.4 L 47,47 L 41,50", "none", { "stroke-width": 2.6 }),
    p("M 70.4,44.4 L 64,47 L 70,50", "none", { "stroke-width": 2.6 }),
    c(57, 53.4, 1.5, INK, { stroke: "none" }),
    p("M 53.6,60.4 Q 57.6,63.8 61.6,60.4", "none", { "stroke-width": 2 }),
  ],
};

// Things held, in sprite units, drawn over the figure.
const hammer = [
  p("M 49,124 L 53,124 L 63,90 L 59,89 Z", HAIR.brown, { "stroke-width": 2.4 }),
  p("M 52,84 L 70,89 L 68,95 L 50,90 Z", HAIR.grey, { "stroke-width": 2.4 }),
  c(52, 115, 4, SKIN),
];
const books = [
  rect(31, 103, 34, 8, 1.5, CLOTH.teal),
  rect(33, 95, 30, 8, 1.5, CLOTH.wine),
  rect(30, 87, 33, 8, 1.5, CLOTH.mustard),
  c(31, 103, 4, SKIN),
  c(62, 108, 4, SKIN),
].map((s) => ({ ...s, "stroke-width": s.tag === "rect" ? 2.4 : 3 }));
const holding = (items) => `  <g stroke="${INK}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">
${items.map((x) => "    " + el(x)).join("\n")}
  </g>`;

// ── the photographs ────────────────────────────────────────────────────────
const W = 640, H = 330, PW = 130, PH = 206, PY = 42, SCALE = 1.05;
const photos = [
  { who: founder, extra: "", name: "The founder", tint: 0.42, wall: CLOTH.olive, tilt: -2 },
  { who: PEOPLE.walter, extra: holding(hammer), name: "Walter", tint: 0.3, wall: CLOTH.wine, tilt: 1.5 },
  { who: PEOPLE.henry, extra: holding(books), name: "Henry", tint: 0.14, wall: CLOTH.green, tilt: -1 },
  { who: squinting, extra: "", name: "Edwin", tint: 0, wall: CLOTH.teal, tilt: 2, sun: true },
];

function photo({ who, extra, name, tint, wall, tilt, sun }, i) {
  const x = 30 + i * 150, cx = x + PW / 2, cy = PY + PH / 2;
  const fx = cx - 48 * SCALE, fy = PY + PH - 14 - 152 * SCALE;
  const id = `ph${i}`;
  return `  <!-- ${name} -->
  <g transform="rotate(${tilt} ${cx} ${cy})">
    <rect x="${x - 6}" y="${PY - 6}" width="${PW + 12}" height="${PH + 12}" rx="2" fill="${CREAM}" stroke="${INK}" stroke-width="2" />
    <clipPath id="${id}"><rect x="${x}" y="${PY}" width="${PW}" height="${PH}" /></clipPath>
    <g clip-path="url(#${id})">
      <!-- Sky, the shop front, its sign and window, the pavement -->
      <rect x="${x}" y="${PY}" width="${PW}" height="${PH}" fill="${CLOTH.periwinkle}" />
      <rect x="${x}" y="${PY + 10}" width="${PW}" height="${PH - 10}" fill="${wall}" />
      <rect x="${x + 10}" y="${PY + 16}" width="${PW - 20}" height="18" fill="${CREAM}" stroke="${INK}" stroke-width="2" />
      <text x="${cx}" y="${PY + 30}" text-anchor="middle" font-family="Georgia, 'Times New Roman', serif" font-size="13" font-weight="bold" fill="${INK}" letter-spacing="1">HALE’S</text>
      ${sun ? `<circle cx="${x + PW - 6}" cy="${PY + 6}" r="15" fill="${CLOTH.mustard}" stroke="${INK}" stroke-width="2" />` : ""}
      <rect x="${x + 14}" y="${PY + 46}" width="${PW - 28}" height="90" fill="${HAIR.grey}" stroke="${CREAM}" stroke-width="4" />
      <path d="M ${cx} ${PY + 46} L ${cx} ${PY + 136} M ${x + 14} ${PY + 91} L ${x + PW - 14} ${PY + 91}" stroke="${CREAM}" stroke-width="3" />
      <rect x="${x}" y="${PY + PH - 24}" width="${PW}" height="24" fill="${HAIR.brown}" />
      <g transform="translate(${fx} ${fy}) scale(${SCALE})">
${figure(who, "idle")}
${extra}
      </g>
      ${tint ? `<rect x="${x}" y="${PY}" width="${PW}" height="${PH}" fill="${CLOTH.mustard}" opacity="${tint}" />` : ""}
    </g>
    <rect x="${x}" y="${PY}" width="${PW}" height="${PH}" fill="none" stroke="${INK}" stroke-width="1.5" />
    <text x="${cx}" y="${PY + PH + 30}" text-anchor="middle" font-family="Georgia, 'Times New Roman', serif" font-style="italic" font-size="15" fill="${INK}">${name}</text>
  </g>`;
}

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- clue-family-photographs: four photos in one frame, built by docs/asset-sources/family-photo.mjs from the player sprites -->
  <rect x="2" y="2" width="${W - 4}" height="${H - 4}" rx="6" fill="${HAIR.brown}" stroke="${INK}" stroke-width="3" />
  <rect x="16" y="16" width="${W - 32}" height="${H - 32}" rx="2" fill="${CREAM}" stroke="${INK}" stroke-width="2" />
${photos.map(photo).join("\n")}
</svg>
`;
writeFileSync(OUT, svg);
console.log("wrote", OUT);
