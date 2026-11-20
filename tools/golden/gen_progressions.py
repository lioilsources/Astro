"""Reference vectors for R5 progressions and solar returns (development only).

JPL DE440 via skyfield (MIT). Output: packages/astro_core/test/golden/progressions.json

    .venv/bin/python gen_progressions.py

DE440_BSP overrides the path of de440.bsp (default: data/ next to this script).
"""
import json
import os
import pathlib

from skyfield.api import load
from skyfield.framelib import ecliptic_frame

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "packages/astro_core/test/golden"

ts = load.timescale()
eph = load(os.environ.get("DE440_BSP", str(pathlib.Path(__file__).parent / "data/de440.bsp")))
earth = eph["earth"]
TROPICAL_YEAR = 365.242189


def lon(body, jd_ut):
    t = ts.ut1_jd(jd_ut)
    _, lo, _ = earth.at(t).observe(eph[body]).apparent().frame_latlon(ecliptic_frame)
    return lo.degrees


def diff(a, b):
    d = (a - b) % 360
    return d - 360 if d > 180 else d


# Natal charts given in UT (Julian Day): J2000 and two more spread over the century.
NATALS = {"j2000": 2451545.0, "1975": 2442500.3172, "1952": 2434100.81}

progressed = []
for name, natal in NATALS.items():
    for age in [0, 10, 25, 30, 47.5, 60, 90]:
        jd = natal + age  # one day after birth per year of life
        progressed.append({"natal": name, "natalJdUt": natal, "age": age, "jdUt": jd,
                           "moon": lon("moon", jd), "sun": lon("sun", jd)})

# Solar returns: the Sun back on the natal longitude, bisected below 0.01 s.
returns = []
for name, natal in NATALS.items():
    target = lon("sun", natal)
    for k in [1, 5, 20, 30, 45]:
        a = natal + k * TROPICAL_YEAR - 3
        b = a + 6
        while (b - a) * 86400 > 0.01:
            m = (a + b) / 2
            if diff(lon("sun", m), target) < 0:
                a = m
            else:
                b = m
        returns.append({"natal": name, "natalJdUt": natal, "sunLon": target, "years": k, "jdUt": (a + b) / 2})

(OUT / "progressions.json").write_text(json.dumps({"progressed": progressed, "solarReturns": returns}, indent=1))
print(f"progressed {len(progressed)}, solar returns {len(returns)}")
