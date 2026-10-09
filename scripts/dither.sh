#!/usr/bin/env bash
# Dither an image to a small grayscale PNG for the low-tech look.
#
#   ./scripts/dither.sh input.jpg assets/img/output.png
#
# Requires ImageMagick:  brew install imagemagick
set -euo pipefail

in="${1:?usage: dither.sh <input> <output.png>}"
out="${2:?usage: dither.sh <input> <output.png>}"

magick "$in" -resize '1000x1000>' -colorspace Gray -ordered-dither o8x8 "$out"

# Alternatives:
#   # Floyd–Steinberg error diffusion (grainier, "classic" look):
#   magick "$in" -resize '1000x1000>' -colorspace Gray -dither FloydSteinberg -colors 2 "$out"
#
#   # `didder` gives the most control over palettes (https://github.com/makew0rld/didder):
#   didder --palette 'black white' -i "$in" -o "$out" edm --serpentine FloydSteinberg

echo "wrote $out"
