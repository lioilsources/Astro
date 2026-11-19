"""Build the offline place list for the app from GeoNames (CC BY 4.0).

Czech names from alternate names (cs, sk). Czech and Slovak populated places (all sizes) + world cities over 15 000
inhabitants, with IANA time zone. Output: app/assets/data/places.tsv

    python3 build_places.py
"""
import csv
import io
import pathlib
import unicodedata
import urllib.request
import zipfile

HERE = pathlib.Path(__file__).resolve().parent
DATA = HERE / "data"
OUT = HERE.parents[1] / "app/assets/data/places.tsv"
BASE = "https://download.geonames.org/export/dump/"


def fetch(name):
    DATA.mkdir(exist_ok=True)
    p = DATA / name
    if not p.exists():
        urllib.request.urlretrieve(BASE + name, p)
    return p


def rows(zipname, member):
    with zipfile.ZipFile(fetch(zipname)) as z:
        with z.open(member) as f:
            yield from csv.reader(io.TextIOWrapper(f, encoding="utf-8"), delimiter="\t", quoting=csv.QUOTE_NONE)


def fold(s):
    return "".join(c for c in unicodedata.normalize("NFD", s.lower()) if unicodedata.category(c) != "Mn")


countries = {}
for line in urllib.request.urlopen(BASE + "countryInfo.txt").read().decode("utf-8").splitlines():
    if line and not line.startswith("#"):
        parts = line.split("\t")
        countries[parts[0]] = parts[4]

places = {}
alias = {}
def add(r):
    gid, name, ascii_, alt, lat, lon, fclass, fcode, cc = r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8]
    pop, tz = r[14], r[17]
    if fclass != "P" or not tz:
        return
    places[gid] = (name, fold(name), cc, f"{float(lat):.4f}", f"{float(lon):.4f}", tz, pop or "0")

for cc in ["CZ", "SK"]:
    for r in rows(f"{cc}.zip", f"{cc}.txt"):
        add(r)
for r in rows("cities15000.zip", "cities15000.txt"):
    add(r)

# Czech and Slovak names (Praha for Prague, Vídeň for Vienna) from alternateNamesV2.
cs_name = {}
for r in rows("alternateNamesV2.zip", "alternateNamesV2.txt"):
    gid, lang, name = r[1], r[2], r[3]
    if gid not in places or lang not in ("cs", "sk"):
        continue
    if (len(r) > 6 and r[6] == "1") or (len(r) > 7 and r[7] == "1"):
        continue  # colloquial or historic
    alias.setdefault(gid, set()).add(fold(name))
    if lang == "cs" and (gid not in cs_name or (len(r) > 4 and r[4] == "1")):
        cs_name[gid] = name
for gid, name in cs_name.items():
    p = places[gid]
    if name != p[0]:
        alias.setdefault(gid, set()).add(p[1])
        places[gid] = (name, fold(name)) + p[2:]

ordered = sorted(((p + ("|".join(sorted(alias.get(g, set()) - {p[1]})),)) for g, p in places.items()), key=lambda p: (-int(p[6]), p[0]))
OUT.parent.mkdir(parents=True, exist_ok=True)
with open(OUT, "w", encoding="utf-8") as f:
    f.write("# GeoNames (geonames.org), CC BY 4.0. name\tfolded\tcountry\tlat\tlon\ttz\tpopulation\taliases\n")
    for p in ordered:
        f.write("\t".join(p) + "\n")
print(len(ordered), "places", OUT.stat().st_size // 1024, "KiB")
