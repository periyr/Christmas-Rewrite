// Builds the cute paper-theatre player sprites in public/assets/player-<who>-<frame>.svg.
//
//   node docs/asset-sources/chibi-family.mjs            (everyone)
//   node docs/asset-sources/chibi-family.mjs henry      (one person)
//
// Everyone shares Walter's body, drawn with Google Gemini and adjusted here:
// the same head, torso, arms, legs, eyes and anchor (soles on y = 152, feet
// centred near x = 48). People differ only in colours, hair, headwear, face
// details and clothing details, so all four match and frames never jump.
//
// Fixes to Gemini's Walter: bigger outline-free irises, features shifted right,
// moustache reshaped so it can't read as lips, both blushes visible, a wide
// arm swing in walk-1, a non-crossing narrow stride in walk-2, and a gap
// between the idle shoes. Every shoe has its rounded toe at the front (right),
// so nobody seems to walk backwards. Henry's look (long hair, round glasses, turtleneck,
// corduroy, flares) follows Gemini's Henry design, redrawn on Walter's body.
//
// Every outer shape is drawn twice: in cream (stroke 7) as the cut-out border,
// then with its fill and the ink outline (stroke 3).

import { writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets");

// The agreed character palette. Nothing else may appear.
const CREAM = "#f2e4c9", INK = "#291e1a", SKIN = "#e8b98f", CHEEK = "#d9806a";
const HAIR = { grey: "#d4d3d1", brown: "#5a3428" };
const CLOTH = { olive: "#393e26", vermilion: "#c95937", mustard: "#d9a443", teal: "#496669", periwinkle: "#7687ab", wine: "#893f43", green: "#31542f" };

const p = (d, fill, extra = {}) => ({ tag: "path", d, fill, ...extra });
const c = (cx, cy, r, fill, extra = {}) => ({ tag: "circle", cx, cy, r, fill, ...extra });
const rect = (x, y, w, h, rx, fill) => ({ tag: "rect", x, y, width: w, height: h, rx, fill });

// ── shared body: limbs (shapes only; colours come from the person) ───────
const ARMS = {
  idleFar: ["M 40,76 C 34,86 32,96 24,94 C 28,84 36,74 40,76 Z", "M 32,96 C 30,106 28,112 22,110 C 24,100 24,94 32,96 Z", [25, 111]],
  idleNear: ["M 54,76 C 64,84 62,98 52,96 C 50,86 46,78 54,76 Z", "M 62,98 C 60,110 56,116 48,114 C 50,104 52,96 62,98 Z", [52, 115]],
  wideFar: ["M 40,76 C 30,82 24,94 18,90 C 28,80 36,74 40,76 Z", "M 24,94 C 18,104 14,110 8,106 C 14,98 18,90 24,94 Z", [11, 108]],
  wideNear: ["M 54,76 C 66,82 74,92 66,98 C 58,88 46,78 54,76 Z", "M 74,92 C 82,102 86,108 78,112 C 72,102 66,98 74,92 Z", [82, 110]],
  closeFar: ["M 40,76 C 34,82 32,90 32,97 C 35,99 38,99 40,97 C 40,90 42,82 44,78 Z", "M 32,97 C 32,103 33,108 35,111 C 37,112 40,111 41,109 C 40,104 40,100 40,97 Z", [37, 112]],
  closeNear: ["M 52,77 C 58,74 64,80 67,96 C 64,99 61,99 59,97 C 58,88 55,82 52,77 Z", "M 59,97 C 62,96 65,96 67,97 C 67,103 66,108 64,111 C 62,112 60,111 59,109 C 59,104 59,100 59,97 Z", [62, 112]],
};
// Legs: [trouser quad (top-left, bottom-left, bottom-right, top-right), shoe]
const LEGS = {
  idleFar: [[[38, 115], [34, 142], [44, 142], [48, 115]], "M 34,142 L 44,142 C 47,142 48,146 48,152 L 33,152 C 33,146 33,142 34,142 Z"],
  idleNear: [[[48, 115], [50, 144], [62, 144], [60, 115]], "M 50,144 L 62,144 C 65,144 66,147 66,152 L 50,152 Z"],
  wideFar: [[[38, 115], [26, 142], [36, 144], [48, 115]], "M 26,142 L 36,144 C 40,144.5 42,148 42,152 L 25,152 C 25,146 25,143 26,142 Z"],
  wideNear: [[[48, 115], [60, 142], [72, 142], [60, 115]], "M 60,142 L 72,142 C 76,142 79,146 79,152 L 59,152 C 59,146 59,142 60,142 Z"],
  narrowFar: [[[38, 115], [34, 142], [44, 143], [48, 115]], "M 34,142 L 44,143 C 47.5,143.5 49,147 49,152 L 33,152 C 33,146 33,143 34,142 Z"],
  narrowNear: [[[48, 115], [54, 143], [64, 142], [60, 115]], "M 54,143 L 64,142 C 69,142 72,146 72,152 L 53,152 Z"],
};
const FRAMES = {
  idle: { arms: ["idleFar", "idleNear"], legs: ["idleFar", "idleNear"] },
  "walk-1": { arms: ["wideFar", "wideNear"], legs: ["wideFar", "wideNear"] },
  "walk-2": { arms: ["closeFar", "closeNear"], legs: ["narrowFar", "narrowNear"] },
};

const TORSO_PATH = "M 32,74 C 48,82 64,74 66,114 C 48,122 30,114 32,74 Z";
const HEAD_PATH = "M 48,18 C 66,18 78,30 78,46 C 78,64 66,76 48,76 C 30,76 18,64 18,46 C 18,30 30,18 48,18 Z";

const eyes = (iris) => [
  { tag: "circle", cx: 41, cy: 57, r: 3.6, fill: CHEEK, stroke: "none" },
  { tag: "circle", cx: 71, cy: 57, r: 3.6, fill: CHEEK, stroke: "none" },
  { tag: "ellipse", cx: 46, cy: 46, rx: 5.6, ry: 7.2, fill: CREAM, "stroke-width": 2.4 },
  { tag: "ellipse", cx: 47.4, cy: 46.6, rx: 4, ry: 5.4, fill: iris, stroke: "none" },
  { tag: "ellipse", cx: 65, cy: 46, rx: 5.6, ry: 7.2, fill: CREAM, "stroke-width": 2.4 },
  { tag: "ellipse", cx: 66.4, cy: 46.6, rx: 4, ry: 5.4, fill: iris, stroke: "none" },
  { tag: "circle", cx: 57, cy: 53.4, r: 1.5, fill: INK, stroke: "none" },
];

// Widen the bottom of a trouser leg into a flare.
function flare([tl, bl, br, tr], fill) {
  const at = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];
  const l = at(tl, bl, 0.62), r = at(tr, br, 0.62);
  const f = (q) => `${Math.round(q[0] * 10) / 10},${Math.round(q[1] * 10) / 10}`;
  return p(`M ${f(l)} L ${f([bl[0] - 3, bl[1] + 1])} L ${f([br[0] + 3, br[1] + 1])} L ${f(r)} Z`, fill);
}

// A turned-up cuff at the bottom of a jeans leg, slightly wider than the leg.
function jeanCuff([tl, bl, br, tr], fill) {
  const at = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];
  const l = at(tl, bl, 0.84), r = at(tr, br, 0.84);
  const f = (q) => `${Math.round(q[0] * 10) / 10},${Math.round(q[1] * 10) / 10}`;
  return p(`M ${f([l[0] - 1.2, l[1]])} L ${f([bl[0] - 1.2, bl[1]])} L ${f([br[0] + 1.2, br[1]])} L ${f([r[0] + 1.2, r[1]])} Z`, fill);
}

// ── the people ─────────────────────────────────────────────────────────────
const PEOPLE = {
  walter: {
    sleeve: CLOTH.mustard, forearm: SKIN, trousers: CLOTH.teal, shoes: INK,
    torso: [p(TORSO_PATH, CLOTH.wine), p("M 40,76 L 56,76 L 48,94 Z", CLOTH.mustard), c(48, 100, 2, CLOTH.mustard), c(48, 106, 2, CLOTH.mustard), c(48, 112, 2, CLOTH.mustard)],
    torsoLabel: "Torso (waistcoat and shirt)",
    behindHead: [p("M 16,30 C 12,40 16,54 26,56 L 30,46 Z", HAIR.grey), rect(28, 44, 6, 12, 3, HAIR.grey)],
    face: [
      ...eyes(CLOTH.teal),
      // Bushy moustache: one smooth arc on top (no dip, so it can't read as lips), drooping ends.
      { tag: "path", d: "M 48.6,61 C 49.4,54.2 65.8,54.2 66.6,61 C 64.6,59.6 62.2,59.2 60.2,60.2 C 59,59 56.2,59 55,60.2 C 53,59.2 50.6,59.6 48.6,61 Z", fill: HAIR.grey, "stroke-width": 2 },
    ],
    topLabel: "Flat cap",
    top: [p("M 12,32 C 12,12 80,12 84,32 C 86,34 86,38 76,40 C 60,42 40,42 12,32 Z", CLOTH.olive), p("M 68,36 C 80,36 88,40 88,42 C 80,44 72,42 68,38 Z", CLOTH.olive)],
  },
  henry: {
    sleeve: CLOTH.vermilion, forearm: CLOTH.vermilion, trousers: CLOTH.olive, shoes: HAIR.brown, flares: true,
    torso: [
      p(TORSO_PATH, CLOTH.vermilion),
      // Corduroy wales, kept inside the jacket.
      ...[39, 45, 51, 57].map((x) => p(`M ${x},86 L ${x},${x < 50 ? 112 : 110}`, "none", { stroke: CLOTH.wine, "stroke-width": 2 })),
      // Turtleneck collar.
      p("M 37,73 C 44,78 52,78 59,73 L 59,81 C 52,86 44,86 37,81 Z", CLOTH.mustard),
    ],
    torsoLabel: "Torso (corduroy jacket and turtleneck)",
    // Collar-length hair at the back of the head only (left), so the face side stays open.
    behindHead: [p("M 40,15 C 26,17 14,30 14,48 C 13,62 15,72 23,75 C 27,76 31,74 32,70 L 36,40 Z", HAIR.brown)],
    face: [
      ...eyes(HAIR.brown),
      // Round glasses: two rims, a bridge and an arm back towards the ear.
      c(46, 46, 8.4, "none", { "stroke-width": 2 }),
      c(65, 46, 8.4, "none", { "stroke-width": 2 }),
      p("M 54.4,45 L 56.6,45", "none", { "stroke-width": 2 }),
      p("M 37.6,45 L 26,43", "none", { "stroke-width": 2 }),
      // Small smile.
      p("M 54.6,60.4 Q 57.6,63.4 60.6,60.4", "none", { "stroke-width": 2 }),
    ],
    topLabel: "Fringe and sideburn",
    top: [
      // Side-parted, swept to the right; the forehead shows below it.
      p("M 18,44 C 16,22 30,13 48,13 C 66,13 80,22 79,33 C 71,27 59,25 49,27 C 40,29 32,34 28,40 C 24,43 21,44 18,44 Z", HAIR.brown),
      p("M 18,40 L 27,38 L 28,60 L 21,62 Z", HAIR.brown),
    ],
  },
};

// Young Edwin, 1998: late-90s look from Gemini's design (curtains haircut, open
// plaid flannel over a plain T-shirt, rolled sleeves, baggy jeans, work boots),
// redrawn on the shared body.
PEOPLE["edwin-young"] = {
  sleeve: CLOTH.green, forearm: SKIN, rolledCuff: CLOTH.green,
  trousers: CLOTH.periwinkle, jeanCuffs: true, shoes: INK, soleStripe: CLOTH.mustard,
  torso: [
    p(TORSO_PATH, CLOTH.green),
    // Flannel checks on the two open shirt fronts, kept inside the shirt.
    ...["M 37,84 L 37,112", "M 34.5,93 L 42,93", "M 34.5,104 L 42,104", "M 59.5,84 L 59.5,108", "M 55,93 L 62,93", "M 55,104 L 62.5,104"].map((d) =>
      p(d, "none", { stroke: CLOTH.wine, "stroke-width": 1.6 }),
    ),
    // Plain T-shirt showing between the open fronts.
    p("M 42,77 C 46,79 50,79 54,77 L 55,115 C 51,116.5 46,116.5 42,115 Z", CLOTH.mustard),
  ],
  torsoLabel: "Torso (open flannel shirt over a T-shirt)",
  behindHead: [],
  face: [
    ...eyes(CLOTH.green),
    // Small unsure mouth.
    p("M 55,61 Q 56.6,60 58.2,61 Q 59.8,62 61.4,61", "none", { "stroke-width": 2 }),
  ],
  topLabel: "Curtains haircut (middle parting)",
  top: [
    p("M 17,52 C 13,26 30,12 50,12 C 71,12 83,25 81,46 L 80,58 C 79,61 75.5,61 74.5,58 C 74,46 68,35 55,29 C 47,34 38,40 33,48 L 31,62 C 27,65 21,64 19,60 Z", HAIR.brown),
  ],
};

// Present-day Edwin, Christmas Eve, about 40: cosy look from Gemini's design
// (wine Christmas jumper with a Fair Isle band and ribbed hem, green scarf with
// mustard stripes, dark jeans, Chelsea boots), short brown hair, clean-shaven,
// thin round glasses, redrawn on the shared body.
const star = (x, y) => p(`M ${x},${y - 2.6} L ${x},${y + 2.6} M ${x - 2.6},${y} L ${x + 2.6},${y} M ${x - 1.7},${y - 1.7} L ${x + 1.7},${y + 1.7} M ${x - 1.7},${y + 1.7} L ${x + 1.7},${y - 1.7}`, "none", { stroke: CREAM, "stroke-width": 1.1 });
PEOPLE["edwin-present"] = {
  sleeve: CLOTH.wine, forearm: CLOTH.wine,
  trousers: CLOTH.teal, shoes: HAIR.brown,
  torso: [
    p(TORSO_PATH, CLOTH.wine),
    // Fair Isle band: two cream lines with little stars and mustard dots between.
    p("M 34.5,87.5 L 61.5,87.5", "none", { stroke: CREAM, "stroke-width": 1.4 }),
    p("M 34.5,98.5 L 62,98.5", "none", { stroke: CREAM, "stroke-width": 1.4 }),
    star(38, 93), star(46.5, 93),
    c(42.2, 93, 1.1, CLOTH.mustard, { stroke: "none" }), c(50.6, 93, 1.1, CLOTH.mustard, { stroke: "none" }), c(61, 93, 1.1, CLOTH.mustard, { stroke: "none" }),
    // Ribbed hem.
    ...[36, 40, 44, 48, 52, 56, 60].map((x) => p(`M ${x},108 L ${x},${x > 57 ? 111.4 : 112}`, "none", { "stroke-width": 1.3 })),
    // Scarf: wrapped round the neck, one end hanging down the front with stripes and a fringe.
    p("M 52,78 L 59.5,78 L 60.5,104 L 52.5,104 Z", CLOTH.green),
    p("M 53,86 L 59.6,86 M 53.2,93 L 59.9,93", "none", { stroke: CLOTH.mustard, "stroke-width": 1.8 }),
    p("M 54,105.5 L 54,108.6 M 56.5,105.5 L 56.5,108.6 M 59,105.5 L 59,108.6", "none", { stroke: CLOTH.green, "stroke-width": 1.6 }),
    p("M 35,73 C 43,79.5 54,79.5 62,72 L 62.5,79.5 C 54,86.5 43,86.5 34.5,80.5 Z", CLOTH.green),
  ],
  torsoLabel: "Torso (Christmas jumper and scarf)",
  behindHead: [],
  face: [
    ...eyes(CLOTH.green),
    // Warm smile.
    p("M 54.4,60.6 Q 57.6,63.6 60.8,60.6", "none", { "stroke-width": 2 }),
    // Thin round glasses.
    c(46, 46, 8.2, "none", { "stroke-width": 1.5 }),
    c(65, 46, 8.2, "none", { "stroke-width": 1.5 }),
    p("M 54.2,45 L 56.8,45", "none", { "stroke-width": 1.5 }),
    p("M 37.8,45 L 27,43", "none", { "stroke-width": 1.5 }),
  ],
  topLabel: "Short brown hair",
  top: [p("M 18,40 C 16,22 30,13 48,13 C 66,13 80,22 79,36 C 76,33 73,31.5 69,31.5 L 71,27 L 64,29.5 L 63.5,25 L 57,28.5 C 46,27.5 36,30.5 30,37.5 C 26,41.5 22,42 18,40 Z", HAIR.brown)],
};

// ── rendering ──────────────────────────────────────────────────────────────
const attrs = (o, overrides = {}) =>
  Object.entries({ ...o, ...overrides })
    .filter(([k, v]) => k !== "tag" && v !== undefined)
    .map(([k, v]) => `${k}="${v}"`)
    .join(" ");
const el = (o, overrides) => `<${o.tag} ${attrs(o, overrides)} />`;
const solid = (s) => s.fill !== "none"; // only filled shapes get a cut-out border

// The figure's two groups (cut-out border, then the drawing), in the sprite's
// own 96 x 160 units. Also used by family-photo.mjs.
export function figure(person, name) {
  const { arms, legs } = FRAMES[name];
  const arm = (key) => {
    const [upper, lower, [hx, hy]] = ARMS[key];
    // A rolled sleeve: a cuff where the forearm starts.
    const [ex, ey] = lower.match(/M ([\d.]+),([\d.]+)/).slice(1).map(Number);
    const cuff = person.rolledCuff ? [{ tag: "ellipse", cx: ex + 1, cy: ey + 1, rx: 5, ry: 3.6, fill: person.rolledCuff }] : [];
    return [p(upper, person.sleeve), p(lower, person.forearm), ...cuff, c(hx, hy, 4, SKIN)];
  };
  const leg = (key) => {
    const [quad, shoe] = LEGS[key];
    const trouser = p(`M ${quad.map((q) => q.join(",")).join(" L ")} Z`, person.trousers);
    const extra = person.flares ? [flare(quad, person.trousers)] : person.jeanCuffs ? [jeanCuff(quad, person.trousers)] : [];
    // A contrasting sole line across the boot, inside its outline.
    const soleXs = [...shoe.matchAll(/([\d.]+),152/g)].map((m) => Number(m[1]));
    const sole = person.soleStripe
      ? [p(`M ${Math.min(...soleXs) + 2},149.4 L ${Math.max(...soleXs) - 2},149.4`, "none", { stroke: person.soleStripe, "stroke-width": 2 })]
      : [];
    return [trouser, ...extra, p(shoe, person.shoes), ...sole];
  };
  const layers = [
    ["Far arm", arm(arms[0])],
    ["Far leg", leg(legs[0])],
    ["Near leg", leg(legs[1])],
    [person.torsoLabel, person.torso],
    ["Near arm", arm(arms[1])],
    ["Hair and head", [...person.behindHead, p(HEAD_PATH, SKIN)]],
  ];
  const border = [...layers.flatMap(([, s]) => s), ...person.top]
    .filter(solid)
    .map((s) => "    " + el(s, { fill: CREAM, stroke: undefined, "stroke-width": undefined }))
    .join("\n");
  const body = layers.map(([label, s]) => `    <!-- ${label} -->\n` + s.map((x) => "    " + el(x)).join("\n")).join("\n");
  return `  <!-- Cut-out border: every outer shape again in cream, 2 units wider than the outline -->
  <g fill="${CREAM}" stroke="${CREAM}" stroke-width="7" stroke-linejoin="round" stroke-linecap="round">
${border}
  </g>
  <g stroke="${INK}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">
${body}
    <!-- Face -->
${person.face.map((x) => "    " + el(x)).join("\n")}
    <!-- ${person.topLabel} -->
${person.top.map((x) => "    " + el(x)).join("\n")}
  </g>`;
}

function frame(who, name) {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 160" width="96" height="160">
  <!-- player-${who}-${name}: facing right, soles on y = 152, feet centred near x = 48. Body drawn with Google Gemini, built by docs/asset-sources/chibi-family.mjs -->
${figure(PEOPLE[who], name)}
</svg>
`;
}

export { PEOPLE, CREAM, INK, SKIN, CHEEK, HAIR, CLOTH, p, c, rect, eyes, el };

// Only writes the sprites when run directly, not when imported.
if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  const wanted = process.argv.slice(2);
  for (const who of wanted.length ? wanted : Object.keys(PEOPLE)) {
    if (!PEOPLE[who]) throw new Error(`unknown person: ${who}`);
    for (const name of Object.keys(FRAMES)) {
      const file = join(OUT, `player-${who}-${name}.svg`);
      writeFileSync(file, frame(who, name));
      console.log("wrote", file);
    }
  }
}
