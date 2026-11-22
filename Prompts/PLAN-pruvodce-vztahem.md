# PLAN: Průvodce vztahem (R9)

Stav: návrh, 2026-11-22. Navazuje na `PLAN-astro-app.md`, oddíl 10.4 (R4, synastrie).
Pravidla z hlavního plánu platí dál (obsah 4.1 a 4.2, filtr 5.1, invarianty v `CLAUDE.md`).

## 1. Cíl

Vyberu dva uložené profily a dostanu souvislé čtení o vztahu po kapitolách, podobně
jako u výkladu jednoho profilu. Dnes appka umí jen seznam aspektů mezi horoskopy.

| Přání vlastníka | Kde to bude |
|---|---|
| V čem si vyhoví | kapitola 1 „V čem si vyhovíte“ |
| Na co si mají dát pozor, jaké krize čekat | kapitola 2 „Na co si dát pozor“ |
| Jak je řešit | vrstva `advice` („Co s tím“) u kapitol 2 až 6 |
| Jak spolu mluvit | kapitola 3 |
| Jak se respektovat | kapitola 4 |
| Jak dopřát druhému, co potřebuje a očekává | kapitola 5 „Co kdo potřebuje“ |
| Kdy krize přijdou | kapitola 6 a záložka „Období“ (časová osa) |

## 2. Výchozí stav (R4 je hotové)

Před začátkem přečti:

| Soubor | Co v něm je |
|---|---|
| `packages/astro_core/lib/src/synastry.dart` | `Synastry.compute`, `Relationship`, `HouseOverlay`, dvojčata |
| `packages/astro_core/lib/src/transits.dart` | `TransitEngine.events`, `ingresses`, série průchodů (`_number`, `seriesGap`), síla |
| `packages/astro_core/lib/src/content/keys.dart`, `factors.dart`, `entry.dart` | klíče skupin, délky, `synastryFactorsOf`, `ContentEntry` s vrstvou `partner` |
| `app/lib/ui/synastry/synastry_screen.dart` | výběr dvou profilů a typu vztahu; záložky Kolo, Tabulky, Výklad |
| `app/lib/logic/synastry_reading.dart` | výklad dvojice: každý text jednou, tři oddíly |
| `app/lib/ui/entry_view.dart` | vykreslení vrstev pod filtrem, `showPartner`, `HelpLink` |
| `tools/content/lib/prompt.dart`, `validate.dart`, `bin/generate.dart` | zadání pro generátor, validátor, dávka (`--batch`, `--collect`) |
| `docs/scoring.md` (Synastrie, Tranzity), `docs/style.md`, `docs/content.md` | zvolené konvence |
| `app/test/synastry_test.dart` | fiktivní dvojice Anna a Petr; test, že vrstva `partner` jde jen přes `Relationship.showsPartnerLayer` |

Co už funguje: 345 textů synastrie (`synastry`, `synastry_point`, `synastry_house`)
se všemi vrstvami a s dovětkem `partner`; 500 textů `transit/…`; dvojité kolo; tabulky.

Co chybí:

- Čtení po tématech. Výklad je seznam 30 a více textů seřazených podle váhy.
- Texty o jednom člověku psané pro toho druhého (co potřebuje, jak s ním mluvit).
- Rady. Pravidlo stylu dnes říká „texty popisují, neradí“.
- Čas. Synastrie je statická, o obdobích neříká nic.
- Uložená dvojice. Výběr se po zavření ztratí a vstup je jen ikona v liště Profilů.

## 3. Zásady

- Všechno offline a deterministicky: klíč → text. Žádné LLM za běhu.
- Žádné skóre shody v procentech (rozhodnutí 22). Místo něj přehled počtů po oblastech.
- Průvodce nedává verdikt o vztahu. Nikdy „hodíte se“, „nehodíte se“, „rozejděte se“.
- O obdobích mluví jako tradice: „tradice čte tohle období jako zkoušku“, nikdy
  „přijde krize“. Kapitola se jmenuje „Zátěžová období“.
- Rady jsou jen ve vrstvě `advice` a jen k jednání ve vztahu (oddíl 5.2).
- Základní vrstvy jsou neutrální pro každý typ vztahu. Romantika a intimita patří
  jen do `partner`, které se dál zobrazuje výhradně přes `Relationship.showsPartnerLayer`.
- Plný text se v průvodci objeví jednou. Jinde je na něj jen odkaz.
- Skutečná data narození do repa nepatří. Testy a příklady používají fiktivní Annu
  a Petra ze `synastry_test.dart`; vlastní kontrola jen v gitignorovaném `run/`.

## 4. Výpočet (`astro_core`)

### 4.1 Průvodce — `lib/src/pair_guide.dart`

Čistá fakta nad `Synastry`, bez textů. Klíče a faktory patří do `content/keys.dart`
a `content/factors.dart` jako u ostatních skupin.

**Tón aspektu** (`PairTone.supportive` / `straining`):

- harmonický → podpůrný, napěťový → třecí,
- konjunkce je třecí, když je jednou z planet Saturn, Uran, Neptun nebo Pluto, nebo
  Mars s jinou planetou než Venuší a Jupiterem; jinak podpůrná.

Je to zvolená konvence, zapiš ji do `docs/scoring.md`. Obdobné pravidlo
`isTenseTransit` v `app/lib/logic/queries.dart` nech být.

**Oblasti** pro přehled a odkazy: cit (Měsíc), řeč (Merkur), láska (Venuše), energie
(Mars), respekt (Slunce, Saturn). Aspekt se počítá do oblasti každé ze svých dvou
planet. Aspekty jen mezi Jupiterem, Uranem, Neptunem, Plutem a osami oblast nemají.

**Potřeby osoby** (`PersonNeed`): znamení Slunce, Měsíce, Merkuru, Venuše, Marsu
a descendentu (ASC + 180°, jen s časem narození).

**Dvojice živlů** (`ElementPair`): pro Slunce, Měsíc, Merkur, Venuši a Mars živel
znamení u obou osob, neuspořádaně (10 kombinací na planetu).

**Bez času narození:** horoskop se počítá pro místní poledne. Když Měsíc v poledne
leží blíž než 7,7° od hranice znamení (největší pohyb za 12 hodin), jeho znamení není jisté: potřeba Měsíce
i dvojice živlů Měsíců se vynechá a průvodce to řekne (`pair_guide/no_birth_time`).
Descendent chybí vždy.

**Kapitoly:**

| # | Kapitola | Z čeho se skládá | Texty |
|---|---|---|---|
| 0 | Přehled | počty „souzní n · tře se m“ v pěti oblastech; věta o nejbližším zátěžovém období | `pair_guide/overview` |
| 1 | V čem si vyhovíte | podpůrné aspekty mezi horoskopy podle váhy | `synastry/…`, `synastry_point/…`: `text`, `partner` |
| 2 | Na co si dát pozor | třecí aspekty podle váhy; pořadí vrstev `shadow`, `text`, `advice` | tytéž skupiny + doplněk `advice` |
| 3 | Jak spolu mluvit | Merkur každého, dvojice živlů Merkurů, odkazy na aspekty oblasti řeč | `pair_need/mercury/…`, `pair_elements/mercury/…` |
| 4 | Jak se respektovat | Slunce každého, dvojice živlů Sluncí, odkazy na aspekty oblasti respekt | `pair_need/sun/…`, `pair_elements/sun/…` |
| 5 | Co kdo potřebuje | u každého Měsíc, Venuše, Mars, descendent; dvojice živlů Měsíců, Venuší, Marsů; odkazy na aspekty oblastí cit, láska, energie | `pair_need/…`, `pair_elements/…` |
| 6 | Zátěžová období | tři nejbližší období z 4.2 a odkaz na záložku Období | `pair_period/…` |

- Kapitoly 1 a 2 ukážou pět nejtěžších položek, zbytek pod „Zobrazit další (n)“.
- Odkaz v kapitolách 3 až 5 je řádek s titulkem faktu, který otevře text v listu
  (`showEntry`). Plný text aspektu je jen v kapitole 1 nebo 2.
- Planety v domech druhého (`synastry_house`) v průvodci nejsou; zůstávají v záložce Výklad.
- Dvojčata: konjunkce téže planety se vynechají jako dnes, karta dvojčat zůstává nahoře.
- Váha položek jako v `synastryFactorsOf`; potřeby a živly podle váhy planety.

### 4.2 Období — `lib/src/pair_timeline.dart`

Pomalé tranzity na citlivé body obou horoskopů v jednom časovém pásu.

1. **Série průchodů.** `TransitEngine.events` vrací každý pobyt v orbu zvlášť. Přidej
   veřejnou funkci, která pobyty téže konfigurace (planeta, cíl, aspekt, strana)
   s mezerou do `seriesGap` spojí do jedné série: začátek prvního pobytu, konec
   posledního, všechny přesné okamžiky, zastávka. Logiku ber z `_number`, neduplikuj ji.
2. **Co se hledá** (pro každou osobu zvlášť, orb `transitOrb` z konfigurace):

   | Druh | Tranzitující | Cíl | Aspekty | Klíč |
   |---|---|---|---|---|
   | zátěž | Saturn, Uran, Neptun, Pluto | Slunce, Měsíc, Venuše, Mars | konjunkce, kvadrát, opozice | `pair_period/{planeta}/{cíl}` |
   | zátěž | tytéž | ASC (osa vztahu) | konjunkce, opozice | `pair_period/{planeta}/axis` |
   | přelom | Saturn, Uran, Neptun, Pluto | vlastní natální poloha | podle tabulky níže | `pair_period/cycle/{id}` |
   | podpora | Jupiter | Slunce, Měsíc, Venuše, Mars | konjunkce, trigon | `pair_period/jupiter/{cíl}` |
   | podpora | Jupiter | ASC | konjunkce, opozice | `pair_period/jupiter/axis` |
   | dům | Saturn, Jupiter | vstup do 7. natálního domu | — | existující `transit_in_house/{planeta}/7` |

   Přelomy: `saturn_return` (konjunkce), `saturn_opposition`, `saturn_square`,
   `uranus_opposition`, `uranus_square`, `neptune_square`, `pluto_square`,
   `jupiter_return` (konjunkce, řadí se k podpoře).

   Bez času narození odpadá cíl Měsíc (nejistota je větší než orb), ASC i vstup do domu.
3. **Váha** pro pořadí: pomalost tranzitující planety (tabulka `_slowness`, zpřístupni
   ji) + 15 za cíl Slunce, Měsíc, Venuše nebo osa, jinak 5; + 10 za zastávku v orbu;
   + 5 za tři a více průchodů. Zapiš do `docs/scoring.md`. Je to pořadí, ne skóre vztahu.
4. **Souběh:** zátěžové období jedné osoby je „společné“, když se s ním aspoň
   30 dní překrývá zátěžové období druhé osoby.
5. **Klidnější okna:** mezery aspoň 90 dní, kdy ani jeden nemá zátěž ani přelom.
6. **Rozsah:** výchozí 2 roky zpět a 10 let dopředu (rozhodnutí 24). Počítat v isolate
   (`Compute.pairTimeline`); pět pomalých těles s krokem 2 dny je levné.

Výklad tranzitu samotného se nepíše znovu: karta období odkazuje na existující
`transit/…` nebo `transit_point/…` přes `transitKey`.

### 4.3 CLI

`packages/astro_core/bin/pair.dart`: dvě narození na příkazové řádce, výpis kapitol
(klíče a fakta) a období. Slouží ke kontrole bez appky, obdoba `bin/chart.dart`.

## 5. Obsah

### 5.1 Nové skupiny

| Klíč | Počet | Základ (slova) | Vrstvy |
|---|---|---|---|
| `pair_need/{bod}/{znamení}` — sun, moon, mercury, venus, mars, dsc × 12 | 72 | 60–110 | `text`, `shadow`, `advice`; `partner` jen u venus a mars |
| `pair_elements/{planeta}/{živel}/{živel}` — 5 planet × 10 neuspořádaných dvojic | 50 | 60–110 | `text`, `shadow`, `advice`; `partner` jen u venus a mars |
| `pair_period/{planeta}/{cíl}` — saturn, uranus, neptune, pluto, jupiter × sun, moon, venus, mars, axis | 25 | 60–110 | `text`, `shadow`, `advice`, `hard` |
| `pair_period/cycle/{id}` — osm přelomů z 4.2 | 8 | 60–110 | `text`, `shadow`, `advice`, `hard` |
| `pair_guide/{id}` — overview, strengths, cautions, talk, respect, needs, periods, calm_window, shared_period, no_birth_time, method | 11 | 25–70 | jen `text` (bez stínu) |
| doplněk `advice` k `synastry/…` (165) a `synastry_point/…` (60) | 225 doplňků | 30–70 | jen nové pole |

Celkem 166 nových textů a 225 krátkých doplňků. Předchozí dávka 759 textů stála
zhruba 25 USD, tady počítej do 15 USD (rozhodnutí 26).

Co které pole říká:

- `pair_need`: `text` = co ten člověk od blízkého potřebuje a očekává; `shadow` = jak
  reaguje, když to nedostává; `advice` = jak mu to dopřát.
- `pair_elements`: `text` = jak se ty dva způsoby potkávají; `shadow` = kde to drhne;
  `advice` = co pomáhá.
- `pair_period`: `text` = čím prochází ten, koho se období týká, a co to dělá mezi
  vámi; `shadow` = jak se to mezi vámi zvrtává; `advice` = jak tím projít spolu
  (co pomáhá tomu, kdo to prožívá, a co druhému). U Jupitera `advice` = jak období využít.
- `pair_guide/method`: co průvodce je a co není; že jde o tradiční čtení bez doloženého
  účinku a že srovnání napětí tranzitů se zlomovými událostmi osobností z katalogu
  žádnou souvislost neukázalo.

### 5.2 Vrstva `advice` („Co s tím“)

Nové volitelné pole `ContentEntry.advice`. Výjimka z pravidla „texty popisují,
neradí“; doplň ji do `docs/style.md`.

- Povoleno jen ve skupinách `synastry`, `synastry_point`, `pair_need`, `pair_elements`,
  `pair_period`. Jinde chyba validátoru.
- Obsah: konkrétní jednání ve vztahu. Jak to říct, na čem se domluvit, kdy si dát
  pauzu, co nedělat.
- Zakázáno: rady k léčbě, lékům, penězům a právu; verdikt o vztahu (zůstat, odejít);
  cokoli, co vede k snášení násilí nebo ponižování.
- 30–70 slov, u `pair_period` 40–80.

### 5.3 Hlas

- `pair_elements`, `pair_period`, doplňky `advice` u synastrie: 2. osoba množného
  čísla jako dnešní synastrie („mezi vámi“, „domluvte si“, „jeden z vás“, „druhý“).
- `pair_need` mluví o jednom člověku ve 3. osobě bez rodu: „Kdo má Měsíc v Raku,
  potřebuje…“, „člověk s Venuší ve Váze“. Žádné on, ona, jeho, její; místo toho
  „ten druhý“, „blízký člověk“. `advice` neosobně: „Pomáhá…“, „Funguje…“, „Nefunguje…“.
- Jména osob dává appka jen do nadpisu („Petr · Měsíc v Raku“). Do textů se jména
  nevkládají, čeština by je musela skloňovat.
- První věta patří jen té kombinaci (pravidlo z `prompt.dart` platí dál).

### 5.4 Validátor a generátor

Validátor (`tools/content/lib/validate.dart`):

- `advice` mimo povolené skupiny → chyba. Prázdné `advice` v `pair_need`,
  `pair_elements`, `pair_period` → chyba; u `synastry*` chyba jen s `--complete`.
- V `advice` slova verdiktu (`rozejd…`, `rozveď…`, `opusť…`) → chyba. „Odejděte na
  chvíli z místnosti“ je v pořádku, proto `odejd…` mezi nimi není.
- Milostná slova (`romantic`) hlídat i v `advice` a v základních vrstvách nových skupin.
- `partner` povolit navíc v `pair_need` a `pair_elements`.
- `pair_need`: zájmena on, ona, jeho, její → varování.
- `pair_guide` do `shadowExempt`. Prázdné `hard` u `pair_period` se Saturnem, Neptunem
  a Plutem → varování (`expectsHard`).

Generátor:

- Nové případy v `describe()` a pravidla hlasu z 5.3 v zadání.
- Do `content/archetypes.cs.json` ručně psaný oddíl `pair`: co která planeta znamená
  ve vztahu (šest bodů z `pair_need`) a co dělá pomalá planeta v období. Vlastní slova,
  žádná předloha z knihy ani z Astromatu.
- Režim `--layer advice`: pro hotové záznamy bez `advice` dostane model titulek,
  `text` a `shadow` a vrátí jen `{"key": …, "advice": …}`. Výsledek se sloučí do
  záznamu a projde validátorem. Musí fungovat i s `--batch` a `--collect`.
- Soubory zapisuj přes `writeFamily` z Dartu, ne Pythonem (přeformátoval by JSON).

## 6. Appka

### 6.1 Uložené dvojice

- `Pair {id, firstId, secondId, relationship}` v `app/lib/data/`, uložené šifrovaně
  přes `EncryptedJsonFiles` (z deníku, R3). Smazání profilu smaže i jeho dvojice.
- Obrazovka Profily: nahoře oddíl „Vztahy“ s uloženými dvojicemi a tlačítkem „Přidat
  vztah“ (dnešní výběr dvou profilů a typu vztahu). Ikona v liště odpadá.
- Dvojice jen z uložených profilů; osobnosti z katalogu ne.

### 6.2 Obrazovka dvojice

Záložky (posuvná lišta): **Průvodce · Období · Kolo · Tabulky · Výklad**. Poslední tři
zůstávají beze změny.

**Průvodce** je jeden svislý list:

- Přehled: pět řádků oblastí s počty „souzní · tře se“; ikona „?“ otevře `pair_guide/method`.
- Každá kapitola: nadpis, úvodní věta z `pair_guide/{id}`, pak bloky.
- Blok má řádek faktů jako dnešní Výklad („Měsíc (Anna) trigon Venuše (Petr)“)
  a text přes `EntryView`. Potřeby mají nadpis se jménem („Petr · Měsíc v Raku“).
- `EntryView` dostane blok „Co s tím“ pro `advice`, hned za stínem. Zobrazuje se
  všude, kde záznam `advice` má, a nepodléhá filtru.
- Filtr 5.1 platí beze změny: stín a těžká témata se skrývají s řádkem „Skryto: …“.
- Pod kapitolou 2 a pod záložkou Období je vždy `HelpLink`. U pasáže se štítkem
  `violence` navíc odkaz na pomoc obětem násilí; číslo ověřit před vydáním.

**Období:**

- Přepínač Zátěžová / Příznivá / Vše a přepínač „Minulost“.
- Seřazeno po rocích, nahoře „Právě probíhá“.
- Karta zátěže: od–do po měsících, jméno osoby, titulek („Saturn kvadrát Venuše“),
  data přesných průchodů, štítek „oba najednou“ u souběhu; text, stín, „Co s tím“;
  odkaz „Výklad tranzitu“ otevře existující text.
- Podpůrná období a vstupy do 7. domu jako úzké řádky, klidnější okna jako oddělovače.
- Časy v zóně telefonu jako jinde.

**Sdílení:** „Sdílet průvodce“ vytvoří PDF (rozšíření `export/pdf_export.dart`)
s kapitolami a obdobími tak, jak jsou vidět pod zapnutým filtrem (rozhodnutí 29).

Všechny texty rozhraní přes ARB. Každé použití `showPartner:` musí dál projít testem
v `synastry_test.dart`.

## 7. Testy

`astro_core`:

- Tón: konjunkce se Saturnem je třecí, Venuše–Jupiter podpůrná, Mars–Venuše podpůrná.
- Průvodce pro Annu a Petra: pořadí kapitol; žádný klíč není plným textem ve dvou
  kapitolách; šest potřeb na osobu s časem, bez času chybí descendent.
- Měsíc u hranice znamení bez času narození: potřeba i dvojice živlů chybí.
- Série: tři průchody při retrográdním pohybu dají jedno období se třemi přesnými okamžiky.
- Návrat Saturnu pro neutrální horoskop (1. 1. 2000 12:00 UT, Praha): okamžiky
  přesných průchodů proti golden vektoru z `tools/golden` (skyfield), tolerance 1 den.
- Souběh a klidnější okna na umělých obdobích. Bez času narození nejsou cíle Měsíc a osa.
- Každý klíč, který průvodce a období umějí vyrobit, je v `allKeysByFamily()`.

`tools/content`: `advice` mimo skupinu, slovo verdiktu, milostné slovo v `advice`
a zájmeno v `pair_need` validátor zachytí.

Appka:

- Průvodce ukáže kapitoly; plný text je jednou; „Co s tím“ se vykreslí.
- Vrstva `partner` v průvodci jen u typu partner; rozšiř stávající smyčku přes
  `Relationship.values`.
- Šetrný režim: stín a těžká témata skryté, řádek „Skryto“ sedí.
- Období: karta s daty, štítek souběhu, přepínače.
- Uložená dvojice přežije restart úložiště; smazání profilu ji odstraní.
- Stávající testy synastrie uprav kvůli nové první záložce, nemaž je.

## 8. Fáze (každá = jeden PR)

| Fáze | Obsah | Hotovo, když |
|---|---|---|
| P1 | `astro_core`: průvodce, období, série, klíče, faktory; vrstva `advice`; validátor; generátor včetně `--layer advice`; CLI; `docs/scoring.md`, `style.md`, `content.md` | gate zelená, CLI vypíše průvodce a období pro Annu a Petra |
| P2 | Texty: **pilot 12 kusů** (2× `pair_need`, 2× `pair_elements`, 3× `pair_period`, 1× přelom, 2× `pair_guide`, 2× doplněk `advice`), po schválení dávka | vlastník schválil pilot; `validate.dart --complete` zelený |
| P3 | Appka: uložené dvojice, Průvodce, Období, „Co s tím“, PDF, l10n | na telefonu vyberu dva profily a čtu průvodce |
| P4 | Volitelně: datum začátku vztahu a jeho výročí (rozhodnutí 28) | — |

P3 nezávisí na textech (chybějící text má dnešní zástupný řádek), takže běží
souběžně s pilotem. Dávku pouštěj přes `bin/gen-content --batch`. Před každým pushem
`bin/gate`. O merge rozhoduje vlastník. Vydání po P3 skillem `release-flutter`, až na pokyn.

## 9. Rozhodnutí vlastníka

Číslování pokračuje za hlavním plánem.

| # | Otázka | Výchozí, pokud neřekne jinak |
|---|---|---|
| 22 | Skóre shody v procentech („match“) | ne; přehled počtů „souzní · tře se“ po oblastech |
| 23 | Rady ve vrstvě `advice` | ano, jen k jednání ve vztahu (5.2) |
| 24 | Rozsah období | 2 roky zpět, 10 let dopředu |
| 25 | Názvy | funkce „Partnerský horoskop“, záložka „Průvodce“, kapitola „Zátěžová období“ |
| 26 | Čím generovat texty | Claude API v dávce jako minule, do 15 USD; nejdřív pilot |
| 27 | Průvodce i pro rodiče a dítě, sourozence, přátele, kolegy | ano, bez vrstvy `partner` |
| 28 | P4: datum začátku vztahu a výročí (Saturn po 7, 14, 21 letech) | až po P3, rozhodne vlastník |
| 29 | PDF průvodce | podle zapnutého filtru (posílá se druhému, ne terapeutovi) |
| 30 | Kompozit (horoskop ze středů) | ne |

Čeká se jen u pilotu textů (P2).

## 10. Rizika

- **Rada ve vztahu, kde je násilí.** Text „mluvte spolu“ může ublížit. Proto zákazy
  v 5.2, kontrola validátorem, odkaz na pomoc a ruční pročtení všech `advice`
  u záznamů se štítkem `violence`.
- **Časová osa straší.** Proto formulace tradice, podpůrná období a klidnější okna
  vedle zátěže, šetrný režim a `pair_guide/method`.
- **Není to doložené.** Ověření na katalogu osobností souvislost neukázalo. Průvodce
  to říká v metodě a nikde neslibuje, že období nastane.
- **App Store 4.3(b):** předpovědi o vztahu jsou věštecký obsah. Zmírnění jako
  u horární části: formulace „podle tradice“, žádný verdikt.
- **3. osoba bez rodu** je v češtině těžká a model bude sklouzávat k „on/ona“.
  Pilot se na to zaměří; validátor varuje.
- **Jednotvárnost** 72 textů potřeb a 50 dvojic živlů: kontrola opakovaných frází
  jako u F3.
- **Soukromí druhého člověka:** data zůstávají v telefonu; PDF odesílá uživatel sám.

## 11. Mimo rozsah

Kompozit a Davisonův horoskop, progrese dvojice, export období do kalendáře,
osobnosti z katalogu ve dvojici, deník dvojice, víc než dva lidé, volné otázky přes LLM.
