// Generates the PLACEHOLDER Henry and Edwin sprites in public/assets/player-*.svg,
// until their Gemini versions in Walter's style replace them.
//
//   node docs/asset-sources/make-characters.mjs [who ...]
//
// One base body is shared by every character and frame, so the head, torso,
// hips and shoulders never move between poses. Only the limbs change.
// viewBox 0 0 96 160, facing right, soles on y = 152, feet centred near x = 48.
// Shoe soles sit exactly on y = 152; the ink outline adds 0.75 below it.

import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets");

// ── palette (ASSETS.md) plus the three character-only additions ───────────
const INK = "#291e1a";
const PAPER = "#d4d3d1";
const SKIN = "#e2b48c"; // added for people
const GREY_HAIR = "#8c8378"; // added for people
const C = {
  darkOlive: "#393e26", darkLeather: "#5a3428", tealSlate: "#496669", ochre: "#a6652b",
  periwinkle: "#7687ab", mustard: "#d9a443", vermilion: "#c95937", moss: "#748b2c", wine: "#893f43",
};

const darker = (hex, f = 0.78) =>
  "#" + [1, 3, 5].map((i) => Math.round(parseInt(hex.slice(i, i + 2), 16) * f).toString(16).padStart(2, "0")).join("");

// ── fixed skeleton ────────────────────────────────────────────────────────
const HIP = { x: 48, y: 90 };
const SHOULDER = { x: 48, y: 51 };
const THIGH = 30, SHIN = 28.5, UPPER = 20, FORE = 18;
const ANKLE_Y = 146, SOLE = 152;

const f = (n) => Math.round(n * 10) / 10;
const pt = (p) => `${f(p.x)} ${f(p.y)}`;

// Two-bone leg: knee bends forward (towards +x).
function knee(hip, ankle) {
  const dx = ankle.x - hip.x, dy = ankle.y - hip.y;
  const d = Math.hypot(dx, dy);
  if (d >= THIGH + SHIN) throw new Error("ankle out of reach");
  const base = Math.atan2(dy, dx);
  const off = Math.acos((THIGH * THIGH + d * d - SHIN * SHIN) / (2 * THIGH * d));
  const a = { x: hip.x + THIGH * Math.cos(base + off), y: hip.y + THIGH * Math.sin(base + off) };
  const b = { x: hip.x + THIGH * Math.cos(base - off), y: hip.y + THIGH * Math.sin(base - off) };
  return a.x > b.x ? a : b;
}

// Arm angles in degrees from straight down; positive swings forward.
function arm(upperDeg, foreDeg) {
  const dir = (deg) => ({ x: Math.sin((deg * Math.PI) / 180), y: Math.cos((deg * Math.PI) / 180) });
  const u = dir(upperDeg), l = dir(upperDeg + foreDeg);
  const elbow = { x: SHOULDER.x + UPPER * u.x, y: SHOULDER.y + UPPER * u.y };
  const hand = { x: elbow.x + FORE * l.x, y: elbow.y + FORE * l.y };
  return { elbow, hand };
}

// ── poses: only limbs differ ──────────────────────────────────────────────
// near = the side facing the viewer (drawn on top); far = behind, darker.
const POSES = {
  idle: { nearAnkle: 50, farAnkle: 45, nearArm: [3, 12], farArm: [-4, 10] },
  "walk-1": { nearAnkle: 61, farAnkle: 35, nearArm: [-24, 10], farArm: [26, 32] },
  "walk-2": { nearAnkle: 35, farAnkle: 61, nearArm: [26, 32], farArm: [-24, 10] },
};

// ── drawing helpers ───────────────────────────────────────────────────────
const stroke = (d, colour, w) =>
  `<path d="${d}" fill="none" stroke="${colour}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`;
const shape = (d, fill, extra = "") => `<path d="${d}" fill="${fill}" stroke="${INK}" stroke-width="1.5" stroke-linejoin="round"${extra}/>`;

function leg(ankleX, look, far) {
  const ankle = { x: ankleX, y: ANKLE_Y };
  const k = knee(HIP, ankle);
  const trousers = far ? darker(look.trousers) : look.trousers;
  const shoes = far ? darker(look.shoes) : look.shoes;
  const w = look.legWidth ?? 10;
  const d = `M${pt(HIP)} L${pt(k)} L${pt(ankle)}`;
  let out = stroke(d, INK, w + 3) + stroke(d, trousers, w);
  if (look.flare) {
    // Flared hem: a trapezoid along the lower shin.
    const sx = ankle.x - k.x, sy = ankle.y - k.y, len = Math.hypot(sx, sy);
    const ux = sx / len, uy = sy / len, px = -uy, py = ux;
    const top = { x: k.x + sx * 0.55, y: k.y + sy * 0.55 };
    const hw = w / 2, bw = w / 2 + 3.2;
    const P = [
      { x: top.x + px * hw, y: top.y + py * hw }, { x: ankle.x + px * bw + ux * 2, y: ankle.y + py * bw + uy * 2 },
      { x: ankle.x - px * bw + ux * 2, y: ankle.y - py * bw + uy * 2 }, { x: top.x - px * hw, y: top.y - py * hw },
    ];
    out += shape(`M${P.map(pt).join(" L")} Z`, trousers);
  }
  const a = ankle.x;
  out += shape(`M${f(a - 4.5)} ${SOLE} L${f(a - 4.5)} 146 Q${f(a - 4)} 143.5 ${f(a + 1)} 143.5 L${f(a + 4)} 143.5 Q${f(a + 12)} 145 ${f(a + 12)} 149.5 L${f(a + 12)} ${SOLE} Z`, shoes);
  if (look.shoeStripe) out += stroke(`M${f(a - 2)} 149 L${f(a + 9)} 149`, far ? darker(look.shoeStripe) : look.shoeStripe, 1.4);
  return out;
}

function armSvg([u, l], look, far) {
  const { elbow, hand } = arm(u, l);
  const sleeve = far ? darker(look.sleeve) : look.sleeve;
  const fore = far ? darker(look.forearm ?? look.sleeve) : look.forearm ?? look.sleeve;
  const skin = far ? darker(SKIN, 0.88) : SKIN;
  const w = 8;
  let out = stroke(`M${pt(SHOULDER)} L${pt(elbow)} L${pt(hand)}`, INK, w + 3);
  out += stroke(`M${pt(SHOULDER)} L${pt(elbow)}`, sleeve, w) + stroke(`M${pt(elbow)} L${pt(hand)}`, fore, w);
  if (look.rolledSleeve) out += `<circle cx="${f(elbow.x)}" cy="${f(elbow.y)}" r="4.6" fill="${sleeve}" stroke="${INK}" stroke-width="1.5"/>`;
  out += `<circle cx="${f(hand.x)}" cy="${f(hand.y)}" r="3.6" fill="${skin}" stroke="${INK}" stroke-width="1.5"/>`;
  return out;
}

// Base body outlines (shared). Front of the body is +x.
const TORSO = "M40 47 Q48 44 56 47 Q60 49 60 56 L59 78 Q58 89 56.5 94 L39.5 94 Q38 88 37.5 78 L37 56 Q37 49 40 47 Z";
const LONG_TORSO = (hem) => `M39.5 46.5 Q48 43.5 57 46.5 Q61 49 61 56 L60.5 80 Q60.5 92 60 ${hem} L38 ${hem} Q37 92 37 80 L36.5 56 Q36.5 49 39.5 46.5 Z`;
const HEAD =
  `<ellipse cx="49" cy="27" rx="10.5" ry="11.5" fill="${SKIN}" stroke="${INK}" stroke-width="1.5"/>` +
  shape("M59.2 23.8 Q63.6 28.4 59.6 31.2", SKIN) +
  `<ellipse cx="45.5" cy="28" rx="2.2" ry="3" fill="${SKIN}" stroke="${INK}" stroke-width="1.2"/>` +
  `<circle cx="55.6" cy="25.6" r="1.1" fill="${INK}"/>` +
  stroke("M55.8 33.6 L58.4 33.3", INK, 1);
const NECK = `<rect x="44.5" y="38" width="8" height="9" rx="1.5" fill="${SKIN}" stroke="${INK}" stroke-width="1.5"/>`;

// ── the four people ───────────────────────────────────────────────────────
const LOOKS = {
  walter: {
    // 1950 shopkeeper in his working week: flat cap, waistcoat, rolled sleeves.
    trousers: C.tealSlate, shoes: INK, sleeve: PAPER, forearm: SKIN, rolledSleeve: true,
    body: () =>
      shape(TORSO, C.darkLeather) +
      shape("M50.5 44.6 L57 46.6 L53.4 51.5 Z", PAPER) +
      [58, 66, 74, 82].map((y) => `<circle cx="58" cy="${y}" r="1" fill="${C.mustard}"/>`).join(""),
    head: () =>
      shape("M39 21 Q37.6 30 41.4 35.5 L44.4 34.6 Q42.6 28 43.4 22 Z", GREY_HAIR) +
      shape("M56.4 31.4 Q59.4 30.4 60.6 32.4 Q58.6 33.4 56.4 32.8 Z", GREY_HAIR) +
      stroke("M53.2 22.9 L57.4 22.4", INK, 1.2) +
      shape("M38.4 23.2 Q39.4 13.4 49.6 13.2 Q57.6 13.2 60 18.6 L66.2 20.8 Q64.6 23.6 59.4 22.8 L38.8 24.6 Z", C.darkOlive),
  },
  henry: {
    // 1973: corduroy jacket, turtleneck, flares, long hair and sideburns.
    trousers: C.darkOlive, shoes: C.darkLeather, sleeve: C.ochre, flare: true,
    body: () =>
      shape(LONG_TORSO(101), C.ochre) +
      stroke("M55.6 47.4 L59.2 64", darker(C.ochre, 0.7), 1.2) +
      [56, 64, 72, 80, 88, 96].map((y) => stroke(`M41 ${y} L54 ${y}`, darker(C.ochre, 0.88), 0.8)).join("") +
      `<rect x="43.6" y="39.6" width="9.6" height="8.4" rx="2.4" fill="${C.mustard}" stroke="${INK}" stroke-width="1.5"/>`,
    head: () =>
      shape("M38.4 25 Q37 14 47 14.4 Q56.4 14 59.6 21 Q53 18.6 47.6 19.6 L47.6 33.4 Q46.4 38 41.6 38.6 Q38 37.6 38.4 25 Z", C.darkLeather) +
      shape("M47.4 25 L49.6 25.4 L49 32.4 L47.2 32.6 Z", C.darkLeather) +
      `<rect x="52.6" y="23" width="6.4" height="5.4" rx="1.6" fill="none" stroke="${INK}" stroke-width="1.3"/>` +
      stroke("M52.6 25.2 L47.8 25.2", INK, 1.1),
  },
  "edwin-young": {
    // 1998, early twenties: hoodie, jeans, trainers, messy fringe.
    trousers: C.periwinkle, shoes: PAPER, shoeStripe: C.vermilion, sleeve: C.wine,
    body: () =>
      shape(LONG_TORSO(96), C.wine) +
      shape("M38.8 48 Q34 42.6 38.6 38.6 Q43.4 36.4 45.4 41.4 L45.4 47 Z", darker(C.wine, 0.85)) +
      stroke("M56.4 49 L57 59", PAPER, 1) + stroke("M54.6 49.4 L55 58", PAPER, 1) +
      stroke("M40 88 L59.6 88", darker(C.wine, 0.8), 1),
    head: () =>
      shape("M38.6 26.4 Q36.6 14.4 47.6 14 Q57 13.4 60.4 20.2 L57.2 19.2 L58.6 22.6 L54.4 20.4 L54.6 23.4 L50.4 20.8 Q46.6 21.6 46 25.6 L44.4 31.8 Q40 33 38.6 26.4 Z", C.darkLeather),
  },
  "edwin-present": {
    // Present day, about fifty: cardigan, scarf, glasses, greying hair and beard.
    trousers: C.darkOlive, shoes: C.darkLeather, sleeve: C.moss,
    body: () =>
      shape(LONG_TORSO(99), C.moss) +
      shape("M50.6 44.6 L56.8 46.6 L53.6 51 Z", PAPER) +
      [60, 69, 78, 87].map((y) => `<circle cx="58.6" cy="${y}" r="1" fill="${C.darkLeather}"/>`).join("") +
      shape("M42.6 40.6 Q49 44.4 55.4 40.8 L56.2 46 Q49 49.6 41.8 46 Z", C.vermilion) +
      shape("M52.4 45.6 L56.6 45.6 L57.8 64 L53.4 64.4 Z", C.vermilion) +
      stroke("M54 64.6 L54 66.4 M55.8 64.4 L55.8 66.2 M57.4 64.2 L57.4 66", C.vermilion, 1),
    head: () =>
      shape("M38.6 25.6 Q37 14.6 47.8 14 Q57 13.6 60 20 Q53.4 18.4 47.8 19.4 Q45.4 23 45.6 26.6 L44.2 33 Q40 33.4 38.6 25.6 Z", GREY_HAIR) +
      shape("M47.4 32 Q50 38.4 55.4 37.6 Q59.4 36.6 60.4 32.6 L56.6 33.8 Q53 32.4 49.4 33.2 Z", GREY_HAIR) +
      `<circle cx="55.8" cy="25.6" r="3" fill="none" stroke="${INK}" stroke-width="1"/>` +
      stroke("M52.8 25.2 L47.8 24.8", INK, 0.9) +
      stroke("M53.4 22.6 L57.4 22.2", INK, 1),
  },
};

function sprite(who, poseName) {
  const look = LOOKS[who];
  const pose = POSES[poseName];
  const parts = [
    `<ellipse cx="48" cy="152" rx="20" ry="2.6" fill="${INK}" opacity="0.18"/>`,
    armSvg(pose.farArm, look, true),
    leg(pose.farAnkle, look, true),
    leg(pose.nearAnkle, look, false),
    `<ellipse cx="48" cy="91" rx="10.5" ry="6.5" fill="${look.trousers}" stroke="${INK}" stroke-width="1.5"/>`,
    NECK,
    look.body(),
    `<g transform="translate(0 3)">${HEAD}${look.head()}</g>`,
    armSvg(pose.nearArm, look, false),
  ];
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 160" width="96" height="160">\n  <!-- player-${who}-${poseName}: facing right, soles on y=152, feet centred near x=48. Generated by docs/asset-sources/make-characters.mjs -->\n  ${parts.join("\n  ")}\n</svg>\n`;
}

// Walter is now drawn by Gemini (see walter-from-gemini.mjs), so this script never writes him.
const who = process.argv.slice(2).filter((n) => n !== "walter");
for (const name of who.length ? who : Object.keys(LOOKS).filter((n) => n !== "walter")) {
  for (const pose of Object.keys(POSES)) {
    const file = join(OUT, `player-${name}-${pose}.svg`);
    writeFileSync(file, sprite(name, pose));
    console.log("wrote", file);
  }
}
