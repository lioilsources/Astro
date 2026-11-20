"""Build the people catalog (Prompts/KATALOG-osobnosti.md) from Wikidata (CC0).

Input:  candidates.tsv  (English Wikipedia title + categories)
        times.json      (by English Wikipedia title: birth times with a citable source and Rodden grade; the rest is X)
Output: content/people/people.json (app/assets/data/people.json is a symlink to it)

Wikidata responses are cached in run/people-cache/ (gitignored). Requests are sequential,
50 entities per call, with a pause in between.

    python3 tools/people/build_people.py
"""
import json
import math
import pathlib
import re
import time
import unicodedata
import urllib.parse
import urllib.error
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
CACHE = ROOT / "run/people-cache"
OUT = ROOT / "content/people/people.json"
PLACES = ROOT / "app/assets/data/places.tsv"
API = "https://www.wikidata.org/w/api.php"
UA = "AstroPeopleCatalog/0.1 (open-source astrology app; Wikidata CC0 import)"
GREGORIAN = "http://www.wikidata.org/entity/Q1985727"
JULIAN = "http://www.wikidata.org/entity/Q1985786"
MAX_EVENTS = 6


def api(params):
    CACHE.mkdir(parents=True, exist_ok=True)
    key = urllib.parse.urlencode(sorted(params.items()))
    p = CACHE / (re.sub(r"[^A-Za-z0-9]", "", key)[:60] + f"_{_stable(key)}.json")
    if p.exists():
        return json.loads(p.read_text())
    q = urllib.parse.urlencode({**params, "format": "json"})
    req = urllib.request.Request(f"{API}?{q}", headers={"User-Agent": UA})
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                data = json.loads(r.read())
            break
        except urllib.error.HTTPError as e:
            if e.code != 429 or attempt == 5:
                raise
            time.sleep(int(e.headers.get("Retry-After") or 30) + 5)
    p.write_text(json.dumps(data))
    time.sleep(3.0)
    return data


def _stable(s):
    h = 0
    for ch in s:
        h = (h * 131 + ord(ch)) % 10**12
    return h


def chunks(xs, n):
    for i in range(0, len(xs), n):
        yield xs[i : i + n]


def by_titles(titles):
    out = {}
    for c in chunks(titles, 50):
        d = api({"action": "wbgetentities", "sites": "enwiki", "titles": "|".join(c), "redirects": "yes",
                 "props": "claims|labels|sitelinks", "languages": "cs|en", "sitefilter": "enwiki|cswiki"})
        for qid, e in d.get("entities", {}).items():
            if "missing" in e:
                continue
            t = e.get("sitelinks", {}).get("enwiki", {}).get("title")
            out[t] = e
    return out


def by_ids(ids):
    out = {}
    for c in chunks(sorted(ids), 50):
        d = api({"action": "wbgetentities", "ids": "|".join(c), "props": "claims|labels", "languages": "cs|en"})
        out.update(d.get("entities", {}))
    return out


def label(e):
    ls = e.get("labels", {})
    return (ls.get("cs") or ls.get("en") or {}).get("value")


def claims(e, prop):
    return [c for c in e.get("claims", {}).get(prop, []) if c.get("rank") != "deprecated"
            and c["mainsnak"].get("snaktype") == "value"]


def best(e, prop):
    cs = claims(e, prop)
    pref = [c for c in cs if c.get("rank") == "preferred"]
    return pref or cs


def day_time(v):
    """Wikidata time value with day precision → (YYYY-MM-DD, calendar) or None."""
    if v.get("precision") != 11:
        return None
    m = re.match(r"^([+-])(\d+)-(\d\d)-(\d\d)T", v["time"])
    if not m or m.group(3) == "00" or m.group(4) == "00":
        return None
    y = int(m.group(2)) * (-1 if m.group(1) == "-" else 1)
    cal = "julian" if v.get("calendarmodel") == JULIAN else "gregorian"
    return f"{y:04d}-{m.group(3)}-{m.group(4)}", cal


def qual_date(c, prop):
    for q in c.get("qualifiers", {}).get(prop, []):
        if q.get("snaktype") == "value":
            dt = day_time(q["datavalue"]["value"])
            if dt:
                return dt
    return None


def jul_to_greg(date):
    """Julian calendar date → proleptic Gregorian (for event dates the app reads as Gregorian)."""
    y, m, d = (int(x) for x in date.split("-"))
    a = (14 - m) // 12
    yy, mm = y + 4800 - a, m + 12 * a - 3
    jdn = d + (153 * mm + 2) // 5 + 365 * yy + yy // 4 - 32083
    a = jdn + 32044
    b = (4 * a + 3) // 146097
    c = a - 146097 * b // 4
    dd = (4 * c + 3) // 1461
    e = c - 1461 * dd // 4
    mm = (5 * e + 2) // 153
    day = e - (153 * mm + 2) // 5 + 1
    month = mm + 3 - 12 * (mm // 10)
    year = 100 * b + dd - 4800 + mm // 10
    return f"{year:04d}-{month:02d}-{day:02d}"


def load_places():
    rows = []
    for line in PLACES.read_text().splitlines():
        if line.startswith("#"):
            continue
        f = line.split("\t")
        rows.append((float(f[3]), float(f[4]), f[5]))
    return rows


def nearest_zone(places, lat, lon):
    best_d, zone = 1e9, None
    cl = math.cos(math.radians(lat))
    for plat, plon, tz in places:
        d = (plat - lat) ** 2 + ((plon - lon) * cl) ** 2
        if d < best_d:
            best_d, zone = d, tz
    return zone


def slug(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def main():
    cands = []
    for line in (HERE / "candidates.tsv").read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        title, cats = line.split("\t")
        cands.append((title, cats.split(",")))
    times = json.loads((HERE / "times.json").read_text()) if (HERE / "times.json").exists() else {}
    people = by_titles([t for t, _ in cands])
    norm = {k.replace("_", " "): v for k, v in people.items() if k}

    ref_ids = set()
    for e in norm.values():
        for p in ("P19", "P166", "P39", "P26", "P54", "P800"):
            for c in claims(e, p):
                ref_ids.add(c["mainsnak"]["datavalue"]["value"]["id"])
    refs = by_ids(ref_ids)
    # Birth places without coordinates (hospitals, districts): use the enclosing place (P131).
    parent_ids = set()
    for r in refs.values():
        if not best(r, "P625"):
            for c in best(r, "P131"):
                parent_ids.add(c["mainsnak"]["datavalue"]["value"]["id"])
    parents = by_ids(parent_ids - set(refs))
    refs = {**parents, **refs}
    places = load_places()

    out, skipped = [], []
    for title, cats in cands:
        e = norm.get(title)
        if not e:
            skipped.append((title, "not found on Wikidata"))
            continue
        qid = e["id"]
        bd = [day_time(c["mainsnak"]["datavalue"]["value"]) for c in best(e, "P569")]
        bd = sorted({x for x in bd if x})
        if len({d for d, _ in bd}) != 1:
            skipped.append((title, f"birth date not unique at day precision: {bd}"))
            continue
        date, cal = bd[0]
        if date < "1582-10-15":
            # Dates before the Gregorian reform are the historical (Julian) dates; Wikidata often
            # tags them as Gregorian without converting.
            cal = "julian"
        bp = best(e, "P19")
        if not bp:
            skipped.append((title, "no birth place"))
            continue
        pe = refs.get(bp[0]["mainsnak"]["datavalue"]["value"]["id"], {})
        coord = best(pe, "P625")
        if not coord:
            for c in best(pe, "P131"):
                up = refs.get(c["mainsnak"]["datavalue"]["value"]["id"], {})
                if best(up, "P625"):
                    pe, coord = up, best(up, "P625")
                    break
        if not coord:
            skipped.append((title, "birth place without coordinates"))
            continue
        cv = coord[0]["mainsnak"]["datavalue"]["value"]
        lat, lon = round(cv["latitude"], 4), round(cv["longitude"], 4)
        zone = nearest_zone(places, lat, lon)
        name = label(e) or title
        pid = slug(label(e) or title)
        death = sorted({x for x in (day_time(c["mainsnak"]["datavalue"]["value"]) for c in best(e, "P570")) if x})
        living = not claims(e, "P570")
        src_url = f"https://www.wikidata.org/wiki/{qid}"

        birth = {"date": date, "calendar": cal, "place": label(pe), "lat": lat, "lon": lon, "zone": zone}
        t = times.get(title)
        if t:
            birth["time"] = t["time"]
            birth["time_basis"] = t.get("time_basis", "zone")
            if t.get("zone"):
                birth["zone"] = t["zone"]
            reliability = t["reliability"]
            source = {"note": t["note"], "url": t["url"], "date_place": src_url}
        else:
            reliability = "X"
            source = {"note": "Wikidata: datum a místo narození; čas narození nedoložen", "url": src_url}
        if cal == "julian" and "time" in birth:
            birth["time_basis"] = "lmt"

        events = []

        def add(d, lab, prop):
            if not d:
                return
            dd, c = d
            if c == "julian":
                dd = jul_to_greg(dd)
            events.append({"date": dd, "label": lab, "source": f"Wikidata {qid} {prop}"})

        for p, prefix, limit in (("P39", "nástup do funkce", 3), ("P166", "ocenění", 2), ("P26", "sňatek", 2), ("P54", "klub", 3)):
            n = 0
            for c in claims(e, p):
                ref = refs.get(c["mainsnak"]["datavalue"]["value"]["id"], {})
                lab = ref.get("labels", {}).get("cs", {}).get("value")
                if not lab or "čestn" in lab.lower() or n >= limit:
                    continue
                d = qual_date(c, "P580") if p != "P166" else (qual_date(c, "P585") or qual_date(c, "P580"))
                if d:
                    n += 1
                    add(d, f"{prefix}: {lab}", p)
        n = 0
        for c in claims(e, "P800"):
            # Notable work dated by its own publication, first performance or inception (day precision only).
            w = refs.get(c["mainsnak"]["datavalue"]["value"]["id"], {})
            lab = w.get("labels", {}).get("cs", {}).get("value")
            d = next((x for p in ("P577", "P1191", "P571") for x in
                      (day_time(cl["mainsnak"]["datavalue"]["value"]) for cl in best(w, p)) if x), None)
            if lab and d and n < 3:
                n += 1
                add(d, f"dílo: {lab}", "P800")
        if death:
            events = [x for x in events if x["date"] <= death[0][0]]  # no posthumous honours
        events.sort(key=lambda x: x["date"])
        seen, ev = set(), []
        for x in events:
            if x["label"] in seen:
                continue
            seen.add(x["label"])
            ev.append(x)
        ev = ev[:MAX_EVENTS]
        if death:
            add(death[0], "úmrtí", "P570")
            ev.append(events[-1])
        rec = {"id": pid, "name": name, "categories": cats, "living": living, "wikidata": qid,
               "birth": birth, "reliability": reliability, "source": source, "events": ev}
        out.append(rec)

    ids = [r["id"] for r in out]
    assert len(ids) == len(set(ids)), "duplicate ids"
    text = json.dumps(out, ensure_ascii=False, indent=1) + "\n"
    OUT.write_text(text)
    grades = {}
    for r in out:
        grades[r["reliability"]] = grades.get(r["reliability"], 0) + 1
    print(f"{len(out)} records, grades {grades}")
    for t, why in skipped:
        print(f"skipped {t}: {why}")
    used = set(times)
    for q in used - {t for t, _ in cands if t in norm}:
        print(f"warning: time for {q} not used")


if __name__ == "__main__":
    main()
