"""Render the display PNGs from the print PDF.

Renders the TRIM area only (1400x1000mm) so no bleed or crop marks appear.
The poster is 1.4:1; the 5120x2880 upload cap is 1.78:1, so the fit is
height-bound -> 2880*1.4 = 4032 wide. The 320x256 thumbnail is 1.25:1, so the
poster is fitted to width and centred on white rather than cropped, which would
have cut off the header or footer.
"""
import subprocess, os
from PIL import Image

BIN = r'C:\Users\tirth\AppData\Local\Programs\MiKTeX\miktex\bin\x64'
PDF = '6474_Joshi_1400x1000mm.pdf'
TRIM_W, TRIM_H, INSET = 1400.0, 1000.0, 15.0
OUT_W, OUT_H = 4032, 2880

scale = OUT_W / TRIM_W
dpi = scale * 25.4 * 2          # render 2x then downsample, so small type stays crisp
subprocess.run([os.path.join(BIN, 'pdftocairo.exe'), '-png', '-r', f'{dpi:.4f}',
                '-singlefile', PDF, '_big'], check=True,
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

im = Image.open('_big.png').convert('RGB')
ppm = im.width / (TRIM_W + 2 * INSET)
trim = im.crop((round(INSET * ppm), round(INSET * ppm),
                round((INSET + TRIM_W) * ppm), round((INSET + TRIM_H) * ppm)))

poster = trim.resize((OUT_W, OUT_H), Image.LANCZOS)
poster.save('poster.png', optimize=True)

tw, th = 320, 256
fitted = poster.resize((tw, round(poster.height * tw / poster.width)), Image.LANCZOS)
thumb = Image.new('RGB', (tw, th), (255, 255, 255))
thumb.paste(fitted, (0, (th - fitted.height) // 2))
thumb.save('poster-thumbnail.png', optimize=True)

os.remove('_big.png')
print(f'poster.png {poster.size}  thumbnail {thumb.size}')
