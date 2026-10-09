"""Draw the footer's street-map strip: Mérida's historic centre, fading upward.

Reads OpenStreetMap ways (Overpass JSON, `out geom`) and writes an SVG strip.
Map data © OpenStreetMap contributors (ODbL), credited in the site footer.
The same data draws the background of the business card.

Get the data (any bbox around the centre works):
  curl -s --data-urlencode 'data=[out:json];way["highway"~"^(primary|secondary|tertiary|unclassified|residential|living_street|pedestrian)$"](20.950,-89.648,20.984,-89.598);out geom;' \
       https://overpass-api.de/api/interpreter -o merida-osm.json
Usage:
  python3 -I scripts/merida_streets.py merida-osm.json assets/img/merida-streets.svg
"""
import json
import math
import sys

SRC, OUT = sys.argv[1], sys.argv[2]

W, H = 2400.0, 160.0               # SVG units; the CSS sets the height to the footer's
WIDTH_M = 9000.0                   # metres of city across the strip
PLAZA = (20.96706, -89.62377)      # Plaza Grande (lat, lon), centred horizontally
PLAZA_AT = (0.5, 0.5)
MAX_OPACITY = 0.20                 # darkest, in the middle band (eases off behind the footer text)

scale = W / WIDTH_M
lat0, lon0 = PLAZA
kx = 111320.0 * math.cos(math.radians(lat0))
ky = 110540.0


def project(lat, lon):
    return ((lon - lon0) * kx * scale + PLAZA_AT[0] * W,
            (lat0 - lat) * ky * scale + PLAZA_AT[1] * H)


ways = [e for e in json.load(open(SRC, encoding="utf-8"))["elements"] if e.get("type") == "way"]
paths = []
for way in ways:
    pts = [project(p["lat"], p["lon"]) for p in way.get("geometry", [])]
    if len(pts) < 2 or all(not (-20 < x < W + 20 and -20 < y < H + 20) for x, y in pts):
        continue
    paths.append("M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts))

svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W:.0f} {H:.0f}" preserveAspectRatio="xMidYMid meet">
<defs>
<linearGradient id="fade" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="{H:.0f}">
<stop offset="0" stop-color="#000" stop-opacity="0"/>
<stop offset="0.4" stop-color="#000" stop-opacity="{MAX_OPACITY}"/>
<stop offset="0.65" stop-color="#000" stop-opacity="{MAX_OPACITY * 0.7:.3f}"/>
<stop offset="1" stop-color="#000" stop-opacity="{MAX_OPACITY * 0.35:.3f}"/>
</linearGradient>
<linearGradient id="ends" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="{W:.0f}" y2="0">
<stop offset="0" stop-color="#fff" stop-opacity="0"/>
<stop offset="0.15" stop-color="#fff" stop-opacity="1"/>
<stop offset="0.85" stop-color="#fff" stop-opacity="1"/>
<stop offset="1" stop-color="#fff" stop-opacity="0"/>
</linearGradient>
<mask id="sides"><rect width="{W:.0f}" height="{H:.0f}" fill="url(#ends)"/></mask>
</defs>
<path mask="url(#sides)" fill="none" stroke="url(#fade)" stroke-width="1" vector-effect="non-scaling-stroke" stroke-linecap="round" stroke-linejoin="round" d="{' '.join(paths)}"/>
</svg>
"""
open(OUT, "w", encoding="utf-8").write(svg)
print(f"{len(paths)} streets -> {OUT}")
