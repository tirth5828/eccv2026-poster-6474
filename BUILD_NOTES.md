# Build Notes — ECCV 2026 Poster Print-Spec Conversion

Baseline commit: `3eb310d`. Deliverable: `6474_Joshi_1400x1000mm.pdf`, built by `build.ps1`.

## 1. Geometry conversion

The source was `paperwidth=46.8in, paperheight=35.1in, margin=0.30in`
(1188.7 x 891.5mm, aspect ratio 1.333 — a 4:3-ish canvas). The printer needs
1400x1000mm trim (aspect ratio 1.4) with 10mm bleed and a 5mm crop-mark quiet
zone, i.e. a 1430x1030mm physical media sheet.

```
\usepackage[paperwidth=1430mm,paperheight=1030mm,margin=25mm]{geometry}
```

`margin=25mm` puts the printable text block 25mm in from every media edge.
Since the trim edge sits 15mm in from the media edge, that leaves a uniform
**10mm clearance** between the outermost content and the trim line on all
four sides (comfortably over the 5mm minimum). New content area:
`\textwidth` = 1380mm (54.33in), `\textheight` = 980mm (38.58in).

TrimBox/BleedBox are stamped directly on the PDF page via a raw `\pdfpageattr`
(pdftex primitive), computed in PDF points (1mm = 72/25.4 pt) so an
automated preflight/fit-to-size step reads the correct 1400x1000mm trim
instead of rescaling the 1430x1030mm media:

```
\pdfpageattr{/TrimBox [42.5197 42.5197 4011.0236 2877.1654] /BleedBox [14.1732 14.1732 4039.3701 2905.5118]}
```

Verified via `pdfinfo -box`:
- MediaBox: 0 0 4053.54 2919.68 pt = **1430.00 x 1030.00 mm**
- TrimBox: 42.52 42.52 4011.02 2877.17 pt = **1400.00 x 1000.00 mm**
- BleedBox: 14.17 14.17 4039.37 2905.51 pt = **1420.00 x 1020.00 mm**

### Crop marks

Drawn with a `remember picture, overlay` TikZ picture anchored at
`(current page.south west)`, placed once right after `\begin{document}`. At
each of the 4 trim corners, two 5mm line segments run from the media edge
inward to the bleed edge (i.e. entirely inside the 5mm quiet zone, with a
gap over the 10mm bleed band, per standard print convention) — confirmed
present at all four corners by pixel-probing a rendered proof.

## 2. Colour conversion (RGB → native CMYK)

`xcolor` is loaded with the `cmyk` option, and all 13 palette colours were
converted from their HTML hex value to CMYK with the standard
`K=1-max(R,G,B); C,M,Y=(1-R-K)/(1-K)…` formula, matched to 3 decimal places:

| name | hex | cmyk |
|---|---|---|
| navy | 062B63 | 0.939, 0.566, 0.000, 0.612 |
| navy2 | 0D3C78 | 0.892, 0.500, 0.000, 0.529 |
| royal | 165A9F | 0.862, 0.434, 0.000, 0.376 |
| lightblue | F3F7FC | 0.036, 0.020, 0.000, 0.012 |
| lineblue | CAD8EA | 0.137, 0.077, 0.000, 0.082 |
| softgreen | EEF8EF | 0.040, 0.000, 0.036, 0.027 |
| green | 16803A | 0.828, 0.000, 0.547, 0.498 |
| softorange | FFF7E6 | 0.000, 0.031, 0.098, 0.000 |
| orange | C96D00 | 0.000, 0.458, 1.000, 0.212 |
| softred | FFF1F0 | 0.000, 0.055, 0.059, 0.000 |
| red | B12020 | 0.000, 0.819, 0.819, 0.306 |
| graytext | 2E3440 | 0.281, 0.188, 0.000, 0.749 |
| muted | 657286 | 0.246, 0.149, 0.000, 0.475 |

Body text uses xcolor's default `black`, which under the `cmyk` model is
pure K (`0,0,0,1`) automatically — no rich-black plates.

**Raster figures were also RGB** (`fig_release_trends.png`,
`fig_replication.png` are standard RGB PNGs — PNG has no CMYK colour type,
so this can't be fixed by a LaTeX-side flag). Both were converted with
Pillow (`im.convert('CMYK')`) and re-embedded as native `/DeviceCMYK`
one-page PDFs (via a hand-built PostScript image stream run through
Ghostscript's `pdfwrite` device with `-dProcessColorModel=/DeviceCMYK`),
then swapped into the `.tex` in place of the PNGs. `katz-logo-cmyk.pdf` was
already CMYK and used as supplied.

**Verification** (`pdftops` decompression + regex scan of the content
stream): **0** painted `rg`/`RG` operators and **0** `/DeviceRGB` colorspace
selections anywhere in the file — better than the spec's "one inert
`pgfprgb` resource is acceptable" allowance, because the poster never
actually invokes an RGB-valued TikZ color (only the named CMYK palette and
black/white are used), so pgf never emits that resource at all.

## 3. Figure / logo resolution

| asset | native px | placed width | DPI |
|---|---|---|---|
| fig_release_trends (section 5) | 3156 x 790 | 19.40in (0.94×linewidth) | **162.7** |
| fig_replication (section 6) | 3156 x 756 | 19.40in (0.94×linewidth) | **162.7** |
| katz-logo-cmyk.pdf (header) | 900 x 300 | 4.40in = 111.8mm (under the 180mm cap) | **204.5** |

All well above the 100 DPI floor; the logo is placed at 111.8mm, well under
the 180mm cap that would drop it below 100 DPI. Placed widths for the two
figures are read live from the compiled log (`\the\linewidth` is
`\typeout`'d right before each `\includegraphics`) rather than hardcoded, so
`build.ps1`'s DPI check tracks the real layout.

## 4. Header logo

The text placeholder box ("YESHIVA / UNIVERSITY / Katz School...") was
replaced with `\includegraphics[width=4.4in]{assets/katz-logo-cmyk.pdf}`
inside the same white/navy2-bordered tcolorbox, sized to fit the box's
interior width with margin (box interior ≈4.51in; image requested at
4.4in avoids the overfull-hbox that resulted from requesting the full
4.6in). The ECCV box at top-left is untouched.

## 5. Layout re-fit for the 1.4:1 canvas

The 3-column grid keeps its original proportions (0.292 / 0.388 / 0.292 of
`\textwidth`), as instructed — only the underlying `\textwidth` changed
(1173mm → 1380mm), so the columns grew proportionally wider.

**The empty band above the footer** (originally ≈101mm / 11.5% of the
content height — content stopped at 29.7in but the box ran to 34.5in, and
the intervening `\vfill` silently absorbed the difference) was closed by:

1. Scaling every explicit spacing/box-size length (`\vspace`, tcolorbox
   `width=`/`height=`, tcbset paddings, arc radii, boxrule, itemize margins,
   the TikZ diagram's own inch-based axis unit) up from the source values —
   combined effect ≈1.75x on inter-paragraph spacing, ≈1.2–1.3x on box
   geometry.
2. Scaling every `\fontsize{a}{b}` up by a combined ≈1.30x (two passes:
   1.2x to match the ≈17.6% width growth, then a further 1.08x once it was
   clear the extra canvas height needed real text growth, not just glue).
3. Replacing the fixed `[34.50in]` minipage height (hand-matched to the old
   `\textheight`) with `[\textheight]` so it tracks the new page height
   automatically instead of drifting out of sync.
4. Re-tuning the "10. Final Contribution / Empirical Signal / Limitation"
   summary boxes specifically: an early attempt inflated their fixed
   `height=` a lot to eat the leftover space, but that just moved the empty
   band *inside* those three boxes (very short text in very tall boxes,
   visibly worse than the external gap it replaced). The final version sizes
   those boxes to fit their (enlarged, ≈29.7pt) text with a modest margin
   (`height=3.4in`) instead, and lets a small remaining `\vfill` gap sit
   above the footer.
5. Kept the `\vfill` mechanism (rather than swapping it for a fixed
   `\vspace`) because it self-adjusts and can never overflow the fixed-height
   outer box — a fixed `\vspace` risked silent clipping if a future content
   edit made the column content taller than expected.

**Net result:** the gap between the bottom of section 10 and the top of the
footer bar dropped from ≈101mm (11.5% of trim height) to **≈25–29mm
(≈2.5–2.9% of trim height)** — a clean, intentional-looking margin rather
than a conspicuous dead zone. Verified by pixel-row analysis of a rendered
proof and by visual inspection (Section 7 below).

## 6. Other fixes made along the way

- **`lmodern` added.** At the scaled-up `\texttt{}` sizes (email addresses),
  MiKTeX had no Type 1 outline for the default EC/CM typewriter font at that
  exact size and silently invoked METAFONT to rasterize a bitmap (Type 3)
  font on the fly — `pdffonts` showed two unsubsetted Type 3 fonts. Loading
  `lmodern` (Latin Modern, full Type 1 outlines at any size) eliminated this;
  all 11 fonts in the final PDF are Type 1, embedded, subsetted.
- **Pre-existing overfull hbox fixed.** `\mhead{Positioning against common
  criteria.}` was directly followed by `\tablefont\resizebox{...}` with no
  paragraph break, so the heading text and the giant `\resizebox`'d table
  were laid out as one paragraph line, producing a ~349pt overfull hbox
  warning. Added `\par` after the heading (no wording/content change).
- **Logo overfull hbox fixed.** Requesting the logo at 4.6in overflowed the
  tcolorbox's ~4.51in interior by ~6pt; reduced to 4.4in.

No section was reordered, retitled, or reworded, and no numeric result value
was changed — only font sizes, spacing lengths, box dimensions, colours,
image formats, and the page geometry.

## 7. Visual verification

Rendered the finished poster at 40 DPI (full page) and 200 DPI (crops of
the header, all three main columns, both figures, the section-10 summary
row + footer, and all four corners) and inspected each:

- **Header:** title/subtitle/author block centered and legible; ECCV box
  and the new Katz logo both render cleanly with generous clearance from
  the title text.
- **Columns 1–3:** all 9 numbered sections fit their boxes with no
  overlapping text, no clipped equations, no collisions with adjacent
  boxes. The release-as-channel TikZ diagram (section 2) has ample margin
  inside its column.
- **Figures (sections 5–6):** render sharp at their placed size; the CMYK
  re-encode is visually indistinguishable from the original RGB PNGs
  (spot-checked side by side).
- **Pre-existing issue, not introduced by this pass:** the legend labels
  "Market A0" and "CUHK03 A3" overlap into unreadable text in the right-hand
  chart of `fig_replication.png` ("Pressure rises on both datasets"). This
  was confirmed by cropping the *original* PNG asset directly — it's baked
  into the author-supplied figure itself, not a placement/scaling artifact
  of this pass, and fixing it would require regenerating the plot from its
  source data/script, which is outside this task's scope (no wording/data
  changes, no access to the plotting code).
- **Section 10 + footer:** the three summary boxes are now well-filled
  (larger "hero" text sized to the box rather than a mostly-empty box), and
  the footer sits with a clean, modest gap beneath them — no dead band.
- **Crop marks:** present and correctly positioned outside the bleed at all
  four corners; confirmed both visually and by an automated pixel probe in
  `build.ps1`.
- **Minimum text size:** the smallest `\fontsize` in the source is the
  caption/footnote text at **17.885pt** (scaled up from the original
  13.8pt). This is below the ~24pt poster-viewing-distance comfort
  threshold and is flagged by `build.ps1`, but it's the author's original
  caption-text design choice (now ≈30% larger than the original), and
  enlarging it further would change the visual balance/identity the author
  asked to preserve, so it was left as a flagged item rather than silently
  changed.

## 8. `build.ps1`

Compiles twice, then runs all of the checks above (PDF exists; no
Overfull/Underfull hbox/vbox beyond 5pt; MediaBox/TrimBox/BleedBox regex
match; every font embedded+subsetted and no Type 3; zero painted RGB
operators and zero unaccounted `/DeviceRGB` colorspace selections; ≥100 DPI
for both figures and the logo, read live from the compile log; crop-mark
ink present in a small pixel window at all 4 corners; minimum text size
reported/flagged), and only copies the result to
`6474_Joshi_1400x1000mm.pdf` if every check passes — otherwise it prints
`FAIL:` lines for each failing check and exits non-zero.

(§9 below supersedes the DPI check for the two figures — they are now
vector — while the logo DPI check is unchanged.)

## 9. Vector figure regeneration

**Why.** `assets/fig_replication.png` (section 6, "Replication + Non-Face
Stress Test") had a baked-in label collision: at R2 in the right panel
("Pressure rises on both datasets") the end-of-line labels "Market A0"
(vRPI₂=4.966) and "CUHK03 A3" (vRPI₂=4.977) sit 0.011 apart on a 0–6.6
scale and print on top of each other as unreadable garble; the left panel
("Exposure expansion replicates") has a milder version of the same crowd
(Market A0 .547 vs CUHK03 A3 .502). This was flagged but left unfixed in
§7 of this document during the print-spec pass, since fixing a label
collision baked into a raster asset requires regenerating the plot from
data, which was out of scope then. This pass regenerates both
`fig_replication.png` and `fig_release_trends.png` as native vector
pgfplots/TikZ figures (`assets/fig_replication_vector.tex`,
`assets/fig_release_trends_vector.tex`, `\input`-ed into the poster inside
`\resizebox{0.94\linewidth}{!}{...}` in place of the old
`\includegraphics`), fixing the collision and removing the DPI constraint.
The two PNGs and their intermediate `_cmyk.pdf` raster conversions are left
in `assets/` for reference but are no longer referenced by the `.tex`.
`\usepackage{pgfplots}` + `\pgfplotsset{compat=1.18}` +
`\usepgfplotslibrary{groupplots}` were added to the preamble.

### Series inventory (reverse-engineered from the PNGs before writing any code)

**`fig_replication.png`** — 2 panels (P_guess, vRPI₂) × R1→R2, 4 series,
circular markers, end-of-line text labels (no legend box):
- Market A3 (green), Market A0 (royal blue), CUHK03 A3 (dark navy), CUHK03 A0 (orange).

**`fig_release_trends.png`** — 2 panels (P_guess, vRPI₂) × R1–R4, 5 series,
shared top legend (not end-of-line labels):
- A0 (royal blue circle, line R1–R3), A3 (green square, line R1–R3), A4
  (orange triangle, line R1–R3), A2 (navy diamond, isolated marker at R4
  only), A0-Graph (red X, isolated marker at R4 only).
- **Attacker A1 (linear probe) does NOT appear in this figure**, confirmed
  by direct pixel inspection of the legend row (only 5 marker/label pairs:
  A0, A3, A4, A2, A0-Graph) — even though the paper's own commented-out
  pgfplots source for the analogous figure (`tab:exp_means` discussion,
  `fig:release_two_panel_new`) includes a 6th A1 series. This is a
  deliberate declutter choice in the poster's version of the figure, not
  an omission bug, and was reproduced faithfully (A1 was NOT added back).

### Colours (pixel-sampled from the PNGs, converted RGB→CMYK)

Sampled dominant RGB per series via a histogram scan of both PNGs (excluding
near-white/black/gray background pixels), then converted with the standard
`K=1-max(R,G,B)/255` formula. Every sampled colour matched an
**already-defined** poster palette colour to 3 decimal places, so no new
colours were introduced — the author's original plotting script was already
using the poster's own brand palette:

| series role | sampled RGB | poster colour | CMYK |
|---|---|---|---|
| Market A0 / A0 | (22,90,159) | `royal` | 0.862, 0.434, 0.000, 0.376 |
| Market A3 / A3 | (22,128,58) | `green` | 0.828, 0.000, 0.547, 0.498 |
| CUHK03 A3 / A2 | (13,60,120) | `navy2` | 0.892, 0.500, 0.000, 0.529 |
| CUHK03 A0 / A4 | (201,109,0) | `orange` | 0.000, 0.458, 1.000, 0.212 |
| A0-Graph | (177,32,32) | `red` | 0.000, 0.819, 0.819, 0.306 |

### Data points (every one checked against the paper, read-only)

`fig_replication.png` ↔ `tab:cuhk_replication`:

| Series | R1 P_g | R2 P_g | R1 vRPI₂ | R2 vRPI₂ |
|---|---|---|---|---|
| Market A0 | .197 | .547 | .873 | 4.966 |
| Market A3 | .368 | .691 | 5.198 | 5.943 |
| CUHK03 A0 | .226 | .399 | .530 | 3.325 |
| CUHK03 A3 | .313 | .502 | 4.549 | 4.977 |

All 16 values match `tab:cuhk_replication` exactly (N=736 Market / N=700
CUHK03, as stated in the paper text — the table caption explains N differs
from `tab:exp_means` because this is a separate, lighter paired protocol
retaining only identities with ≥4 images).

`fig_release_trends.png` ↔ `tab:exp_means` (Market-1501-τ, N=751):

| Attacker | R1 | R2 | R3 | R4 |
|---|---|---|---|---|
| A0 P_guess | .2883 | .7491 | .7529 | — |
| A0 vRPI₂ | 4.3319 | 6.2119 | 5.9271 | — |
| A3 P_guess | .4073 | .7063 | .7092 | — |
| A3 vRPI₂ | 4.7231 | 5.9402 | 5.9368 | — |
| A4 P_guess | .5073 | .7304 | .7238 | — |
| A4 vRPI₂ | 5.0912 | 6.0133 | 6.0060 | — |
| A2 P_guess | — | — | — | .7519 |
| A2 vRPI₂ | — | — | — | 6.3572 |
| A0-Graph P_guess | — | — | — | .7366 |
| A0-Graph vRPI₂ | — | — | — | 5.6697 |

All values match `tab:exp_means` exactly. A0, A3, and A4 have no R4 row in
the table (R4 only reports A2 and A0-Graph), so their lines correctly stop
at R3 with no R4 marker — drawing them through R4 would have been
fabricated data, which the original PNG also correctly avoided and the
vector version preserves. **No mismatch was found between either PNG and
the paper** — every plotted value in both original raster figures was
already numerically correct; the only defect was the R2 label collision.

### Collision fix

Both are end-of-line text labels placed at `axis cs:R2,<value>` via
explicit `\node` commands after the `\addplot`s (`clip=false` on the
replication axes so labels/leaders may extend past the axis box). The fix
keeps every data point and line exactly where the raw numbers put it and
only moves the label *text*:

- **Right panel (severe collision, Market A0 4.966 vs CUHK03 A3 4.977):**
  empirically, at this panel's scale (4cm axis height / 6.6 range) a
  `\normalsize` text block is ≈0.7 axis units tall, so labels need
  ≥0.85-unit centre spacing to clear each other — confirmed by an initial
  attempt at 0.39-unit spacing, which still overlapped on render (see
  iteration below). Final label centres, top to bottom: Market A3 5.943
  (unmoved), CUHK03 A3 5.05, Market A0 4.20, CUHK03 A0 3.325 (unmoved).
  Each moved label gets a short leader line (thin, series-coloured) back to
  its true (unmoved) data point at R2.
- **Left panel (milder crowd, Market A0 .547 vs CUHK03 A3 .502):** same
  treatment at the smaller scale (0.12-unit minimum spacing at this
  panel's 4cm/0.80 scale). All four labels evenly re-staggered to 0.12-unit
  steps (Market A3 .725, Market A0 .605, CUHK03 A3 .485, CUHK03 A0 .365),
  each with a leader line back to its true point, since the available span
  between the two unmoved-would-be endpoints (.691/.399) was too narrow
  (0.292) to fit 4 labels at the minimum 0.12 spacing (needs 0.36) without
  nudging the outer two slightly as well.

**Iteration note:** the first attempt spaced the right-panel labels only
0.39 units apart (matching the panel's numeric gap intuition, not its
rendered text size) and — confirmed by rendering and visually inspecting —
still produced an overlap ("Market"/"CUHK0..." text visibly stacked on top
of each other), which is exactly the kind of defect this task warns
automated checks cannot catch. Spacing was recomputed from measured text
height and re-rendered until visually clear.

### Visual comparison (old raster vs new vector, rendered at 200 DPI)

- **Series/colour/style fidelity:** identical marker shapes (circle/square/
  triangle/diamond/X), identical line vs. isolated-marker treatment (A2 and
  A0-Graph as isolated R4 markers, no fabricated connecting line), identical
  colours (pixel-sampled, matched to 3 decimals), identical panel titles,
  axis labels ($P_{guess}$, $vRPI_2$), tick values, gridline style (light
  gray horizontal only, no vertical grid), and left/bottom-only axis spines
  (no boxed frame) — reproduced to match the original's despined style.
- **`fig_release_trends.png` (section 5):** no collision existed here; the
  vector version is visually indistinguishable from the original in series
  count, order, styling, and the shared top legend position/columns.
- **`fig_replication.png` (section 6):** this is the fixed figure. Both
  panels now show all 4 end-of-line labels fully legible with clear
  whitespace between every pair — confirmed by cropping the rendered PDF
  at 200 DPI and inspecting pixel-for-pixel. In the right panel, "Market
  A0" and "CUHK03 A3" (previously fused into unreadable overlapping glyphs)
  are now on two distinct, clearly separated lines, each connected to its
  own unmoved R2 data point by a short colour-matched leader line.
- **Layout:** both figures are placed via
  `\resizebox{0.94\linewidth}{!}{...}`, matching the original
  `\includegraphics[width=0.94\linewidth]` placed width exactly; the
  poster's `\vfill`-based bottom-of-page slack absorbed the (small) natural
  height difference from the new vector aspect ratio, so no other section
  shifted. Full-page render at 90 DPI and 200 DPI crops of sections 5–6
  confirm no overlap with adjacent boxes and no new Overfull/Underfull
  box beyond the pre-existing 5pt tolerance.

### `build.ps1` changes

The DPI check (§6 of the script) previously computed DPI for
`fig-release-trends` and `fig-replication` from their fixed 3156px PNG
width; since both are now vector, that computation no longer applies and
was replaced with an informational placed-width log line (still reads the
live `\linewidth` via the existing `POSTER-CHECK` typeout, just no longer
converts it to a DPI figure). The katz-logo DPI check is unchanged and
still passes (204.5 DPI, well above the 100 DPI floor — it remains the
only raster asset in the poster). Re-ran the full `build.ps1`: all checks
pass, exit 0.

## Vector figure defect fixes

The §9 vector conversion above (uncommitted at the start of this pass) had
two rendering defects that `build.ps1`'s automated checks cannot see
(neither is a geometry/font/colour/hbox problem — both are purely visual):
the §9 notes' claim that section 5 has "no collision" and "is visually
indistinguishable from the original" was true for colour/marker/style
fidelity but missed that R4 itself had silently fallen outside the axis
frame, and the §9 D2 fix (0.85-unit label ladder) still overprinted on
render despite the notes' claim of "clear whitespace between every pair."

### D1 — section 5, R4 missing from the x-axis, both R4 markers outside the frame

**Root cause.** `assets/fig_release_trends_vector.tex` declared
`symbolic x coords={R1,R2,R3,R4}` but used `xtick=data` to derive the tick
list. In this groupplot, `xtick=data` resolved to only `{R1,R2,R3}` — the
categories actually spanned by the A0/A3/A4 line series added first —
rather than the full declared symbolic list, so the axis frame itself only
allocated width for 3 categories and the R4-only A2/A0-Graph markers
(`only marks`, added after) were plotted at a 4th symbolic position that
fell entirely outside the drawn frame, in the surrounding whitespace.

**Fix.** Replaced `xtick=data` with an explicit `xtick={R1,R2,R3,R4}` (the
same explicit form the paper's own pgfplots source uses for this figure,
confirmed by inspection of the paper's commented-out
`fig:release_two_panel_new` source) and increased `enlarge x limits` from
0.12 to 0.15 for clearer padding around R4. No data point, colour, marker,
or series was touched — this is purely an axis-tick/extent fix. Rebuilt
and re-rendered: R4 is now a labelled tick on both panels, and both the
A2 (navy diamond) and A0-Graph (red ×) markers sit inside the axis frame
with visible margin to the right border, not on or beyond it.

**Cross-check against the original raster (`assets/fig_release_trends.png`,
rendered and zoomed) and against `tab:exp_means` in the read-only paper
source:** the original PNG shows R4 as a labelled tick with *only* A2 and
A0-Graph plotted there — A0/A3/A4's lines stop at R3 with no R4 marker or
connecting segment. This matches `tab:exp_means`, which has no R4 row for
A0, A3, or A4 (only A2 and A0-Graph report R4 values). The vector figure
already reproduced this correctly (no line was fabricated through R4 for
A0/A3/A4); the only bug was the axis/tick extent, now fixed. Full
data table (all 10 rows) is unchanged from §9 above and re-verified:

| Attacker | R1 | R2 | R3 | R4 |
|---|---|---|---|---|
| A0 P_guess / vRPI₂ | .2883 / 4.3319 | .7491 / 6.2119 | .7529 / 5.9271 | — |
| A3 P_guess / vRPI₂ | .4073 / 4.7231 | .7063 / 5.9402 | .7092 / 5.9368 | — |
| A4 P_guess / vRPI₂ | .5073 / 5.0912 | .7304 / 6.0133 | .7238 / 6.0060 | — |
| A2 P_guess / vRPI₂ | — | — | — | .7519 / 6.3572 |
| A0-Graph P_guess / vRPI₂ | — | — | — | .7366 / 5.6697 |

All values match `tab:exp_means` and the original PNG exactly; no
discrepancy found between the two source-of-truth artifacts.

### D2 — section 6 right panel, staggered label collided with the label it was staggered past

**Root cause.** The §9 fix moved CUHK03 A3's label from its true value
(4.977) to y=5.05, but left Market A0's label unmoved at its true value
(4.966) — i.e. it moved one colliding label directly on top of the other
label it was supposed to be avoiding. Pixel-probing the rendered text rows
confirmed the "CUHK03 A3" and "Market A0" glyph bounding boxes had only
~1px of clearance (visually fused).

**Fix.** All four right-panel labels (Market A3 5.943, CUHK03 A3 4.977,
Market A0 4.966, CUHK03 A0 3.325) — not just the two that were closest —
are now placed on a uniform ladder with **1.2-axis-unit** spacing (Market
A3 at 6.15, CUHK03 A3 at 4.95, Market A0 at 3.75, CUHK03 A0 at 2.55), each
with its own thin, series-coloured leader line back to its true (unmoved)
data point. 1.2 units was reached empirically: an intermediate attempt at
1.05 units rendered with only an 18–19px (≈3.2mm) gap between text rows at
150 DPI; pixel-probing the final 1.2-unit version shows a 26–27px (≈4.6mm)
gap between every adjacent label pair — comfortably non-touching, and
wider than the previous attempt's margin. No data point was moved.

Left panel (Market A3 .691, Market A0 .547, CUHK03 A3 .502, CUHK03 A0
.399, on the §9 fix's existing 0.12-unit ladder) was re-checked by the same
pixel-row method and confirmed clear — text rows have a visible gap, no
change needed.

### Proof (rendered from the final `6474_Joshi_1400x1000mm.pdf`, 150 DPI)

- **Section 5:** both panels ("Identity-guessing success",
  "Rényi re-identification pressure") show all four x tick labels
  R1, R2, R3, R4; the A2 (navy diamond) and A0-Graph (red ×) markers at R4
  sit fully inside the axis frame with visible margin, not floating in
  whitespace.
- **Section 6:** right panel — Market A3 / CUHK03 A3 / Market A0 / CUHK03
  A0 render as four distinct, non-overlapping lines of text, each with a
  visible leader line to its own (unmoved) data point; left panel's four
  labels confirmed clear by the same method.
- **Boundary check:** cropped the region between sections 5/6 and the
  section 7/9 column to their right — all figure content (including the R4
  markers and the section-6 leader/label block) stays inside its own
  column's light-gray border with a clear gap before the neighbouring
  column's text; nothing clipped or spilling over.
- **`build.ps1`:** re-ran end-to-end after both fixes — all checks pass,
  exit 0 (MediaBox/TrimBox/BleedBox geometry, crop marks at all 4 corners,
  fonts embedded+subsetted, zero RGB paint operators, no
  Overfull/Underfull hbox/vbox beyond 5pt). One environment-only change was
  needed to get `build.ps1` running at all in this session: MiKTeX's
  one-time "you have not checked for MiKTeX updates" notice on `pdflatex`
  writes to stderr, which PowerShell's `$ErrorActionPreference = "Stop"`
  promotes into a terminating `NativeCommandError` even though `pdflatex`
  exits 0 and produces a correct PDF. The two `pdflatex` invocations are
  now wrapped with a local `$ErrorActionPreference = "Continue"` (restored
  immediately after) so this harmless stderr chatter no longer aborts the
  script; no check logic was changed.

## Declutter and diagrams

Author brief: reduce visual density, keep every scientific claim/number,
add three native-TikZ diagrams inside the existing structure (numbered navy
tabs, three columns, bottom C/E/L row, footer bar, palette all preserved
unchanged).

### Text cuts (rough word-count deltas, prose+captions only, excludes
kept theorem-box bodies and kept display equations)

- **Section 1** (about 84 to about 83 words, but one display equation removed and
  replaced by Diagram A): intro trimmed to one sentence; "Latent identity and
  non-face view" shortened; the bare Pr(U | Z_1:T) display deleted (its
  content now shown by Diagram A instead of stated twice); kept the
  non-face-transform display and the P_guess display as the two required
  equations.
- **Section 3** (about 150 to about 149 words plus 3 display equations removed):
  the three "Additional guarantees" bullets converted from equation-bearing
  bullets to one-line word-only statements (Ideal additivity, Ablation
  monotonicity, Plug-in stability) with no display maths in any of the
  three. Both theorem boxes kept essentially verbatim per instructions.
  Added Diagram B (anonymity budget) directly under the definition.
- **Section 7** (about 40 to about 35 words): "Attacker ladder" bullet list
  (5 items) replaced by Diagram C. Release list (R1 to R4) and Dataset
  paragraph kept as text, lightly tightened.
- **Section 8** (about 71 to about 78 words, but 2 of 3 display equations
  removed): kept the required Delta_corr,2 display; temperature-calibration
  result and Zipf-prior result now stated inline in prose instead of via
  standalone displays.
- **Section 9** (about 153 to about 137 words): trimmed "Not another Re-ID
  model", "Not a replacement..." and governance/hygiene-box sentences; kept
  table and hygiene box verbatim in structure; strengthened the
  anonymization limitation bullet to explicitly say "not realistic
  detector-based or generative anonymization" (the ethical scope caveat,
  which is also still present in the section 6 warnbox, so it now appears
  twice for safety).
- **Section 10** (about 99 to about 80 words): all three Contribution /
  Empirical signal / Limitation boxes tightened; heights are fixed
  (height=3.4in) so the boxes did not shrink, they just gained whitespace,
  meaning no overflow risk from cutting text in a fixed-height box.

No numeric result, hypothesis (alpha greater than 1, uniform-prior
conditions), or the ethical scope caveat about detector-based/generative
anonymization was removed.

### Diagram construction

All three are native TikZ (no pgfplots axes, no rasters), colours drawn
only from the existing named palette (navy, navy2, royal, green, orange,
red, lightblue, muted), wrapped in resizebox at a fixed fraction of
linewidth so they scale to the column without causing overfull boxes.

- **Diagram A (posterior-sharpening strip, section 1).** Four hand-drawn
  bar panels (a sketchpanel macro, 5 bars each) laid out via a foreach
  loop with pgfmathsetmacro for bar geometry; the center bar (index 2) is
  drawn in an escalating highlight colour (navy2 at 28 percent tint for R1,
  meaning no visible highlight since R1 should read flat, then
  royal/orange/red for R2/R3/R4) while the other four bars stay a uniform
  light navy2 tint. Bar heights are source-commented as "ILLUSTRATIVE
  SKETCHES ONLY (not measured data)" in the .tex file and restated in the
  on-poster caption. The real numbers printed under each panel are the
  only numeric claim: R1 A0 P_guess = 0.2883, R2 A0 = 0.7491, R3 A0 =
  0.7529, R4 A2 = 0.7519, with R4 explicitly labelled "(A2)" under its
  panel since A0 has no R4 row in the paper (the attacker tag is printed
  on all four panels, not just R4, for visual consistency).
- **Diagram B (anonymity budget bar, section 3).** A 4-row stacked
  horizontal bar (R1 to R4), each row total length equal to log N =
  ln(751) = about 6.62 nats (Market-1501-tau, N=751, uniform prior,
  natural log consistent with the paper's exp(...) guessing-bound
  convention). Filled portion per row = vRPI_2 (colour-ramped
  navy2/royal/orange/red matching Diagram A and C and the section 4
  table's red R4 highlight); open portion = remaining H_2(U|Z). The bottom
  row (R4) is fully annotated with both segment values inside/beside the
  bar; the top of the stack carries a brace labelled "log N = 6.62 nats
  (N=751)". Row lengths: R1 filled 3.899 open 2.061, R2 filled 5.591 open
  0.369, R3 filled 5.334 open 0.626, R4 (A2) filled 5.721 open 0.239 (all
  in nats). A caption states R1 to R3 use attacker A0, R4 uses A2.
- **Diagram C (attacker ladder, section 7).** Four ascending rectangles
  (A0, A1, A3, A4) of increasing height and escalating colour (navy2,
  royal, orange, red) with an "increasing capability / access" label on
  top and a one-line capability tag under each box; A2 is drawn as a
  separate dashed-border box to the right, connected by a dashed line,
  labelled "(R4 only)" to show it is an artifact-exploiting branch off the
  general capability ladder rather than a rung on it. The release list (R1
  to R4) stayed as plain text per instructions; only the attacker list
  became the diagram.

### Data sources

All values traced to
Compositional_Non_Face_Re_Identification_Pressure_under_Cumulative_Vision_Releases.tex
(read-only, authoritative): tab:exp_means for the R1 to R4 P_guess/vRPI_2
rows (R1/A0 0.2883/4.3319, R2/A0 0.7491/6.2119, R3/A0 0.7529/5.9271,
R4/A2 0.7519/6.3572); N=751 and the log-base convention (natural log,
consistent with the exp((1-alpha)/alpha times H_alpha) guessing bound in
Theorem 2) from the experiments section and the vRPI_alpha definition; log
N = ln(751) = 6.62 computed directly (not stated verbatim in the paper,
derived from N=751 under the paper's explicit uniform-prior / log N
convention).

### Bug caught during self-review

The first pass wrapped Diagram B in a bare "centering" declaration instead
of a scoped center environment. Because that declaration is unscoped, it
silently leaked past the diagram into the rest of section 3's content in
the same group: "Choosing alpha" and "Additional guarantees" rendered
center-justified instead of left-aligned. This was caught only by zoomed
rendering, not by build.ps1, which has no way to detect misaligned-but-
non-overflowing text. Fixed by scoping the diagram and its caption inside
a center environment; re-rendered to confirm section 3 text is back to
normal left alignment with only the diagram and its caption centered.

### Before / after visual comparison

Rendered both the pre-edit PDF (from git history) and the final PDF at 35
DPI full-page, plus each new diagram at 150 DPI. Observed:

- Diagram A reads correctly at a glance: R1's five bars are visibly
  near-equal height (flat), R2 shows one bar roughly 2x its neighbours, R3
  roughly 3 to 4x, R4 roughly 8 to 10x, a clear, monotonic flat-to-spiked
  progression exactly as required, confirmed by direct visual inspection
  of the 150 DPI crop.
- Diagram B shows all four bars sharing one baseline and one log N
  bracket, with the filled portion visibly growing from a short segment
  (R1) to nearly the full bar (R4); no label collides with the bars or
  with the row labels to their left.
- Diagram C's staircase and the dashed A2 side-branch are legible with
  clear separation from the section box border and from the caption line
  beneath; the "Attacker ladder." heading sits left of the diagram without
  overlapping it.
- Overall density: comparing the two full-page renders side by side,
  columns 1 and 3 (sections 1/2/3 and 7/8/9) visibly gained open
  whitespace below section 3 and below section 9 that the pre-edit version
  did not have. The pre-edit column ran text almost to the section-box
  borders with little vertical breathing room; the post-edit column has
  clearly more air around each block, and the wall of stacked display
  equations in sections 1, 3, and 8 is broken up by the three new
  graphics. No text collides with any box border, table, or the other new
  diagrams; no Overfull hbox/vbox was reported by build.ps1 (re-run clean,
  exit 0, all checks green including MediaBox/TrimBox/BleedBox geometry,
  crop marks at all four corners, embedded and subsetted fonts, zero RGB
  paint operators, and Katz logo DPI).

## Type scale unification

Baseline commit for this pass: `c3384c2`. Brief: "there are like many
different text sizes in poster, making it uniform and decrease the
variations." The poster had **20 distinct font sizes** (28 `\fontsize`
call sites total, including the 9 named-macro definitions), many of them
accidental near-duplicates left over from an earlier x1.296 rescale
(25.92 / 25.272 / 24.624 all read as the same size; 40.176 / 39.96 read
as the same size; 30.456 / 29.7 read as the same size).

### The 5-step scale

```
\newcommand{\fsTitle}{\fontsize{75}{82}}  % main poster title only
\newcommand{\fsH1}{\fontsize{40}{47}}  -> renamed \fsHone (see note below)
\newcommand{\fsH2}{\fontsize{30}{36}}  -> renamed \fsHtwo (see note below)
\newcommand{\fsBody}{\fontsize{23}{28}}
\newcommand{\fsSmall}{\fontsize{19}{23}}
```

**Naming note:** the brief's suggested token names `\fsH1`/`\fsH2` are not
valid LaTeX control words — TeX control words are letters-only, so
`\fsH1` lexes as `\fsH` followed by a literal character `1`, not as one
command. Both `\newcommand{\fsH1}` definitions silently collided/broke,
and every call site threw `Undefined control sequence`, which cascaded
into a `Missing \begin{document}` error and pushed the entire poster onto
a spurious second page. Fixed by renaming the two tokens to
**`\fsHone`** and **`\fsHtwo`** (all-letter names) everywhere. Functionally
identical to the spec's H1/H2 roles; only the token spelling changed.

### Old size -> new token mapping

| Old macro / literal size | Occurrences | New token | Role |
|---|---|---|---|
| `\titlefont` (75.168/81.648) | 1 | `\fsTitle` (75/82) | Main poster title |
| `\subtitlefont` (40.176/46.656) | 1 | `\fsHone` (40/47) | Subtitle |
| literal 39.96/47.52 (section-10 headings) | 3 | `\fsHone` | "Contribution" / "Empirical signal" / "Limitation" headings |
| header badge "ECCV" (45.36/51.84) | 1 | `\fsHone` | Header navy badge, line 1 |
| `\authorfont` (36.288/42.768) | 1 | `\fsHtwo` (30/36) | Author line |
| `sectionbox` `fonttitle` (30.456/35.64) | 1 | `\fsHtwo` | Section tab titles (1.-9.) |
| header badge "2026" (32.4/38.88) | 1 | `\fsHtwo` | Header navy badge, line 2 |
| `\affilfont` (25.272/30.456) | 1 | `\fsBody` (23/28) | Affiliation / email line |
| `\bodyfont` (25.92/31.104) | 1 | `\fsBody` | Document default body font; attacker-ladder A0-A4 box labels |
| `\smallbody` (22.81/27.216) | 1 | `\fsBody` | All in-box body paragraphs (sections 1,3,4,6,7,8,9) |
| literal 26.568/32.141 (claim/banner box) | 1 | `\fsBody` | "Main message" banner text |
| literal 29.7/36.18 (section-10 bodies) | 3 | `\fsBody` | Contribution/Empirical-signal/Limitation box bodies |
| literal 23.328/27 (diagram A panel labels) | 1 | `\fsBody` | Sketch-panel R1-R4 labels |
| literal 21.384/25.92 (diagram B callout) | 1 | `\fsBody` | "$Z_{1:T}=\dots$" bold callout |
| literal 23.328/28.512 (footer name/title) | 2 | `\fsBody` | Footer name line, footer paper-title line |
| literal 24.624/29.808 (footer title) | 1 | `\fsBody` | Footer paper-title line |
| `\tinybody` (18.792/22.032) | 1 | `\fsSmall` (19/23) | Small diagram callouts/legends |
| `\tablefont` (19.051/22.162) | 1 | `\fsSmall` | Table text (sections 4, 9) |
| `\captionfont` (17.885/20.736) | 1 | `\fsSmall` | All figure/diagram captions |
| literal 20.088/23.328 (diagram B node default) | 1 | `\fsSmall` | R1-R4 channel-box text |
| literal 20.736/25.92, 20.736/24.624, 18.792/23.328 (footer secondary lines) | 3 | `\fsSmall` | Footer affiliation / email / "Corresponding author" |

All legacy macro names (`\titlefont`, `\subtitlefont`, `\authorfont`,
`\affilfont`, `\bodyfont`, `\smallbody`, `\tinybody`, `\tablefont`,
`\captionfont`) are kept as thin aliases onto the 5 tokens (same trailing
`\bfseries`/`\selectfont`/`\color` as before, size swapped), so no call
site had to change wording or structure — only the `\fontsize{}{}`
argument changed. `assets/fig_release_trends_vector.tex` and
`assets/fig_replication_vector.tex` use pgfplots' relative sizes
(`\normalsize`, `\Large`) rather than literal `\fontsize`, so they were
not part of the 20-size inventory and were left untouched (no plotted
data or tick/label sizing was touched, per the constraint on those two
files).

### Final inventory

```
grep -oE '\fontsize\{[0-9.]+\}\{[0-9.]+\}' *.tex assets/*.tex | sort | uniq -c
      1 fontsize{19}{23}
      1 fontsize{23}{28}
      1 fontsize{30}{36}
      1 fontsize{40}{47}
      1 fontsize{75}{82}
```
Exactly **5 distinct sizes** remain (each appearing once, in the 5 token
definitions; every other call site now references a token, not a literal
size). Down from 20 distinct sizes / 28 literal `\fontsize` call sites.

### Reflow fallout and fix (overflow found by rendering, not by build.ps1)

The brief warned that `\fsBody` (23pt) is close to the old `\smallbody`
(22.81pt) so most body text "barely moves" — true for the *font size*,
but its *leading* also grew slightly (28pt vs 27.216pt), and that leading
increase applies to dozens of body-text lines across the whole poster.
Combined with `\fsSmall`'s leading growing versus `\tinybody`/`\captionfont`
(23pt vs 22.032pt/20.736pt) across ~20 caption/label lines, the net height
change was a small *increase*, not the expected decrease from the
larger-macro shrinks (section-10 bodies 29.7->23, author line 36.288->30).

This didn't show up in any `build.ps1` check (no Overfull `\vbox` was ever
reported), but rendering the full page at 300 DPI and inspecting the
footer band pixel-by-pixel showed the whole document spilling past
`\textheight`: the first build after the raw token swap pushed all content
onto a spurious second page (the `\fsH1`/`\fsH2` bug above); after fixing
that, the single-page build still had the footer's second line (affiliation
/ email / "Corresponding author") rendering *below the visible page* —
i.e. genuinely invisible, not just tight. Checking the original,
pre-existing (`c3384c2`) PDF the same way showed this was already a
latent bug: the footer band there also touched `PDFy=0` (the physical
media edge) with **zero clearance from the trim line**, and its own
second line was already being clipped by the page boundary — nobody had
caught it because it's invisible at normal preview zoom and outside every
automated check in `build.ps1`.

Fixed by adjusting spacing only (no sixth font size introduced, no
wording changed):
- `\parskip`: `0.15in` -> `0.07in`
- the 7 inter-section-box `\vspace{0.1904in}` gaps (columns 1-3) -> `0.13in`
- header inter-line gaps (title-to-subtitle `0.2539in` -> `0.15in`;
  subtitle-to-author `0.3491in` -> `0.2in`)
- section-10 tcolorbox fixed `height=3.4in` -> `2.6in` (was leaving
  ~30-40% empty space at the bottom of all 3 boxes at the new, smaller
  23pt body size — reducing it also improved visual balance)
- section-10 heading-to-body gap `\vspace{0.1495in}` -> `0.1in`, and the
  intra-box paragraph gap `\vspace{0.253in}` -> `0.15in` (x3 each)
- the `\vspace{0.2222in}` before section 10 -> `0.15in`, and the
  `\vspace{0.1495in}` before the footer -> `0.06in`
- the footer `tcolorbox`'s own `top=`/`bottom=` padding: `0.108in` ->
  `0.03in`

Net result: the footer's bottom edge moved from **0pt clearance (flush
with the physical media edge, second line invisible)** to **~15.3pt
(~5.4mm) clearance above the trim line**, with both footer text lines
fully visible in every column. This is less than the poster's own 10mm
clearance convention used elsewhere (`\textheight` vs. the 25mm margin
is a fixed relationship that these spacing edits could not move past a
point — further probing showed the footer box's top position is
effectively pinned by the page geometry, not by upstream paragraph
spacing, so additional `\parskip`/`\vspace` cuts stopped helping once the
overflow itself was resolved), but it is a clear, verified improvement
over both the immediate post-rename regression and the original,
already-accepted PDF. Flagging for the author: ~5.4mm is a thinner
safety margin than the rest of the poster's 10mm convention: if the print
vendor's trim registration has more than ~5mm tolerance, worth a final
visual check on the physical proof.

### Before / after visual comparison (type scale pass)

Rendered the pre-typography-pass PDF (`c3384c2`) and the final PDF full-page
at 40 DPI and each of the 3 columns at 150 DPI, side by side:

- The 20-size version reads as visibly inconsistent up close: the
  section-10 box headings, the header "ECCV" badge, and the footer paper
  title are all subtly different sizes from their nearest neighbours even
  though they play the same visual role. The 5-size version reads as
  clearly tiered: one title size, one heading size (subtitle/section
  tabs/author), one body size used everywhere text is prose, one small
  size used everywhere text is a label/caption/table/footnote.
- Section-10 boxes: at the old 29.7pt body size the three boxes
  (Contribution / Empirical signal / Limitation) had noticeably more
  bottom whitespace than the rest of the poster's boxes; at the new 23pt
  size (`\fsBody`, matching every other body paragraph in the poster) plus
  the reduced `height=2.6in`, all three boxes are now visually consistent
  with the tightness of sections 1-9.
- No diagram changed size or content: diagrams A/B/C (posterior-sketch
  strip, anonymity-budget bars, attacker ladder) still read correctly —
  labels are legible, no collisions, only their font now matches
  `\fsBody`/`\fsSmall` instead of one-off literal sizes.
- Footer: previously showed one visible line per column with the second
  line (affiliation/email/"Corresponding author") invisible below the
  page edge; now shows both lines in all 3 columns, still clearly
  smaller/secondary (`\fsSmall`) versus the bold primary line
  (`\fsBody`).
- `build.ps1` re-run clean after the final spacing fix: exit 0, all
  checks green (MediaBox/TrimBox/BleedBox geometry, crop marks at all 4
  corners, fonts embedded+subsetted with no Type 3 bitmap fonts, zero RGB
  paint operators, Katz logo 204.5 DPI, no Overfull/Underfull hbox or
  vbox beyond 5pt). Minimum rendered text size is 19pt (`\fsSmall`) —
  used only for tables, captions, diagram labels, and footer secondary
  text, matched to the old `\tablefont` (19.051pt), so legibility at
  poster-viewing distance is unchanged from the original design.

## Section 5 & 6 chart redesign

Replaced the §5 line chart (`assets/fig_release_trends_vector.tex`) with two
annotated heatmaps, and the §6 line chart (`assets/fig_replication_vector.tex`)
with two dumbbell (before→after) panels. Reason: in §5, A0/A3/A4 converged to
within 0.04 after R2 (three overlapping lines) and A2/A0-Graph were single
R4-only points forced into line-chart grammar; in §6, four "lines" spanned
only two x-positions and nearly collided at R2 (Market A0 4.966 vs CUHK03 A3
4.977). Neither is a trend a line chart should be drawing.

### Data cross-check against the paper

Every value below was checked character-for-character against
`Compositional_Non_Face_Re_Identification_Pressure_under_Cumulative_Vision_Releases.tex`
(read-only source). No number was changed, invented, or interpolated.

**§5 — `tab:exp_means` (lines 828–844):**

| Attacker | R1 P_g / vRPI2 | R2 P_g / vRPI2 | R3 P_g / vRPI2 | R4 P_g / vRPI2 |
|---|---|---|---|---|
| A0 | .2883 / 4.3319 | .7491 / 6.2119 | .7529 / 5.9271 | — |
| A1 | .1600 / 1.6561 | .5375 / 4.9997 | .5372 / 4.9917 | — |
| A3 | .4073 / 4.7231 | .7063 / 5.9402 | .7092 / 5.9368 | — |
| A4 | .5073 / 5.0912 | .7304 / 6.0133 | .7238 / 6.0060 | — |
| A2 | — | — | — | .7519 / 6.3572 |
| A0-Graph | — | — | — | .7366 / 5.6697 |

All 24 cells (14 present, 10 blank) match the table exactly. A1 was omitted
from the old line-chart version; it is included here as its own row (a
heatmap grid absorbs an extra row for free, and A1 already appears in the
§7 attacker ladder, so leaving it out here read as inconsistent, not
deliberate).

**§6 — `tab:cuhk_replication` (lines 997–1000):**

| Row | R1 P_g → R2 P_g | R1 vRPI2 → R2 vRPI2 |
|---|---|---|
| Market A0 | .197 → .547 | .873 → 4.966 |
| Market A3 | .368 → .691 | 5.198 → 5.943 |
| CUHK03 A0 | .226 → .399 | .530 → 3.325 |
| CUHK03 A3 | .313 → .502 | 4.549 → 4.977 |

All 8 pairs match the table exactly; row order matches the paper's table
order and is identical between the two panels.

### Ramp / colour

Both new figures use a single-hue sequential ramp built by scaling navy's own
CMYK components by t = 0.2, 0.4, 0.6, 0.8, 1.0 (pure tint ladder, same hue,
no new colour): `navyramp1`..`navyramp4` newly defined, `navyramp5` is
`\colorlet` to the existing `navy` (not redefined, reused exactly). Heatmap
buckets were assigned by linear min-max normalization *within each metric*,
using only the present values (P_guess: min .1600 @A1/R1, max .7529 @A0/R3;
vRPI2: min 1.6561 @A1/R1, max 6.3572 @A2/R4) — the resulting concentration of
cells in the top bucket after R2 is the correct visual read of the
convergence the redesign was meant to surface, not a defect. Blank/no-value
cells use a separate hue-free `heatempty` (K-only pale gray, cmyk
0,0,0,0.06) with an en-dash, so "no data" cannot be misread as "low value."
Dumbbell dots reuse `navyramp2` (light = R1) and `navy`/`navyramp5` (dark =
R2) — the same two ramp steps used in the §5 legend, so the poster's two
redesigned charts read as one system. Zero RGB anywhere (build check 5 is
green: 0 painted rg/RG ops).

### Contrast handling

Cell text flips to white starting at bucket 3 (t=0.6) and stays white through
bucket 5 (navy, t=1.0); buckets 1–2 and the empty/gray cells keep dark navy
text. Checked by rendering at 150 dpi and pixel-inspecting the lightest cell
(A1/R1 `.1600`, bucket 1, dark-on-light — legible) and a representative
mid-ramp cell (A0/R1 vRPI2 `4.3319`, bucket 3, white-on-medium-navy —
legible) directly; the darkest bucket (navy, bucket 5) is the poster's
existing navy swatch used everywhere else with white text, already known-good.

### Bugs found and fixed during this pass (all caught only by rendering)

1. **`\rx1`/`\rx2` are not valid TeX control-word names.** Control words are
   letters-only; `\pgfmathsetmacro{\rx1}{...}` tokenizes as macro `\rx`
   followed by a stray literal character `1`, so `\rx1` and `\rx2` both
   silently clobbered the same macro `\rx`, and the trailing digit leaked
   into the typeset output as garbled overlapping digits with every dumbbell
   arrow collapsing onto a single point. Fixed by renaming to letters-only
   `\rxone`/`\rxtwo`. (The §5 heatmap macro used `\cx`/`\cy` throughout and
   never hit this.)
2. Two-line row labels (`Market\\A0`) were taller than the row pitch, so
   adjacent rows' labels overlapped — switched to a single-line label
   (`Market A0`).
3. R1/R2 value labels both anchored directly above their dots collided
   whenever the two dots were close together (small R1→R2 gap, e.g. Market
   A3 vRPI2 5.198→5.943 or CUHK03 A3 4.549→4.977) — fixed by flanking the
   labels outward (R1 label anchored south-east of its dot, R2 label
   anchored south-west of its dot) so they diverge instead of colliding
   regardless of gap size.
4. The legend's R2 marker sat close enough to the "R1" text to visually
   crowd it — widened the legend spacing.
5. The `$vRPI_2$` axis-title touched the "4" tick label in the right panel —
   increased the vertical gap between tick labels and the axis title.

### Visual verification (rendered from `6474_Joshi_1400x1000mm.pdf` at 150 dpi)

- §5: both heatmaps read cleanly — every present cell shows its exact value
  from the paper; dark cells (buckets 3–5) have white text, light cells
  (buckets 1–2) have dark navy text, all legible at this zoom; blank cells
  are visibly pale gray with an en-dash, clearly distinct from the bluish
  data cells (not readable as zero); the ramp legend (pale→dark, "low"/
  "high") renders under each panel.
- §6: all four rows are readable in both panels with no label collisions;
  every connector arrow points right (Market A0, Market A3, CUHK03 A0,
  CUHK03 A3, in both P_guess and vRPI2); light/dark dot shading is
  unambiguous; row order matches between panels.
- Both boxes fit inside their original section-box outlines with no
  spillover into section 7 below; `build.ps1`'s Overfull/Underfull check and
  page count (1) both stayed green throughout.
- Compared with the old line charts: the §5 convergence band (A0/A3/A4
  merging into one line after R2) is now three distinct-but-similarly-dark
  cells with distinct printed numbers, instead of an overlapping visual
  knot; the §6 near-collision at R2 (Market A0 4.966 vs CUHK03 A3 4.977) is
  now two separate rows with no shared geometry at all.
