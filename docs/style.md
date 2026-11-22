# Pravidla psaní textů výkladu

Platí pro generátor (`tools/content/lib/prompt.dart` je obsahuje doslova) i pro ruční
opravy. Plán: oddíl 4.

## Hlas

- 2. osoba, tykání, přítomný čas.
- **Bez rodových tvarů.** Žádné „jsi citlivý / citlivá“, „byl jsi“, „mohla bys“.
  Místo přídavného jména v přísudku podstatné jméno nebo sloveso: „máš citlivou
  povahu“, „cítíš víc, než dáváš najevo“, „tvoje citlivost“. Validátor hledá
  typické chyby a hlásí varování.
- Věty krátké, konkrétní, bez frází typu „hvězdy ti říkají“.
- Žádné rady: ani k léčbě, investicím, právním krokům. Text popisuje.
  Výjimka: vrstva `advice` („Co s tím“) v průvodci vztahem, viz níže.

## Tři vrstvy

| Pole | Co do něj patří |
|---|---|
| `text` | povaha, nadání, jak se postavení projevuje |
| `shadow` | slabiny a odvrácená strana téhož, bez změkčování |
| `hard[]` | co tradice říká o smrti, nemoci, duševní krizi, závislosti, násilí, ztrátě, úpadku; každá pasáž se štítkem tématu |

- Nic se nevynechává ani nezměkčuje. Těžká témata věcně a s uvozením, že jde o
  tradiční výklad („tradice tu mluví o…“, „starší astrologie spojovala…“), ne o jistotu.
- Stinná stránka čerpá ze stínu znamení, z napěťových aspektů, z oslabení planety
  (pád, zničení) a z přemíry.
- `hard` jen tam, kde tradice něco říká. Prázdné `hard` je v pořádku, kromě
  8. a 12. domu a napěťových aspektů Marsu, Saturnu, Neptunu a Pluta (tam validátor varuje).

## Pole a štítky

- `keywords`: 3–5 hesel, malými písmeny.
- `themes`: z výčtu `character, relationships, family, work, money, health, growth`.
- `traits.text`, `traits.shadow`: jen id ze `content/cs/traits.json`, 2–5 na vrstvu.
- `hard[].topics`: `death, illness, mental_crisis, addiction, violence, loss, ruin`.

## Délky (základní vrstva, slova)

| Skupina | Délka |
|---|---|
| planeta ve znamení | 120–250; Slunce a Měsíc 180–300 |
| planeta v domě, aspekt | 80–150 |
| aspekt k bodu (ASC, MC, uzel) | 60–100 |
| znamení na hrotu | 40–100; ascendent a MC 120–200 |
| tranzity | 40–80 |
| přemíra a nedostatek | 60–100 |
| stinná stránka | 40–100 navíc |

## Průvodce vztahem (R9)

- Synastrie, dvojice živlů, období a `advice` u synastrie: 2. osoba množného čísla
  („mezi vámi“, „domluvte si“, „jeden z vás“, „druhý“).
- `pair_need` čte ten druhý: 3. osoba bez rodu („kdo má Měsíc v Raku, potřebuje…“,
  „člověk s Venuší ve Váze“). Žádné on, ona, jeho, její; „ten druhý“, „blízký
  člověk“. `advice` neosobně: „Pomáhá…“, „Funguje…“. Jména do textů nepatří.
- `advice` (30–70 slov, u období 40–80): konkrétní jednání ve vztahu. Zakázáno:
  léčba, léky, peníze, právo, verdikt o vztahu (zůstat, rozejít se) a cokoli, co
  vede k snášení násilí nebo ponižování.
- Období: „tradice čte toto období jako zkoušku“, nikdy „přijde krize“.
- Romantika a intimita jen v `partner` (Venuše a Mars u potřeb a dvojic živlů, synastrie).
