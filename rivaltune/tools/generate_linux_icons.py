#!/usr/bin/env python3
from PIL import Image
import os

SRC = 'assets/icon/icon.png'
ICON_NAME = 'rivaltune.png'
SIZES = [512,256,128,96,64,48,32,24,16]
OUT_DIR = 'linux/icons/hicolor'

if not os.path.exists(SRC):
    raise SystemExit(f'Source icon not found: {SRC}')

img = Image.open(SRC).convert('RGBA')
for s in SIZES:
    dirpath = os.path.join(OUT_DIR, f'{s}x{s}', 'apps')
    os.makedirs(dirpath, exist_ok=True)
    outpath = os.path.join(dirpath, ICON_NAME)
    resized = img.resize((s, s), Image.LANCZOS)
    resized.save(outpath)
    print('Wrote', outpath)
