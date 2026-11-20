# Obsah výkladu

Texty leží v `content/cs/<skupina>.json` (pole záznamů). Klíče, délky a skupiny
určuje `tools/content/lib/keys.dart`; pravidla psaní `docs/style.md`.

| Soubor | Co |
|---|---|
| `content/archetypes.cs.json` | ruční tabulka významů planet, znamení, domů, aspektů a obrazců aspektů (`patterns`); vstup generátoru |
| `content/cs/traits.json` | slovník rysů pro dotaz „co to vysvětluje?“ (id, název, synonyma, protiklad) |
| `content/cs/*.json` | texty výkladu, tři vrstvy (`text`, `shadow`, `hard[]`) |

## Validace

```
dart run tools/content/bin/validate.dart              # chyby → exit 1
dart run tools/content/bin/validate.dart --complete   # navíc chybějící klíče jako chyby (po F3)
```

Chyby: neznámý klíč, prázdný text nebo stín, štítek `hard` mimo výčet, rys mimo
slovník, angličtina, text bez diakritiky. Varování: délka, rodové tvary, prázdné
`hard` tam, kde ho tradice má, opakované sedmislovné fráze.

## Generování

Generátor projde chybějící klíče, sestaví zadání z tabulky archetypů a pravidel
a uloží JSON. Hotové klíče přeskakuje, po přerušení pokračuje. Každý text před
uložením projde validátorem.

SPARK (výchozí, plán rozhodnutí 2) — přes broker, nikdy přímo:

```
sparkctl exec astro llm 120 0 "astro texty" -- \
  env LLM_BASE_URL=<gateway>/v1 LLM_API_KEY=<klíč> LLM_MODEL=qwen36 \
  dart run tools/content/bin/generate.dart --family aspect
```

Claude API (záloha, když pilot na SPARKu nedá dobrou češtinu):

```
LLM_PROVIDER=anthropic ANTHROPIC_API_KEY=… LLM_MODEL=claude-opus-5-5 \
  dart run tools/content/bin/generate.dart --family planet_in_sign --limit 20
```

Klíče patří do `.env` (gitignorované), nikdy do repa.

## Pilot

20 textů ve všech skupinách (meta `pilot: true`) napsal Claude Opus 5.5 přímo
v session, protože SPARK byl obsazený. Slouží ke schválení stylu vlastníkem.
Plná dávka (F3) jde až po schválení.

## Katalog osobností

Záznamy leží v `content/people/people.json` (formát v `Prompts/KATALOG-osobnosti.md`),
appka je čte přes odkaz `app/assets/data/people.json`.

```
dart run tools/content/bin/people.dart
```

Validátor odmítne záznam bez zdroje (`source.note` i `source.url`), čas bez
`time_basis`, čas u stupně X a chybějící čas u jiného stupně než X a DD. Události
musí mít zdroj. Kandidáti z `Prompts/KATALOG-osobnosti.md` jsou z paměti modelu
a neověření; do katalogu jde každý až po dohledání zdroje.
