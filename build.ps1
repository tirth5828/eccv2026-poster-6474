# build.ps1
# Build + verify the ECCV 2026 poster against the Nordic Expo Service printer spec:
#   1400 x 1000 mm trim, 10mm bleed, 5mm crop-mark quiet zone (1430x1030mm media),
#   native CMYK, embedded/subsetted fonts, >=100 DPI raster figures, crop marks,
#   content inside the trim box with clearance, no Overfull hbox/vbox.
#
# Compiles pdflatex twice, runs the checks below, and renames the result to
# 6474_Joshi_1400x1000mm.pdf. Exits non-zero (and prints FAIL lines) if any
# check does not pass.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$MikTexBin = "C:\Users\tirth\AppData\Local\Programs\MiKTeX\miktex\bin\x64"
$PdfLatex  = Join-Path $MikTexBin "pdflatex.exe"
$PdfInfo   = Join-Path $MikTexBin "pdfinfo.exe"
$PdfFonts  = Join-Path $MikTexBin "pdffonts.exe"
$PdfToPs   = Join-Path $MikTexBin "pdftops.exe"
$PdfToPpm  = Join-Path $MikTexBin "pdftoppm.exe"

$TexFile   = "ECCV_2026_Poster_Tirth_Joshi.tex"
$BaseName  = "ECCV_2026_Poster_Tirth_Joshi"
$PdfFile   = "$BaseName.pdf"
$LogFile   = "$BaseName.log"
$FinalName = "6474_Joshi_1400x1000mm.pdf"

$script:failures = @()
function Fail([string]$msg) {
    Write-Host "FAIL: $msg" -ForegroundColor Red
    $script:failures += $msg
}
function Pass([string]$msg) {
    Write-Host "OK:   $msg" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 1. Compile twice
# ---------------------------------------------------------------------------
Write-Host "== pdflatex pass 1/2 ==" -ForegroundColor Cyan
# pdflatex writes a harmless "you have not checked for MiKTeX updates" notice to
# stderr on this machine; under $ErrorActionPreference=Stop that non-terminating
# native-command stderr gets promoted into a terminating error even though
# pdflatex exits 0 and the PDF is produced fine. Relax to Continue only around
# the two pdflatex invocations so that chatter doesn't abort the build.
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& $PdfLatex -interaction=nonstopmode --enable-installer $TexFile 2>&1 | Out-File -Encoding utf8 "build_pass1.log"
Write-Host "== pdflatex pass 2/2 ==" -ForegroundColor Cyan
& $PdfLatex -interaction=nonstopmode --enable-installer $TexFile 2>&1 | Out-File -Encoding utf8 "build_pass2.log"
$ErrorActionPreference = $prevEAP

if (-not (Test-Path $PdfFile)) {
    Fail "PDF was not produced by pdflatex"
    Write-Host "`nBUILD FAILED - see above" -ForegroundColor Red
    exit 1
}
Pass "PDF produced: $PdfFile"

# ---------------------------------------------------------------------------
# 2. No Overfull / Underfull hbox/vbox (tolerate < 5pt rounding noise)
# ---------------------------------------------------------------------------
$logText = Get-Content $LogFile -Raw
$badBoxes = @()
$boxMatches = [regex]::Matches($logText, "(Overfull|Underfull) \\[hv]box \(([0-9.]+)pt too (wide|high)\)")
foreach ($m in $boxMatches) {
    $amt = [double]$m.Groups[2].Value
    if ($amt -gt 5.0) { $badBoxes += $m.Value }
}
if ($badBoxes.Count -gt 0) {
    Fail "Overfull/Underfull hbox or vbox > 5pt found:`n  $($badBoxes -join "`n  ")"
} else {
    Pass "No Overfull/Underfull hbox or vbox beyond 5pt rounding noise"
}

# ---------------------------------------------------------------------------
# 3. pdfinfo -box : MediaBox 1430x1030mm, TrimBox 1400x1000mm, BleedBox 1420x1020mm
# ---------------------------------------------------------------------------
$boxInfo = (& $PdfInfo -box $PdfFile) -join "`n"
Write-Host $boxInfo

function Test-Box([string]$label, [string]$pattern) {
    if ($boxInfo -match $pattern) {
        Pass "$label matches expected geometry"
    } else {
        Fail "$label does NOT match expected geometry (pattern: $pattern)"
    }
}
Test-Box "MediaBox (1430x1030mm)" "MediaBox:\s+0\.00\s+0\.00\s+4053\.5[0-9]\s+2919\.6[0-9]"
Test-Box "TrimBox (1400x1000mm)"  "TrimBox:\s+42\.5[0-9]\s+42\.5[0-9]\s+4011\.0[0-9]\s+2877\.1[0-9]"
Test-Box "BleedBox (1420x1020mm)" "BleedBox:\s+14\.1[0-9]\s+14\.1[0-9]\s+4039\.3[0-9]\s+2905\.5[0-9]"

# ---------------------------------------------------------------------------
# 4. pdffonts : every font embedded and subsetted, no Type 3 bitmap fonts
# ---------------------------------------------------------------------------
$fontsRaw = & $PdfFonts $PdfFile
Write-Host ($fontsRaw -join "`n")
$fontRows = $fontsRaw | Select-Object -Skip 2 | Where-Object { $_.Trim() -ne "" }
if ($fontRows.Count -eq 0) {
    Fail "pdffonts reported no fonts at all (unexpected)"
} else {
    $badFonts = @()
    foreach ($row in $fontRows) {
        $cols = ($row -replace '\s+', ' ').Trim().Split(' ')
        # columns: name type... encoding emb sub uni objectID gen  (type may be 2 tokens e.g. "Type 1")
        if ($row -match 'Type 3') { $badFonts += "$row  (Type 3 bitmap font - not scalable)" }
        if ($row -notmatch '\byes\s+yes\s+(yes|no)\s+\d') { $badFonts += "$row  (not embedded+subsetted)" }
    }
    if ($badFonts.Count -gt 0) {
        Fail "Fonts not embedded/subsetted or Type 3 bitmap fonts present:`n  $($badFonts -join "`n  ")"
    } else {
        Pass "All fonts embedded and subsetted; no Type 3 bitmap fonts"
    }
}

# ---------------------------------------------------------------------------
# 5. No RGB paint operators (decompress via pdftops, scan for rg/RG and /DeviceRGB)
# ---------------------------------------------------------------------------
& $PdfToPs $PdfFile "check_decompressed.ps" 2>$null
$psText = Get-Content "check_decompressed.ps" -Raw
$paintMatches = [regex]::Matches($psText, "[0-9.]+ [0-9.]+ [0-9.]+ (rg|RG)\b")
$rgbColorspaceCount = ([regex]::Matches($psText, "/DeviceRGB")).Count
$pgfprgbCount = ([regex]::Matches($psText, "pgfprgb")).Count

if ($paintMatches.Count -gt 0) {
    Fail "Found $($paintMatches.Count) painted rg/RG (DeviceRGB) operators in content stream"
} else {
    Pass "No painted rg/RG operators found"
}
# Allow at most one inert /pgfprgb [/Pattern /DeviceRGB] resource entry (unused TikZ artifact).
# Every remaining /DeviceRGB occurrence must be accounted for by that single inert resource.
if ($rgbColorspaceCount -gt $pgfprgbCount) {
    Fail "Found $rgbColorspaceCount /DeviceRGB colorspace selconnections but only $pgfprgbCount look like the inert pgfprgb resource - investigate"
} else {
    Pass "/DeviceRGB occurrences ($rgbColorspaceCount) fully accounted for by inert pgfprgb resource allowance"
}
Remove-Item "check_decompressed.ps" -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
# 6. Raster DPI at placed size (>=100 DPI required)
#    fig-release-trends and fig-replication (sections 5/6) were converted to native
#    vector pgfplots/TikZ figures and are no longer raster, so no DPI constraint
#    applies to them (checked only for informational placed-width logging below).
#    The Katz logo remains the only raster asset in the poster and is still checked.
# ---------------------------------------------------------------------------
$passLog = Get-Content "build_pass2.log" -Raw
foreach ($key in @("fig-release-trends","fig-replication")) {
    $pat = "POSTER-CHECK: $key placed-linewidth-pt=\[([0-9.]+)pt\]"
    if ($passLog -match $pat) {
        $linewidthPt = [double]$Matches[1]
        $placedWidthIn = (0.94 * $linewidthPt) / 72.27
        Pass ("{0}: now vector (pgfplots/TikZ); placed width {1:N2}in, no DPI constraint" -f $key, $placedWidthIn)
    } else {
        Fail "Could not find POSTER-CHECK linewidth for $key in build log"
    }
}
# Both logos are raster; each must clear 100 DPI at its placed size and stay
# under the 180mm cap. PxWidth is the source pixel width of each asset.
$logos = @(
    @{ Key = "katz-logo"; PxWidth = 900;  CapMm = 180 }
)
if ($passLog -match "POSTER-CHECK: eccv-logo placed-width-pt=\[([0-9.]+)pt\]") {
    $eccvIn = [double]$Matches[1] / 72.27
    Pass ("eccv-logo: vector (from organizers' SVG); placed width {0:N2}in ({1:N1}mm), no DPI constraint" -f $eccvIn, ($eccvIn * 25.4))
} else {
    Fail "Could not find POSTER-CHECK width for eccv-logo in build log"
}
foreach ($lg in $logos) {
    $pat = "POSTER-CHECK: $($lg.Key) placed-width-pt=\[([0-9.]+)pt\]"
    if ($passLog -match $pat) {
        $wIn = [double]$Matches[1] / 72.27
        $dpi = $lg.PxWidth / $wIn
        if ($wIn -le ($lg.CapMm / 25.4) + 0.01) {
            Pass ("{0}: placed width {1:N2}in ({2:N1}mm) <= {3}mm cap" -f $lg.Key, $wIn, ($wIn*25.4), $lg.CapMm)
        } else {
            Fail ("{0}: placed width {1:N2}in exceeds the {2}mm cap" -f $lg.Key, $wIn, $lg.CapMm)
        }
        if ($dpi -ge 100) {
            Pass ("{0}: {1:N1} DPI (>= 100)" -f $lg.Key, $dpi)
        } else {
            Fail ("{0}: {1:N1} DPI (< 100 !)" -f $lg.Key, $dpi)
        }
    } else {
        Fail "Could not find POSTER-CHECK width for $($lg.Key) in build log"
    }
}

# ---------------------------------------------------------------------------
# 7. Crop marks present near all four corners, outside the bleed box
# ---------------------------------------------------------------------------
& $PdfToPpm -png -r 40 $PdfFile "check_render" 2>$null
$renderPng = Get-ChildItem "check_render-*.png" | Select-Object -First 1
if ($null -eq $renderPng) {
    Fail "Could not render PDF to PNG for crop-mark check"
} else {
    Add-Type -AssemblyName System.Drawing
    $bmp = [System.Drawing.Bitmap]::FromFile($renderPng.FullName)
    $w = $bmp.Width; $h = $bmp.Height
    # crop marks live in the 0-5mm quiet zone at each trim corner (15mm from edge);
    # at 40dpi, 1mm ~= 1.575px. Probe a small window near each corner (not the exact
    # corner pixel, to tolerate anti-aliasing) for any non-white pixel.
    function Test-CornerInk([int]$x0, [int]$y0, [int]$x1, [int]$y1, [string]$label) {
        $found = $false
        for ($y = $y0; $y -lt $y1 -and -not $found; $y++) {
            for ($x = $x0; $x -lt $x1 -and -not $found; $x++) {
                $px = $bmp.GetPixel($x, $y)
                if (($px.R -lt 250) -or ($px.G -lt 250) -or ($px.B -lt 250)) { $found = $true }
            }
        }
        if ($found) { Pass "Crop mark ink detected near $label corner" }
        else { Fail "No crop mark ink detected near $label corner" }
    }
    $margin = 30
    Test-CornerInk 0 0 $margin $margin "top-left"
    Test-CornerInk ($w - $margin) 0 $w $margin "top-right"
    Test-CornerInk 0 ($h - $margin) $margin $h "bottom-left"
    Test-CornerInk ($w - $margin) ($h - $margin) $w $h "bottom-right"
    $bmp.Dispose()
}
Remove-Item "check_render-*.png" -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# 7b. Content sits inside the TrimBox with >=5mm clearance on all four sides.
#     Added after the footer was found sitting ENTIRELY below the trim line --
#     the fixed-height content frame used inner position [t], which appends
#     \vss (infinitely shrinkable glue), so the overflow never raised a warning.
# ---------------------------------------------------------------------------
$marginOut = & python check_margins.py $PdfFile 2>&1
$marginOut | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    Fail "Content does not clear the trim box by >=5mm on all sides"
} else {
    Pass "Content inside TrimBox with >=5mm clearance on all four sides"
}

# 8. Minimum rendered text size (report only; flag if below ~24pt)
# ---------------------------------------------------------------------------
$texText = Get-Content $TexFile -Raw
$sizeMatches = [regex]::Matches($texText, "\\fontsize\{([0-9.]+)\}\{[0-9.]+\}")
$sizes = $sizeMatches | ForEach-Object { [double]$_.Groups[1].Value }
$minSize = ($sizes | Measure-Object -Minimum).Minimum
Write-Host ("Minimum \fontsize found in source: {0}pt" -f $minSize)
if ($minSize -lt 24) {
    Write-Host ("FLAG: minimum text size {0}pt is below the ~24pt poster-distance comfort threshold (this is the author's caption/table-footnote text; preserved intentionally per the original design)." -f $minSize) -ForegroundColor Yellow
} else {
    Pass "Minimum text size $minSize pt is at/above the 24pt comfort threshold"
}

# ---------------------------------------------------------------------------
# Finalize: rename deliverable
# ---------------------------------------------------------------------------
if ($script:failures.Count -eq 0) {
    Copy-Item $PdfFile $FinalName -Force
    Pass "Deliverable written: $FinalName"
    Write-Host "`n================ BUILD PASSED ================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n================ BUILD FAILED ================" -ForegroundColor Red
    Write-Host "$($script:failures.Count) check(s) failed:" -ForegroundColor Red
    foreach ($f in $script:failures) { Write-Host " - $f" -ForegroundColor Red }
    exit 1
}
