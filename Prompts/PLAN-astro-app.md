# PLAN: Astro — horoskop v mobilní appce

Stav: návrh k implementaci (2026-11-18). Zadání pro implementační session: „implementuj podle plánu“.

## 1. Cíl

Mobilní appka (Flutter, iOS + Android), která **offline** spočítá nativní horoskop
z data, času a místa narození a ke každému řádku tabulky nabídne český výklad.
Navíc spočítá tranzity a **vyloží je** — to starému Astromatu chybí.

Oba původní zdroje (web Astromat, tištěná kniha) se **obcházejí**:

- výpočet dělá vlastní engine v Dartu,
- texty výkladu jsou vlastní, nově napsané (generované LLM podle zadání níže),
  včetně stinných stránek a těžkých témat; co z toho uvidí, si řídí uživatel filtrem.

Důvod: texty Astromatu i knihy jsou autorská díla, repo je veřejné a appka půjde
do obchodů. Čísla (polohy planet) jsou fakta, ta porovnávat smíme. Texty z webu
ani z knihy se do repa nekopírují, ani jako předloha k parafrázi.

Mimo rozsah v1: účty, backend, synchronizace, platby. Partnerský horoskop a další
techniky přijdou po v1 jako rozšíření (oddíl 10).

## 2. Co dělá Astromat (zmapováno, slouží jako specifikace)

Vstup: datum, čas (SEČ/SELČ, nebo GMT), pohlaví, místo (226 předvoleb) nebo
šířka/délka, systém domů (Placidus, Koch, Equal, Campanus, Meridian,
Regiomontanus, Porphyry, Morinus, žádný), volba „řadit do témat“.
Bez času narození počítá horoskop bez domů.

Výstup nativního horoskopu:

| Blok | Obsah |
|---|---|
| Hlavička | datum a čas GMT, souřadnice, systém domů, juliánský den |
| Pozice planet | Slunce–Pluto + střední uzel: délka ve znamení, šířka, denní změna (°/den), znamení, dům |
| Domy | hroty 1–12 (úhel + znamení) |
| Aspekty | konjunkce, sextil, kvadrát, trigon, opozice mezi planetami, uzlem, ASC a MC; orby těsné (~3°, u Slunce a Měsíce o něco víc) |
| Stav planet | vládne / v povýšení / v pádu / ve zničení + bodové skóre „vlivu“ |
| Zvěrokruh | kolo s domy a planetami |
| Výklad | ~3000 slov, 4 druhy oddílů (níže) |

Druhy výkladových oddílů (nadpis → text):

1. planeta ve znamení — „Slunce v kozorohu“ (Slunce–Uran; před textem hesla typu MOTTO, POVAHA, MYŠLENÍ)
2. planeta v domě — „Měsíc v 6. domě“ (Slunce–Neptun)
3. aspekt — „Slunce trigon Saturn“
4. znamení na hrotu domu — „štír na hrotu 7. domu“

Tranzitní horoskop: kalendář nejvýš 31 dní; pro každý den aspekty tranzitující
planety k natální (denní / začínající / končící), stav na začátku a konci období
(„od–do, N dnů“), souhrn s rozsahy dat. U natální planety uvádí její znamení a dům.
Výklad žádný.

## 3. Architektura

Bez backendu, vše v zařízení. Data narození neopouštějí telefon.

```
packages/astro_core/   čistý Dart: čas, efemeridy, domy, aspekty, stav planet, tranzity
app/                   Flutter UI
content/cs/            výklady jako JSON (verzované v repu)
tools/content/         generátor a validátor textů
tools/golden/          generátor referenčních vektorů (jen pro vývoj)
tools/prototype/       ověřovací prototyp (už existuje)
```

### 3.1 Výpočet — ověřeno prototypem

`tools/prototype/ephtest.dart` počítá polohy balíčkem **`astronomia` 1.1.1**
(MIT, čistý Dart, VSOP87B + Meeus pro Měsíc a Pluto) a domy vlastním Placidem.
Proti Astromatu (1. 1. 2000 12:00 UT, Praha 50°05′ s. š., 14°25′ v. d.):

| Veličina | Rozdíl |
|---|---|
| Slunce, Měsíc, Merkur–Neptun | do 1,6′ (typicky 0,5′) |
| střední uzel | 0,1′ |
| ASC, MC, hroty 2, 3, 11, 12 (Placidus) | do 0,6′ |
| Pluto | 4,8′ — kdo je blíž, rozhodne golden vektor ze Swiss Ephemeris (předběžně se mýlí Astromat) |

Druhý, osobní horoskop ze screenshotů vyšel stejně (1–2′, Pluto 4′).
Astromat používá **střední** uzel, tropický zvěrokruh, geocentrické zdánlivé polohy.

Rozhodnutí:

- Efemeridy: `astronomia` s připnutou verzí. Je to mladý balíček od neověřeného
  vydavatele, proto golden testy a záloha: potřebné moduly (VSOP87B, Měsíc, Pluto,
  nutace, hvězdný čas) jdou převzít do `astro_core` (licence MIT to dovoluje).
- Swiss Ephemeris (`sweph`) **ne**: AGPL-3.0, neslučitelné s distribucí přes App Store
  bez placené licence Astrodienstu. Smí se použít jen ve vývojovém skriptu
  `tools/golden/` na vygenerování referenčních čísel; do appky se nelinkuje.
- Historická data (katalog osobností sahá do středověku):
  - Pluto: řada z Meeuse platí jen pro roky 1885–2099. Mimo ně použij tabulku
    poloh předpočítanou při vývoji z efemeridy JPL DE440 (volné dílo) knihovnou
    `skyfield` (MIT), krok 30 dní, kubická interpolace, rozsah 1550–2200 (DE440 začíná koncem roku 1549; starší data jsou bez Pluta).
  - Stejnou cestou (skyfield + DE440) generuj i golden vektory planet; Swiss
    Ephemeris pak stačí jen na křížovou kontrolu domů.
  - Kalendář: záznam nese `calendar: julian | gregorian`. Před 15. 10. 1582 vždy
    juliánský; mezi 1582 a 1923 záleží na zemi (Británie 1752, Rusko 1918) →
    u ručního zadání přepínač.
  - Čas před zavedením pásmového času: místní střední čas z délky místa narození
    (`UT = čas − délka/15 h`), ne posun referenčního města z tzdb.
- Prototyp vrací u planet rovníkové souřadnice a převádí zpět; v `astro_core`
  počítej ekliptikální délku, šířku a denní změnu přímo (změna = rozdíl poloh ±12 h,
  záporná = retrográdní).

### 3.2 Čas a místo

- Místní čas → UT přes IANA tzdb (balíček `timezone`), včetně historického letního
  času. Volba „zadávám UT“ zůstává. ΔT z `astronomia` (`deltat`).
- Neznámý čas narození: poledne místního času, bez domů, ASC, MC a bez Měsíce v domě;
  u Měsíce upozornit na nejistotu znamení, pokud ten den přechází.
- Místa: offline seznam z GeoNames (CC BY 4.0, uvést atribuci) — obce ČR a SR
  + světová města nad 15 000 obyvatel, s časovou zónou. Ruční zadání souřadnic vždy možné.

### 3.3 Domy, aspekty, stav planet

- Domy: Placidus, Koch, Regiomontanus, Campanus, Porphyry, Equal, Whole sign,
  Meridian, Morinus. Texty výkladu jsou pro všechny systémy společné; mění se jen
  to, do kterého domu planeta padne.
- Výchozí systém se volí automaticky podle **zeměpisné šířky narození**:
  do 60° Placidus; mezi 60° a 66° Placidus s upozorněním na silně nestejné domy
  a nabídkou Porphyry; nad 66° Porphyry (Placidus a Koch tam nejsou definované,
  hranice je 90° − sklon ekliptiky ≈ 66°34′). Zeměpisná délka na volbu vliv nemá.
  Poloha telefonu se nepoužívá: domy se počítají pro místo narození a appka tak
  nepotřebuje oprávnění k poloze. Uživatel může systém přepnout globálně i u profilu.
- Porphyry: každý kvadrant mezi úhly (MC→ASC, ASC→IC) rozdělit na ekliptice na tři
  stejné díly. Meridian: hrot = `atan2(sin α, cos α · cos ε)` pro α = RAMC + n·30°
  (hrot 10 = MC, hrot 1 není ascendent). Morinus: hrot = `atan2(sin α · cos ε, cos α)`
  pro stejná α (nesedí ASC ani MC, nezávisí na šířce). Číslování hrotů ověřit
  golden vektorem.
- Srovnání systémů domů: pohled pro libovolné dva systémy, výchozí dvojice
  Placidus × Porphyry. Ukazuje hroty vedle sebe s rozdílem ve stupních, velikosti
  domů a planety, které mění dům, u nich oba výklady. Zkouška na čtyřech horoskopech
  z okolí 50° s. š.: hroty se liší o 0,2° až 20°, dům mění 1 až 4 planety.
- Aspekty: 5 hlavních. Orby v jedné konfigurační tabulce (aspekt × typ tělesa),
  výchozí: konjunkce a opozice 8°, trigon a kvadrát 6°, sextil 4°, se Sluncem nebo
  Měsícem +2°, pro ASC/MC/uzel 3°. Přepínač „těsné orby (3°)“ pro výsledek blízký Astromatu.
  U aspektu ukládej orb a zda se sbíhá, nebo rozchází.
- Stav planet: tabulka vládce / povýšení / pád / zničení (moderní i tradiční vládci:
  Mars i Pluto ve štíru, Saturn i Uran ve vodnáři, Jupiter i Neptun v rybách).
  Bodové skóre navrhni vlastní a popiš v `docs/scoring.md`; algoritmus Astromatu
  není známý, shoda bodů není cílem. Skóre řídí pořadí vrstev textu (viz 4.1).

### 3.4 Tranzity

Tranzit není nový horoskop, ale seznam aspektů, které planety ve zvoleném okamžiku
tvoří k bodům uloženého nativního horoskopu, plus údaj, kterým nativním domem
procházejí.

- Vstup: nativní horoskop + okamžik nebo období. Výchozí je aktuální datum a čas
  telefonu; jde zvolit libovolný den dopředu i zpět (bez limitu 31 dní, počítat
  v isolate). Poloha telefonu roli nehraje, domy se berou nativní.
- Cíle: 10 nativních planet, ASC a MC.
- Krok 1 den (Měsíc 1 h); vstup do orbu, přesný okamžik a výstup dohledat bisekcí
  s přesností na minutu. Retrográdní pohyb dává víc průchodů; každý je zvlášť
  a nese pořadí (1., 2., 3.). Zastávka planety v orbu nativního bodu je samostatná událost.
- Orby tranzitů ve stejné konfigurační tabulce jako natální; výchozí 1° pro všechna tělesa.
- Výstup: události `{tranzitující, aspekt, cíl, začátek, přesně, konec, průchod,
  fáze, síla}` + vstupy tranzitujících planet do nativních domů.
- Vrstvy podle rychlosti: pozadí (Saturn, Uran, Neptun, Pluto), týdny (Mars,
  Jupiter), dny (Slunce, Merkur, Venuše), hodiny (Měsíc).
- Fáze: blíží se / přesný / odeznívá. Šířku okna „přesný“ odvodit z rychlosti planety.
- Síla 0–100 řadí události a určuje označení „akutní“. Skládá se z těsnosti orbu,
  pomalosti tranzitující planety, cíle na osobním bodě (Slunce, Měsíc, ASC, MC),
  zastávky a souběhu víc tranzitů na týž bod. Vzorec popsat v `docs/scoring.md`.

Pohledy:

- **Dnes**: nahoře akutní události, pod nimi vrstvy od pozadí po hodiny; věta
  „dnes jednou větou“ složená šablonou z nejsilnější události (bez LLM za běhu).
- **Denní časová osa po hodinách**: aspekty Měsíce jako úseky (začátek, přesně,
  konec), přesné okamžiky ostatních planet jako body („přesně ve 14:20“), vstupy
  do nativních domů, značka „teď“. Časy v časové zóně telefonu.
- **Měsíční kalendář**: začínající, přesné a končící aspekty po dnech.
- **Probíhající**: dlouhé tranzity s daty od–do a pořadím průchodu.

Výklad tranzitu se skládá z hotových dílů, vše offline:

1. základní text `transit/…` nebo `transit_point/…` se všemi třemi vrstvami (4.1),
2. věta o oblasti života podle nativního domu cílové planety,
3. modifikátor fáze a pořadí průchodu nebo zastávky (`transit_modifier/…`),
4. u souběhu upozornění, že na týž bod míří víc tranzitů.

### 3.5 Dotazy

Dva druhy dotazů, oba offline a deterministické. Appka mluví o „souvislostech“,
nikdy o „důkazu“.

**A. „Co to vysvětluje?“ — od rysu k horoskopu** (např. „bojuje s chaosem“)

- Slovník rysů: asi 200 hesel se synonymy a s protikladem (chaos ↔ řád).
- Každá vrstva každého textu nese štítky `traits[]` z tohoto slovníku (4.2).
- Uživatel napíše slovo; hledání bez ohledu na diakritiku a tvar najde heslo,
  při neshodě nabídne nejbližší.
- Výsledek má vždy dva sloupce: **co to podporuje** (postavení se štítkem rysu)
  a **co mluví proti** (postavení se štítkem protikladu), řazené podle síly
  (těsnost orbu, osobní planety, úhly). V každém horoskopu se najde opora pro
  skoro cokoli; druhý sloupec je tam proto, aby to bylo vidět.

**B. „Co se dělo ten den?“ — od události k tranzitům** (např. „Waterloo“)

- Vstup: osoba + datum (čas volitelně) + popis. Události se ukládají k profilu
  jako deník; osoby z katalogu je mají předvyplněné.
- Výsledek: tranzity toho dne z 3.4 seřazené podle síly, zvlášť napěťové
  a harmonické, s výkladem.
- **Jak výjimečný to byl den:** spočítat denní skóre napětí přes celý život
  (isolate, výsledek uložit) a ukázat percentil dne. U nejsilnějších tranzitů
  uvést, jak často se v životě opakují a jak dlouho trvají.

**C. Volné otázky přes LLM** nejsou ve v1: potřebují síť a klíč nebo vlastní
prostředník. Pokud přibudou, LLM jen převede otázku na dotaz A nebo B a zformuluje
odpověď; fakta dodává engine.

## 4. Obsah: mapování tabulky na výklad

Každý řádek tabulky má klíč; klíč vede na text. Ťuknutí na řádek otevře výklad.

| Klíč | Počet | Délka |
|---|---|---|
| `planet_in_sign/{planeta}/{znamení}` — 10 planet + uzel | 132 | 120–250 slov (Slunce, Měsíc delší + hesla) |
| `planet_in_house/{planeta}/{dům}` | 132 | 80–150 |
| `aspect/{p1}/{p2}/{aspekt}` — 45 párů × 5 | 225 | 80–150 |
| `aspect_point/{bod}/{planeta}/{typ}` — ASC, MC, uzel × 10 × (konjunkce, harmonický, napěťový) | 90 | 60–100 |
| `sign_on_cusp/{dům}/{znamení}` — dům 1 = ascendent, 10 = MC (delší) | 144 | 40–200 |
| `transit/{tranzitující}/{natální}/{aspekt}` — 10 × 10 × 5 | 500 | 40–80 |
| `transit_point/{tranzitující}/{bod}/{typ}` — ASC, MC × 10 × (konjunkce, harmonický, napěťový) | 60 | 40–80 |
| `transit_in_house/{planeta}/{dům}` | 120 | 40–80 |
| `transit_modifier/{druh}` — blíží se, přesný, odeznívá, 1./2./3. průchod, zastávka, souběh | ~10 | 15–30 |
| `house_area/{dům}` — jedna věta o oblasti života pro skládání tranzitů | 12 | 15–25 |
| `traits/{rys}` — slovník rysů pro dotazy (3.5): název, synonyma, protiklad | ~200 | bez textu |
| `emphasis/{druh}/{hodnota}` — přemíra a nedostatek: 3+ planety v jednom znamení (12) nebo domě (12), převládající a chybějící živel (8) | 32 | 60–100 |
| `glossary/{heslo}` — ascendent, descendent, MC, IC, dům, aspekt, sextil, kvadrát, trigon, opozice, konjunkce, vládce, povýšení, retrográdní… | ~40 | 40–120 |

Délky platí pro základní vrstvu; stinná stránka přidává 40–100 slov na text.
Celkem zhruba 1500 textů, řádově 260 tisíc slov včetně všech vrstev.

### 4.1 Tři vrstvy každého textu

Obsah se **při psaní nefiltruje**. Generátor zapíše všechno, co tradice o postavení
říká, a rozdělí to do vrstev. Co se zobrazí, rozhoduje až uživatel filtrem (5.1).

| Vrstva | Pole | Obsah |
|---|---|---|
| Základ | `text` | povaha, nadání, jak se postavení projevuje |
| Stinná stránka | `shadow` | slabiny a odvrácená strana téhož; povinná u všech textů kromě slovníčku |
| Těžká témata | `hard[]` | pasáže, které tradice spojuje se smrtí, nemocí, duševní krizí, závislostí, násilím, ztrátou a úpadkem; každá se štítkem tématu; jen tam, kde tradice něco říká |

Z čeho se stinná stránka plní (generátor to dostává v zadání):

1. stín znamení — odvrácená strana jeho přednosti,
2. napěťové aspekty — kvadrát, opozice a konjunkce se Saturnem, Marsem, Uranem,
   Neptunem nebo Plutem,
3. oslabení — planeta v pádu nebo ve zničení (součást `planet_in_sign`),
4. přemíra a nedostatek — klíče `emphasis/…`.

Pořadí při zobrazení: u planety se záporným skóre (3.3) jde stinná stránka před
základ, jinak za něj.

### 4.2 Formát, pravidla psaní, generování

Formát (`content/cs/<skupina>.json`, validováno schématem v CI):

```json
{"key": "planet_in_sign/mars/cancer", "title": "Mars v Raku",
 "keywords": ["domov", "obrana", "nálady"], "themes": ["povaha", "rodina"],
 "text": "…", "shadow": "…",
 "hard": [{"topics": ["violence"], "text": "…"}],
 "traits": {"text": ["protectiveness"], "shadow": ["moodiness", "sulking"]}}
```

Štítky `traits` jsou jen ze slovníku rysů a přiřazují se zvlášť základu a stinné
stránce.

Štítky `hard` jsou uzavřený výčet: `death`, `illness`, `mental_crisis`, `addiction`,
`violence`, `loss`, `ruin`.

Pravidla psaní (`docs/style.md`):

- 2. osoba, přítomný čas, bez rodových tvarů → přepínač pohlaví odpadá.
- Nic se nevynechává ani nezměkčuje, včetně smrti a nemocí. Těžká témata se píšou
  věcně a s uvedením, že jde o tradiční výklad („tradice tu mluví o…“), ne o jistotu.
- Texty popisují, neradí: žádné pokyny k léčbě, investicím ani právním krokům.
- Témata pro pohled „podle témat“: povaha, vztahy, rodina, práce, peníze, zdraví, růst.
- Tranzitní texty: co období přináší a jak ho využít; mají `shadow` a případně `hard`
  stejně jako natální.

Generování (`tools/content/`): skript projde seznam klíčů, pro každý sestaví zadání
(významy planety, znamení, domu, aspektu z malé ručně psané tabulky archetypů
+ pravidla stylu) a uloží JSON. Idempotentní, pokračuje po přerušení, hotové klíče
přeskakuje. Zadání výslovně žádá úplný tradiční výklad včetně těžkých témat
a jeho rozdělení do tří vrstev. Kontroly: schéma, délka, čeština (diakritika, žádná
angličtina), podobnost mezi texty (opakované fráze), neprázdné `shadow`, štítky
`hard` jen z výčtu. Pro klíče, kde tradice těžká témata má (8. a 12. dům, napěťové
aspekty Marsu, Saturnu, Neptunu a Pluta), je prázdné `hard` varování: model mohl
téma zamlčet. **Nejdřív pilot 20 textů se všemi třemi vrstvami ke schválení
vlastníkem, až potom celá dávka.**

### 4.3 Katalog osobností

Známí lidé s datem, časem a místem narození, spolehlivostí času, zdrojem
a událostmi ze života. Formát záznamu, zdroje, postup sestavení a výchozí seznam
kandidátů jsou v `Prompts/KATALOG-osobnosti.md`.

- Do appky jdou jen záznamy s dohledaným zdrojem. Stupně AA a A se označí jako
  potvrzené, B a C nesou upozornění, X (bez času) dává horoskop bez domů.
- Výklad osobnosti z katalogu je tentýž obecný text jako u kohokoli; appka u něj
  uvádí, že jde o tradiční výklad postavení, ne o tvrzení o té osobě.
- Cíl první verze: 150–300 osob.

## 5. Appka

Obrazovky:

1. **Profily** — seznam uložených osob (lokálně, šifrované úložiště).
2. **Zadání** — datum, čas (nebo „neznám“), místo (vyhledávání / souřadnice), systém domů.
3. **Horoskop** — záložky:
   - Přehled: kolo zvěrokruhu + Slunce, Měsíc, ascendent jednou větou.
   - Tabulky: pozice, domy, aspekty, stav planet; každý řádek vede na svůj výklad.
     U domů přepínač systému a srovnání dvou systémů (3.3).
   - Výklad: po oddílech, nebo seskupený podle témat.
   - Tranzity: dnes, denní časová osa po hodinách, kalendář, probíhající;
     každá událost s výkladem (3.4).
4. **Slovníček** — pojmy; odkazy z tabulek (dotaz „co je kvadrát?“ na jedno ťuknutí).
5. **Zeptej se** — dotazy z 3.5: hledání rysu se dvěma sloupci a události s tranzity
   a percentilem dne.
6. **Osobnosti** — katalog podle kategorií, u každého spolehlivost času a zdroj;
   otevře se jako běžný profil včetně událostí.

Kolo kresli vlastním `CustomPainter` (znamení, hroty domů, planety s odsazením
při shluku, čáry aspektů). Symboly z fontu se svobodnou licencí
(např. Noto Sans Symbols, OFL), ne obrázky z Astromatu. Světlý i tmavý režim.
Stav: Riverpod; úložiště: drift nebo JSON v šifrovaném souboru. Jazyk UI česky,
texty přes ARB, aby šla později přidat angličtina.

### 5.1 Filtr „Co nechci vidět“

- Výchozí stav: **zobrazuje se všechno**. Filtr si zapíná uživatel sám.
- Úvodní obrazovka při prvním spuštění řekne, že výklad obsahuje i stinné stránky
  a těžká témata, a nabídne šetrný režim. Doporučí ho tomu, kdo prochází těžkým
  obdobím. Pracovní znění: „Nebudu ti zobrazovat to, co by ti mohlo ublížit.
  Ukaž to svému terapeutovi, sám se na to nedívej.“
- Nastavení: přepínač pro každý štítek `hard` zvlášť a jeden pro stinné stránky
  povahy. Šetrný režim skryje všechna těžká témata jedním ťuknutím.
- Skrytá pasáž nezmizí beze stopy; na jejím místě je řádek „Skryto: 2 pasáže
  (nemoc, ztráta)“.
- „Sdílet celý výklad“: export nefiltrovaného výkladu do PDF, aniž se skryté
  pasáže otevřou na obrazovce. Slouží k předání terapeutovi.
- U skrytých pasáží a v šetrném režimu odkaz na odbornou pomoc (linka první
  psychické pomoci; číslo ověřit před vydáním).
- Filtr je jedno nastavení pro celou appku; platí pro natální výklad i tranzity
  a jde kdykoli změnit.

## 6. Testy

- Golden vektory `astro_core`: neutrální data (1. 1. 2000 12:00 UT, Praha) s čísly
  z tabulky v 3.1 + sada ze Swiss Ephemeris (roky 1900–2100, různé šířky).
  Tolerance: planety 1′, Měsíc 1′, domy 1′.
- Čas: převody SEČ/SELČ v historických letech, přechod data, jižní a západní polokoule.
- Domy: všech 9 systémů proti golden vektorům na rovníku, 50° s. š., 66° s. š.
  a jižní polokouli; Porphyry navíc uzavřeným vzorcem. Automatická volba: 50° →
  Placidus, 63° → Placidus s upozorněním, 70° → Porphyry.
- Tranzity: porovnat s kalendářem Astromatu pro neutrální horoskop, listopad 2026
  (např. Slunce sextil natální Slunce 1.–5. 11., Slunce kvadrát natální Mars 19.–23. 11.).
  Dále: tři průchody při retrográdním pohybu, zastávka v orbu, aspekt Měsíce trvá
  hodiny a leží celý na časové ose, fáze se mění ve správných okamžicích.
- Obsah: každý klíč, který engine umí vyrobit, má text (test úplnosti).
- Filtr: se zapnutým štítkem se žádná jeho pasáž neobjeví ve výkladu, v pohledu
  podle témat ani v tranzitech; počet v řádku „Skryto“ sedí; export celého
  výkladu obsahuje vše.
- Historie: horoskop z 18. století proti DE440, převod juliánského data, místní
  střední čas, tabulka Pluta proti DE440 (odchylka do 1′).
- Dotazy: dotaz na rys vrací oba sloupce a je deterministický; percentil dne se
  při opakování nemění; neznámé slovo nabídne nejbližší hesla.
- Katalog: každý záznam má zdroj a stupeň spolehlivosti; žádný čas bez zdroje.
- **Osobní data narození do repa nepatří** (repo je veřejné). Lokální kontrolní
  horoskopy jen v gitignorovaném `run/`.

## 7. Fáze (každá = jeden PR)

| Fáze | Obsah | Hotovo, když |
|---|---|---|
| F0 | Založení repa (skill `bootstrap-repo`), CLAUDE.md, gate | repo existuje, gate běží |
| F1 | `astro_core`: čas včetně historických dat, polohy, tabulka Pluta, 9 systémů domů s automatickou volbou, aspekty, stav planet + CLI `bin/chart` | golden testy zelené |
| F2 | Schéma obsahu (tři vrstvy), generátor, validátor, **pilot 20 textů** | vlastník schválil styl |
| F3 | Plná dávka textů nativního horoskopu | test úplnosti zelený |
| F4 | Appka: profily, zadání, tabulky, srovnání systémů domů, výklad, slovníček, filtr s úvodní obrazovkou, export PDF | horoskop na telefonu |
| F5 | Kolo zvěrokruhu | odpovídá tabulkám |
| F6 | Tranzity: engine (fáze, průchody, síla), texty, pohledy včetně denní časové osy | kalendář sedí s Astromatem |
| F7 | Dotazy: slovník rysů a štítky, události u profilu, percentil dne | oba druhy dotazů fungují offline |
| F8 | Katalog osobností: nástroje, ověřování, prvních 150 záznamů | každý záznam má zdroj |
| F9 | Vydání (skilly `setup-flutter-app`, `release-flutter`) | TestFlight + Android build |

F1 a F2 jdou souběžně. Po milníku pokračuj dál, stůj jen u rozhodnutí níže.
Po F9 navazují rozšíření R1–R8 z oddílu 10.

## 8. Rozhodnutí vlastníka

| # | Otázka | Výchozí, pokud neřekne jinak |
|---|---|---|
| 1 | Název appky a bundle id | pracovně `astro`, `com.ol1n.astro` |
| 2 | Čím generovat texty | LLM na SPARKu přes gateway (skill `spark-job`); pokud pilot nedá dobrou češtinu, Claude API v dávce |
| 3 | Tykání, nebo vykání | tykání |
| 4 | Repo veřejné? | ano, podle zvyku `lioilsources` |
| 5 | Kniha | nepoužívá se; přesný titul a autorka nejsou ověřené |
| 6 | Android hned, nebo jen iOS | obojí, vydání nejdřív TestFlight |
| 7 | Filtrování obsahu | **rozhodnuto 2026-11-19:** obsah se generuje celý, výchozí stav zobrazuje vše, filtr si zapíná uživatel |
| 8 | Uvádět u těžkých témat „tradice tu mluví o…“ | ano |
| 9 | Výchozí systém domů | automaticky podle šířky narození (3.3); poloha telefonu se nepoužívá |
| 10 | Astro-Databank jako zdroj katalogu | bez svolení jen ruční nahlédnutí k jednotlivým záznamům; požádat Astrodienst o písemné svolení rozhoduje vlastník |
| 11 | Volné otázky přes LLM | ve v1 ne |
| 12 | Stinná stránka a těžká témata u žijících osobností z katalogu | zobrazovat stejně jako u ostatních; viz rizika |
| 13 | Rozšíření (oddíl 10): pořadí a zda R1 patří už do v1 | po v1, v pořadí R1–R8 |
| 14 | Místo pobytu pro planetární hodiny | ručně zvolené město v profilu, výchozí místo narození; poloha telefonu se nepoužívá |
| 15 | Synastrie: partnerský dovětek | jen u typu vztahu partner |
| 16 | Deník: slepý test | dobrovolný, výchozí vypnuto |
| 17 | Solár pro místo pobytu, nebo narození | místo pobytu, přepínatelné |
| 18 | Stálice: seznam a orb | 32 hvězd z 10.6, orb 1° |
| 19 | Elekční: zdravotní záměry (operace, zákrok) | tradiční pravidla popsat ve slovníčku; vyhledávání termínu nenabízet |
| 20 | Horární: otázky o zdraví, smrti a těhotenství | bez verdiktu; tradici popsat ve slovníčku (stejně jako 19) |
| 21 | Horární: varianta pravidel | Lillyho tradice: Regiomontanus, sedm planet, ptolemaiovské termy, trojice pro den a noc |

Bod 2 a pilot z F2 jsou jediná místa, kde se čeká na vlastníka.

## 9. Rizika

- **App Store, pravidlo 4.3(b)**: Apple jmenuje věštecké appky jako přesycenou
  kategorii a zamítá průměrné kusy. Zmírnění: vlastní české texty, výklad tranzitů,
  kvalitní kolo; nejdřív TestFlight. Záloha: webová verze z téhož kódu (Flutter web).
- `astronomia` je mladý balíček → připnutá verze, golden testy, možnost převzít kód.
- Kvalita a jednotvárnost 1400 generovaných textů → pilot, kontrola podobnosti,
  namátková korektura po skupinách.
- Historické časové zóny mimo Evropu a místa bez záznamu → ruční zadání UT a souřadnic.
- Velikost: VSOP87B data ~2 MB, texty ~2 MB, místa ~2–3 MB — přijatelné.
- Nefiltrovaný obsah o smrti a nemocech → vyšší věková kategorie v obchodech
  a přísnější posouzení zdravotních tvrzení. Proto texty popisují tradici a neradí
  k léčbě; kategorii určit podle dotazníku obchodu.
- Model může těžká témata zamlčet nebo změkčit → kontrola v pilotu, varování
  validátoru, případně jiný model.
- Katalog: hromadné převzetí cizí databáze naráží na právo pořizovatele databáze;
  údaje o žijících lidech jsou osobní údaje i tehdy, když jsou veřejné → jen
  veřejně známé osoby, u každého zdroj, odstranění záznamu na žádost.
- Negativní výklad u jmenovaných žijících lidí může obchod posoudit jako urážlivý
  obsah o skutečných osobách → výklad označit jako tradiční čtení postavení,
  ne tvrzení o osobě (rozhodnutí 12).
- Spolehlivost časů narození je u většiny osobností nízká; české osobnosti čas
  doložený většinou nemají.
- Rozšíření: víc technik znamená víc shod náhodou. Appka to říká ve slovníčku
  a deník (10.3) to měří; výsledek „žádná souvislost“ se nesmí skrývat.
- Deník hodnotí náladu → nepsat nic, co by znělo jako diagnóza nebo rada k léčbě.
- Synastrie mezi rodičem a dítětem → partnerský dovětek hlídá validátor (10.4).
- Dalších ~770 textů → stejná kontrola jednotvárnosti jako v F3, pilot pro každou fázi.
- Stálice jsou nejtemnější obsah appky → počítat s nejvyšší věkovou kategorií;
  uvození „tradice tu mluví o…“ je u nich povinné.
- Elekční část radí, kdy jednat → záměry jen z uzavřeného seznamu, žádné
  zdravotní, právní ani finanční doporučení (rozhodnutí 19).
- Horární část dává konkrétní verdikt → nejvyšší odpovědnost v appce a nejsnáze
  vyvratitelné tvrzení; obchod to může číst jako věštění (pravidlo 4.3(b)).
  Zmírnění: uzavřený seznam témat, formulace „podle tradičních pravidel“,
  vyhodnocení zásahů (10.8), rozhodnutí 20.
- Horární pravidla a tabulky důstojností se v pramenech liší a model je z paměti
  splete → opsat z volného pramene, hlídat kontrolními testy.

## 10. Rozšíření po v1

Sedm technik a deník předpovědí. Výběr se řídil třemi pravidly: staví na enginu
z F1 a F6 bez nové efemeridy (stálice chtějí jen malý katalog hvězd), hodí se pro
rodinu s více profily a vejde se do stejného modelu obsahu (klíč → text ve třech
vrstvách, oddíl 4). Co neprošlo a proč, je v 10.9.

| Fáze | Obsah | Závisí na | Nové texty |
|---|---|---|---|
| R1 | Obrazce aspektů | F1, F3, F5 | ~56 |
| R2 | Měsíc a planetární hodiny v denní ose | F6 | ~69 |
| R3 | Deník předpovědí | F6, F7 | ~10 |
| R4 | Partnerský horoskop (synastrie) | F4 | ~345 |
| R5 | Progrese a solár | F1, F6 | ~110 |
| R6 | Stálice | F1, F4, F5 | ~47 |
| R7 | Elekční astrologie („najdi termín“) | R2, F6 | ~41 |
| R8 | Horární astrologie („zeptej se“) | R2, R3, R7 | ~93 |

Celkem zhruba 770 textů navíc. Každá fáze je jeden PR. Pořadí určují závislosti; R6 je nezávislá a smí jít dřív.
R1 nezávisí na tranzitech a smí jít hned po F5.

R9 (průvodce vztahem nad R4: čtení po kapitolách, rady, zátěžová období) má vlastní
plán: `Prompts/PLAN-pruvodce-vztahem.md`.

### 10.1 R1 — Obrazce aspektů

Hledání tvarů v hotovém seznamu aspektů, žádná nová astronomie.

- Tvary: velký trigon, T-kvadrát, velký kříž, drak, kolébka, mystický obdélník, jod.
- Jod potřebuje kvinkunx (150°). Počítá se jen kvůli němu, orb 2°, v tabulce
  aspektů se nezobrazuje.
- Tvar platí, když všechny jeho strany leží v orbech z 3.3. Výpis jmenuje planety,
  které ho tvoří; kolo (F5) tvar zvýrazní.
- Stellium neduplikovat, pokrývá ho `emphasis/…`.

| Klíč | Počet |
|---|---|
| `pattern/grand_trine/{živel}` | 4 |
| `pattern/t_square/{kvalita}` + `pattern/t_square_apex/{planeta}` | 3 + 10 |
| `pattern/grand_cross/{kvalita}` | 3 |
| `pattern/yod_apex/{planeta}` | 10 |
| `pattern/kite/{živel}`, `pattern/cradle`, `pattern/mystic_rectangle` | 4 + 1 + 1 |
| `pattern/modality/{kvalita}/{přemíra, nedostatek}` | 6 |
| `pattern/hemisphere/{nad, pod, východ, západ}` | 4 |
| `pattern/unaspected/{planeta}` — planeta bez hlavního aspektu | 10 |

### 10.2 R2 — Měsíc a planetární hodiny

Doplňuje denní časovou osu z 3.4 o věci, které se mění po hodinách.

- **Planetární hodiny:** den od východu do západu Slunce a noc od západu do východu
  se dělí každý na 12 nestejných hodin. Vládci jdou v chaldejském pořadí Saturn,
  Jupiter, Mars, Slunce, Venuše, Merkur, Měsíc; první hodina dne určuje vládce dne.
  Východ a západ dává `astronomia` (`sunrise`, `rise`); ověřit golden vektorem.
- **Místo pobytu:** hodiny závisejí na tom, kde člověk právě je, ne kde se narodil.
  Profil dostane pole „místo pobytu“, výchozí je místo narození (rozhodnutí 14).
  Za polárním kruhem, když Slunce nevychází nebo nezapadá, se hodiny nezobrazí.
- **Fáze Měsíce:** osm fází, přesné časy novu a úplňku půlením elongace.
  U narození navíc fáze, ve které se člověk narodil.
- **Lunace v domě:** do kterého natálního domu padne nov a úplněk.
- **Měsíc bez aspektu:** od posledního hlavního aspektu Měsíce ve znamení po vstup
  do dalšího. Výchozí výpočet bere planety Slunce až Pluto; přepínač „jen tradiční“.
- **Zatmění:** jen příznak u novu a úplňku blízko uzlu, bez místní viditelnosti.

| Klíč | Počet |
|---|---|
| `planetary_hour/{planeta}`, `planetary_day/{planeta}` | 7 + 7 |
| `moon_phase/{fáze}`, `natal_moon_phase/{fáze}` | 8 + 8 |
| `moon_today/{znamení}` | 12 |
| `lunation_in_house/{nov, úplněk}/{dům}` | 24 |
| `void_of_course`, `eclipse/{sluneční, měsíční}` | 1 + 2 |

### 10.3 R3 — Deník předpovědí

Odpověď na otázku „je na to důkaz?“ nad vlastními daty. Metodika je převzatá
z projektu heliograf: hypotéza zapsaná předem, srovnání se základním odhadem,
záznam bez přepisování.

- **Hodnocení dne:** celkově −2 až +2, volitelně štítky ze slovníku rysů (3.5)
  a poznámka. Večerní připomínka je místní oznámení, bez sítě.
- **Záznam bez přepisování:** den se uzavře koncem následujícího dne, pak ho nejde
  upravit. Oprava je nový záznam s odkazem na původní.
- **Co se ukládá:** hodnocení, skóre napětí dne, verze enginu a verze vzorce skóre.
  Tranzity samotné se neukládají, dají se kdykoli spočítat znovu.
- **Vlastní hypotézy:** uživatel zapíše pravidlo, například „při kvadrátu Marsu
  na Měsíc spím špatně“. Počítají se jen dny po zápisu. Výsledek: kolikrát to
  vyšlo, proti tomu, jak často ten štítek dává i bez tranzitu.
- **Slepý test:** dobrovolný režim na 90 dní, kdy se pohled Dnes odemkne až po
  ohodnocení dne. Hodnocení mimo test nesou příznak „viděl předpověď“ a vyhodnocují
  se zvlášť.
- **Vyhodnocení od 60 ohodnocených dní:**
  1. pořadová korelace skóre napětí a hodnocení,
  2. test proti náhodě: přeházení hodnocení po celých týdnech, 10 000×; výsledek
     říká, v kolika procentech náhodných přeházení vyjde shoda stejná nebo lepší,
  3. kontrola cizím horoskopem: totéž proti tranzitům dvaceti náhodných osob
     z katalogu. Otázka zní, jestli vlastní horoskop sedí líp než cizí.
- Do 60 dní appka píše „zatím málo dat“. Výsledek se uvádí větou a velikostí
  efektu, nikdy slovem „důkaz“. I výsledek „žádná souvislost“ je platný a zobrazí se
  stejně výrazně jako opačný.
- Týdny místo dnů proto, že pomalé tranzity trvají týdny a nálada drží několik dní
  po sobě; přeházení po dnech by shodu nadhodnotilo.
- Export deníku do CSV. Všechno zůstává v telefonu.

Testy: syntetický deník s náhodným hodnocením nesmí vyjít jako shoda; syntetický
deník odvozený ze skóre vyjít musí.

### 10.4 R4 — Partnerský horoskop (synastrie)

Srovnání dvou uložených profilů. V1 ho měla mimo rozsah, tady se vrací.

- Výpočet: aspekty planet jedné osoby na planety a osy druhé, planety jedné osoby
  v domech druhé. Orby jako u natálních aspektů (3.3).
- **Typ vztahu:** partner, rodič a dítě, sourozenci, přátelé, kolegové. Základní
  text je psaný neutrálně („mezi vámi“). Partnerský dovětek o přitažlivosti
  a intimitě je čtvrté volitelné pole `partner` a zobrazí se jen u typu partner.
  U rodiče a dítěte se nesmí objevit nikdy; validátor to hlídá.
- **Téměř shodné horoskopy** (dvojčata, rozdíl všech planet pod 1°): místo deseti
  konjunkcí appka řekne, že horoskopy jsou skoro stejné, ukáže, co se liší
  (osy a domy podle minut), a odkáže na heslo o dvojčatech ve slovníčku.
- Pohled: dvojité kolo (vnitřní a vnější prstenec), tabulka aspektů mezi osobami.
- Kompozit (horoskop ze středů) je možný druhý krok, v R4 není.

| Klíč | Počet |
|---|---|
| `synastry/{p1}/{p2}/{typ}` — 55 neuspořádaných párů včetně stejné planety × (konjunkce, harmonický, napěťový) | 165 |
| `synastry_point/{bod}/{planeta}/{typ}` — ASC, MC × 10 × 3 | 60 |
| `synastry_house/{planeta}/{dům}` — planeta jedné osoby v domě druhé | 120 |

### 10.5 R5 — Progrese a solár

Dvě časové techniky vedle tranzitů. Tranzit říká, co přichází zvenčí; progrese
popisuje pomalý vnitřní vývoj, solár jeden rok.

- **Sekundární progrese:** den po narození odpovídá roku života. Progresní horoskop
  pro věk N let je horoskop pro okamžik narození + N dní.
  - Osy: MC posunuté o sluneční oblouk, ASC z něj dopočítaný. Zapsat do
    `docs/scoring.md` jako zvolenou metodu.
  - Hlavní ukazatel je progresní Měsíc: znamení a dům mění zhruba po 2,5 roce.
    Progresní Slunce mění znamení jednou za 30 let.
  - Progresní aspekty na natální polohy, orb 1°. Výklad skládá text z `transit/…`
    s úvodní větou `progressed/modifier`; samostatné texty se nepíšou.
  - Progresní fáze Měsíce, cyklus 29,5 roku.
- **Solár:** horoskop pro okamžik, kdy se Slunce vrátí přesně na natální délku.
  Hledá se půlením na sekundu, tropicky, bez precese. Počítá se pro místo pobytu
  s přepínačem na místo narození (rozhodnutí 17).
- Pohled: časová osa života s milníky (změna znamení progresního Měsíce, soláry)
  a přepínač tranzity / progrese / solár u profilu.

| Klíč | Počet |
|---|---|
| `progressed/moon_in_sign/{znamení}`, `progressed/moon_in_house/{dům}` | 12 + 12 |
| `progressed/sun_in_sign/{znamení}` | 12 |
| `progressed/lunar_phase/{fáze}`, `progressed/modifier` | 8 + 2 |
| `solar_return/asc/{znamení}`, `solar_return/sun_in_house/{dům}` | 12 + 12 |
| `solar_return/planet_on_angle/{planeta}/{osa}` | 40 |

Testy: progresní Měsíc pro J2000 + 30 let proti golden vektoru; okamžik soláru
proti golden vektoru na sekundy; solár pro stejný rok a dvě místa má stejné
planety a jiné domy.

### 10.6 R6 — Stálice

Konjunkce planet a os s jasnými hvězdami. Je to nejtemnější část tradice: významy
hvězd jsou většinou o násilí, slepotě, utonutí a pádu, takže skoro celý obsah leží
ve stinné a těžké vrstvě (4.1).

- **Výpočet:** souřadnice a vlastní pohyb z veřejného katalogu (Hipparcos nebo
  Yale Bright Star; licenci ověřit), precese na datum přes `astronomia`
  (`precess`), převod na ekliptikální délku. Malá tabulka v `astro_core`, bez sítě.
- **Pravidlo:** jen konjunkce podle ekliptikální délky, orb 1°, s planetami
  Slunce až Pluto, s ASC a MC. Při 32 hvězdách vyjdou v průměru dva zásahy
  na horoskop.
- Hvězdy daleko od ekliptiky (Sírius, Vega, Algol) se podle tradice berou stejně;
  slovníček to vysvětlí. Společný východ a kulminace (parany) se nepočítají.
- **Seznam, 32 kandidátů:** Algol, Alkyone, Aldebaran, Rigel, Bellatrix, Capella,
  Betelgeuze, Sírius, Castor, Pollux, Prokyon, Praesepe, Alphard, Regulus, Denebola,
  Vindemiatrix, Algorab, Spica, Arcturus, Zubenelgenubi, Zubeneschamali, Unukalhai,
  Akrab, Antares, Ras Alhague, Vega, Altair, Deneb Algedi, Fomalhaut, Achernar,
  Markab, Scheat.
- **Vrstvy:** základní text říká, kde hvězda leží, její mýtus a povahu podle planet
  („povahy Marsu a Jupitera“). Tradiční výroky patří do stinné a těžké vrstvy
  s uvozením z rozhodnutí 8. Moderní psychologický přepis se nevydává za tradici.
  Validátor u hvězd nevyžaduje minimální délku základní vrstvy.
- **Filtr:** se zapnutým filtrem zbude u většiny hvězd jen základní text
  a zástupný řádek; tabulka stálic to nahoře řekne jednou větou.
- **Pohled:** tabulka „Stálice“ u horoskopu (hvězda, délka, s čím je v konjunkci,
  orb) a značky na vnějším okraji kola s přepínačem.
- Tranzity na hvězdy ani hvězdy v synastrii se nepočítají.

| Klíč | Počet |
|---|---|
| `star/{hvězda}` — 150–250 slov včetně vrstev | 32 |
| `star_target/{bod}` — věta o tom, co znamená hvězda u Slunce, Měsíce, ASC, MC… | 12 |
| hesla slovníčku: stálice, precese, královské hvězdy | 3 |

Testy: délky pěti hvězd pro roky 1800 a 2000 proti golden vektoru (skyfield
+ katalog); planeta 0,9° od hvězdy zásah má, 1,1° nemá.

### 10.7 R7 — Elekční astrologie („Najdi termín“)

Obrácený směr než zbytek appky: čas se nečte, ale hledá. Uživatel zadá záměr
a období, engine vrátí seřazená časová okna s důvody pro a proti.

- **Vstup:** záměr z uzavřeného seznamu, období nejvýš 90 dní, místo pobytu,
  volitelně profil, omezení na hodiny dne a dny v týdnu.
- **Záměry a jejich ukazatele:**

| Záměr | Dům | Planeta |
|---|---|---|
| svatba, vztah | 7 | Venuše |
| smlouva, podpis, jednání | 3, 7 | Merkur |
| zahájení podnikání, spuštění projektu | 1, 10 | Slunce, Jupiter |
| peníze, nákup | 2 | Jupiter, Venuše |
| stěhování, nemovitost | 4 | Měsíc |
| cesta | 3, 9 | Merkur, Jupiter |
| zkouška, studium | 3, 9 | Merkur |
| žádost, pohovor | 10 | Slunce, Jupiter |

  Zdravotní záměry (operace, zákrok): rozhodnutí 19.

- **Vyloučení:** Měsíc bez aspektu (z R2). Je to jediné tvrdé pravidlo.
- **Plus:** dorůstající Měsíc; příští aspekt Měsíce míří na Venuši nebo Jupiter;
  Venuše nebo Jupiter u osy; vládce ascendentu ve vlastním znamení nebo
  v povýšení a přímý; planetární hodina planety záměru.
- **Minus:** příští aspekt Měsíce je kvadrát nebo opozice na Mars nebo Saturn;
  Mars nebo Saturn u osy; planeta záměru retrográdní, v pádu nebo ve zničení;
  vládce ascendentu v 6., 8. nebo 12. domě; zatmění a den před ním a po něm;
  Měsíc ve „spálené cestě“ (15° Vah až 15° Štíra).
- **Osobní vrstva**, je-li vybraný profil: skóre napětí tranzitů toho dne (F6)
  a aspekt Měsíce okna na natální Slunce, Měsíc a ASC.
- **Pravidla jsou data:** `content/rules/election.json` — `id`, druh (`exclude`,
  `plus`, `minus`), váha, záměry, klíč textu. Váhy a vzorec v `docs/scoring.md`.
  Kód pravidla jen vyhodnocuje.
- **Hledání:** vzorek po 10 minutách, protože ascendent se posune o stupeň
  za 4 minuty. Planety počítat po hodině a interpolovat, osy pro každý vzorek.
  Sousední vzorky se stejným výsledkem slít do okna. Běží v samostatném izolátu
  (isolate), 90 dní do 2 sekund.
- **Výstup:** nejvýš 10 oken; u každého datum, od–do, skóre a důvody pro a proti
  ve dvou sloupcích jako u dotazu na rys (3.5). Ťuknutí otevře horoskop okamžiku.
  Export do kalendáře souborem `.ics`.
- **Formulace:** „podle tradičních pravidel nejvhodnější“, nikdy záruka. Když
  žádné okno neprojde, appka to řekne a ukáže nejméně špatné s výčtem proti.
- **Vazba na deník (10.3):** zvolený termín se dá zapsat jako hypotéza a po akci
  ohodnotit.

| Klíč | Počet |
|---|---|
| `election/rule/{pravidlo}` — proč to tradice bere jako dobré nebo špatné | ~25 |
| `election/intent/{záměr}` | 8 |
| `election/verdict/{druh}` — šablony výsledku | ~5 |
| hesla slovníčku: elekce, spálená cesta, přijetí | 3 |

Testy: okno s Měsícem bez aspektu se nikdy nevrátí; stejné zadání dává stejné
skóre; slévání oken; validace souboru pravidel (každé má váhu a text); 90 dní
pod 2 sekundy.

### 10.8 R8 — Horární astrologie („Zeptej se“)

Horoskop se staví na okamžik otázky, ne na narození. Výsledkem není výklad povahy,
ale verdikt na jednu konkrétní otázku s výčtem důvodů. Je to jiný druh enginu:
rozhodovací strom podle pravidel 17. století.

- **Vstup:** otázka vlastními slovy (jen pro uživatele, appka ji nečte), téma
  z uzavřeného seznamu, okamžik potvrzení otázky, místo pobytu.
- **Rámec, odlišný od zbytku appky:** jen sedm tradičních planet, tradiční vládci,
  domy Regiomontanus bez ohledu na nastavení profilu (za polárním kruhem Porphyry).
- **Ukazatele (signifikátory):** tazatele zastupuje vládce ascendentu a Měsíc,
  dotazovanou věc vládce domu tématu a její přirozená planeta.

| Téma | Dům |
|---|---|
| peníze, majetek, ztracená věc | 2 |
| sourozenci, krátká cesta, zpráva | 3 |
| domov, nemovitost, rodiče | 4 |
| děti, láska, hra | 5 |
| každodenní práce, podřízení, domácí zvíře | 6 |
| partner, smlouva, spor, protivník | 7 |
| dluhy, dědictví, cizí peníze | 8 |
| dálková cesta, studium, úřady a právo | 9 |
| kariéra, místo, nadřízený | 10 |
| přátelé, přání | 11 |
| skryté věci, tajní nepřátelé | 12 |

  Otázky o zdraví, smrti a těhotenství: rozhodnutí 20.

- **Otázka o někom jiném:** odvozené domy. Uživatel vybere osobu (sourozenec 3,
  dítě 5, partner 7, rodič 4 nebo 10, přítel 11) a téma; dům se počítá od domu
  osoby. Práce sourozence je 10. dům od 3., tedy 12.
- **Výhrady před výkladem** (varování, výklad neblokují): ascendent v prvních nebo
  posledních 3° znamení, Měsíc bez aspektu, Měsíc ve spálené cestě, Saturn
  v 1. nebo 7. domě, vládce planetární hodiny (R2) nesouhlasí s ascendentem.
- **Strom rozhodnutí:**
  1. Síla ukazatelů: bytostné důstojnosti (sídlo, povýšení, trojice, term, tvář;
     zničení, pád, bez důstojnosti) a nahodilé (dům, retrográdnost, rychlost,
     spálení do 8°30′ od Slunce, pod paprsky do 17°, v srdci Slunce do 17′).
  2. Dokonání: engine posune oblohu dopředu (krok 1 h, půlení jako u tranzitů)
     a hledá, jestli se aspekt mezi ukazateli stane přesným dřív, než jeden z nich
     opustí znamení. Blížící se aspekt znamená ano, vzdalující se „už je to pryč“.
  3. Náhradní cesty: přenos světla (rychlejší planeta jde od jednoho k druhému),
     sběr světla (oba míří na pomalejší třetí), postavení ukazatele v domě věci.
  4. Co dokonání zruší: zábrana (třetí planeta se vloží dřív), zmaření, ústup
     (ukazatel se před dokonáním zastaví a obrátí), spálení.
  5. Přijetí (recepce): s přijetím jde věc snadno; kvadrát nebo opozice bez
     přijetí dávají „ano, ale s potížemi“.
- **Verdikt** z uzavřené sady: ano / ano s potížemi / ne / už je to pryč /
  nic z toho nebude / nelze říct. Pod ním důvody pro a proti ve dvou sloupcích.
- **Čas:** počet stupňů do dokonání a jednotka podle druhu znamení a domu
  (rychlé, střední, pomalé). Uvádí se jako tradiční odhad, ne termín.
- **Ztracená věc:** navíc směr a druh místa podle znamení a domu ukazatele.
- **Pravidla a tabulky jsou data:** `content/rules/horary.json` a tabulky
  důstojností v `astro_core`. **Nepsat je z paměti modelu.** Opsat z volného
  pramene (William Lilly, *Christian Astrology*, 1647) a postup popsat
  v `docs/horary.md`. Výchozí varianty: rozhodnutí 21.
- **Deník otázek:** záznam bez přepisování jako v 10.3. Stejné téma znovu během
  24 hodin: appka upozorní, že tradice druhý pokus nebere, a ukáže první horoskop.
- **Vyhodnocení:** každá otázka dostane po čase dotaz „jak to dopadlo?“.
  Od 30 uzavřených otázek s odpovědí ano nebo ne appka ukáže podíl zásahů proti
  dvěma základním odhadům: „vždycky ano“ a „vždycky ne“.
- **Formulace:** „podle tradičních pravidel vychází…“, nikdy „stane se“.
- **Soukromí:** text otázek je citlivý; ukládá se šifrovaně s profilem a do exportu
  PDF jde jen na výslovnou volbu.

| Klíč | Počet |
|---|---|
| `horary/house/{dům}` — co do domu patří v horární otázce | 12 |
| `horary/significator/{planeta}` — koho a co planeta zastupuje | 7 |
| `horary/testimony/{pravidlo}` — dokonání, náhradní cesty, zrušení, přijetí, síla | ~25 |
| `horary/consideration/{druh}`, `horary/verdict/{druh}` | 6 + 6 |
| `horary/timing/{jednotka}` | ~5 |
| `horary/lost/{znamení}`, `horary/lost_house/{dům}` | 12 + 12 |
| hesla slovníčku: horární astrologie, ukazatel, dokonání, přenos a sběr světla, spálení, radikální horoskop… | ~8 |

Testy:

- tabulky důstojností: každý stupeň zvěrokruhu má právě jednoho vládce termu
  a tváře, termy každého znamení dají 30°;
- blížící se a vzdalující se aspekt na sestavených polohách; dokonání před změnou
  znamení a po ní;
- zábrana třetí planetou, ústup na skutečné zastávce Merkuru, přenos a sběr světla
  na sestavených případech;
- odvozené domy; výhrady (ascendent na 2° dá varování);
- stejný okamžik, místo a téma dají stejný verdikt;
- dva příklady z Lillyho knihy přepočítat jako kontrolní případy (Anglie tehdy
  užívala juliánský kalendář); porovnávat polohy a postup.

### 10.9 Zvažováno, nezařazeno

**Odloženo — stejný engine, může přijít později:**

| Technika | Proč teď ne |
|---|---|
| Roční profekce, firdarie | výpočet je tabulka, ale stojí na helénistickém rámci (celoznamenné domy, tradiční vládci), který appka jinde nevykládá |
| Bod štěstí a další arabské body | levné (vzorec, 24 textů); první kandidát na přidání k R1 |
| Lilith, Chiron, asteroidy | střední Lilith je vzorec, Chiron a asteroidy chtějí vlastní tabulky poloh; každé těleso znamená přes 100 nových textů |
| Sluneční oblouk, primární direkce, lunární návraty, zodiakální uvolňování | další předpovědní vrstvy přes sebe; nejdřív jedna rodina (progrese a solár) |
| Kompozit | druhý krok po R4 |
| Vedlejší aspekty, středy, harmonické, dekany, deklinace | jemnější síto dává víc „zásahů“ náhodou a málo nového; zhoršilo by vypovídací hodnotu deníku |
| Astrokartografie | chce mapu světa offline a nový pohled; dobrý kandidát na odlišení v obchodě |
| Siderický zodiak, 13 souhvězdí, heliocentrický horoskop | přepínač ve výpočtu, ale texty jsou psané pro tropický zodiak; bez textů jen tabulka |

**Jiné systémy — nestaví na horoskopu, každý je vlastní appka:**

| Systém | Proč ne |
|---|---|
| Védská astrologie (nakšatry, daši) | vlastní zodiak, vlastní časové techniky a korpus textů velký jako celý západní |
| Čínský horoskop a čtyři pilíře, mayský kalendář | vlastní kalendářní výpočet a vlastní korpus |
| Numerologie, biorytmy | výpočet triviální, ale jiná tradice; číslo jména naráží na přepis diakritiky |
| Tarot, I-ťing, runy, geomancie | náhodný tah bez data narození, jiný produkt; tarot chce vlastní ilustrace |
| Tabulky souvztažností (kovy, kameny, byliny, kabala) | šly by jako hesla slovníčku; byliny a kameny se blíží zdravotním tvrzením |

**Nejde:** Human Design a Gene Keys jsou chráněné systémy a značky.

**Vazba na projekt heliograf (snímky Slunce):** do appky se přebírá jen metodika
(10.3). Skutečná data o Slunci k datu události — počet skvrn, index Kp, snímek —
by byla volitelný doplněk se sítí, ne výklad: souvislost sluneční aktivity
s osobními událostmi se z dat vyvodit nedá. Zdroje by byly veřejné (NASA, NOAA,
GFZ); řada počtu skvrn SILSO je jen pro nekomerční užití. Opačným směrem může
engine popsat planety v zorném poli koronografu při konjunkci se Sluncem.
