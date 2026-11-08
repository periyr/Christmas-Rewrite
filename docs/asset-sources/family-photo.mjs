// Builds the family photographs in public/assets:
//
//   clue-family-photographs.svg        the photograph in the shop (Content.Clues FamilyPhotograph)
//   clue-family-photographs-taped.svg  the same after 1973, its broken glass held with tape
//   frame-photo-1973.svg               the same photo without frame or caption, under the
//                                      broken glass of the 1973 puzzle (Views.Frame)
//
//   node docs/asset-sources/family-photo.mjs
//
// A photo outside the shop, with the same bodies as the player sprites
// (chibi-family.mjs): grandad Walter with his walking stick, dad Henry, and
// little Edwin in front, squinting into the sun. The cracks follow the nine
// glass pieces of the 1973 puzzle (Views.Frame.pieces, same numbers), and every
// crack has a strip of tape.

import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { MIRROR, PEOPLE, CREAM, INK, SKIN, CHEEK, HAIR, CLOTH, p, c, el, figure } from "./chibi-family.mjs";

const ASSETS = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets");

const TORSO = "M 32,74 C 48,82 64,74 66,114 C 48,122 30,114 32,74 Z";
const squint = [
  c(41, 57, 3.6, CHEEK, { stroke: "none" }),
  c(71, 57, 3.6, CHEEK, { stroke: "none" }),
  p("M 40.6,44.4 L 47,47 L 41,50", "none", { "stroke-width": 2.6 }),
  p("M 70.4,44.4 L 64,47 L 70,50", "none", { "stroke-width": 2.6 }),
  c(57, 53.4, 1.5, INK, { stroke: "none" }),
  p("M 52.6,60 Q 57.6,65.4 62.6,60", "none", { "stroke-width": 2 }),
];

// Little Edwin, about five: bowl haircut, a mustard jumper with a red stripe,
// blue trousers, red shoes, eyes screwed up against the sun.
const littleEdwin = {
  sleeve: CLOTH.mustard, forearm: CLOTH.mustard, trousers: CLOTH.periwinkle, shoes: CLOTH.vermilion,
  torso: [
    p(TORSO, CLOTH.mustard),
    p("M 32.5,93 C 44,97 56,97 65,93 L 65.6,101 C 56,105 44,105 32.4,101 Z", CLOTH.vermilion, { "stroke-width": 2 }),
  ],
  torsoLabel: "Torso (striped jumper)",
  behindHead: [],
  face: squint,
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

// ── the photo itself: 480 x 330, origin top left ─────────────────────────
const PW = 480, PH = 330, GROUND = PH - 26;

// A figure standing with its soles on the pavement, centred on x.
const place = (person, x, scale, { flip = false, extra = "" } = {}) => {
  const tx = flip ? x + 48 * scale : x - 48 * scale;
  const ty = GROUND - 152 * scale;
  return `      <g transform="translate(${tx} ${ty}) scale(${flip ? -scale : scale} ${scale})">
${figure(person, "idle")}
${extra}
      </g>`;
};

function shopPhoto(people, { wall, fade }) {
  return `    <!-- Sky and sun -->
    <rect x="0" y="0" width="${PW}" height="${PH}" fill="${CLOTH.periwinkle}" />
    <circle cx="${PW - 30}" cy="26" r="22" fill="${CLOTH.mustard}" stroke="${INK}" stroke-width="2" />
    <!-- Shop front: wall, sign, two windows and the door -->
    <rect x="0" y="46" width="${PW - 70}" height="${PH - 46}" fill="${wall}" stroke="${INK}" stroke-width="2" />
    <rect x="30" y="58" width="${PW - 130}" height="34" fill="${CREAM}" stroke="${INK}" stroke-width="2.5" />
    <text x="${30 + (PW - 130) / 2}" y="84" text-anchor="middle" font-family="Georgia, 'Times New Roman', serif" font-size="24" font-weight="bold" fill="${INK}" letter-spacing="3">HALE’S BOOKSHOP</text>
    <g stroke="${CREAM}" stroke-width="5">
      <rect x="22" y="108" width="120" height="150" fill="${HAIR.grey}" />
      <rect x="268" y="108" width="120" height="150" fill="${HAIR.grey}" />
      <path d="M 82 108 L 82 258 M 22 183 L 142 183 M 328 108 L 328 258 M 268 183 L 388 183" />
    </g>
    <rect x="168" y="112" width="74" height="192" fill="${CLOTH.wine}" stroke="${INK}" stroke-width="2.5" />
    <rect x="180" y="126" width="50" height="60" fill="${HAIR.grey}" stroke="${INK}" stroke-width="2" />
    <circle cx="230" cy="222" r="3.5" fill="${CLOTH.mustard}" stroke="${INK}" stroke-width="1.5" />
    <!-- Pavement -->
    <rect x="0" y="${GROUND - 4}" width="${PW}" height="${PH}" fill="${HAIR.brown}" />
    <path d="M 0 ${GROUND - 4} L ${PW} ${GROUND - 4}" stroke="${INK}" stroke-width="2" />
${people}
    <!-- Faded with age -->
    <rect x="0" y="0" width="${PW}" height="${PH}" fill="${CLOTH.mustard}" opacity="${fade}" />`;
}

const family = shopPhoto(
  `    <!-- Grandad Walter, facing in -->
${place(PEOPLE.walter, 132, 1.32, { extra: stick })}
    <!-- Dad Henry, facing in -->
${place(PEOPLE.henry, 340, 1.36, { flip: true })}
    <!-- Little Edwin, in front -->
${place(littleEdwin, 238, 0.86)}`,
  { wall: CLOTH.green, fade: 0.18 },
);

// ── the broken glass: the nine pieces of the 1973 puzzle ──────────────────
// Same numbers as Views.Frame.pieces (photo units, 480 x 330).
const PIECES = [
  [[237, 105], [90, 0], [260, 0], [291, 117]],
  [[291, 117], [260, 0], [480, 0], [480, 90], [350, 133]],
  [[350, 133], [480, 90], [480, 280], [336, 176]],
  [[336, 176], [480, 280], [480, 330], [330, 330], [309, 204]],
  [[309, 204], [330, 330], [120, 330], [255, 195]],
  [[255, 195], [120, 330], [0, 330], [0, 250], [246, 168]],
  [[246, 168], [0, 250], [0, 60], [219, 126]],
  [[219, 126], [0, 60], [0, 0], [90, 0], [237, 105]],
  [[237, 105], [291, 117], [350, 133], [336, 176], [309, 204], [255, 195], [246, 168], [219, 126]],
];
// Every crack: each edge between two pieces, once. Edges along the photo's
// border are the frame, not cracks.
const onBorder = ([x, y]) => x === 0 || x === PW || y === 0 || y === PH;
const sameSide = ([ax, ay], [bx, by]) => (ax === bx && (ax === 0 || ax === PW)) || (ay === by && (ay === 0 || ay === PH));
const CRACKS = [];
for (const piece of PIECES) {
  piece.forEach((a, i) => {
    const b = piece[(i + 1) % piece.length];
    const along = onBorder(a) && onBorder(b) && sameSide(a, b);
    const seen = CRACKS.some(([c1, c2]) => (c1 === a && c2 === b) || (c1.join() === b.join() && c2.join() === a.join()));
    if (!along && !seen) CRACKS.push([a, b]);
  });
}
// A strip of tape along a whole crack, a little past each end.
function tapeStrip([[xa, ya], [xb, yb]]) {
  const full = Math.hypot(xb - xa, yb - ya), ux = (xb - xa) / full, uy = (yb - ya) / full;
  const x1 = xa - ux * 3, y1 = ya - uy * 3, x2 = xb + ux * 3, y2 = yb + uy * 3;
  const len = Math.hypot(x2 - x1, y2 - y1), w = 4.5;
  const nx = (-(y2 - y1) / len) * w, ny = ((x2 - x1) / len) * w;
  const f = (n) => Math.round(n * 10) / 10;
  return `<path d="M ${f(x1 + nx)},${f(y1 + ny)} L ${f(x2 + nx)},${f(y2 + ny)} L ${f(x2 - nx)},${f(y2 - ny)} L ${f(x1 - nx)},${f(y1 - ny)} Z" />`;
}
const taped = `    <!-- Cracks in the mended glass -->
    <g fill="none" stroke="${INK}" stroke-width="1.6" stroke-linejoin="round" opacity="0.75">
${PIECES.map((piece) => `      <path d="M ${piece.map((q) => q.join(",")).join(" L ")} Z" />`).join("\n")}
    </g>
    <!-- A strip of tape along every crack -->
    <g fill="${CREAM}" fill-opacity="0.7" stroke="${INK}" stroke-width="1" stroke-linejoin="round">
${CRACKS.map((t) => "      " + tapeStrip(t)).join("\n")}
    </g>`;

// ── the files ──────────────────────────────────────────────────────────────
const W = 600, H = 470, PX = 60, PY = 56;
const framed = (photo, extra, note) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- ${note}, built by docs/asset-sources/family-photo.mjs from the player sprites -->
  <!-- Wooden frame and cream mat -->
  <rect x="2" y="2" width="${W - 4}" height="${H - 4}" rx="8" fill="${HAIR.brown}" stroke="${INK}" stroke-width="3" />
  <rect x="22" y="22" width="${W - 44}" height="${H - 44}" rx="2" fill="${CREAM}" stroke="${INK}" stroke-width="2" />
  <clipPath id="photo"><rect x="0" y="0" width="${PW}" height="${PH}" /></clipPath>
  <g transform="translate(${PX} ${PY})">
    <g clip-path="url(#photo)">
${photo}
${extra}
    </g>
    <rect x="0" y="0" width="${PW}" height="${PH}" fill="none" stroke="${INK}" stroke-width="2" />
  </g>
  <text x="${W / 2}" y="${PY + PH + 40}" text-anchor="middle" font-family="Georgia, 'Times New Roman', serif" font-style="italic" font-size="20" fill="${INK}">Grandad Walter, Dad and me</text>
</svg>
`;

const files = {
  "clue-family-photographs.svg": framed(family, "", "clue-family-photographs: Walter, Henry and little Edwin outside the shop"),
  "clue-family-photographs-taped.svg": framed(family, taped, "clue-family-photographs-taped: the same photograph, its glass mended with tape in 1973"),
  "frame-photo-1973.svg": `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${PW} ${PH}" width="${PW}" height="${PH}">
  <!-- frame-photo-1973: the family photograph without frame or caption, under the 1973 glass puzzle. Built by docs/asset-sources/family-photo.mjs -->
  <clipPath id="photo"><rect x="0" y="0" width="${PW}" height="${PH}" /></clipPath>
  <g clip-path="url(#photo)">
${family}
  </g>
</svg>
`,
};
for (const [name, svg] of Object.entries(files)) {
  writeFileSync(join(ASSETS, name), svg);
  console.log("wrote", join(ASSETS, name));
}
