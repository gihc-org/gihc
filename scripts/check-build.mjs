import { access, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";

const outputDir = "_site";
const requiredFiles = [
  "index.html",
  "en/index.html",
  "404.html",
  "assets/styles.css",
  "assets/favicon.svg",
  "assets/gihc-emblem.svg",
  "assets/gihc-emblem.webp",
  "assets/gihc-og.png",
  "assets/gihc-badge-75mm.zip"
];

for (const file of requiredFiles) {
  await access(path.join(outputDir, file));
}

const index = await readFile(path.join(outputDir, "index.html"), "utf8");
const englishIndex = await readFile(path.join(outputDir, "en/index.html"), "utf8");
const notFound = await readFile(path.join(outputDir, "404.html"), "utf8");

const expectations = [
  ["dokumentets sprog", index.includes('<html lang="da">')],
  ["sidens titel", index.includes("<title>GIHC — Global Institute of Hybrid Cleverness</title>")],
  ["hero-tekst", index.includes("Foreningen for legende beredskab")],
  ["aktiviteter", index.includes("Workshops") && index.includes("Lejre") && index.includes("Spil")],
  ["downloadlink", index.includes('href="/assets/gihc-badge-75mm.zip"')],
  ["e-mailkontakt", index.includes("mailto:kristian.n.jensen@gmail.com")],
  ["telefonkontakt", index.includes("tel:+4552699443")],
  ["dansk sprogskift", index.includes('href="/en/"') && index.includes('hreflang="en"')],
  ["engelsk sprogkode", englishIndex.includes('<html lang="en">')],
  ["engelsk hero", englishIndex.includes("The association for playful preparedness")],
  ["engelsk indhold", englishIndex.includes("Four ways to") && englishIndex.includes("Without internet")],
  ["socialt previewbillede", index.includes('property="og:image" content="https://gihc.online/assets/gihc-og.png"') && index.includes('property="og:image:type" content="image/png"') && index.includes('property="og:image:width" content="1200"') && index.includes('property="og:image:height" content="630"')],
  ["Twitter-previewbillede", index.includes('name="twitter:image" content="https://gihc.online/assets/gihc-og.png"') && englishIndex.includes('name="twitter:image" content="https://gihc.online/assets/gihc-og.png"')],
  ["engelsk sprogskift", englishIndex.includes('href="/"') && englishIndex.includes('hreflang="da"')],
  ["sprogalternativer", index.includes('hreflang="x-default"') && englishIndex.includes('hreflang="x-default"')],
  ["404-indhold", notFound.includes("Denne sti fører ikke hjem. Endnu.")],
  ["ingen Nunjucks-rester", !index.includes("{{") && !index.includes("{%") && !englishIndex.includes("{{") && !englishIndex.includes("{%")]
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

for (const match of englishIndex.matchAll(/(?:href|src)="(\/[^"#?]+)"/g)) {
  const target = match[1];
  if (target === "/" || target === "/en/") continue;
  if (!existsSync(path.join(outputDir, target))) {
    throw new Error(`Broken local URL in English HTML: ${target}`);
  }
}

const zip = await readFile(path.join(outputDir, "assets/gihc-badge-75mm.zip"));
if (zip[0] !== 0x50 || zip[1] !== 0x4b) {
  throw new Error("Badge download is not a ZIP file");
}

const socialImage = await readFile(path.join(outputDir, "assets/gihc-og.png"));
const pngSignature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
if (!socialImage.subarray(0, pngSignature.length).equals(pngSignature)) {
  throw new Error("Open Graph image is not a PNG file");
}
const width = socialImage.readUInt32BE(16);
const height = socialImage.readUInt32BE(20);
if (width !== 1200 || height !== 630) {
  throw new Error(`Open Graph image has unexpected dimensions: ${width}x${height}`);
}

console.log("PASS: Eleventy build, dansk og engelsk indhold, links og assets er OK");

