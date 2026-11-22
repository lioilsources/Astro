"""Reference vector for R9 periods: exact passes of the Saturn return (development only).

JPL DE440 via skyfield (MIT). Output: packages/astro_core/test/golden/pair_saturn_return.json

    .venv/bin/python gen_pair.py

Natal chart: 2000-01-01 12:00 UT. Transiting Saturn on its natal longitude, found by
sampling every 2 days and bisecting the sign change below one minute.
"""
import json
import os
import pathlib

from skyfield.api import load
from skyfield.framelib import ecliptic_frame

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "packages/astro_core/test/golden/pair_saturn_return.json"

ts = load.timescale()
eph = load(os.environ.get("DE440_BSP", str(pathlib.Path(__file__).parent / "data/de440.bsp")))
earth = eph["earth"]
SATURN = eph["saturn barycenter"]


def lon(jd_ut):
    t = ts.ut1_jd(jd_ut)
    _, lo, _ = earth.at(t).observe(SATURN).apparent().frame_latlon(ecliptic_frame)
    return lo.degrees


def diff(a, b):
    d = (a - b) % 360
    return d - 360 if d > 180 else d


NATAL = 2451545.0
target = lon(NATAL)
exacts = []
t, step = NATAL + 365 * 27, 2.0
end = NATAL + 365 * 31
prev = diff(lon(t), target)
while t < end:
    t2 = t + step
    cur = diff(lon(t2), target)
    if prev != 0 and abs(prev) < 90 and abs(cur) < 90 and (prev < 0) != (cur < 0):
        lo, hi = t, t2
        while hi - lo > 1 / 1440:
            m = (lo + hi) / 2
            if (diff(lon(m), target) < 0) == (prev < 0):
                lo = m
            else:
                hi = m
        exacts.append((lo + hi) / 2)
    t, prev = t2, cur

OUT.write_text(json.dumps({"natalJdUt": NATAL, "saturnLon": target, "exacts": exacts}, indent=1) + "\n")
print(OUT, exacts)
