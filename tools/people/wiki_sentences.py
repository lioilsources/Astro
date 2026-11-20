"""Candidate sentences for defining events (tools/people/defining.json) from Wikipedia.

For every catalog person, fetch the plain-text English article (TextExtracts API, cached in
run/people-cache/wiki/, sequential with a pause) and list the sentences that write a
day-precise date within the person's lifetime. Output: run/people-events/<id>.txt, one line
per sentence: "YYYY-MM-DD[,...]<TAB>sentence". With --cs, the Czech articles of the people
that still have fewer than two defining events go to run/people-events/cs-<id>.txt.
A curator then picks the headline events; the builder checks that each picked sentence
occurs in the cached article and writes its date.

    python3 tools/people/wiki_sentences.py [--fetch-only | --cached | --cs]
"""
import json
import pathlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from build_people import ROOT, UA, WIKI_CACHE, quote_dates, slug, wiki_path, wiki_text  # noqa: E402

OUT = ROOT / "run/people-events"
MAX_LINES = 40
KEYWORDS = re.compile(
    r"\b(elect\w*|inaugurat\w*|sworn|appoint\w*|crown\w*|coronat\w*|abdicat\w*|resign\w*|won|wins?|winning|"
    r"victory|champion\w*|title|record|gold|medal|final|premier\w*|first performance|published|publication|"
    r"released|debut\w*|discover\w*|award\w*|prize|Nobel|Oscar|Academy Award|Grammy|signed|founded|"
    r"assassin\w*|shot|arrest\w*|trial|convicted|scandal|battle|treaty|landed|declared|proclaimed|"
    r"broke|launched|announced|patent\w*|exhibit\w*|opened|scored|"
    r"zvolen\w*|jmenován\w*|korunov\w*|abdik\w*|premiér\w*|vydal\w*|vydán\w*|vyšl\w*|objev\w*|získal\w*|"
    r"vyhrál\w*|zvítěz\w*|vítěz\w*|mistr\w*|titul\w*|rekord\w*|medail\w*|cen[auy]|založil\w*|atentát\w*|"
    r"zatčen\w*|odsouzen\w*|proces\w*|bitv\w*|podepsal\w*|odstoupil\w*|rezign\w*|nastoupil\w*|"
    r"prezident\w*|olympi\w*|uveden\w*|vystoupil\w*|natočil\w*)\b", re.I)


def fetch(title, lang="en"):
    WIKI_CACHE.mkdir(parents=True, exist_ok=True)
    p = wiki_path(title, lang)
    if p.exists():
        return json.loads(p.read_text())["text"]
    q = urllib.parse.urlencode({"action": "query", "prop": "extracts", "explaintext": 1, "redirects": 1,
                                "titles": title, "format": "json", "formatversion": 2})
    req = urllib.request.Request(f"https://{lang}.wikipedia.org/w/api.php?{q}", headers={"User-Agent": UA})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                data = json.loads(r.read())
            break
        except urllib.error.HTTPError as e:
            if e.code != 429 or attempt == 4:
                raise
            time.sleep(int(e.headers.get("Retry-After") or 30) + 5)
    page = data["query"]["pages"][0]
    text = page.get("extract") or ""
    p.write_text(json.dumps({"title": page.get("title"), "text": text}, ensure_ascii=False))
    time.sleep(1.0)
    return text


def sentences(text):
    flat = " ".join(text.split())
    return re.split(r"(?<=[a-zá-ž0-9\)\]\"'“][.!?])\s+(?=[A-ZÁČĎÉĚÍŇÓŘŠŤÚŮÝŽ\"„])", flat)


def write_candidates(title, text, r, out, header=""):
    birth = r["birth"]["date"] if r else "0000"
    death = next((e["date"] for e in r["events"] if e.get("type") == "death"), "9999") if r else "9999"
    rows = []
    for i, s in enumerate(sentences(text)):
        if len(s) > 600:
            continue
        # Old dates may be Julian as written; allow the birth year itself.
        ds = [d for d in sorted(quote_dates(s))
              if birth < d <= death or (d < "1753" and birth[:4] <= d[:4] <= death[:4])]
        if ds:
            rows.append((len(KEYWORDS.findall(s)), i, ds, s))
    # The sentences most likely to name a defining event first, at most MAX_LINES, in article order.
    keep = sorted(sorted(rows, key=lambda x: (-x[0], x[1]))[:MAX_LINES], key=lambda x: x[1])
    lines = [f"# {title}\tborn {birth}\tdied {death if death != '9999' else '-'}{header}"]
    lines += [f"{','.join(ds)}\t{s}" for _, _, ds, s in keep]
    out.write_text("\n".join(lines) + "\n")
    return len(rows), len(keep)


def main():
    if "--fetch-only" in sys.argv:
        for line in (ROOT / "tools/people/candidates.tsv").read_text().splitlines():
            if line.strip() and not line.startswith("#"):
                fetch(line.split("\t")[0])
        return
    OUT.mkdir(parents=True, exist_ok=True)
    records = json.loads((ROOT / "content/people/people.json").read_text())
    if "--cs" in sys.argv:
        for r in records:
            n = sum(1 for e in r["events"] if e.get("defining"))
            if n >= 2 or not r.get("cswiki"):
                continue
            text = fetch(r["cswiki"], "cs")
            res = write_candidates(r["enwiki"], text, r, OUT / f"cs-{slug(r['enwiki'])}.txt",
                                   header=f"\tlang cs\tarticle {r['cswiki']}")
            print("cs", slug(r["enwiki"]), *res)
        return
    cached_only = "--cached" in sys.argv
    people = {r.get("enwiki"): r for r in records}
    for line in (ROOT / "tools/people/candidates.tsv").read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        title = line.split("\t")[0]
        if cached_only and wiki_text(title) is None:
            continue
        res = write_candidates(title, fetch(title), people.get(title), OUT / f"{slug(title)}.txt")
        print(slug(title), *res)


if __name__ == "__main__":
    main()
