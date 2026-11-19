# Astro

Mobilní appka (iOS + Android), která **offline** spočítá nativní horoskop z data,
času a místa narození a ke každému řádku tabulky nabídne český výklad. Spočítá
i tranzity a vyloží je. Data narození neopouštějí telefon.

Stav: ve vývoji, plán v [`Prompts/PLAN-astro-app.md`](Prompts/PLAN-astro-app.md).

## Co je uvnitř

| Složka | Obsah |
|---|---|
| `packages/astro_core` | výpočetní jádro v čistém Dartu |
| `app` | Flutter appka |
| `content/cs` | texty výkladu (JSON) |
| `tools/content` | generátor a validátor textů |
| `tools/golden` | referenční čísla pro testy (jen pro vývoj) |

## Přesnost

Polohy planet z VSOP87B (balíček `astronomia`, MIT), Měsíc podle Meeuse, Pluto
z tabulky předpočítané z efemeridy JPL DE440 (1550–2200). Testy porovnávají
s DE440 a se Swiss Ephemeris: planety i hroty všech devíti systémů domů do 1′.
Podrobnosti v [`docs/ephemeris.md`](docs/ephemeris.md).

## Spuštění

```
dart pub get
bin/gate
dart run packages/astro_core/bin/chart.dart 2000-01-01 12:00 50.0833 14.4167 UT
cd app && flutter run
```

## Licence a zdroje dat

- Kód: MIT.
- Efemeridy: VSOP87 a algoritmy Meeuse přes `astronomia` (MIT); tabulka Pluta
  z JPL DE440 (volné dílo).
- Časová pásma: IANA tzdb (volné dílo) přes balíček `timezone`.
- Místa: GeoNames, CC BY 4.0.
- Symboly: Noto Sans Symbols, SIL Open Font License.

Astrologie popisuje tradiční výklad postavení, ne prokázané souvislosti.
