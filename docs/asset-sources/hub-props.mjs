// Builds the pictures for the three present-day hub props, one per state of the
// foundation each one shows (Content.Clues hubProp):
//
//   clue-roof-<state>.svg        RoofAndShelves, from world.premises (1950)
//   clue-wall-<state>.svg        CommunityWall,  from world.tradition (1973)
//   clue-desk-<state>.svg        OrderDesk,      from world.onlineService (1998)
//
// where <state> is original (NotRevisited), missing (Missing) or established
// (Established). Each picture shows exactly what its text says.
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

const svg = (name, note, body) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
  <!-- ${name}: ${note}. Built by docs/asset-sources/hub-props.mjs -->
  <g stroke="${INK}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">
${body}
  </g>
</svg>
`;

// A row of book spines standing on a shelf top at y, from x0 to x1.
function books(x0, x1, y, { lean = 0, gaps = [], seed = 1 } = {}) {
  const colours = [C.wine, C.teal, C.mustard, C.green, C.periwinkle, C.vermilion, BROWN, C.olive];
  let out = "", x = x0, i = seed;
  while (x < x1 - 10) {
    const w = 10 + ((i * 7) % 6), h = 34 + ((i * 13) % 14);
    if (!gaps.some(([a, b]) => x >= a && x <= b)) {
      const tilt = lean && i % 5 === 0 ? ` transform="rotate(${lean} ${x} ${y})"` : "";
      out += `    <rect x="${x}" y="${y - h}" width="${w}" height="${h}" fill="${colours[i % colours.length]}" stroke-width="1.5"${tilt} />\n`;
    }
    x += w + 1;
    i += 1;
  }
  return out;
}

// ── Roof and shelves (1950) ────────────────────────────────────────────────
function roofRoom({ stain, sag, makeshift, bucket, archive }) {
  // Ceiling, wall, floor.
  let s = `    <rect x="0" y="0" width="${W}" height="70" fill="${GREY}" />
    <rect x="0" y="70" width="${W}" height="200" fill="${CREAM}" />
    <rect x="0" y="270" width="${W}" height="30" fill="${BROWN}" />
    <path d="M 0 70 L ${W} 70" />
`;
  if (stain === "patched") {
    s += `    <!-- Walter's patch, still sound -->
    <path d="M 150 14 L 300 10 L 302 30 L 152 34 Z" fill="${TAN}" />
    <path d="M 152 34 L 302 30 L 304 50 L 154 54 Z" fill="#b97a3a" />
    <g fill="${INK}" stroke="none"><circle cx="160" cy="22" r="2" /><circle cx="292" cy="18" r="2" /><circle cx="162" cy="44" r="2" /><circle cx="294" cy="40" r="2" /></g>
`;
  } else {
    s += `    <!-- The water stain on the ceiling -->
    <path d="M 120 8 C 150 -4 200 6 230 2 C 270 -2 320 10 330 26 C 342 44 300 58 260 54 C 230 66 180 62 150 54 C 110 58 92 40 100 26 C 104 16 110 12 120 8 Z" fill="${TAN}" fill-opacity="0.55" stroke-width="1.5" />
    <path d="M 150 20 C 180 12 230 16 260 14 C 290 14 306 24 298 34 C 280 46 240 44 210 46 C 180 48 150 42 146 32 Z" fill="${BROWN}" fill-opacity="0.35" stroke="none" />
    <path d="M 160 62 C 156 70 156 74 160 76 C 164 74 164 70 160 62 Z" fill="${C.periwinkle}" stroke-width="1.5" />
    <path d="M 160 112 C 156 120 156 124 160 126 C 164 124 164 120 160 112 Z" fill="${C.periwinkle}" stroke-width="1.5" />
`;
  }
  // The archive door on the left.
  s += `    <!-- The back-room archive -->
    <rect x="30" y="110" width="90" height="160" fill="${archive === "open" ? "#3f2c1c" : BROWN}" />
    <rect x="18" y="98" width="114" height="16" fill="${TAN}" />
    <text x="75" y="111" text-anchor="middle" ${FONT} font-size="11" font-weight="bold" fill="${INK}" stroke="none" letter-spacing="1">ARCHIVE</text>
`;
  if (archive === "open") {
    s += `    <g stroke-width="1.5">
      <rect x="40" y="150" width="34" height="26" fill="${TAN}" /><rect x="76" y="150" width="34" height="26" fill="${TAN}" />
      <rect x="40" y="180" width="34" height="26" fill="${TAN}" /><rect x="76" y="180" width="34" height="26" fill="${TAN}" />
      <rect x="40" y="210" width="34" height="26" fill="${TAN}" /><rect x="76" y="210" width="34" height="26" fill="${TAN}" />
      <rect x="40" y="240" width="34" height="26" fill="${TAN}" /><rect x="76" y="240" width="34" height="26" fill="${TAN}" />
    </g>
    <g fill="${CREAM}" stroke-width="1"><rect x="50" y="158" width="14" height="8" /><rect x="86" y="158" width="14" height="8" /><rect x="50" y="188" width="14" height="8" /><rect x="86" y="218" width="14" height="8" /><rect x="50" y="248" width="14" height="8" /></g>
`;
  } else if (archive === "lost") {
    s += `    <circle cx="106" cy="196" r="4" fill="${C.mustard}" />
    <g fill="${C.green}" fill-opacity="0.6" stroke="none"><circle cx="48" cy="140" r="9" /><circle cx="62" cy="150" r="6" /><circle cx="96" cy="236" r="10" /><circle cx="82" cy="250" r="7" /><circle cx="44" cy="226" r="5" /></g>
    <path d="M 22 150 L 128 210 M 22 214 L 128 150" stroke="${TAN}" stroke-width="9" />
    <path d="M 22 150 L 128 210 M 22 214 L 128 150" stroke-width="1.5" fill="none" />
`;
  } else {
    s += `    <circle cx="106" cy="196" r="4" fill="${C.mustard}" />
    <g fill="${C.green}" fill-opacity="0.5" stroke="none"><circle cx="50" cy="132" r="7" /><circle cx="60" cy="142" r="4" /><circle cx="94" cy="246" r="8" /></g>
`;
  }
  // Shelves on the right.
  if (makeshift) {
    s += `    <!-- Makeshift shelves: planks on bricks -->
    <g fill="${C.vermilion}" stroke-width="1.5">
      <rect x="200" y="250" width="22" height="20" /><rect x="400" y="250" width="22" height="20" />
      <rect x="208" y="196" width="22" height="20" /><rect x="392" y="196" width="22" height="20" />
    </g>
    <path d="M 192 238 L 432 246 L 432 254 L 192 246 Z" fill="${TAN}" />
    <path d="M 200 186 L 424 180 L 424 188 L 200 194 Z" fill="${TAN}" />
${books(210, 300, 240, { seed: 3 })}${books(330, 420, 244, { seed: 9, gaps: [[360, 384]] })}${books(220, 290, 187, { seed: 5 })}
`;
  } else {
    const plank = (y) =>
      sag
        ? `    <path d="M 190 ${y} C 260 ${y + 16} 360 ${y + 16} 430 ${y} L 430 ${y + 8} C 360 ${y + 24} 260 ${y + 24} 190 ${y + 8} Z" fill="${TAN}" />\n`
        : `    <rect x="190" y="${y}" width="240" height="8" fill="${TAN}" />\n`;
    s += `    <!-- Bookcase -->
    <rect x="180" y="84" width="260" height="186" fill="${BROWN}" />
    <rect x="190" y="92" width="240" height="170" fill="#3f2c1c" />
`;
    if (sag) {
      s += `${books(196, 240, 150, { seed: 2 })}${books(370, 424, 150, { seed: 6 })}${books(200, 300, 216, { seed: 4, gaps: [[236, 270]] })}`;
    } else {
      s += `${books(194, 428, 140, { seed: 1, lean: -8 })}${books(194, 428, 196, { seed: 4, lean: 6 })}${books(194, 428, 254, { seed: 7 })}`;
    }
    s += plank(140) + plank(196) + plank(254);
  }
  if (bucket) {
    s += `    <!-- A bucket under the drip -->
    <path d="M 138 236 L 182 236 L 176 270 L 144 270 Z" fill="#7c8486" />
    <path d="M 140 238 C 144 222 176 222 180 238" fill="none" />
    <path d="M 142 242 L 178 242" stroke="${C.periwinkle}" stroke-width="3" />
`;
  }
  return s;
}

// ── Community wall (1973) ──────────────────────────────────────────────────
function communityWall(kind) {
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

// ── Order desk (1998) ──────────────────────────────────────────────────────
function orderDesk(kind) {
  const on = kind === "busy";
  let s = `    <rect x="0" y="0" width="${W}" height="232" fill="${CREAM}" />
    <rect x="0" y="232" width="${W}" height="68" fill="${BROWN}" />
`;
  if (on) {
    s += `    <!-- The first email, framed on the wall -->
    <rect x="296" y="8" width="158" height="72" fill="${TAN}" />
    <rect x="305" y="16" width="140" height="56" fill="#fbf6ea" stroke-width="1.5" />
    <path d="M 314 26 L 364 26" fill="none" stroke="${GREY}" stroke-width="3" />
    <text x="375" y="46" text-anchor="middle" ${FONT} font-size="12" font-style="italic" fill="${INK}" stroke="none">“You found</text>
    <text x="375" y="62" text-anchor="middle" ${FONT} font-size="12" font-style="italic" fill="${INK}" stroke="none">Lucy’s book!”</text>
`;
  }
  // Desk.
  s += `    <!-- The desk -->
    <rect x="30" y="170" width="420" height="20" fill="${TAN}" />
    <rect x="44" y="190" width="160" height="80" fill="${BROWN}" />
    <rect x="390" y="190" width="40" height="80" fill="${BROWN}" />
`;
  if (kind === "drawer") {
    s += `    <!-- The drawer pulled open, one printed email inside -->
    <rect x="44" y="196" width="160" height="30" fill="#3f2c1c" />
    <path d="M 36 214 L 214 214 L 220 246 L 30 246 Z" fill="${TAN}" />
    <path d="M 70 230 L 84 196 L 168 200 L 160 232 Z" fill="#fbf6ea" stroke-width="1.5" />
    <path d="M 92 206 L 150 209 M 90 214 L 140 216 M 88 222 L 146 225" fill="none" stroke="${GREY}" stroke-width="2.5" />
    <rect x="114" y="236" width="20" height="5" fill="${C.mustard}" stroke-width="1" />
`;
  } else {
    s += `    <rect x="54" y="200" width="140" height="26" fill="${BROWN}" /><rect x="110" y="210" width="28" height="6" fill="${C.mustard}" stroke-width="1" />
    <rect x="54" y="234" width="140" height="26" fill="${BROWN}" /><rect x="110" y="244" width="28" height="6" fill="${C.mustard}" stroke-width="1" />
`;
  }
  // Old computer.
  s += `    <!-- The computer -->
    <rect x="80" y="70" width="130" height="100" rx="6" fill="${GREY}" />
    <rect x="94" y="82" width="102" height="72" rx="4" fill="${on ? C.teal : "#2f3533"}" />
    <rect x="70" y="160" width="150" height="12" fill="${GREY}" />
`;
  if (on) {
    s += `    <path d="M 104 96 L 168 96 M 104 108 L 184 108 M 104 120 L 150 120 M 104 132 L 176 132" fill="none" stroke="${CREAM}" stroke-width="3" />
    <!-- The printer, full of orders -->
    <rect x="232" y="126" width="80" height="44" rx="3" fill="${GREY}" />
    <path d="M 246 126 L 250 94 L 296 94 L 298 126" fill="#fbf6ea" stroke-width="1.5" />
    <path d="M 256 104 L 288 104 M 256 112 L 282 112" fill="none" stroke="${GREY}" stroke-width="2" />
    <path d="M 240 150 L 304 150" fill="none" />
    <!-- Parcels with labels for three countries -->
    <g>
      <rect x="320" y="122" width="62" height="48" fill="${TAN}" /><rect x="330" y="134" width="42" height="20" fill="#fbf6ea" stroke-width="1.2" />
      <rect x="388" y="136" width="54" height="34" fill="${TAN}" /><rect x="393" y="144" width="40" height="16" fill="#fbf6ea" stroke-width="1.2" />
      <rect x="340" y="88" width="56" height="34" fill="${TAN}" /><rect x="350" y="96" width="32" height="16" fill="#fbf6ea" stroke-width="1.2" />
      <path d="M 368 88 L 368 96 M 368 112 L 368 122 M 320 128 L 382 128 M 434 136 L 434 170" fill="none" stroke="${C.wine}" stroke-width="2" />
    </g>
    <g ${FONT} font-size="7.5" fill="${INK}" stroke="none" text-anchor="middle"><text x="351" y="147">FRANCE</text><text x="413" y="155">CANADA</text><text x="366" y="107">JAPAN</text></g>
`;
  } else {
    s += `    <path d="M 108 92 L 126 92" fill="none" stroke="#4a5150" stroke-width="3" />
`;
  }
  return s;
}

const files = {
  "clue-roof-original.svg": ["the 1950 repairs not revisited: a spreading water stain, sagging shelves, a damp archive", roofRoom({ stain: "stain", sag: true, archive: "damp" })],
  "clue-roof-missing.svg": ["the 1950 repairs failed: stained ceiling, makeshift shelves, the archive lost to damp", roofRoom({ stain: "stain", makeshift: true, bucket: true, archive: "lost" })],
  "clue-roof-established.svg": ["the 1950 repairs held: a sound patched roof, straight full shelves, a dry full archive", roofRoom({ stain: "patched", archive: "open" })],
  "clue-wall-original.svg": ["the 1973 story not revisited: a bare board by the children's corner, only pin holes", communityWall("bare")],
  "clue-wall-missing.svg": ["the 1973 story failed: one faded poster, Christmas Reading 1973", communityWall("one")],
  "clue-wall-established.svg": ["the 1973 story became a tradition: posters, fox-and-lantern drawings, Ruth and Lucy's photo", communityWall("full")],
  "clue-desk-original.svg": ["1998 not revisited: an empty desk and an old computer, no parcels", orderDesk("empty")],
  "clue-desk-missing.svg": ["1998 failed: one printed email in the open drawer, no parcels", orderDesk("drawer")],
  "clue-desk-established.svg": ["1998 succeeded: parcels for three countries, a printer full of orders, the framed first email", orderDesk("busy")],
};
for (const [name, [note, body]] of Object.entries(files)) {
  writeFileSync(join(OUT, name), svg(name.replace(".svg", ""), note, body));
  console.log("wrote", name);
}
