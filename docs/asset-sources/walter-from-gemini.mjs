// Builds public/assets/player-walter-{idle,walk-1,walk-2}.svg from Gemini's
// drawing (shapes kept as Gemini drew them unless noted), with fixes:
//   face: bigger outline-free irises, eyes/nose/moustache shifted right,
//         bushy single-arc moustache (no mouth line), both blushes visible, no blush outline
//   idle: gap between the shoes
//   walk-1: wide arm swing (Gemini's walk-2 arms), so no arm crosses the chest
//   walk-2: narrower stride whose legs don't cross, arms close to the body
// Every outer shape is drawn twice: once in cream (stroke 7) as the cut-out
// border, once with its fill and the ink outline (stroke 3).
//
//   node docs/asset-sources/walter-from-gemini.mjs

import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets");
const CREAM = "#f2e4c9", INK = "#291e1a", SKIN = "#e8b98f", CHEEK = "#d9806a";
const SHIRT = "#d9a443", WAISTCOAT = "#893f43", TROUSERS = "#496669", HAIR = "#d4d3d1", CAP = "#393e26", IRIS = "#496669";

const p = (d, fill) => ({ tag: "path", d, fill });
const c = (cx, cy, r, fill) => ({ tag: "circle", cx, cy, r, fill });
const r = (x, y, w, h, rx, fill) => ({ tag: "rect", x, y, width: w, height: h, rx, fill });

// ── limbs ────────────────────────────────────────────────────────────────
const ARMS = {
  // Gemini idle arms
  idleFar: [p("M 40,76 C 34,86 32,96 24,94 C 28,84 36,74 40,76 Z", SHIRT), p("M 32,96 C 30,106 28,112 22,110 C 24,100 24,94 32,96 Z", SKIN), c(25, 111, 4, SKIN)],
  idleNear: [p("M 54,76 C 64,84 62,98 52,96 C 50,86 46,78 54,76 Z", SHIRT), p("M 62,98 C 60,110 56,116 48,114 C 50,104 52,96 62,98 Z", SKIN), c(52, 115, 4, SKIN)],
  // Gemini walk-2 arms: wide swing
  wideFar: [p("M 40,76 C 30,82 24,94 18,90 C 28,80 36,74 40,76 Z", SHIRT), p("M 24,94 C 18,104 14,110 8,106 C 14,98 18,90 24,94 Z", SKIN), c(11, 108, 4, SKIN)],
  wideNear: [p("M 54,76 C 66,82 74,92 66,98 C 58,88 46,78 54,76 Z", SHIRT), p("M 74,92 C 82,102 86,108 78,112 C 72,102 66,98 74,92 Z", SKIN), c(82, 110, 4, SKIN)],
  // new: arms hanging close to the sides
  closeFar: [p("M 40,76 C 34,82 32,90 32,97 C 35,99 38,99 40,97 C 40,90 42,82 44,78 Z", SHIRT), p("M 32,97 C 32,103 33,108 35,111 C 37,112 40,111 41,109 C 40,104 40,100 40,97 Z", SKIN), c(37, 112, 4, SKIN)],
  closeNear: [p("M 52,77 C 58,74 64,80 67,96 C 64,99 61,99 59,97 C 58,88 55,82 52,77 Z", SHIRT), p("M 59,97 C 62,96 65,96 67,97 C 67,103 66,108 64,111 C 62,112 60,111 59,109 C 59,104 59,100 59,97 Z", SKIN), c(62, 112, 4, SKIN)],
};
const LEGS = {
  // Gemini idle legs; shoes trimmed so they no longer overlap
  idleFar: [p("M 38,115 L 36,142 L 46,142 L 48,115 Z", TROUSERS), p("M 36,142 L 46,142 L 46,152 L 30,152 C 30,144 33,142 36,142 Z", INK)],
  idleNear: [p("M 48,115 L 50,144 L 62,144 L 60,115 Z", TROUSERS), p("M 50,144 L 62,144 C 65,144 66,147 66,152 L 50,152 Z", INK)],
  // Gemini walk-1 legs: wide stride
  wideFar: [p("M 38,115 L 26,142 L 36,144 L 48,115 Z", TROUSERS), p("M 26,142 L 38,144 L 38,152 L 20,152 C 20,144 24,142 26,142 Z", INK)],
  wideNear: [p("M 48,115 L 60,142 L 72,142 L 60,115 Z", TROUSERS), p("M 60,142 L 74,142 L 74,152 L 52,152 C 52,144 58,142 60,142 Z", INK)],
  // new: narrow stride, no crossing
  narrowFar: [p("M 38,115 L 34,142 L 44,143 L 48,115 Z", TROUSERS), p("M 34,142 L 45,143 L 45,152 L 28,152 C 28,145 31,142 34,142 Z", INK)],
  narrowNear: [p("M 48,115 L 54,143 L 64,142 L 60,115 Z", TROUSERS), p("M 54,143 L 64,142 C 69,142 72,146 72,152 L 53,152 Z", INK)],
};

// ── fixed body (identical in every frame) ─────────────────────────────────
const TORSO = [
  p("M 32,74 C 48,82 64,74 66,114 C 48,122 30,114 32,74 Z", WAISTCOAT),
  p("M 40,76 L 56,76 L 48,94 Z", SHIRT),
  c(48, 100, 2, SHIRT), c(48, 106, 2, SHIRT), c(48, 112, 2, SHIRT),
];
const HEAD = [
  p("M 16,30 C 12,40 16,54 26,56 L 30,46 Z", HAIR),
  r(28, 44, 6, 12, 3, HAIR),
  p("M 48,18 C 66,18 78,30 78,46 C 78,64 66,76 48,76 C 30,76 18,64 18,46 C 18,30 30,18 48,18 Z", SKIN),
];
// Face: drawn on top of the head, with no cut-out border (it's inside the head).
const FACE = [
  { tag: "circle", cx: 41, cy: 57, r: 3.6, fill: CHEEK, stroke: "none" },
  { tag: "circle", cx: 71, cy: 57, r: 3.6, fill: CHEEK, stroke: "none" },
  { tag: "ellipse", cx: 46, cy: 46, rx: 5.6, ry: 7.2, fill: CREAM, "stroke-width": 2.4 },
  { tag: "ellipse", cx: 47.4, cy: 46.6, rx: 4, ry: 5.4, fill: IRIS, stroke: "none" },
  { tag: "ellipse", cx: 65, cy: 46, rx: 5.6, ry: 7.2, fill: CREAM, "stroke-width": 2.4 },
  { tag: "ellipse", cx: 66.4, cy: 46.6, rx: 4, ry: 5.4, fill: IRIS, stroke: "none" },
  { tag: "circle", cx: 57, cy: 53.4, r: 1.5, fill: INK, stroke: "none" },
  // Bushy moustache: one smooth arc on top (no dip, so it can't read as lips), drooping ends.
  { tag: "path", d: "M 48.6,61 C 49.4,54.2 65.8,54.2 66.6,61 C 64.6,59.6 62.2,59.2 60.2,60.2 C 59,59 56.2,59 55,60.2 C 53,59.2 50.6,59.6 48.6,61 Z", fill: HAIR, "stroke-width": 2 },
];
const CAP_SHAPES = [
  p("M 12,32 C 12,12 80,12 84,32 C 86,34 86,38 76,40 C 60,42 40,42 12,32 Z", CAP),
  p("M 68,36 C 80,36 88,40 88,42 C 80,44 72,42 68,38 Z", CAP),
];

const FRAMES = {
  idle: { arms: ["idleFar", "idleNear"], legs: ["idleFar", "idleNear"] },
  "walk-1": { arms: ["wideFar", "wideNear"], legs: ["wideFar", "wideNear"] },
  "walk-2": { arms: ["closeFar", "closeNear"], legs: ["narrowFar", "narrowNear"] },
};

const attrs = (o, overrides = {}) =>
  Object.entries({ ...o, ...overrides })
    .filter(([k]) => k !== "tag")
    .map(([k, v]) => `${k}="${v}"`)
    .join(" ");
const el = (o, overrides) => `<${o.tag} ${attrs(o, overrides)} />`;

function frame(name) {
  const { arms, legs } = FRAMES[name];
  const layers = [
    ["Far arm", ARMS[arms[0]]],
    ["Far leg", LEGS[legs[0]]],
    ["Near leg", LEGS[legs[1]]],
    ["Torso (waistcoat and shirt)", TORSO],
    ["Near arm", ARMS[arms[1]]],
    ["Hair and head", HEAD],
  ];
  const border = [...layers.flatMap(([, s]) => s), ...CAP_SHAPES].map((s) => "    " + el(s, { fill: CREAM, stroke: undefined })).join("\n").replaceAll(' stroke="undefined"', "");
  const body = layers.map(([label, s]) => `    <!-- ${label} -->\n` + s.map((x) => "    " + el(x)).join("\n")).join("\n");
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 160" width="96" height="160">
  <!-- player-walter-${name}: facing right, soles on y = 152, feet centred near x = 48. Drawn with Google Gemini, adjusted by docs/asset-sources/walter-from-gemini.mjs -->
  <!-- Cut-out border: every outer shape again in cream, 2 units wider than the outline -->
  <g fill="${CREAM}" stroke="${CREAM}" stroke-width="7" stroke-linejoin="round" stroke-linecap="round">
${border}
  </g>
  <g stroke="${INK}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">
${body}
    <!-- Face -->
${FACE.map((x) => "    " + el(x)).join("\n")}
    <!-- Flat cap -->
${CAP_SHAPES.map((x) => "    " + el(x)).join("\n")}
  </g>
</svg>
`;
}

for (const name of Object.keys(FRAMES)) {
  const file = join(OUT, `player-walter-${name}.svg`);
  writeFileSync(file, frame(name));
  console.log("wrote", file);
}
