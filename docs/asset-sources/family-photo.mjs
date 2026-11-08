// Builds public/assets/clue-family-photographs.svg: the family photograph that
// hangs in the shop (Content.Clues FamilyPhotograph).
//
//   node docs/asset-sources/family-photo.mjs
//
// One photo in one frame, taken outside the shop around 1990: grandad Walter
// with his walking stick, dad Henry, and little Edwin in front, squinting into
// the sun. The figures use the same bodies as the player sprites
// (chibi-family.mjs). Walter and Henry turn in towards Edwin.

import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { MIRROR, PEOPLE, CREAM, INK, SKIN, CHEEK, HAIR, CLOTH, p, c, el, figure } from "./chibi-family.mjs";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets", "clue-family-photographs.svg");

// Little Edwin, about five: bowl haircut, a mustard jumper with a red stripe,
// blue trousers, red shoes, eyes screwed up against the sun.
const littleEdwin = {
  sleeve: CLOTH.mustard, forearm: CLOTH.mustard, trousers: CLOTH.periwinkle, shoes: CLOTH.vermilion,
  torso: [
    p("M 32,74 C 48,82 64,74 66,114 C 48,122 30,114 32,74 Z", CLOTH.mustard),
    p("M 32.5,93 C 44,97 56,97 65,93 L 65.6,101 C 56,105 44,105 32.4,101 Z", CLOTH.vermilion, { "stroke-width": 2 }),
  ],
  torsoLabel: "Torso (striped jumper)",
  behindHead: [],
  face: [
    c(41, 57, 3.6, CHEEK, { stroke: "none" }),
    c(71, 57, 3.6, CHEEK, { stroke: "none" }),
    p("M 40.6,44.4 L 47,47 L 41,50", "none", { "stroke-width": 2.6 }),
    p("M 70.4,44.4 L 64,47 L 70,50", "none", { "stroke-width": 2.6 }),
    c(57, 53.4, 1.5, INK, { stroke: "none" }),
    p("M 52.6,60 Q 57.6,65.4 62.6,60", "none", { "stroke-width": 2 }),
  ],
  topLabel: "Bowl haircut",
  top: [p("M 17,48 C 13,24 30,12 50,12 C 71,12 83,25 81,44 C 72,40 62,37 52,37 C 40,37 28,41 22,46 C 20,48 18,49 17,48 Z", HAIR.brown)],
};

// Walter's walking stick in his front hand, in sprite units, drawn with the
// mirrored arms so it lines up with the hand.
const stick = `  <g transform="${MIRROR}" stroke="${INK}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">
${[
  p("M 24.5,110 L 21,152 L 25,152 L 28.5,110 Z", HAIR.brown, { "stroke-width": 2.4 }),
  p("M 28,112 C 28,102 16,100 14,108 L 17.5,109 C 19,104 24.5,105 24.5,112 Z", HAIR.brown, { "stroke-width": 2.4 }),
  c(25, 111, 4, SKIN),
].map((x) => "    " + el(x)).join("\n")}
  </g>`;

const W = 600, H = 470;
// Photo window inside the frame and mat.
const PX = 60, PY = 56, PW = 480, PH = 330, GROUND = PY + PH - 26;

// A figure standing with its soles on the pavement, centred on x.
const place = (person, x, scale, { flip = false, extra = "" } = {}) => {
  const tx = flip ? x + 48 * scale : x - 48 * scale;
  const ty = GROUND - 152 * scale;
  return `      <g transform="translate(${tx} ${ty}) scale(${flip ? -scale : scale} ${scale})">
${figure(person, "idle")}
${extra}
      </g>`;
};

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- clue-family-photographs: Walter, Henry and little Edwin outside the shop, built by docs/asset-sources/family-photo.mjs from the player sprites -->
  <!-- Wooden frame and cream mat -->
  <rect x="2" y="2" width="${W - 4}" height="${H - 4}" rx="8" fill="${HAIR.brown}" stroke="${INK}" stroke-width="3" />
  <rect x="22" y="22" width="${W - 44}" height="${H - 44}" rx="2" fill="${CREAM}" stroke="${INK}" stroke-width="2" />
  <clipPath id="photo"><rect x="${PX}" y="${PY}" width="${PW}" height="${PH}" /></clipPath>
  <g clip-path="url(#photo)">
    <!-- Sky and sun -->
    <rect x="${PX}" y="${PY}" width="${PW}" height="${PH}" fill="${CLOTH.periwinkle}" />
    <circle cx="${PX + PW - 30}" cy="${PY + 26}" r="22" fill="${CLOTH.mustard}" stroke="${INK}" stroke-width="2" />
    <!-- Shop front: wall, sign, two windows and the door -->
    <rect x="${PX}" y="${PY + 46}" width="${PW - 70}" height="${PH - 46}" fill="${CLOTH.green}" stroke="${INK}" stroke-width="2" />
    <rect x="${PX + 30}" y="${PY + 58}" width="${PW - 130}" height="34" fill="${CREAM}" stroke="${INK}" stroke-width="2.5" />
    <text x="${PX + 30 + (PW - 130) / 2}" y="${PY + 84}" text-anchor="middle" font-family="Georgia, 'Times New Roman', serif" font-size="24" font-weight="bold" fill="${INK}" letter-spacing="3">HALE’S BOOKSHOP</text>
    <g stroke="${CREAM}" stroke-width="5">
      <rect x="${PX + 22}" y="${PY + 108}" width="120" height="150" fill="${HAIR.grey}" />
      <rect x="${PX + 268}" y="${PY + 108}" width="120" height="150" fill="${HAIR.grey}" />
      <path d="M ${PX + 82} ${PY + 108} L ${PX + 82} ${PY + 258} M ${PX + 22} ${PY + 183} L ${PX + 142} ${PY + 183} M ${PX + 328} ${PY + 108} L ${PX + 328} ${PY + 258} M ${PX + 268} ${PY + 183} L ${PX + 388} ${PY + 183}" />
    </g>
    <rect x="${PX + 168}" y="${PY + 112}" width="74" height="192" fill="${CLOTH.wine}" stroke="${INK}" stroke-width="2.5" />
    <rect x="${PX + 180}" y="${PY + 126}" width="50" height="60" fill="${HAIR.grey}" stroke="${INK}" stroke-width="2" />
    <circle cx="${PX + 230}" cy="${PY + 222}" r="3.5" fill="${CLOTH.mustard}" stroke="${INK}" stroke-width="1.5" />
    <!-- Pavement -->
    <rect x="${PX}" y="${GROUND - 4}" width="${PW}" height="${PH}" fill="${HAIR.brown}" />
    <path d="M ${PX} ${GROUND - 4} L ${PX + PW} ${GROUND - 4}" stroke="${INK}" stroke-width="2" />
    <!-- Grandad Walter, facing in -->
${place(PEOPLE.walter, PX + 132, 1.32, { extra: stick })}
    <!-- Dad Henry, facing in -->
${place(PEOPLE.henry, PX + 340, 1.36, { flip: true })}
    <!-- Little Edwin, in front -->
${place(littleEdwin, PX + 238, 0.86)}
    <!-- Faded with age -->
    <rect x="${PX}" y="${PY}" width="${PW}" height="${PH}" fill="${CLOTH.mustard}" opacity="0.18" />
  </g>
  <rect x="${PX}" y="${PY}" width="${PW}" height="${PH}" fill="none" stroke="${INK}" stroke-width="2" />
  <text x="${W / 2}" y="${PY + PH + 40}" text-anchor="middle" font-family="Georgia, 'Times New Roman', serif" font-style="italic" font-size="20" fill="${INK}">Grandad Walter, Dad and me</text>
</svg>
`;
writeFileSync(OUT, svg);
console.log("wrote", OUT);
