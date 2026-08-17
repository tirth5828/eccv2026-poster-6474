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
