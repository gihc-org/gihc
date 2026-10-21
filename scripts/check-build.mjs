import { access, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";

const outputDir = "_site";
const requiredFiles = [
  "index.html",
  "404.html",
  "assets/styles.css",
  "assets/favicon.svg",
  "assets/gihc-emblem.svg",
  "assets/gihc-emblem.webp",
  "assets/gihc-badge-75mm.zip"
];

for (const file of requiredFiles) {
  await access(path.join(outputDir, file));
}

const index = await readFile(path.join(outputDir, "index.html"), "utf8");
const notFound = await readFile(path.join(outputDir, "404.html"), "utf8");

const expectations = [
  ["dokumentets sprog", index.includes('<html lang="da">')],
  ["sidens titel", index.includes("<title>GIHC — Global Institute of Hybrid Cleverness</title>")],
  ["hero-tekst", index.includes("Foreningen for legende beredskab")],
  ["aktiviteter", index.includes("Workshops") && index.includes("Lejre") && index.includes("Spil")],
  ["downloadlink", index.includes('href="/assets/gihc-badge-75mm.zip"')],
  ["e-mailkontakt", index.includes("mailto:kristian.n.jensen@gmail.com")],
  ["telefonkontakt", index.includes("tel:+4552699443")],
  ["404-indhold", notFound.includes("Denne sti fører ikke hjem. Endnu.")],
  ["ingen Nunjucks-rester", !index.includes("{{") && !index.includes("{%")]
];

for (const [label, passed] of expectations) {
  if (!passed) {
    throw new Error(`Build check failed: ${label}`);
  }
}

const ids = [...index.matchAll(/\sid="([^"]+)"/g)].map((match) => match[1]);
const duplicateIds = ids.filter((id, index) => ids.indexOf(id) !== index);
if (duplicateIds.length > 0) {
  throw new Error(`Duplicate HTML ids: ${[...new Set(duplicateIds)].join(", ")}`);
}

for (const match of index.matchAll(/(?:href|src)="(\/[^"#?]+)"/g)) {
  const target = match[1];
  if (target === "/") continue;
  if (!existsSync(path.join(outputDir, target))) {
    throw new Error(`Broken local URL in generated HTML: ${target}`);
  }
}

const zip = await readFile(path.join(outputDir, "assets/gihc-badge-75mm.zip"));
if (zip[0] !== 0x50 || zip[1] !== 0x4b) {
  throw new Error("Badge download is not a ZIP file");
}

console.log("PASS: Eleventy build, HTML-indhold, links og assets er OK");

