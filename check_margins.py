"""Assert poster content sits inside the 1400x1000mm TrimBox with clearance.

The build had no such check, which is how the footer silently ended up entirely
below the trim line (it would have been cut off in print). The fixed-height
content frame used inner position [t], appending \vss -- infinitely SHRINKABLE
glue -- so LaTeX never warned about the overflow.

Crop marks legitimately live outside the trim, so the four corner zones are
excluded from the content measurement.
"""
import subprocess, sys, os
from PIL import Image
import numpy as np

PDF      = sys.argv[1] if len(sys.argv) > 1 else '6474_Joshi_1400x1000mm.pdf'
DPI      = 50.0
MEDIA_W, MEDIA_H = 1430.0, 1030.0   # mm
TRIM_INSET       = 15.0             # mm from media edge to trim line
MIN_CLEAR        = 5.0              # mm of content clearance required inside trim
CORNER_EXCLUDE   = 60.0             # mm corner zones where crop marks live
BIN = r'C:\Users\tirth\AppData\Local\Programs\MiKTeX\miktex\bin\x64'

tmp = '_marginchk'
subprocess.run([os.path.join(BIN, 'pdftocairo.exe'), '-png', '-r', str(int(DPI)),
                '-singlefile', PDF, tmp], check=True,
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
a = np.array(Image.open(tmp + '.png').convert('L'))
os.remove(tmp + '.png')

H, W = a.shape
mm = lambda p: p / DPI * 25.4
px = lambda m: int(round(m * DPI / 25.4))
ink = a < 245

m = ink.copy()
C = px(CORNER_EXCLUDE)
for y0, y1 in ((0, C), (H - C, H)):
    for x0, x1 in ((0, C), (W - C, W)):
        m[y0:y1, x0:x1] = False

ys, xs = np.where(m)
if len(ys) == 0:
    print('FAIL: no content ink found'); sys.exit(1)

clear = {
    'left':   mm(xs.min()) - TRIM_INSET,
    'right':  MEDIA_W - TRIM_INSET - mm(xs.max()),
    'top':    mm(ys.min()) - TRIM_INSET,
    'bottom': MEDIA_H - TRIM_INSET - mm(ys.max()),
}
bad = [k for k, v in clear.items() if v < MIN_CLEAR]
for k in ('left', 'right', 'top', 'bottom'):
    v = clear[k]
    tag = '  <-- OUTSIDE TRIM' if v < 0 else ('  <-- BELOW %.0fmm MINIMUM' % MIN_CLEAR if v < MIN_CLEAR else '')
    print('    %-7s %7.1f mm%s' % (k, v, tag))
if bad:
    print('FAIL: trim clearance too small on: ' + ', '.join(bad)); sys.exit(1)
print('OK: all four margins >= %.0fmm inside the trim' % MIN_CLEAR)
