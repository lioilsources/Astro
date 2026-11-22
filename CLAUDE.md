# Astro

<!-- Max 80 řádků. Co se nevejde, jde do docs/ a sem jeden odkaz. Veřejné repo: žádné LAN IP, domovské cesty, ID. -->

## Účel
Mobilní astrologická appka (Flutter, iOS + Android), offline: nativní horoskop,
tranzity a jejich český výklad. Náhrada starého webu Astromat, bez jeho textů.
Zadání a fáze: `Prompts/PLAN-astro-app.md`.

## Build a test
```
bin/gate                                   # analyze + testy všech balíčků
cd packages/astro_core && dart test        # jen engine
dart run packages/astro_core/bin/chart.dart 2000-01-01 12:00 50.0833 14.4167 UT
cd app && flutter run
tools/golden/.venv/bin/python tools/golden/gen_golden.py   # přegenerovat golden + tabulku Pluta
python3 tools/people/build_people.py && dart run tools/content/bin/people.dart   # katalog osobností
app/tool/store_screenshots.sh && python3 app/tool/upload_store_screenshots.py ios   # screenshoty obchodu
```

## Mapa
- `packages/astro_core/` — čistý Dart: čas, efemeridy, domy, aspekty, stav planet, tranzity
- `app/` — Flutter UI
- `content/cs/` — výklady jako JSON (tři vrstvy: text, shadow, hard)
- `tools/content/` — generátor a validátor textů
- `tools/people/` — katalog osobností z Wikidat; časy narození jen ze `times.json` se zdrojem
- `tools/golden/` — referenční vektory (skyfield + DE440, Swiss Ephemeris jen tady)
- `tools/prototype/` — původní ověřovací prototyp
- `docs/` — ephemeris, scoring, style, content; GitHub Pages (index, privacy, support)
- `fastlane/metadata/` — texty a screenshoty obchodů (ios cs/en-US, android cs-CZ/en-US)

## Invarianty
- Swiss Ephemeris (AGPL) se do appky nikdy nelinkuje; jen `tools/golden/`.
- `astronomia` je připnutá na 1.1.1; změnu verze kryjí golden testy.
- Osobní data narození do repa nepatří (repo je veřejné). Lokální kontrolní
  horoskopy jen v gitignorovaném `run/`.
- Texty Astromatu ani knihy se nekopírují, ani jako předloha k parafrázi.
- Obsah se generuje nefiltrovaný; filtruje až uživatel v appce (plán 5.1).
- Štítky `hard` jen z výčtu: death, illness, mental_crisis, addiction, violence, loss, ruin.
- `lib/src/pluto_table.dart` a `lib/src/star_catalog.dart` (`gen_stars.py`) jsou generované, needitovat ručně.

## Odchylky
Žádné.

## Kam dál
`docs/ephemeris.md`, `docs/scoring.md`, `docs/style.md`, `docs/content.md`, `docs/horary.md`, `Prompts/`
