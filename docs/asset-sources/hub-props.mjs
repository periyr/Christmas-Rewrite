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

import { writeFileSync } from "node:fs";
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
  } else {
    const poster = (x, y, w, h, tilt, fill, year) => `    <g transform="rotate(${tilt} ${x + w / 2} ${y + h / 2})">
      <rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${fill}" />
      <text x="${x + w / 2}" y="${y + 22}" text-anchor="middle" ${FONT} font-size="9" font-weight="bold" fill="${CREAM}" stroke="none">Shadow Story</text>
      <text x="${x + w / 2}" y="${y + h - 10}" text-anchor="middle" ${FONT} font-size="13" fill="${CREAM}" stroke="none">${year}</text>
      <circle cx="${x + w / 2}" cy="${y + 4}" r="3" fill="${C.mustard}" />
    </g>
`;
    // A child's drawing: the fox with the lantern, in crayon.
    const drawing = (x, y, tilt, fox) => `    <g transform="rotate(${tilt} ${x + 40} ${y + 30})">
      <rect x="${x}" y="${y}" width="80" height="60" fill="#fbf6ea" stroke-width="1.5" />
      <path d="M ${x + 14} ${y + 46} C ${x + 18} ${y + 32} ${x + 32} ${y + 28} ${x + 42} ${y + 36} L ${x + 50} ${y + 26} L ${x + 50} ${y + 40} C ${x + 56} ${y + 44} ${x + 54} ${y + 52} ${x + 46} ${y + 52} L ${x + 18} ${y + 52} Z" fill="${fox}" stroke-width="1.2" />
      <path d="M ${x + 18} ${y + 50} C ${x + 8} ${y + 46} ${x + 6} ${y + 38} ${x + 12} ${y + 34}" fill="none" stroke="${fox}" stroke-width="4" />
      <path d="M ${x + 58} ${y + 22} L ${x + 58} ${y + 30}" fill="none" stroke-width="1.2" />
      <rect x="${x + 54}" y="${y + 30}" width="9" height="12" fill="${C.mustard}" stroke-width="1.2" />
      <path d="M ${x + 52} ${y + 26} L ${x + 47} ${y + 20} M ${x + 64} ${y + 26} L ${x + 69} ${y + 20} M ${x + 58} ${y + 24} L ${x + 58} ${y + 16}" stroke="${C.mustard}" stroke-width="2" fill="none" />
    </g>
`;
    s += poster(50, 36, 70, 92, -5, C.wine, "1974")
      + poster(128, 32, 70, 92, 3, C.teal, "1986")
      + poster(296, 38, 66, 88, 5, C.green, "2019")
      + drawing(206, 40, -3, C.vermilion)
      + drawing(56, 140, 4, TAN)
      + drawing(280, 136, -6, C.vermilion)
      + `    <!-- The 1973 photograph: Ruth with little Lucy in the front row -->
    <g transform="rotate(2 200 176)">
      <rect x="150" y="134" width="104" height="84" fill="#fbf6ea" stroke-width="1.5" />
      <rect x="158" y="142" width="88" height="62" fill="${GREY}" stroke-width="1.2" />
      <circle cx="186" cy="166" r="9" fill="${SKIN}" stroke-width="1.2" /><path d="M 172 204 C 172 184 200 184 200 204 Z" fill="${C.periwinkle}" stroke-width="1.2" />
      <path d="M 177 164 C 176 152 196 152 195 164 C 190 158 182 158 177 164 Z" fill="${BROWN}" stroke-width="1.2" />
      <circle cx="218" cy="178" r="7" fill="${SKIN}" stroke-width="1.2" /><path d="M 207 204 C 207 190 229 190 229 204 Z" fill="${C.vermilion}" stroke-width="1.2" />
      <path d="M 211 176 C 210 166 226 166 225 176 C 221 171 215 171 211 176 Z" fill="${C.mustard}" stroke-width="1.2" />
      <text x="202" y="214" text-anchor="middle" ${FONT} font-size="7" fill="${INK}" stroke="none">Ruth &amp; Lucy, 1973</text>
    </g>
`;
  }
  return s;
}

const files = {
  "clue-wall-original.svg": ["the 1973 story not revisited: just the bare board with its old pin holes", communityWall("bare"), [39, 25, 332, 202]],
  "clue-wall-missing.svg": ["the 1973 story failed: one faded poster, Christmas Reading 1973", communityWall("one")],
  "clue-wall-established.svg": ["the 1973 story became a tradition: posters, fox-and-lantern drawings, Ruth and Lucy's photo", communityWall("full")],
};
for (const [name, [note, body, view]] of Object.entries(files)) {
  writeFileSync(join(OUT, name), svg(name.replace(".svg", ""), note, body, view));
  console.log("wrote", name);
}
