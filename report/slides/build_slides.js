// report/slides/build_slides.js -------------------------------------------------
// Builds the project deck, report/slides/group3_project_slides.pptx, from the
// pipeline's figures. Numbers are typed from report/report.docx as rendered on
// 2026-11-10; rebuild (and recheck them) after any rerun that moves a number.
// The appendix numbers come from the bonus-track branch
// claude/score-a6-calibration-3fcbb3 (data/output/tables/score_calibration.csv),
// which is never merged into master.
//
//   cd report/slides && npm install && node build_slides.js

const fs = require("fs");
const path = require("path");
const pptxgen = require("pptxgenjs");

const ROOT = path.resolve(__dirname, "..", "..");
const FIG = (name) => path.join(ROOT, "data", "output", "figures", name);
const OUT = path.join(__dirname, "group3_project_slides.pptx");

// --- palette: map blue and LISA terracotta match the pipeline's figures -------
const NAVY = "0F3B47", INK = "1A1F2B", MUTED = "5B6670", TINT = "EEF3F5";
const BLUE = "1F6FB2", TERRA = "C2410C", TEAL = "0F766E", LINE = "D5DDE2";
const PALE = "CFE0EA", WHITE = "FFFFFF";
const HEAD = "Cambria", BODY = "Calibri";

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE";                       // 13.333 x 7.5 in
pres.theme = { headFontFace: HEAD, bodyFontFace: BODY };
pres.title = "Whose 15-Minute City?";
pres.author = "TBA4220 Group 3 (Metropolitans)";
const S = pres.shapes;

// --- layouts -----------------------------------------------------------------
const FOOTER = "TBA4220 Group 3  ·  Whose 15-minute city?";
pres.defineSlideMaster({
  title: "TITLE", background: { color: NAVY },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.8, y: 1.9, w: 11.7, h: 1.5,
      fontFace: HEAD, fontSize: 48, bold: true, color: WHITE, valign: "bottom", align: "left", margin: 0 }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: 0.8, y: 3.6, w: 11.7, h: 1.0,
      fontFace: BODY, fontSize: 22, color: PALE, valign: "top", margin: 0 }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "SECTION", background: { color: NAVY },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 2.3, y: 2.6, w: 10.2, h: 1.3,
      fontFace: HEAD, fontSize: 40, bold: true, color: WHITE, valign: "bottom", align: "left", margin: 0 }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: 2.3, y: 4.05, w: 10.2, h: 1.4,
      fontFace: BODY, fontSize: 20, color: PALE, valign: "top", margin: 0 }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "CONTENT", background: { color: WHITE },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.35, w: 12.13, h: 0.85,
      fontFace: HEAD, fontSize: 32, bold: true, color: NAVY, valign: "middle", align: "left", margin: 0 }, text: "" } },
    { text: { text: FOOTER, options: { x: 0.6, y: 7.0, w: 8, h: 0.3, fontFace: BODY, fontSize: 10, color: MUTED, margin: 0 } } },
  ],
  slideNumber: { x: 12.23, y: 7.0, w: 0.5, h: 0.3, fontFace: BODY, fontSize: 10, color: MUTED, align: "right" },
});
pres.defineSlideMaster({
  title: "DARK", background: { color: NAVY },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.35, w: 12.13, h: 0.85,
      fontFace: HEAD, fontSize: 32, bold: true, color: WHITE, valign: "middle", align: "left", margin: 0 }, text: "" } },
  ],
  slideNumber: { x: 12.23, y: 7.0, w: 0.5, h: 0.3, fontFace: BODY, fontSize: 10, color: PALE, align: "right" },
});

// --- helpers -----------------------------------------------------------------
let section = "";
function newSlide(master, title, notes) {
  const s = pres.addSlide({ masterName: master, sectionTitle: section });
  if (title) s.addText(title, { placeholder: "title" });
  if (notes) s.addNotes(notes);
  return s;
}
function startSection(title) { section = title; pres.addSection({ title }); }

function text(s, t, o) { s.addText(t, Object.assign({ isTextBox: true, fontFace: BODY, color: INK, valign: "top", margin: 0 }, o)); }

function badge(s, x, y, label, color, d = 0.46) {
  s.addShape(S.OVAL, { x, y, w: d, h: d, fill: { color }, line: { color, width: 0 } });
  text(s, String(label), { x, y, w: d, h: d, fontSize: 15, bold: true, color: WHITE, align: "center", valign: "middle" });
}

// A tinted card with a numbered badge, a bold heading and body text.
function card(s, x, y, w, h, o) {
  s.addShape(S.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.08, fill: { color: o.fill || TINT }, line: { color: o.fill || TINT, width: 0 } });
  let top = y + 0.22;
  if (o.badge !== undefined) { badge(s, x + 0.22, top, o.badge, o.color || NAVY); top += 0.6; }
  const titleH = o.titleH || 0.4;
  text(s, o.title, { x: x + 0.22, y: top, w: w - 0.44, h: titleH, fontSize: o.titleSize || 16, bold: true, color: o.titleColor || NAVY });
  if (o.body) text(s, o.body, { x: x + 0.22, y: top + titleH + 0.08, w: w - 0.44, h: y + h - (top + titleH + 0.08) - 0.15,
    fontSize: o.bodySize || 14, color: INK, paraSpaceAfter: 4 });
}

// Numbered steps left to right, with an arrow between each pair.
function flow(s, steps, x0, y, totalW, h, o = {}) {
  const gap = 0.36, n = steps.length, w = (totalW - gap * (n - 1)) / n;
  steps.forEach((st, i) => {
    const x = x0 + i * (w + gap);
    card(s, x, y, w, h, { badge: i + 1, color: st.color || o.color || NAVY, title: st.title, body: st.body,
      titleH: o.titleH || 0.75, bodySize: o.bodySize });
    if (i < n - 1) s.addShape(S.ISOSCELES_TRIANGLE,
      { x: x + w + 0.1, y: y + h / 2 - 0.12, w: 0.16, h: 0.24, rotate: 90, fill: { color: MUTED }, line: { color: MUTED, width: 0 } });
  });
}

// Big number with a small label under it.
function stat(s, x, y, w, value, label, color = NAVY, size = 40) {
  text(s, value, { x, y, w, h: size / 60, fontSize: size, bold: true, color, fontFace: HEAD });
  text(s, label, { x, y: y + size / 60 + 0.05, w, h: 0.6, fontSize: 14, color: MUTED });
}

function bullets(s, items, x, y, w, h, size = 16) {
  s.addText(items.map((t, i) => {
    const runs = Array.isArray(t) ? t : [{ text: t }];
    return runs.map((r, j) => ({ text: r.text, options: Object.assign({ bullet: j === 0 ? { indent: 16 } : undefined,
      breakLine: j === runs.length - 1 && i < items.length - 1, paraSpaceAfter: 8 }, r.options || {}) }));
  }).flat(), { x, y, w, h, isTextBox: true, fontFace: BODY, fontSize: size, color: INK, valign: "top", margin: 0 });
}

// Picture with alt text, scaled to fit a box, keeping its aspect ratio (PNG size from the IHDR header).
function picture(s, file, alt, x, y, maxW, maxH, align = "center") {
  const b = fs.readFileSync(file), pw = b.readUInt32BE(16), ph = b.readUInt32BE(20);
  const k = Math.min(maxW / pw, maxH / ph), w = pw * k, h = ph * k;
  const dx = align === "left" ? 0 : (maxW - w) / 2;
  s.addImage({ path: file, altText: alt, x: x + dx, y: y + (maxH - h) / 2, w, h });
}

const AXIS = { catAxisLabelColor: MUTED, valAxisLabelColor: MUTED, catAxisLabelFontSize: 12, valAxisLabelFontSize: 11,
  catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt", dataLabelFontFace: "+mn-lt", dataLabelFontSize: 12,
  dataLabelColor: INK, legendFontFace: "+mn-lt", legendFontSize: 12, legendColor: INK, titleFontFace: "+mn-lt",
  titleFontSize: 14, titleColor: NAVY, catAxisLineShow: false, valAxisLineShow: false };
const grid = () => ({ valGridLine: { color: LINE, size: 0.5 }, catGridLine: { style: "none" } });

// --- title and roadmap ---------------------------------------------------------
startSection("Introduction");
let s = newSlide("TITLE", "Whose 15-Minute City?",
  "Walkable access to everyday services in Singapore, and whether it differs between towns planned in different eras.");
s.addText("Walkable access to everyday services in Singapore's residential subzones", { placeholder: "body" });
text(s, "TBA4220 Geospatial Analysis  ·  Group 3 (Metropolitans)", { x: 0.8, y: 5.4, w: 11.7, h: 0.4, fontSize: 16, color: WHITE, bold: true });
text(s, "Qu Haotian  ·  Hew Xing Yi  ·  Zachary Chng Yao Wei  ·  Coltrane Yao Zhiming", { x: 0.8, y: 5.85, w: 11.7, h: 0.4, fontSize: 16, color: PALE });

s = newSlide("CONTENT", "One target question, built from three analyses",
  "Singapore's LTMP aims for 20-minute towns. We ask what kinds of neighbourhood exist by walkable access, and whether old and new HDB towns have the same ones. Q1 and Q2 each set a rule that Q3 follows.");
s.addShape(S.ROUNDED_RECTANGLE, { x: 0.6, y: 1.5, w: 5.0, h: 5.2, rectRadius: 0.08, fill: { color: NAVY }, line: { color: NAVY, width: 0 } });
text(s, "Target question", { x: 0.9, y: 1.8, w: 4.4, h: 0.4, fontSize: 16, bold: true, color: PALE });
text(s, "What kinds of neighbourhood exist in Singapore by walkable access to everyday services, and does the same set appear in towns planned in different eras?",
  { x: 0.9, y: 2.3, w: 4.4, h: 2.6, fontSize: 22, color: WHITE, fontFace: HEAD });
text(s, "Eras: HDB's mature and non-mature towns, a classification retired in 2024 and used here as a fixed historical grouping.",
  { x: 0.9, y: 5.25, w: 4.4, h: 1.2, fontSize: 14, color: PALE });
[
  ["Q1  Spatial structure", "How is each category of service structured in space?", "Sets how Q3 must resample: whole blocks, not single subzones."],
  ["Q2  Drivers", "What explains access, and how much is just density?", "Decides whether Q3 removes density first, and supplies residuals."],
  ["Q3  Types", "Which kinds exist, and do old and new towns share them?", "Answers the target question."],
].forEach(([t, q, r], i) => {
  const y = 1.5 + i * 1.8;
  s.addShape(S.ROUNDED_RECTANGLE, { x: 6.0, y, w: 6.73, h: 1.6, rectRadius: 0.08, fill: { color: TINT }, line: { color: TINT, width: 0 } });
  badge(s, 6.25, y + 0.25, i + 1, [BLUE, TEAL, TERRA][i]);
  text(s, t, { x: 6.95, y: y + 0.22, w: 5.55, h: 0.4, fontSize: 18, bold: true, color: NAVY });
  text(s, q, { x: 6.95, y: y + 0.62, w: 5.55, h: 0.45, fontSize: 15, color: INK });
  text(s, r, { x: 6.95, y: y + 1.08, w: 5.55, h: 0.4, fontSize: 14, color: MUTED, italic: true });
});

s = newSlide("CONTENT", "The pipeline runs in a fixed sequence",
  "Each stage reads only what the stages before it wrote. Rscript R/run_all.R rebuilds every output from the raw data in about 75 seconds.");
flow(s, [
  { title: "Prep data", body: "Subzones, census, OSM facilities and buildings, all in SVY21", color: NAVY },
  { title: "Access score", body: "Services within 1 km of where residents live, weighted by spending", color: BLUE },
  { title: "Coverage check", body: "How much of a complete register does OSM hold?", color: NAVY },
  { title: "Q1 Spatial", body: "Moran's I and LISA per category", color: BLUE },
  { title: "Q2 Drivers", body: "OLS, then a spatial lag model", color: TEAL },
  { title: "Q3 Types", body: "k-means, tested against chance", color: TERRA },
], 0.6, 1.55, 12.13, 3.3, { titleH: 0.7 });
text(s, "What each stage hands on", { x: 0.6, y: 5.2, w: 12.13, h: 0.4, fontSize: 16, bold: true, color: NAVY });
bullets(s, [
  [{ text: "Score → all three questions: ", options: { bold: true } }, { text: "one score per category and a composite for 201 residential subzones" }],
  [{ text: "Coverage → Q1: ", options: { bold: true } }, { text: "a per-subzone mapping-quality flag.   " }, { text: "Q1 → Q2, Q3: ", options: { bold: true } }, { text: "the neighbour network and 31 planning-area blocks" }],
  [{ text: "Q2 → Q3: ", options: { bold: true } }, { text: "the density share (cluster raw or adjusted scores?) and residuals for the under-service test" }],
], 0.6, 5.65, 12.13, 1.3, 15);

// --- part 1: the access score ------------------------------------------------
startSection("1. Access score");
s = newSlide("SECTION", "How access is measured", "Four steps turn raw layers into one score per residential subzone.");
s.addText("Four steps from open data to one score per residential subzone", { placeholder: "body" });
badge(s, 0.8, 2.95, 1, BLUE, 1.0);

s = newSlide("CONTENT", "Six open datasets feed the analysis",
  "All layers are projected to SVY21 (EPSG:3414), so distances are in metres. Every raw file is logged with its URL, download date, md5 and licence in docs/data_log.md.");
[
  ["Unit", "URA Master Plan 2019 subzones", "332 polygons; the unit of every analysis", NAVY],
  ["People", "Census of Population 2020", "Residents by subzone, age and dwelling type", BLUE],
  ["Facilities", "OpenStreetMap, 2 Nov 2026", "21,284 scored facilities and the residential buildings", TEAL],
  ["Weights", "Household Expenditure Survey 2023", "Monthly spending by category, which sets the weights", TERRA],
  ["Benchmark", "ECDA preschool register", "A near-complete list to test how much OSM misses", NAVY],
  ["Control", "URA rail station layer", "Distance from each subzone to rail, used in Q2", BLUE],
].forEach(([tag, t, b, c], i) => {
  const x = 0.6 + (i % 3) * 4.13, y = 1.55 + Math.floor(i / 3) * 2.65;
  s.addShape(S.ROUNDED_RECTANGLE, { x, y, w: 3.87, h: 2.4, rectRadius: 0.08, fill: { color: TINT }, line: { color: TINT, width: 0 } });
  s.addShape(S.ROUNDED_RECTANGLE, { x: x + 0.25, y: y + 0.25, w: 1.35, h: 0.38, rectRadius: 0.19, fill: { color: c }, line: { color: c, width: 0 } });
  text(s, tag, { x: x + 0.25, y: y + 0.25, w: 1.35, h: 0.38, fontSize: 13, bold: true, color: WHITE, align: "center", valign: "middle" });
  text(s, t, { x: x + 0.25, y: y + 0.85, w: 3.37, h: 0.7, fontSize: 18, bold: true, color: NAVY });
  text(s, b, { x: x + 0.25, y: y + 1.55, w: 3.37, h: 0.75, fontSize: 14, color: INK });
});

s = newSlide("CONTENT", "Steps 1–2: residential subzones and their centres",
  "A polygon centroid can fall in a reservoir or outside an L-shaped subzone, so the centre is weighted by where the residential floor area actually is.");
badge(s, 0.6, 1.6, 1, BLUE);
text(s, "Keep subzones with at least 1,000 residents", { x: 1.2, y: 1.6, w: 4.4, h: 0.46, fontSize: 17, bold: true, color: NAVY, valign: "middle" });
stat(s, 1.2, 2.2, 2.3, "201", "of 332 subzones kept", BLUE);
stat(s, 3.5, 2.2, 2.3, "99.65%", "of all residents", BLUE);
text(s, "Airports, reservoirs, ports and industrial estates drop out.", { x: 1.2, y: 3.5, w: 4.4, h: 0.4, fontSize: 14, color: MUTED });
badge(s, 0.6, 4.2, 2, BLUE);
text(s, "Centre on where residents live", { x: 1.2, y: 4.2, w: 4.4, h: 0.46, fontSize: 17, bold: true, color: NAVY, valign: "middle" });
text(s, "Each subzone's centre is the floor-area-weighted mean of its OSM residential buildings (footprint × storeys). Worker dormitories are excluded, since the census counts only residents.",
  { x: 1.2, y: 4.8, w: 4.4, h: 1.8, fontSize: 15 });
picture(s, FIG("score_centres_map.png"), "Map of the subzone centres used for the 1 km count", 5.9, 1.45, 6.83, 5.35);

s = newSlide("CONTENT", "Step 3: count services within 1 km, on one scale",
  "Counts differ hugely in scale between categories, so each is log-scaled and divided by its maximum before they are combined. 1 km is a straight line: a known caveat, measured in Appendix A.");
badge(s, 0.6, 1.6, 3, BLUE);
text(s, "Count every OSM facility within 1 km (straight line) of the centre, by category", { x: 1.2, y: 1.55, w: 5.2, h: 0.75, fontSize: 17, bold: true, color: NAVY });
s.addChart(pres.charts.BAR, [{ name: "Median count within 1 km", labels: ["Recreation", "Food services", "Food retail", "Education", "Retail goods", "Health"],
  values: [59, 56, 20, 12, 11, 9] }], Object.assign({ x: 0.6, y: 2.45, w: 5.8, h: 4.3, barDir: "bar", chartColors: [BLUE],
  showValue: true, dataLabelPosition: "outEnd", showLegend: false, showTitle: true, title: "Median count per residential subzone",
  catAxisOrientation: "maxMin", valAxisHidden: true }, AXIS, grid()));
s.addShape(S.ROUNDED_RECTANGLE, { x: 6.9, y: 1.55, w: 5.83, h: 2.4, rectRadius: 0.08, fill: { color: NAVY }, line: { color: NAVY, width: 0 } });
text(s, "Category score", { x: 7.2, y: 1.8, w: 5.2, h: 0.4, fontSize: 16, bold: true, color: PALE });
text(s, "100 × log(1 + count) / max", { x: 7.2, y: 2.3, w: 5.2, h: 0.7, fontSize: 28, bold: true, color: WHITE, fontFace: HEAD });
text(s, "max = the highest log count over the 201 residential subzones, so every category runs 0–100.", { x: 7.2, y: 3.05, w: 5.3, h: 0.7, fontSize: 14, color: PALE });
bullets(s, [
  "Six categories from a published OSM tag lookup, which also writes the download queries",
  "21,284 scored facilities; hospitals, private facilities and alcohol outlets are not scored",
  "A median of 56 food outlets against 9 health facilities, so each category gets its own 0–100 scale",
], 6.9, 4.25, 5.83, 2.5, 15);

s = newSlide("CONTENT", "Step 4: weight each category by household spending",
  "Weights are each category's share of 2023 household spending. Composite = sum of weight × category score.");
badge(s, 0.6, 1.6, 4, BLUE);
text(s, "Composite = Σ weight × category score", { x: 1.2, y: 1.6, w: 5.6, h: 0.46, fontSize: 17, bold: true, color: NAVY, valign: "middle" });
s.addChart(pres.charts.BAR, [{ name: "Weight", labels: ["Food services", "Retail goods", "Health", "Food retail", "Education", "Recreation"],
  values: [0.308, 0.161, 0.151, 0.145, 0.129, 0.107] }], Object.assign({ x: 0.6, y: 2.3, w: 6.2, h: 4.45, barDir: "bar", chartColors: [TERRA],
  showValue: true, dataLabelPosition: "outEnd", dataLabelFormatCode: "0.0%", showLegend: false, showTitle: true,
  title: "Share of 2023 household spending (HES)", catAxisOrientation: "maxMin", valAxisHidden: true }, AXIS, grid()));
text(s, "Three caveats", { x: 7.3, y: 1.6, w: 5.4, h: 0.4, fontSize: 18, bold: true, color: NAVY });
bullets(s, [
  "Spending share is not trip frequency",
  "Spending says nothing about variety within a category, so variety is counted separately",
  "National averages: every subzone is scored on the same basket",
], 7.3, 2.1, 5.43, 2.1, 15);
s.addShape(S.ROUNDED_RECTANGLE, { x: 7.3, y: 4.4, w: 5.43, h: 2.35, rectRadius: 0.08, fill: { color: TINT }, line: { color: TINT, width: 0 } });
text(s, "Does the basket matter?", { x: 7.55, y: 4.6, w: 5.0, h: 0.4, fontSize: 16, bold: true, color: NAVY });
stat(s, 7.55, 5.05, 2.0, "0.994", "Spearman ρ with equal weights", TERRA, 36);
text(s, "Equal weights rank the subzones almost identically. The basket barely moves the ranking.", { x: 9.75, y: 5.1, w: 2.8, h: 1.5, fontSize: 14 });

s = newSlide("CONTENT", "The result: one access score per residential subzone",
  "Composite ranges 14 to 97, median 58.9. Robust to weights, less so to the radius.");
picture(s, FIG("score_composite_map.png"), "Map of the composite access score by residential subzone", 0.6, 1.4, 8.1, 5.45, "left");
stat(s, 9.1, 1.6, 3.6, "14 – 97", "composite range; median 58.9", BLUE);
text(s, "Rank agreement with the main score", { x: 9.1, y: 3.05, w: 3.63, h: 0.4, fontSize: 16, bold: true, color: NAVY });
[["Equal weights", "0.994"], ["800 m radius", "0.95"], ["1.2 km radius", "0.91"]].forEach(([k, v], i) => {
  const y = 3.55 + i * 0.6;
  s.addShape(S.RECTANGLE, { x: 9.1, y, w: 3.63, h: 0.5, fill: { color: i % 2 ? WHITE : TINT }, line: { color: TINT, width: 0 } });
  text(s, k, { x: 9.25, y, w: 2.2, h: 0.5, fontSize: 15, valign: "middle" });
  text(s, v, { x: 11.3, y, w: 1.3, h: 0.5, fontSize: 15, bold: true, align: "right", valign: "middle", color: NAVY });
});
text(s, "Single subzones move by up to 100 places when the radius changes, so read the map as a relative ranking.", { x: 9.1, y: 5.45, w: 3.63, h: 1.3, fontSize: 14, color: MUTED });

// --- part 2: coverage ----------------------------------------------------------
startSection("2. OSM coverage");
s = newSlide("SECTION", "Can we trust OpenStreetMap?", "OSM is volunteer-built, so its gaps could bias every later result.");
s.addText("A completeness check against ECDA's register of licensed preschools, before any analysis", { placeholder: "body" });
badge(s, 0.8, 2.95, 2, TEAL, 1.0);

s = newSlide("CONTENT", "Matching ECDA preschools to OSM, one to one",
  "Preschools are the one category with a near-complete official register. CHAS clinics are a supplementary benchmark only.");
flow(s, [
  { title: "ECDA register", body: "Every licensed preschool, with its address and postcode" },
  { title: "Find candidates", body: "OSM preschool within 50 m with a similar name (Jaro-Winkler) or the same postcode; unnamed within 30 m" },
  { title: "Pair one to one", body: "Hungarian algorithm picks the pairs with the best total score" },
  { title: "Check by hand", body: "Stratified sample of 160 matched and unmatched pairs, checked against OSM and operators' pages" },
  { title: "Correct recall", body: "Adjust for false matches and false misses, with Wilson intervals" },
], 0.6, 1.55, 12.13, 3.6, { color: TEAL, titleH: 0.7 });
s.addShape(S.ROUNDED_RECTANGLE, { x: 0.6, y: 5.8, w: 12.13, h: 0.9, rectRadius: 0.08, fill: { color: WHITE }, line: { color: TERRA, width: 1.25 } });
text(s, "Provisional: 29 of the 160 rows still await a Google Maps check, so the matcher error rates may still move.", { x: 0.9, y: 5.8, w: 11.6, h: 0.9, fontSize: 15, color: INK, valign: "middle" });

s = newSlide("CONTENT", "OSM holds 1 in 8 preschools, evenly across town groups",
  "Low recall, but no detectable gap between mature and non-mature towns. The score is therefore a relative measure: comparisons between subzones hold approximately, absolute counts do not.");
stat(s, 0.6, 1.5, 2.9, "9.7%", "of ECDA preschools matched (95% CI 8.5–11.1%)", NAVY);
stat(s, 3.6, 1.5, 2.9, "12.1%", "after matcher correction (9.3–21.9%)", TEAL);
stat(s, 6.6, 1.5, 2.9, "≈ 17%", "counting buildings tagged kindergarten", MUTED);
bullets(s, [
  [{ text: "No gap between town groups: ", options: { bold: true } }, { text: "90.9% vs 90.1% missed, p = 0.606; a 3.8-point gap was detectable at 80% power" }],
  [{ text: "Misses are not clustered: ", options: { bold: true } }, { text: "random labelling with cross-K, p = 0.318" }],
  [{ text: "Logistic odds ratio 0.36 ", options: { bold: true } }, { text: "for non-mature towns rests on Sengkang and Hougang; without them 0.83 (p = 0.56)" }],
  [{ text: "Uneven within groups: ", options: { bold: true } }, { text: "9 subzones mapped clearly better, 8 clearly worse (empirical-Bayes flag)" }],
], 0.6, 3.05, 6.0, 3.8, 15);
picture(s, FIG("coverage_missrate_map.png"), "Map of the share of ECDA preschools missing from OSM by subzone", 6.85, 3.0, 5.88, 3.85);
text(s, "CHAS clinics (supplementary): missed clinics do cluster, p = 0.001, so read the health category with care.", { x: 9.75, y: 1.55, w: 2.98, h: 1.3, fontSize: 14, color: MUTED });

// --- part 3: Q1 ----------------------------------------------------------------
startSection("3. Q1 Spatial structure");
s = newSlide("SECTION", "Q1: How is access structured in space?", "H₀: Moran's I = 0, for each category score and the composite.");
s.addText("H₀: Moran's I = 0, for each category score and for the composite", { placeholder: "body" });
badge(s, 0.8, 2.95, 3, BLUE, 1.0);

s = newSlide("CONTENT", "Q1 method: neighbours first, then global and local tests",
  "The network is built after dropping non-residential subzones, so a reservoir never counts as a neighbour. Q2 and Q3 reuse the same network and blocks.");
flow(s, [
  { title: "Neighbour network", body: "Queen contiguity on 201 subzones; one island linked to its nearest; 4.8 links on average; row-standardised. k = 6 nearest neighbours as a check" },
  { title: "Global Moran's I", body: "Does each category cluster across the island? 999 permutations per test, so p cannot fall below 0.001" },
  { title: "Local Moran's I (LISA)", body: "Where are the hot spots, cold spots and outliers? 9,999 conditional permutations" },
  { title: "Correct for 201 tests", body: "About 10 subzones would look significant by chance, so Benjamini-Hochberg false discovery rate, q < 0.05" },
], 0.6, 1.55, 12.13, 3.7, { color: BLUE, titleH: 0.7, bodySize: 15 });
text(s, "31 planning-area blocks (3–16 subzones each) are fixed here and reused for resampling in Q2 and Q3.", { x: 0.6, y: 5.6, w: 12.13, h: 0.5, fontSize: 15, color: MUTED });

s = newSlide("CONTENT", "Every category clusters in space",
  "Moran's I 0.47–0.57 with queen weights, every p at the 0.001 floor. H0 rejected for all seven. kNN agrees at 0.36–0.51.");
const mi = [["Food services", 0.568, 0.508], ["Retail goods", 0.5, 0.476], ["Health", 0.473, 0.413], ["Food retail", 0.535, 0.43],
  ["Education", 0.487, 0.358], ["Recreation", 0.521, 0.446], ["Composite", 0.548, 0.474]];
s.addChart(pres.charts.BAR, [
  { name: "Queen contiguity", labels: mi.map((r) => r[0]), values: mi.map((r) => r[1]) },
  { name: "6 nearest neighbours", labels: mi.map((r) => r[0]), values: mi.map((r) => r[2]) },
], Object.assign({ x: 0.6, y: 1.45, w: 7.6, h: 5.35, barDir: "col", barGrouping: "clustered", chartColors: [BLUE, PALE],
  showValue: true, dataLabelPosition: "outEnd", dataLabelFormatCode: "0.00", showLegend: true, legendPos: "b", showTitle: true,
  title: "Global Moran's I", valAxisMinVal: 0, valAxisMaxVal: 0.7, valAxisLabelFormatCode: "0.0" }, AXIS, grid()));
stat(s, 8.7, 1.6, 4.0, "0.47 – 0.57", "Moran's I, queen weights (composite 0.55)", BLUE);
bullets(s, [
  "H₀ rejected for all seven: every p sits at the 0.001 permutation floor",
  "Well-served subzones sit next to other well-served subzones",
  "The kNN check gives the same answer (0.36–0.51)",
], 8.7, 3.05, 4.03, 3.6, 16);

s = newSlide("CONTENT", "Hot spots sit in the centre, with no isolated outliers",
  "After FDR correction almost every significant subzone is High-High. No High-Low or Low-High outlier in any category.");
picture(s, FIG("q1_lisa_maps.png"), "LISA cluster maps for each category and the composite", 0.4, 1.35, 8.3, 5.5);
bullets(s, [
  [{ text: "Centre: ", options: { bold: true } }, { text: "every map has a hot spot in Kallang, Outram and Rochor (7 subzones for the composite)" }],
  [{ text: "North-east: ", options: { bold: true } }, { text: "education and recreation hot spots in Punggol, Sengkang (and Hougang), where OSM maps best: 79% of preschools missed against 90% island-wide" }],
  [{ text: "Cold spots: ", options: { bold: true } }, { text: "only recreation has some (8 Low-Low)" }],
  [{ text: "For Q3: ", options: { bold: true } }, { text: "all six categories are contiguous, so stability must be judged by resampling whole blocks" }],
], 8.9, 1.5, 3.83, 5.3, 15);

// --- part 4: Q2 ----------------------------------------------------------------
startSection("4. Q2 Drivers");
s = newSlide("SECTION", "Q2: What explains access?", "H0: elderly share and housing mix do not lower the composite score.");
s.addText("H₀: elderly share and housing mix do not lower the composite score (one-sided, coefficient ≥ 0)", { placeholder: "body" });
badge(s, 0.8, 2.95, 4, TEAL, 1.0);

s = newSlide("CONTENT", "Q2 method: from OLS to a spatial lag model",
  "Predictors are standardised, so coefficients are score points per SD. In a lag model a coefficient is not a marginal effect, so total impacts (coefficient times about 2.2) are reported.");
text(s, "Tested (one-sided)", { x: 0.6, y: 1.5, w: 3.4, h: 0.4, fontSize: 16, bold: true, color: TERRA });
bullets(s, ["Elderly share (65+)", "Housing mix: share in HDB 1–3 room flats, an income proxy"], 0.6, 1.95, 3.4, 1.7, 15);
text(s, "Controls", { x: 0.6, y: 3.75, w: 3.4, h: 0.4, fontSize: 16, bold: true, color: NAVY });
bullets(s, ["Log population density", "Distance to the nearest rail station", "OSM mapping effort (mappers per km²)"], 0.6, 4.2, 3.4, 2.4, 15);
flow(s, [
  { title: "OLS", body: "201 subzones, 5 predictors. R² = 0.53; largest VIF 2.2" },
  { title: "Residuals cluster", body: "Moran's I 0.28, p < 0.001: errors are not independent" },
  { title: "Robust LM tests", body: "Favour lag (p < 0.001) over error (p = 0.417)" },
  { title: "Spatial lag model", body: "Lowest AIC: 1,468 vs 1,485 (error) and 1,525 (OLS); ρ = 0.54" },
], 4.3, 1.55, 8.43, 3.7, { color: TEAL, titleH: 0.7, bodySize: 15 });
text(s, "The planned spatial error model gives the same conclusion (one-sided p = 0.87 and 0.51).", { x: 4.3, y: 5.55, w: 8.43, h: 0.7, fontSize: 14, color: MUTED });

s = newSlide("CONTENT", "No equity effect; rail and density drive access",
  "Neither tested variable lowers access in any model. Distance to rail and density matter. Density explains about a third of the model, below the 0.5 threshold fixed in advance.");
const hdr = (t) => ({ text: t, options: { bold: true, color: WHITE, fill: { color: NAVY }, fontSize: 14 } });
const rows = [
  [hdr("Predictor"), hdr("OLS b"), hdr("OLS p"), hdr("Lag total impact"), hdr("Lag p")],
  ["Elderly share (65+)", "0.25", "0.595", "1.41", "0.771"],
  ["Housing mix (HDB 1–3 room)", "0.12", "0.542", "-1.12", "0.284"],
  ["Log population density", "2.29", "0.012", "5.71", "0.003"],
  ["Distance to rail", "-4.09", "< 0.001", "-7.13", "< 0.001"],
  ["OSM mapping effort", "7.58", "< 0.001", "8.75", "< 0.001"],
];
s.addTable(rows.map((r, i) => r.map((c, j) => typeof c === "string"
  ? { text: c, options: { fontSize: 14, color: INK, fill: { color: i % 2 ? WHITE : TINT }, bold: j === 0 && i <= 2, align: j ? "right" : "left" } } : c)),
  { x: 0.6, y: 1.55, w: 7.4, colW: [2.9, 1.0, 1.1, 1.4, 1.0], rowH: 0.5, fontFace: BODY, border: { type: "solid", pt: 0.5, color: LINE }, valign: "middle" });
text(s, "p is one-sided for the two tested variables (bold) and two-sided for the controls.", { x: 0.6, y: 4.7, w: 7.4, h: 0.4, fontSize: 12, color: MUTED });
bullets(s, [
  [{ text: "H₀ not rejected ", options: { bold: true } }, { text: "for either tested variable, in OLS, lag and error models. Across the six categories the smallest p is 0.031, or 0.37 after Holm" }],
  [{ text: "Mapping effort is partly mechanical: ", options: { bold: true } }, { text: "without it the elderly coefficient grows from 0.25 to 2.52, the opposite of the tested sign" }],
], 0.6, 5.2, 7.4, 1.7, 15);
s.addShape(S.ROUNDED_RECTANGLE, { x: 8.5, y: 1.55, w: 4.23, h: 5.2, rectRadius: 0.08, fill: { color: TINT }, line: { color: TINT, width: 0 } });
text(s, "How much is just density?", { x: 8.8, y: 1.8, w: 3.7, h: 0.4, fontSize: 16, bold: true, color: NAVY });
stat(s, 8.8, 2.35, 3.7, "0.32", "density's share of the model's R² (0.17 of 0.53)", TEAL, 48);
text(s, "Below the 0.5 threshold fixed in advance, so Q3 clusters on the raw category scores: a typology built on them is not just density under another name.",
  { x: 8.8, y: 3.95, w: 3.7, h: 2.0, fontSize: 15 });
text(s, "Residuals go to Q3 for the under-service test.", { x: 8.8, y: 6.0, w: 3.7, h: 0.6, fontSize: 14, color: MUTED });

// --- part 5: Q3 ----------------------------------------------------------------
startSection("5. Q3 Types");
s = newSlide("SECTION", "Q3: What kinds of neighbourhood exist?", "H0(a) type mix same in mature and non-mature towns; H0(b) type unrelated to Q2 residuals.");
s.addText("H₀(a): the type mix is the same in mature and non-mature towns\nH₀(b): type membership is unrelated to Q2's residuals", { placeholder: "body" });
badge(s, 0.8, 2.95, 5, TERRA, 1.0);

s = newSlide("CONTENT", "Q3 method: cluster, then test the clusters against chance",
  "Silhouette always picks some k of at least 2, even in data with no groups, so the chosen k is compared with structureless data. Q1's clustering means resampling and permutation work on whole blocks.");
flow(s, [
  { title: "Standardise", body: "Six category scores as z-scores, so each weighs equally" },
  { title: "k-means", body: "k chosen by the highest mean silhouette; recovers 3 planted groups in a test" },
  { title: "No-cluster null", body: "Same rule on 200 simulated datasets with the real correlations but no groups" },
  { title: "Block bootstrap", body: "Resample the 31 blocks 200 times; a group is stable if Jaccard ≥ 0.75" },
  { title: "Block permutation", body: "H₀(a): swap town labels between blocks. H₀(b): permute residuals within blocks" },
], 0.6, 1.55, 12.13, 3.6, { color: TERRA, titleH: 0.7, bodySize: 15 });
text(s, "Q2 decided the input: raw scores, since density explains less than half the model.", { x: 0.6, y: 5.5, w: 12.13, h: 0.5, fontSize: 15, color: MUTED });

s = newSlide("CONTENT", "One gradient, not distinct kinds of neighbourhood",
  "k = 2 wins the silhouette, but the real data separate no better than data with no groups. Every category is 0.5 to 0.8 SD below average at the low end: the groups differ in level, not mix.");
stat(s, 0.6, 1.5, 2.6, "p = 0.47", "silhouette 0.356 vs null mean 0.355", TERRA);
stat(s, 3.3, 1.5, 2.6, "70%", "of variation on one principal component", TERRA);
stat(s, 0.6, 3.1, 2.6, "0.92–0.93", "mean Jaccard: both halves are stable", NAVY);
stat(s, 3.3, 3.1, 2.6, "92 | 109", "subzones at the low | high end", NAVY);
text(s, "A cut through a continuum is also stable, so stability confirms a repeatable split, not distinct types.",
  { x: 0.6, y: 4.75, w: 5.3, h: 1.0, fontSize: 15 });
const cats = ["Food services", "Retail goods", "Health", "Food retail", "Education", "Recreation"];
s.addChart(pres.charts.BAR, [
  { name: "Low-access end (92)", labels: cats, values: [-0.76, -0.75, -0.83, -0.76, -0.68, -0.5] },
  { name: "High-access end (109)", labels: cats, values: [0.64, 0.63, 0.7, 0.65, 0.57, 0.42] },
], Object.assign({ x: 6.2, y: 1.45, w: 6.53, h: 5.35, barDir: "col", barGrouping: "clustered", chartColors: [BLUE, TERRA],
  showValue: true, dataLabelPosition: "outEnd", dataLabelFormatCode: "0.00", showLegend: true, legendPos: "b", showTitle: true,
  title: "Mean z-score by category", valAxisMinVal: -1, valAxisMaxVal: 1, valAxisLabelFormatCode: "0.0", catAxisLabelPos: "low" }, AXIS, grid()));

s = newSlide("CONTENT", "Old and new towns sit alike on the gradient",
  "H0(a) not rejected, though with only 26 exchangeable blocks the test has little power. H0(b) rejects by construction, so it is reported descriptively.");
picture(s, FIG("q3_types_map.png"), "Map of the low-access and high-access ends of the gradient", 0.4, 1.35, 7.4, 5.5);
card(s, 8.0, 1.5, 4.73, 3.05, { title: "H₀(a): not rejected", titleColor: TERRA, titleH: 0.4,
  body: "The low-access end holds 42.5% of mature-town and 55.7% of non-mature subzones, a 13.2-point gap. Block permutation: χ² = 2.97, p = 0.27. Only 26 blocks, so this is no evidence of a difference, not evidence of equal mixes." });
card(s, 8.0, 4.7, 4.73, 2.1, { title: "H₀(b): rejected by construction", titleH: 0.4,
  body: "Low end 6.0 points below the Q2 prediction, high end 6.3 above (F = 132.8). Groups cut by score always split the residuals." });

// --- conclusion ------------------------------------------------------------------
startSection("Conclusion");
s = newSlide("DARK", "Whose 15-minute city? One gradient, shared by all towns",
  "Neighbourhoods differ in how much lies within walking distance, more than in what kind. For planning, target the low-access end, which spans both town groups.");
text(s, "Singapore's residential subzones spread along one gradient of walkable access, on which every category rises and falls together. Older and newer towns sit alike on it.",
  { x: 0.6, y: 1.45, w: 12.13, h: 1.2, fontSize: 20, color: WHITE, fontFace: HEAD });
[
  ["Q1", "The gradient is spatial", "Every category clusters (Moran's I 0.47–0.57); hot spots in the centre; no isolated outliers", BLUE],
  ["Q2", "It is not just density", "Density is a third of the model (0.32); rail matters; no elderly or housing-mix effect", TEAL],
  ["Q3", "It has no natural break", "k = 2 separates no better than no groups (p = 0.47); town mixes do not differ (p = 0.27)", TERRA],
].forEach(([q, t, b, c], i) => {
  const x = 0.6 + i * 4.13;
  s.addShape(S.ROUNDED_RECTANGLE, { x, y: 2.95, w: 3.87, h: 2.7, rectRadius: 0.08, fill: { color: WHITE }, line: { color: WHITE, width: 0 } });
  badge(s, x + 0.25, 3.2, q, c, 0.6);
  text(s, t, { x: x + 1.0, y: 3.2, w: 2.7, h: 0.6, fontSize: 17, bold: true, color: NAVY, valign: "middle" });
  text(s, b, { x: x + 0.25, y: 4.0, w: 3.37, h: 1.5, fontSize: 15, color: INK });
});
text(s, "For planning: the useful unit is the low-access end of the gradient, which spans both town groups. Town age alone is not a reliable guide to it.",
  { x: 0.6, y: 5.95, w: 12.13, h: 0.8, fontSize: 17, color: PALE, italic: true });

s = newSlide("CONTENT", "Limitations",
  "Each limitation is stated in the report's Discussion. The straight-line caveat is examined in the appendix bonus track.");
[
  ["OpenStreetMap is incomplete", "The features the score reads hold about 12% of licensed preschools. Comparisons between subzones hold only approximately; absolute counts do not."],
  ["Straight-line distance", "Known caveat: 1 km as the crow flies, not along streets. Kept for simplicity; see Appendix A."],
  ["Mapping effort is mechanical", "Q2's control is counted from the same OSM features; we report the model with and without it."],
  ["Dates do not align", "Residents counted in 2020, facilities mapped in 2026; ECDA records carry a 2021 timestamp."],
  ["H₀(b) cannot discriminate", "Groups cut by score level always split the residuals, so it rejects by construction."],
  ["National spending weights", "No income-specific baskets, though equal weights give near-identical ranks (ρ 0.99)."],
].forEach(([t, b], i) => {
  const x = 0.6 + (i % 3) * 4.13, y = 1.5 + Math.floor(i / 3) * 2.7;
  card(s, x, y, 3.87, 2.5, { title: t, body: b, titleH: 0.45, titleColor: i === 1 ? TERRA : NAVY });
});

// --- appendix: bonus track -----------------------------------------------------------
startSection("Appendix: bonus track");
s = newSlide("SECTION", "Appendix: bonus track",
  "Outside the project scope. Answered after the project with GenAI assistance on branch claude/score-a6-calibration-3fcbb3, never merged into master and not part of the report.");
s.addText("Outside the project scope. Answered after the project with GenAI assistance; kept on its own branch, never merged into master, and not part of the report.", { placeholder: "body" });
badge(s, 0.8, 2.95, "A", MUTED, 1.0);

s = newSlide("CONTENT", "A. How far do people really walk for 1 km?",
  "198 walks from subzone centres to scored facilities were routed on the public OSRM foot server; 194 kept (4 snapped more than 100 m off the network). Detour = walking distance / straight-line distance.");
flow(s, [
  { title: "Sample walks", body: "198 centre-to-facility pairs" },
  { title: "Route on foot", body: "OSRM foot server; 194 kept" },
  { title: "Detour", body: "Walk ÷ straight line" },
], 0.6, 1.55, 5.6, 2.6, { color: MUTED, titleH: 0.75, bodySize: 14 });
stat(s, 0.6, 4.45, 2.6, "1.51", "median detour (IQR 1.39–1.79)", TERRA, 44);
stat(s, 3.4, 4.45, 2.8, "≈ 661 m", "straight line reached by a 1 km walk", TERRA, 44);
s.addChart(pres.charts.BAR, [{ name: "Median detour", labels: ["Education", "Retail goods", "Recreation", "Health", "Food retail", "Food services"],
  values: [1.564, 1.547, 1.535, 1.53, 1.484, 1.384] }], Object.assign({ x: 6.6, y: 1.45, w: 6.13, h: 5.35, barDir: "bar", chartColors: [MUTED],
  showValue: true, dataLabelPosition: "outEnd", dataLabelFormatCode: "0.00", showLegend: false, showTitle: true,
  title: "Median detour factor by category (194 routes)", catAxisOrientation: "maxMin", valAxisHidden: true, valAxisMinVal: 0, valAxisMaxVal: 1.8 }, AXIS, grid()));

s = newSlide("CONTENT", "A. What the detour means for the results",
  "The 1 km circle is closer to a 1.5 km walk. Rankings should hold; absolute within-a-walk claims should be read as straight-line reach.");
s.addChart(pres.charts.BAR, [{ name: "Median detour", labels: ["Mature", "Non-mature", "Excluded areas", "All routes"],
  values: [1.53, 1.496, 1.5, 1.514] }], Object.assign({ x: 0.6, y: 1.45, w: 5.6, h: 5.35, barDir: "col", chartColors: [MUTED],
  showValue: true, dataLabelPosition: "outEnd", dataLabelFormatCode: "0.00", showLegend: false, showTitle: true,
  title: "Median detour by town group", valAxisHidden: true, valAxisMinVal: 0, valAxisMaxVal: 1.8 }, AXIS, grid()));
bullets(s, [
  [{ text: "Absolute counts overstate a 1 km walk: ", options: { bold: true } }, { text: "a circle of about 660 m would match one" }],
  [{ text: "Rankings should hold: ", options: { bold: true } }, { text: "the 800 m variant keeps rank order at Spearman 0.95 with the main score" }],
  [{ text: "Town groups barely differ (1.50–1.53), ", options: { bold: true } }, { text: "so the mature vs non-mature comparison is not biased by detours" }],
  [{ text: "1.51 is likely an upper estimate: ", options: { bold: true } }, { text: "OSM misses many through-block links (void decks, mall interiors), and OSRM routes on the live graph" }],
  [{ text: "Not checked: ", options: { bold: true } }, { text: "a rerun of the score at 660 m" }],
], 6.6, 1.55, 6.13, 5.2, 16);

// pptxgenjs writes folder entries into the zip, which some cloud viewers refuse; drop them.
const JSZip = require(require.resolve("jszip", { paths: [path.dirname(require.resolve("pptxgenjs"))] }));
pres.write({ outputType: "nodebuffer" })
  .then((buf) => JSZip.loadAsync(buf))
  .then((zip) => {
    // zip.remove() on a folder would drop its files too, so delete only the folder entries.
    Object.keys(zip.files).filter((k) => zip.files[k].dir).forEach((k) => delete zip.files[k]);
    return zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE" });
  })
  .then((buf) => { fs.mkdirSync(path.dirname(OUT), { recursive: true }); fs.writeFileSync(OUT, buf); console.log("wrote", OUT); });
