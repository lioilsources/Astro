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
DEFINING = HERE / "defining.json"
WIKI_CACHE = ROOT / "run/people-cache/wiki"
MAX_EVENTS = 6  # ordinary life events (marriages, clubs) per person, death not counted
MAX_DEFINING_WD = 8


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


def _greg(d):
    dd, c = d
    return jul_to_greg(dd) if c == "julian" else dd


def item_date(item, props=("P585", "P580", "P577", "P1191", "P571")):
    for p in props:
        for cl in best(item, p):
            d = day_time(cl["mainsnak"]["datavalue"]["value"])
            if d:
                return d
    return None


def wikidata_events(e, refs, qid, death, death_greg):
    """Events from Wikidata statements. Offices, awards, notable works, significant events and
    won competitions are the defining ones (what the person is known for); marriages, clubs and
    death are ordinary life events."""
    defining, ordinary = [], []

    def add(bucket, d, lab, prop, typ, value=None):
        if not d:
            return
        dd = _greg(d)
        if death_greg and dd > death_greg:
            return  # no posthumous honours
        bucket.append({"date": dd, "label": lab, "type": typ, "defining": bucket is defining,
                       "source": f"Wikidata {qid} {prop}" + (f" {value}" if value else ""),
                       "url": f"https://www.wikidata.org/wiki/{qid}#{prop}"})

    def cs(item):
        return item.get("labels", {}).get("cs", {}).get("value")

    for p, prefix, limit, typ in (("P39", "nástup do funkce", 4, "office"), ("P166", "ocenění", 3, "award")):
        n = 0
        for c in claims(e, p):
            vid = c["mainsnak"]["datavalue"]["value"]["id"]
            lab = cs(refs.get(vid, {}))
            if not lab or "čestn" in lab.lower() or n >= limit:
                continue
            d = qual_date(c, "P580") if p == "P39" else (qual_date(c, "P585") or qual_date(c, "P580"))
            if d:
                n += 1
                add(defining, d, f"{prefix}: {lab}", p, typ, vid)
    n = 0
    for c in claims(e, "P800"):
        # Notable work dated by its own publication, first performance or inception (day precision only).
        vid = c["mainsnak"]["datavalue"]["value"]["id"]
        w = refs.get(vid, {})
        lab = cs(w)
        d = item_date(w, ("P577", "P1191", "P571"))
        if lab and d and n < 3:
            n += 1
            add(defining, d, f"dílo: {lab}", "P800", "work", vid)
    for c in claims(e, "P793"):
        vid = c["mainsnak"]["datavalue"]["value"]["id"]
        lab = cs(refs.get(vid, {}))
        d = qual_date(c, "P585") or qual_date(c, "P580") or item_date(refs.get(vid, {}), ("P585", "P580"))
        if lab:
            add(defining, d, lab, "P793", "event", vid)
    won = [(c, "P2522") for c in claims(e, "P2522")]
    for c in claims(e, "P1344"):
        rank = [q for q in c.get("qualifiers", {}).get("P1352", []) if q.get("snaktype") == "value"]
        if rank and rank[0]["datavalue"]["value"].get("amount") in ("+1", 1):
            won.append((c, "P1344"))
    n = 0
    for c, p in won:
        vid = c["mainsnak"]["datavalue"]["value"]["id"]
        item = refs.get(vid, {})
        lab = cs(item)
        # A won competition counts on its final day (end time), else its point in time.
        d = qual_date(c, "P585") or item_date(item, ("P582", "P585"))
        if lab and d and n < 4:
            n += 1
            add(defining, d, f"vítězství: {lab}", p, "title", vid)
    for p, prefix, limit, typ in (("P26", "sňatek", 2, "marriage"), ("P54", "klub", 3, "club")):
        n = 0
        for c in claims(e, p):
            vid = c["mainsnak"]["datavalue"]["value"]["id"]
            lab = cs(refs.get(vid, {}))
            if not lab or n >= limit:
                continue
            d = qual_date(c, "P580")
            if d:
                n += 1
                add(ordinary, d, f"{prefix}: {lab}", p, typ, vid)
    defining.sort(key=lambda x: x["date"])
    ordinary.sort(key=lambda x: x["date"])
    out = _dedupe(defining)[:MAX_DEFINING_WD] + _dedupe(ordinary)[:MAX_EVENTS]
    if death:
        add(ordinary, death[0], "úmrtí", "P570", "death")
        out.append(ordinary[-1])
    return out


def _dedupe(evs):
    seen, out = set(), []
    for x in evs:
        if x["label"] in seen:
            continue
        seen.add(x["label"])
        out.append(x)
    return out


MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September",
          "October", "November", "December"]


def quote_dates(text):
    """Day-precise dates written in an English sentence → set of YYYY-MM-DD."""
    m = "|".join(MONTHS)
    out = set()
    for d, mo, y in re.findall(rf"\b(\d{{1,2}}) ({m}),? (\d{{3,4}})\b", text):
        out.add(f"{int(y):04d}-{MONTHS.index(mo) + 1:02d}-{int(d):02d}")
    for mo, d, y in re.findall(rf"\b({m}) (\d{{1,2}}),? (\d{{3,4}})\b", text):
        out.add(f"{int(y):04d}-{MONTHS.index(mo) + 1:02d}-{int(d):02d}")
    return out


def wiki_text(title):
    p = WIKI_CACHE / (slug(title) + ".json")
    return json.loads(p.read_text())["text"] if p.exists() else None


def curated_events(title, items, errors):
    """Headline events read from English Wikipedia (tools/people/defining.json). Each carries the
    sentence it comes from; the date must be written in that sentence, and when the article is in
    the local cache the sentence must occur in it verbatim."""
    out = []
    text = wiki_text(title)
    url = "https://en.wikipedia.org/wiki/" + urllib.parse.quote(title.replace(" ", "_"))
    for it in items:
        written = it["date"]
        # Dates as Wikipedia writes them: Julian before the Gregorian reform unless marked otherwise.
        cal = it.get("calendar") or ("julian" if written < "1582-10-15" else "gregorian")
        if written not in quote_dates(it["quote"]):
            errors.append(f"{title}: date {written} not written in quote: {it['quote'][:80]}")
            continue
        if text is not None and it["quote"] not in " ".join(text.split()):
            errors.append(f"{title}: quote not found in article: {it['quote'][:80]}")
            continue
        rec = {"date": jul_to_greg(written) if cal == "julian" else written, "label": it["label"], "type": it["type"], "defining": True,
               "source": f"Wikipedia: {title}", "url": url, "quote": it["quote"]}
        if cal == "julian":
            rec["date_julian"] = written
        out.append(rec)
    return out


def merge_events(events):
    """Chronological; a Wikipedia event on the same day as a Wikidata one of the same type wins
    (it carries the sentence)."""
    keep = {}
    for x in events:
        k = (x["date"], x["type"]) if x["defining"] else (x["date"], x["label"])
        if k in keep and not keep[k].get("quote") and x.get("quote"):
            keep[k] = x
        else:
            keep.setdefault(k, x)
    return sorted(keep.values(), key=lambda x: (x["date"], not x["defining"]))


def main():
    cands = []
    for line in (HERE / "candidates.tsv").read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        title, cats = line.split("\t")
        cands.append((title, cats.split(",")))
    times = json.loads((HERE / "times.json").read_text()) if (HERE / "times.json").exists() else {}
    defining = json.loads(DEFINING.read_text()) if DEFINING.exists() else {}
    errors = []
    people = by_titles([t for t, _ in cands])
    norm = {k.replace("_", " "): v for k, v in people.items() if k}

    ref_ids = set()
    for e in norm.values():
        for p in ("P19", "P166", "P39", "P26", "P54", "P800", "P793", "P1344", "P2522"):
            for c in claims(e, p):
                v = c["mainsnak"]["datavalue"]["value"]
                if isinstance(v, dict) and "id" in v:
                    ref_ids.add(v["id"])
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

        death_greg = None
        if death:
            death_greg = jul_to_greg(death[0][0]) if death[0][1] == "julian" else death[0][0]
        events = wikidata_events(e, refs, qid, death, death_greg) + curated_events(title, defining.get(title, []), errors)
        events = merge_events(events)
        rec = {"id": pid, "name": name, "categories": cats, "living": living, "wikidata": qid, "enwiki": title,
               "birth": birth, "reliability": reliability, "source": source, "events": ev}
        out.append(rec)

    for m in errors:
        print(f"error: {m}")
    assert not errors, "curated events failed verification"
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
