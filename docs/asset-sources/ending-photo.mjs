// Builds the photograph for the "shop saved" ending (Content.Endings.saved):
//
//   ending-saved-photo.svg
//
// It shows exactly what the ending says: midnight on the clock, Walter's roof
// beams holding, the wall crowded with shadow-story posters, the order desk
// stacked with parcels, Edwin turning the door sign to OPEN, and Ruth (older
// now) coming in out of the snow with Lucy beside her and Lucy's daughter
// holding a fox-and-lantern book.
//
//   node docs/asset-sources/ending-photo.mjs
//
// Same style as the other clue photos (docs/asset-sources/hub-props.mjs): the
// team palette, thin ink outlines, a print with a paper border and a caption.
// Edwin and the fox and lantern are the real game files, drawn in place.

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets");

const INK = "#291e1a", CREAM = "#f2e4c9", PAPER = "#fbf6ea", BROWN = "#5a3428", TAN = "#a6652b", SKIN = "#e8b98f", GREY = "#d4d3d1";
const C = { olive: "#393e26", vermilion: "#c95937", mustard: "#d9a443", teal: "#496669", periwinkle: "#7687ab", wine: "#893f43", green: "#31542f" };
const FONT = `font-family="Georgia, 'Times New Roman', serif"`;

// One of the real game files, drawn inside this picture at its own place and size.
function file(name, x, y, w, h = w) {
  const src = readFileSync(join(OUT, name), "utf8");
  const viewBox = src.match(/viewBox="([^"]+)"/)[1];
  const inner = src.replace(/^[\s\S]*?<svg[^>]*>/, "").replace(/<\/svg>\s*$/, "");
  return `<svg x="${x}" y="${y}" width="${w}" height="${h}" viewBox="${viewBox}">${inner}</svg>`;
}

// ── The room ───────────────────────────────────────────────────────────────

const room = () => `
    <!-- Warm wall, floorboards, and Walter's roof beams overhead, holding -->
    <rect x="0" y="0" width="480" height="300" fill="#e6d5b3" stroke="none" />
    <rect x="0" y="232" width="480" height="68" fill="${BROWN}" stroke="none" />
    <path d="M 0 250 H 480 M 0 272 H 480" fill="none" stroke="#4a2a20" stroke-width="1.5" />
    <rect x="0" y="0" width="480" height="18" fill="${TAN}" />
    <path d="M 120 0 V 18 M 240 0 V 18 M 360 0 V 18" fill="none" stroke-width="1.5" />
    <!-- A lamp's warm pool on the wall -->
    <ellipse cx="300" cy="120" rx="170" ry="110" fill="${C.mustard}" opacity="0.14" stroke="none" />`;

const door = () => `
    <!-- The front door, open to the snow -->
    <rect x="18" y="52" width="104" height="180" fill="#2b3550" />
    <g fill="${PAPER}" stroke="none" opacity="0.9">${[[30, 70], [56, 92], [90, 66], [104, 110], [40, 128], [76, 140], [100, 170], [30, 186], [64, 200], [96, 214], [48, 160]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="2.4" />`).join("")}</g>
    <path d="M 18 222 Q 70 210 122 222 V 232 H 18 Z" fill="${PAPER}" stroke-width="1.5" />
    <!-- The door itself, swung in, with its window and the sign -->
    <path d="M 122 52 L 150 60 L 150 238 L 122 232 Z" fill="${TAN}" />
    <rect x="128" y="74" width="16" height="44" fill="#2b3550" stroke-width="1.5" />
    <rect x="10" y="44" width="120" height="10" fill="${BROWN}" />
    <!-- The bell above the door, just rung -->
    <path d="M 142 30 V 38" fill="none" />
    <path d="M 134 52 C 134 40 150 40 150 52 Z" fill="${C.mustard}" />
    <circle cx="142" cy="54" r="2.2" fill="${C.mustard}" />
    <path d="M 128 40 l -5 -3 M 156 40 l 5 -3 M 126 48 h -6 M 158 48 h 6" fill="none" stroke="${C.mustard}" stroke-width="1.8" />`;

// The sign on the door, turned to OPEN, Edwin's hand on its corner.
const sign = () => `
    <path d="M 128 150 L 136 132 L 144 150" fill="none" stroke-width="1.2" />
    <rect x="106" y="148" width="60" height="26" rx="2" fill="${PAPER}" transform="rotate(-8 136 161)" />
    <text x="136" y="167" text-anchor="middle" ${FONT} font-size="14" font-weight="bold" fill="${C.wine}" stroke="none" letter-spacing="1.5" transform="rotate(-8 136 161)">OPEN</text>`;

// The wall clock at midnight.
const clock = () => `
    <circle cx="300" cy="44" r="19" fill="${BROWN}" />
    <circle cx="300" cy="44" r="14" fill="${PAPER}" stroke-width="1.5" />
    <path d="M 300 44 V 33 M 300 44 V 36" fill="none" stroke-width="2.2" />
    <circle cx="300" cy="44" r="1.8" fill="${C.wine}" stroke="none" />`;

// A shadow-story poster: the lit sheet with the fox and its lantern, and the year.
const poster = (x, y, tilt, fill, year, s = 0.62) => {
  const w = 100 * s, h = 136 * s, cx = x + w / 2;
  return `
    <g transform="rotate(${tilt} ${cx} ${y + h / 2})">
      <rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${fill}" stroke-width="1.5" />
      <text x="${cx}" y="${y + 13}" text-anchor="middle" ${FONT} font-size="6.5" font-weight="bold" fill="${CREAM}" stroke="none">Shadow Story</text>
      <rect x="${x + 8}" y="${y + 18}" width="${w - 16}" height="${32 * s * 1.3}" fill="${CREAM}" stroke-width="1" />
      ${file("shadow-fox.svg", x + 6, y + 14, 38 * s * 1.3)}
      ${file("prop-lantern.svg", x + 32 * s * 1.3, y + 24, 18 * s * 1.3)}
      <text x="${cx}" y="${y + h - 9}" text-anchor="middle" ${FONT} font-size="10" font-weight="bold" fill="${CREAM}" stroke="none">${year}</text>
      <circle cx="${cx}" cy="${y + 3}" r="2.4" fill="${C.vermilion}" stroke-width="1" />
    </g>`;
};

// Decades of posters crowding the wall.
const posters = () =>
  poster(212, 30, -4, C.wine, "1974") +
  poster(334, 26, 3, C.teal, "1986") +
  poster(400, 40, -3, C.green, "2003") +
  poster(256, 98, 5, C.periwinkle, "1991", 0.55) +
  poster(420, 112, 4, C.wine, "2019", 0.55) +
  poster(352, 108, -5, C.olive, "1979", 0.5);

// The order desk, stacked with string-tied parcels for tomorrow.
const desk = () => {
  const parcel = (x, y, w, h, fill) => `
      <rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${fill}" stroke-width="1.5" />
      <path d="M ${x + w / 2} ${y} V ${y + h} M ${x} ${y + h / 2} H ${x + w}" fill="none" stroke="${CREAM}" stroke-width="1.6" />
      <rect x="${x + w / 2 - 6}" y="${y + 3}" width="12" height="7" fill="${PAPER}" stroke-width="0.8" />`;
  return `
    <rect x="392" y="196" width="96" height="44" fill="${TAN}" />
    <rect x="388" y="190" width="104" height="8" fill="${BROWN}" />${parcel(398, 162, 38, 28, "#c79a62")}${parcel(440, 168, 34, 22, "#b4834e")}${parcel(404, 138, 30, 24, "#b4834e")}${parcel(436, 146, 28, 22, "#c79a62")}${parcel(414, 118, 26, 20, "#c79a62")}`;
};

// ── The people ─────────────────────────────────────────────────────────────

// A grown-up in a winter coat, in the same round style as the 1973 photo.
// x is the centre, y the top of the head.
function person({ x, y, coat, scarf, hair, bun = false, grey = false, smile = true, scale = 1, snow = false }) {
  const S = (v) => v * scale;
  const body = `M ${x - S(26)} ${y + S(136)} C ${x - S(28)} ${y + S(64)} ${x + S(28)} ${y + S(64)} ${x + S(26)} ${y + S(136)} Z`;
  const head = `<circle cx="${x}" cy="${y + S(30)}" r="${S(24)}" fill="${SKIN}" />`;
  const hairShape = `<path d="M ${x - S(24)} ${y + S(32)} C ${x - S(28)} ${y - S(2)} ${x + S(28)} ${y - S(2)} ${x + S(24)} ${y + S(30)} C ${x + S(14)} ${y + S(16)} ${x - S(12)} ${y + S(14)} ${x - S(24)} ${y + S(32)} Z" fill="${hair}" />`;
  const bunShape = bun ? `<circle cx="${x}" cy="${y + S(2)}" r="${S(10)}" fill="${hair}" />` : "";
  const face = `
      <g fill="${INK}" stroke="none"><circle cx="${x - S(8)}" cy="${y + S(32)}" r="${S(2.2)}" /><circle cx="${x + S(8)}" cy="${y + S(32)}" r="${S(2.2)}" /></g>
      <g fill="${C.vermilion}" stroke="none" opacity="0.35"><circle cx="${x - S(14)}" cy="${y + S(40)}" r="${S(4)}" /><circle cx="${x + S(14)}" cy="${y + S(40)}" r="${S(4)}" /></g>
      <path d="M ${x - S(6)} ${y + S(42)} Q ${x} ${y + S(smile ? 48 : 44)} ${x + S(6)} ${y + S(42)}" fill="none" stroke-width="1.5" />
      ${grey ? `<path d="M ${x - S(17)} ${y + S(30)} h ${S(6)} M ${x + S(11)} ${y + S(30)} h ${S(6)}" fill="none" stroke-width="1" />` : ""}`;
  const scarfShape = `<path d="M ${x - S(18)} ${y + S(62)} C ${x - S(8)} ${y + S(72)} ${x + S(8)} ${y + S(72)} ${x + S(18)} ${y + S(62)} L ${x + S(12)} ${y + S(92)} L ${x + S(6)} ${y + S(72)} Z" fill="${scarf}" />`;
  const snowShape = snow ? `<g fill="${PAPER}" stroke="none"><circle cx="${x - S(18)}" cy="${y + S(72)}" r="${S(2.6)}" /><circle cx="${x + S(20)}" cy="${y + S(74)}" r="${S(2.2)}" /><circle cx="${x - S(4)}" cy="${y + S(8)}" r="${S(2.2)}" /><circle cx="${x + S(10)}" cy="${y + S(4)}" r="${S(1.8)}" /></g>` : "";
  return `
    <g>
      <path d="${body}" fill="${coat}" />
      ${scarfShape}${bunShape}${head}${hairShape}${face}${snowShape}
    </g>`;
}

// Ruth, older now: grey hair in her bun, the blue coat, the red scarf, snow on her.
const ruth = () => person({ x: 252, y: 96, coat: C.periwinkle, scarf: C.vermilion, hair: GREY, bun: true, grey: true, snow: true });

// Lucy, grown up: the mustard hair from the photo, a red coat, beside her mother.
const lucy = () => person({ x: 308, y: 88, coat: C.wine, scarf: C.mustard, hair: C.mustard, snow: true });

// Lucy's daughter: plaits with teal ribbons, holding the fox-and-lantern book.
const daughter = () => {
  const x = 358, y = 150;
  return `
    <g>
      <path d="M ${x - 18} ${y + 84} C ${x - 20} ${y + 40} ${x + 20} ${y + 40} ${x + 18} ${y + 84} Z" fill="${C.green}" />
      <circle cx="${x}" cy="${y + 20}" r="18" fill="${SKIN}" />
      <path d="M ${x - 18} ${y + 22} C ${x - 20} ${y - 2} ${x + 20} ${y - 2} ${x + 18} ${y + 20} C ${x + 10} ${y + 10} ${x - 10} ${y + 10} ${x - 18} ${y + 22} Z" fill="${C.mustard}" />
      <path d="M ${x - 17} ${y + 20} q -6 10 -3 20 M ${x + 17} ${y + 20} q 6 10 3 20" fill="none" stroke="${C.mustard}" stroke-width="5" />
      <g fill="${C.teal}" stroke-width="1"><circle cx="${x - 20}" cy="${y + 40}" r="3" /><circle cx="${x + 20}" cy="${y + 40}" r="3" /></g>
      <g fill="${INK}" stroke="none"><circle cx="${x - 6}" cy="${y + 22}" r="1.8" /><circle cx="${x + 6}" cy="${y + 22}" r="1.8" /></g>
      <g fill="${C.vermilion}" stroke="none" opacity="0.35"><circle cx="${x - 11}" cy="${y + 28}" r="3" /><circle cx="${x + 11}" cy="${y + 28}" r="3" /></g>
      <path d="M ${x - 5} ${y + 29} Q ${x} ${y + 34} ${x + 5} ${y + 29}" fill="none" stroke-width="1.3" />
      <!-- The book, held up to show its cover: the fox carrying its lantern -->
      <rect x="${x - 22}" y="${y + 46}" width="44" height="34" rx="2" fill="${C.teal}" />
      <rect x="${x - 17}" y="${y + 50}" width="34" height="26" fill="${CREAM}" stroke-width="1" />
      ${file("shadow-fox.svg", x - 18, y + 44, 30)}
      ${file("prop-lantern.svg", x + 2, y + 52, 15)}
      <g fill="${SKIN}" stroke-width="1.2"><circle cx="${x - 22}" cy="${y + 66}" r="4" /><circle cx="${x + 22}" cy="${y + 66}" r="4" /></g>
    </g>`;
};

// Edwin: the real present-day sprite, at the door with his hand on the sign.
const edwin = () => file("player-edwin-present-idle.svg", 146, 78, 96, 160);

// ── The print ──────────────────────────────────────────────────────────────

function photo() {
  return `
  <rect x="0" y="0" width="520" height="372" fill="${PAPER}" stroke-width="1.5" />
  <clipPath id="ending"><rect x="20" y="20" width="480" height="300" /></clipPath>
  <g clip-path="url(#ending)">
    <g transform="translate(20 20)">${room()}${door()}${posters()}${clock()}${desk()}${edwin()}${sign()}${ruth()}${lucy()}${daughter()}
      <!-- A warm print -->
      <rect x="0" y="0" width="480" height="300" fill="${C.mustard}" opacity="0.08" stroke="none" />
    </g>
  </g>
  <rect x="20" y="20" width="480" height="300" fill="none" stroke-width="1.5" />
  <text x="260" y="352" text-anchor="middle" ${FONT} font-size="18" font-style="italic" fill="${INK}" stroke="none">One more Christmas</text>`;
}

const out = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 372" width="520" height="372">
  <!-- ending-saved-photo: the shop-saved ending as a photograph. Built by docs/asset-sources/ending-photo.mjs -->
  <g stroke="${INK}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">${photo()}
  </g>
</svg>
`;
writeFileSync(join(OUT, "ending-saved-photo.svg"), out);
console.log("wrote ending-saved-photo.svg");
