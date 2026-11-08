// Cross-platform build (Mac/Windows/Linux). Only uses Node's standard library.
//
//   npm run build                 -> build/ (dev build, Debug allowed)
//   npm run build -- --optimize   -> build/ (release build; fails while Debug.todo stubs remain)
//
// Output layout (build/ is git-ignored and recreated every time):
//   build/elm.js       compiled Elm (module Main)
//   build/...          everything in public/ copied as-is (index.html, styles.css, assets/)
//   build/index.html   fallback page, written only when public/index.html does not exist yet

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
export const outDir = path.join(root, "build");
const publicDir = path.join(root, "public");

function elmBinary() {
  // Same lookup as the official `elm` npm package, without needing a shell on Windows.
  const require = createRequire(path.join(root, "package.json"));
  const file = process.platform === "win32" ? "elm.exe" : "elm";
  try {
    return require.resolve(`@elm_binaries/${process.platform}_${process.arch}/${file}`);
  } catch {
    return file; // fall back to an `elm` on PATH
  }
}

const fallbackIndex = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Christmas Rewrite</title>
</head>
<body>
  <!-- Temporary page written by scripts/build.mjs. Person B's public/index.html replaces it. -->
  <div id="app"></div>
  <script src="elm.js"></script>
  <script>Elm.Main.init({ node: document.getElementById("app") });</script>
</body>
</html>
`;

export function build({ optimize = false } = {}) {
  fs.rmSync(outDir, { recursive: true, force: true });
  fs.mkdirSync(outDir, { recursive: true });

  // Fixtures.elm and every Rules module are type-checked by `npm test`.
  const args = ["make", "src/Main.elm", "--output=" + path.join("build", "elm.js")];
  if (optimize) args.push("--optimize");

  const result = spawnSync(elmBinary(), args, { cwd: root, encoding: "utf8" });
  const output = [result.stdout, result.stderr, result.error ? String(result.error) : ""]
    .filter(Boolean)
    .join("\n");
  const ok = result.status === 0;

  if (fs.existsSync(publicDir)) {
    fs.cpSync(publicDir, outDir, { recursive: true });
  }
  if (!fs.existsSync(path.join(outDir, "index.html"))) {
    fs.writeFileSync(path.join(outDir, "index.html"), fallbackIndex);
  }
  return { ok, output };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const { ok, output } = build({ optimize: process.argv.includes("--optimize") });
  process.stdout.write(output);
  if (ok) console.log("\nBuilt into build/ — open build/index.html or run `npm start`.");
  process.exit(ok ? 0 : 1);
}
