// Builds the pictures for the community wall, one per state of the 1973
// tradition (Content.Clues hubProp CommunityWall, from world.tradition):
//
//   clue-wall-<state>.svg
//
// where <state> is original (NotRevisited), missing (Missing) or established
// (Established). Each picture shows exactly what its text says. The roof and
// shelves and the order desk have no picture, by the team's choice. The bare
// original is just the board with its old pin holes.
//
//   node docs/asset-sources/hub-props.mjs
//
// Flat paper-theatre style like the room props: the team palette only, thin ink
// outlines (2 units), 480 x 300.

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "public", "assets");

const INK = "#291e1a", CREAM = "#f2e4c9", GREY = "#d4d3d1", BROWN = "#5a3428", TAN = "#a6652b", SKIN = "#e8b98f";
const C = { olive: "#393e26", vermilion: "#c95937", mustard: "#d9a443", teal: "#496669", periwinkle: "#7687ab", wine: "#893f43", green: "#31542f" };
const W = 480, H = 300;
const FONT = `font-family="Georgia, 'Times New Roman', serif"`;

const svg = (name, note, body, [x, y, w, h] = [0, 0, W, H]) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${x} ${y} ${w} ${h}" width="${w}" height="${h}">
  <!-- ${name}: ${note}. Built by docs/asset-sources/hub-props.mjs -->
  <g stroke="${INK}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">
${body}
  </g>
</svg>
`;

// ── Community wall (1973) ──────────────────────────────────────────────────
function communityWall(kind) {
  if (kind === "bare") {
    // Only the board, with its old pin holes.
    return `    <rect x="40" y="26" width="330" height="200" rx="3" fill="#c79a62" />
    <g fill="${INK}" stroke="none"><circle cx="82" cy="52" r="1.8" /><circle cx="150" cy="60" r="1.8" /><circle cx="226" cy="48" r="1.8" /><circle cx="300" cy="66" r="1.8" /><circle cx="110" cy="140" r="1.8" /><circle cx="188" cy="118" r="1.8" /><circle cx="262" cy="150" r="1.8" /><circle cx="330" cy="120" r="1.8" /><circle cx="96" cy="196" r="1.8" /><circle cx="214" cy="190" r="1.8" /><circle cx="318" cy="204" r="1.8" /></g>
`;
  }
  let s = `    <rect x="0" y="0" width="${W}" height="250" fill="${CREAM}" />
    <rect x="0" y="250" width="${W}" height="50" fill="${BROWN}" />
    <!-- The children's corner: rug and a little chair -->
    <ellipse cx="370" cy="282" rx="90" ry="14" fill="${C.teal}" />
    <path d="M 410 232 L 446 232 L 446 270 M 410 232 L 410 270 M 410 252 L 446 252" fill="none" stroke="${TAN}" stroke-width="5" />
    <path d="M 410 232 L 446 232 L 446 270 M 410 232 L 410 270 M 410 252 L 446 252" fill="none" stroke-width="1.5" />
    <!-- The wall board -->
    <rect x="40" y="26" width="330" height="200" rx="3" fill="#c79a62" />
`;
  if (kind === "bare") {
    s += `    <g fill="${INK}" stroke="none"><circle cx="82" cy="52" r="1.8" /><circle cx="150" cy="60" r="1.8" /><circle cx="226" cy="48" r="1.8" /><circle cx="300" cy="66" r="1.8" /><circle cx="110" cy="140" r="1.8" /><circle cx="188" cy="118" r="1.8" /><circle cx="262" cy="150" r="1.8" /><circle cx="330" cy="120" r="1.8" /><circle cx="96" cy="196" r="1.8" /><circle cx="214" cy="190" r="1.8" /><circle cx="318" cy="204" r="1.8" /></g>
`;
  } else if (kind === "one") {
    s += `    <g fill="${INK}" stroke="none"><circle cx="82" cy="52" r="1.8" /><circle cx="300" cy="66" r="1.8" /><circle cx="110" cy="190" r="1.8" /><circle cx="318" cy="204" r="1.8" /></g>
    <!-- One faded poster -->
    <g transform="rotate(-4 205 126)" opacity="0.7">
      <rect x="150" y="50" width="110" height="150" fill="#ece0c4" />
      <path d="M 170 160 C 176 146 190 142 200 150 L 214 140 L 212 156 C 220 162 220 172 210 176 L 176 176 C 168 174 166 166 170 160 Z" fill="${GREY}" stroke-width="1.5" />
      <text x="205" y="84" text-anchor="middle" ${FONT} font-size="15" font-weight="bold" fill="${BROWN}" stroke="none">Christmas</text>
      <text x="205" y="102" text-anchor="middle" ${FONT} font-size="15" font-weight="bold" fill="${BROWN}" stroke="none">Reading</text>
      <text x="205" y="128" text-anchor="middle" ${FONT} font-size="17" fill="${BROWN}" stroke="none">1973</text>
      <circle cx="205" cy="56" r="3.5" fill="${C.vermilion}" />
    </g>
`;
  }
  return s;
}

// ── The tradition: the whole board, full of the shadow story ──────────────
const PAPER = "#fbf6ea";

// One of the real cut-out files (shadow-*.svg, prop-*.svg), drawn inside this
// picture at its own place and size.
function cutout(file, x, y, size) {
  const src = readFileSync(join(OUT, file), "utf8");
  const viewBox = src.match(/viewBox="([^"]+)"/)[1];
  const inner = src.replace(/^[\s\S]*?<svg[^>]*>/, "").replace(/<\/svg>\s*$/, "");
  return `<svg x="${x}" y="${y}" width="${size}" height="${size}" viewBox="${viewBox}">${inner}</svg>`;
}

// A poster for one year's show: the lit sheet with the fox and its lantern.
const poster = (x, y, tilt, fill, year) => {
  const w = 100, h = 136, cx = x + w / 2;
  return `    <g transform="rotate(${tilt} ${cx} ${y + h / 2})">
      <rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${fill}" />
      <rect x="${x + 5}" y="${y + 5}" width="${w - 10}" height="${h - 10}" fill="none" stroke="${CREAM}" stroke-width="1.2" />
      <text x="${cx}" y="${y + 20}" text-anchor="middle" ${FONT} font-size="8" fill="${CREAM}" stroke="none" letter-spacing="1">THE CHRISTMAS</text>
      <text x="${cx}" y="${y + 34}" text-anchor="middle" ${FONT} font-size="12" font-weight="bold" fill="${CREAM}" stroke="none">Shadow Story</text>
      <!-- The lit sheet, the fox with its lantern on it, stars below -->
      <rect x="${x + 16}" y="${y + 42}" width="68" height="50" fill="${CREAM}" stroke-width="1.2" />
      <path d="M ${x + 16} ${y + 42} L ${x + 84} ${y + 42}" fill="none" stroke-width="2" />
      <circle cx="${x + 64}" cy="${y + 72}" r="13" fill="${C.mustard}" fill-opacity="0.35" stroke="none" />
      ${cutout("shadow-fox.svg", x + 12, y + 38, 58)}
      ${cutout("prop-lantern.svg", x + 52, y + 54, 26)}
      <g fill="${C.mustard}" stroke="none"><circle cx="${x + 26}" cy="${y + 102}" r="1.6" /><circle cx="${x + 74}" cy="${y + 100}" r="1.6" /><circle cx="${x + 50}" cy="${y + 98}" r="1.2" /></g>
      <text x="${cx}" y="${y + 118}" text-anchor="middle" ${FONT} font-size="15" font-weight="bold" fill="${CREAM}" stroke="none">${year}</text>
      <text x="${cx}" y="${y + 129}" text-anchor="middle" ${FONT} font-size="6.5" fill="${CREAM}" stroke="none" letter-spacing="1">HALE’S BOOKSHOP</text>
      <circle cx="${cx}" cy="${y + 4}" r="3.5" fill="${C.vermilion}" />
    </g>
`;
};

// A child's crayon drawing of the fox carrying its lantern at night.
const drawing = (x, y, tilt, fox) => {
  const w = 122, h = 88;
  const X = (v) => x + v, Y = (v) => y + v;
  return `    <g transform="rotate(${tilt} ${X(w / 2)} ${Y(h / 2)})">
      <rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${PAPER}" stroke-width="1.2" />
      <!-- Crayon sky, moon and stars -->
      <path d="M ${X(6)} ${Y(14)} l 10 -6 l 4 10 l 10 -8 l 4 10 l 10 -8 l 4 10 l 10 -8 l 4 10 l 10 -8 l 4 10 l 10 -8 l 4 10 l 10 -8 l 4 8" fill="none" stroke="${C.periwinkle}" stroke-width="3" opacity="0.55" />
      <circle cx="${X(18)}" cy="${Y(26)}" r="7" fill="${C.mustard}" stroke="none" />
      <path d="M ${X(98)} ${Y(26)} h 8 m -4 -4 v 8 M ${X(80)} ${Y(32)} h 6 m -3 -3 v 6" fill="none" stroke="${C.mustard}" stroke-width="1.6" />
      <!-- Crayon grass -->
      <path d="M ${X(4)} ${Y(80)} q 6 -6 10 0 q 6 -6 10 0 q 6 -6 10 0 q 6 -6 10 0 q 6 -6 10 0 q 6 -6 10 0 q 6 -6 10 0 q 6 -6 10 0 q 6 -6 10 0 q 6 -6 10 0 q 6 -6 10 0 q 6 -6 10 0" fill="none" stroke="${C.green}" stroke-width="2.4" />
      <!-- The fox: tail with a white tip, body, legs, head with pointed ears -->
      <path d="M ${X(30)} ${Y(66)} C ${X(14)} ${Y(66)} ${X(10)} ${Y(50)} ${X(18)} ${Y(42)} C ${X(22)} ${Y(52)} ${X(28)} ${Y(56)} ${X(36)} ${Y(58)} Z" fill="${fox}" stroke-width="1.2" />
      <path d="M ${X(18)} ${Y(42)} C ${X(14)} ${Y(46)} ${X(14)} ${Y(50)} ${X(16)} ${Y(53)} C ${X(18)} ${Y(49)} ${X(20)} ${Y(46)} ${X(18)} ${Y(42)} Z" fill="${PAPER}" stroke-width="1" />
      <path d="M ${X(30)} ${Y(66)} C ${X(30)} ${Y(54)} ${X(42)} ${Y(50)} ${X(56)} ${Y(52)} C ${X(64)} ${Y(54)} ${X(66)} ${Y(62)} ${X(62)} ${Y(66)} Z" fill="${fox}" stroke-width="1.2" />
      <path d="M ${X(36)} ${Y(64)} v 10 M ${X(44)} ${Y(65)} v 10 M ${X(54)} ${Y(65)} v 10 M ${X(60)} ${Y(64)} v 10" fill="none" stroke="${fox}" stroke-width="3" />
      <path d="M ${X(56)} ${Y(54)} C ${X(56)} ${Y(44)} ${X(64)} ${Y(40)} ${X(70)} ${Y(44)} L ${X(78)} ${Y(48)} L ${X(70)} ${Y(54)} Z" fill="${fox}" stroke-width="1.2" />
      <path d="M ${X(59)} ${Y(45)} L ${X(60)} ${Y(34)} L ${X(65)} ${Y(42)} Z M ${X(64)} ${Y(43)} L ${X(68)} ${Y(33)} L ${X(70)} ${Y(44)} Z" fill="${fox}" stroke-width="1.2" />
      <circle cx="${X(66)}" cy="${Y(46)}" r="1.4" fill="${INK}" stroke="none" />
      <circle cx="${X(78)}" cy="${Y(48)}" r="1.6" fill="${INK}" stroke="none" />
      <!-- The lantern, carried on a stick, glowing -->
      <path d="M ${X(72)} ${Y(50)} L ${X(90)} ${Y(42)} V ${Y(48)}" fill="none" stroke="${BROWN}" stroke-width="1.8" />
      <circle cx="${X(90)}" cy="${Y(55)}" r="13" fill="${C.mustard}" fill-opacity="0.3" stroke="none" />
      <rect x="${X(85)}" y="${Y(48)}" width="10" height="13" fill="${C.mustard}" stroke-width="1.2" />
      <path d="M ${X(85)} ${Y(48)} h 10 M ${X(85)} ${Y(61)} h 10" fill="none" stroke-width="2" />
      <path d="M ${X(80)} ${Y(42)} l -4 -4 M ${X(100)} ${Y(42)} l 4 -4 M ${X(104)} ${Y(55)} h 5 M ${X(76)} ${Y(55)} h -5" fill="none" stroke="${C.mustard}" stroke-width="1.8" />
      <circle cx="${X(w / 2)}" cy="${Y(4)}" r="3.5" fill="${C.teal}" />
    </g>
`;
};

// The 1973 photograph: Ruth with little Lucy in the front row, the lit sheet
// with the fox's shadow behind them, other children's heads at the sides.
const photo = (x, y, tilt) => {
  const X = (v) => x + v, Y = (v) => y + v;
  return `    <g transform="rotate(${tilt} ${X(78)} ${Y(61)})">
      <rect x="${x}" y="${y}" width="156" height="122" fill="${PAPER}" stroke-width="1.2" />
      <clipPath id="ruth-lucy"><rect x="${X(8)}" y="${Y(8)}" width="140" height="92" /></clipPath>
      <g clip-path="url(#ruth-lucy)">
        <rect x="${X(8)}" y="${Y(8)}" width="140" height="92" fill="#4a3c33" stroke="none" />
        <!-- The lit sheet and the fox's shadow on it -->
        <rect x="${X(36)}" y="${Y(12)}" width="86" height="42" fill="#efe2c2" stroke="none" />
        <g opacity="0.85">${cutout("shadow-fox.svg", X(50), Y(4), 50)}${cutout("prop-lantern.svg", X(84), Y(18), 22)}</g>
        <!-- Other children's heads in the dark -->
        <g fill="#2e2620" stroke="none"><circle cx="${X(16)}" cy="${Y(76)}" r="9" /><circle cx="${X(30)}" cy="${Y(80)}" r="8" /><circle cx="${X(130)}" cy="${Y(78)}" r="9" /><circle cx="${X(144)}" cy="${Y(82)}" r="8" /></g>
        <g transform="translate(0 -12)">
        <!-- Ruth: hair in a bun, blue coat, red scarf, smiling -->
        <path d="M ${X(46)} ${Y(100)} C ${X(46)} ${Y(78)} ${X(80)} ${Y(78)} ${X(80)} ${Y(100)} Z" fill="${C.periwinkle}" stroke-width="1.2" />
        <path d="M ${X(54)} ${Y(80)} C ${X(60)} ${Y(86)} ${X(68)} ${Y(86)} ${X(74)} ${Y(80)} L ${X(70)} ${Y(94)} L ${X(66)} ${Y(86)} Z" fill="${C.vermilion}" stroke-width="1" />
        <circle cx="${X(63)}" cy="${Y(68)}" r="11" fill="${SKIN}" stroke-width="1.2" />
        <path d="M ${X(52)} ${Y(68)} C ${X(50)} ${Y(54)} ${X(76)} ${Y(54)} ${X(74)} ${Y(66)} C ${X(68)} ${Y(60)} ${X(58)} ${Y(60)} ${X(52)} ${Y(68)} Z" fill="${BROWN}" stroke-width="1.2" />
        <circle cx="${X(63)}" cy="${Y(54)}" r="5" fill="${BROWN}" stroke-width="1.2" />
        <g fill="${INK}" stroke="none"><circle cx="${X(59)}" cy="${Y(68)}" r="1.1" /><circle cx="${X(67)}" cy="${Y(68)}" r="1.1" /></g>
        <path d="M ${X(60)} ${Y(73)} Q ${X(63)} ${Y(76)} ${X(66)} ${Y(73)}" fill="none" stroke-width="1" />
        <!-- Lucy: plaits with ribbons, red coat, holding a paper fox -->
        <path d="M ${X(84)} ${Y(100)} C ${X(84)} ${Y(84)} ${X(106)} ${Y(84)} ${X(106)} ${Y(100)} Z" fill="${C.vermilion}" stroke-width="1.2" />
        <circle cx="${X(95)}" cy="${Y(76)}" r="8.5" fill="${SKIN}" stroke-width="1.2" />
        <path d="M ${X(86)} ${Y(76)} C ${X(85)} ${Y(65)} ${X(105)} ${Y(65)} ${X(104)} ${Y(76)} C ${X(99)} ${Y(71)} ${X(91)} ${Y(71)} ${X(86)} ${Y(76)} Z" fill="${C.mustard}" stroke-width="1.2" />
        <path d="M ${X(86)} ${Y(74)} q -4 6 -2 12 M ${X(104)} ${Y(74)} q 4 6 2 12" fill="none" stroke="${C.mustard}" stroke-width="3.4" />
        <g fill="${C.teal}" stroke="none"><circle cx="${X(84)}" cy="${Y(86)}" r="2" /><circle cx="${X(106)}" cy="${Y(86)}" r="2" /></g>
        <g fill="${INK}" stroke="none"><circle cx="${X(92)}" cy="${Y(77)}" r="1" /><circle cx="${X(98)}" cy="${Y(77)}" r="1" /></g>
        <path d="M ${X(92)} ${Y(81)} Q ${X(95)} ${Y(84)} ${X(98)} ${Y(81)}" fill="none" stroke-width="1" />
        <path d="M ${X(100)} ${Y(94)} l 6 -6 l 2 4 l 3 -3 l 1 6 Z" fill="${TAN}" stroke-width="1" />
        </g>
        <!-- The front-row bench -->
        <rect x="${X(8)}" y="${Y(86)}" width="140" height="16" fill="${BROWN}" stroke="none" />
        <!-- Aged print -->
        <rect x="${X(8)}" y="${Y(8)}" width="140" height="92" fill="${C.mustard}" opacity="0.16" stroke="none" />
      </g>
      <rect x="${X(8)}" y="${Y(8)}" width="140" height="92" fill="none" stroke-width="1" />
      <text x="${X(78)}" y="${Y(114)}" text-anchor="middle" ${FONT} font-size="9" font-style="italic" fill="${INK}" stroke="none">Ruth &amp; Lucy, front row, 1973</text>
      <path d="M ${X(-6)} ${Y(10)} l 22 -14 l 6 10 l -22 14 Z M ${X(162)} ${Y(10)} l -22 -14 l -6 10 l 22 14 Z" fill="${CREAM}" fill-opacity="0.75" stroke-width="0.8" />
    </g>
`;
};

function tradition() {
  // Cork speckles, placed by a fixed pattern so the picture never changes.
  const speckles = Array.from({ length: 90 }, (_, i) => {
    const px = ((i * 97) % 470) + 5, py = ((i * 53 + (i % 7) * 31) % 290) + 5;
    return `<circle cx="${px}" cy="${py}" r="${1 + (i % 3) * 0.5}" />`;
  }).join("");
  return `    <!-- The whole board -->
    <rect x="0" y="0" width="${W}" height="${H}" fill="#c79a62" stroke="none" />
    <g fill="#a87c47" stroke="none" opacity="0.6">${speckles}</g>
    <rect x="3" y="3" width="${W - 6}" height="${H - 6}" fill="none" stroke="${BROWN}" stroke-width="6" />
${poster(16, 16, -4, C.wine, "1974")}${poster(124, 12, 3, C.teal, "1986")}${poster(364, 18, 4, C.green, "2019")}${drawing(234, 24, -3, C.vermilion)}${drawing(18, 178, 4, TAN)}${drawing(340, 182, -5, C.vermilion)}${photo(164, 162, 2)}`;
}

const files = {
  "clue-wall-original.svg": ["the 1973 story not revisited: just the bare board with its old pin holes", communityWall("bare"), [39, 25, 332, 202]],
  "clue-wall-missing.svg": ["the 1973 story failed: one faded poster, Christmas Reading 1973, on the board", communityWall("one"), [39, 25, 332, 202]],
  "clue-wall-established.svg": ["the 1973 story became a tradition: the whole board of posters, children's fox-and-lantern drawings and Ruth and Lucy's photo", tradition()],
};
for (const [name, [note, body, view]] of Object.entries(files)) {
  writeFileSync(join(OUT, name), svg(name.replace(".svg", ""), note, body, view));
  console.log("wrote", name);
}
