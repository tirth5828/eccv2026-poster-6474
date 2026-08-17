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
