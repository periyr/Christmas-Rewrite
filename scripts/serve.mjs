// Local preview server (Mac/Windows/Linux), standard library only.
//
//   npm start                 -> http://localhost:8000
//   PORT=9000 npm start       (Windows PowerShell: $env:PORT=9000; npm start)
//
// Every time the page itself is requested (reload the browser), the project is
// rebuilt into build/. Compile errors are shown in the browser instead of the game.

import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { build, outDir } from "./build.mjs";

const port = Number(process.env.PORT) || 8000;

const types = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".gif": "image/gif",
  ".mp3": "audio/mpeg",
  ".ogg": "audio/ogg",
  ".wav": "audio/wav",
  ".woff2": "font/woff2",
  ".ico": "image/x-icon",
};

const escapeHtml = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;");

http
  .createServer((req, res) => {
    const urlPath = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
    const isPage = urlPath === "/" || urlPath === "/index.html";

    if (isPage) {
      const { ok, output } = build();
      if (!ok) {
        res.writeHead(500, { "Content-Type": "text/html; charset=utf-8" });
        res.end(`<!doctype html><title>Compile error</title><pre style="white-space:pre-wrap;font:14px monospace;padding:1em">${escapeHtml(output)}</pre>`);
        console.log("Compile failed:\n" + output);
        return;
      }
    }

    const file = path.join(outDir, isPage ? "index.html" : urlPath);
    if (!file.startsWith(outDir) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
      res.writeHead(404, { "Content-Type": "text/plain" });
      res.end("Not found");
      return;
    }
    res.writeHead(200, {
      "Content-Type": types[path.extname(file).toLowerCase()] || "application/octet-stream",
      "Cache-Control": "no-store",
    });
    fs.createReadStream(file).pipe(res);
  })
  .listen(port, () => {
    console.log(`One More Christmas preview: http://localhost:${port}  (reload to rebuild, Ctrl+C to stop)`);
  });
