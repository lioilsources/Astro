"""Check curated defining events (tools/people/defining.json or a part of it) against the cached
Wikipedia articles: every quote must occur verbatim and write its date.

    python3 tools/people/check_defining.py [file.json]
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from build_people import DEFINING, curated_events  # noqa: E402

TYPES = {"office", "election", "coronation", "abdication", "award", "title", "record", "work", "premiere",
         "publication", "discovery", "breakthrough", "battle", "treaty", "founding", "scandal", "arrest",
         "trial", "assassination_attempt", "assassination", "resignation", "event"}


def main():
    path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFINING
    data = json.loads(path.read_text())
    errors = []
    for title, items in data.items():
        for it in items:
            missing = {"date", "label", "type", "quote"} - set(it)
            if missing:
                errors.append(f"{title}: missing {sorted(missing)} in {it}")
                continue
            if it["type"] not in TYPES:
                errors.append(f"{title}: unknown type {it['type']}")
        curated_events(title, [it for it in items if {"date", "label", "type", "quote"} <= set(it)], errors)
    for e in errors:
        print(e)
    print("ok" if not errors else f"{len(errors)} problems")


if __name__ == "__main__":
    main()
