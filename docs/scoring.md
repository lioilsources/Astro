# Skóre a vzorce

Vlastní, dokumentované vzorce. Algoritmus Astromatu není známý a shoda bodů
s ním není cílem.

## Stav planety (`planetScore`)

| Složka | Body |
|---|---|
| sídlo (vládne) | +5 |
| povýšení | +4 |
| zničení | −5 |
| pád | −4 |
| úhlový dům (1, 4, 7, 10) | +2 |
| dům 6, 8, 12 | −1 |
| retrográdní (mimo Slunce a Měsíc) | −1 |
| každý harmonický aspekt (sextil, trigon) | +1 |
| každý napěťový aspekt (kvadrát, opozice) | −1 |

Záporné skóre → stinná stránka planety jde ve výkladu před základní text (plán 4.1).

Vládci: tradiční i moderní (Mars i Pluto ve Štíru, Saturn i Uran ve Vodnáři,
Jupiter i Neptun v Rybách). Povýšení sedmi klasických planet podle tradice;
u moderních je volba sporná, zvoleno: Uran ve Štíru, Neptun v Raku, Pluto ve Lvu.

## Orby

| Aspekt | Výchozí | Těsné orby |
|---|---|---|
| konjunkce, opozice | 8° | 3° |
| trigon, kvadrát | 6° | 3° |
| sextil | 4° | 3° |
| se Sluncem nebo Měsícem | +2° | +1° |
| ASC, MC, uzel | 3° | 3° |
| tranzity | 1° | 1° |

Aspekt se sbíhá (`applying`), když se odchylka od přesného úhlu zmenšuje.
Úhly mají v nativním horoskopu rychlost 0.

## Obrazce aspektů (`findPatterns`, plán 10.1)

Hledají se jen mezi deseti planetami (bez uzlu, ASC a MC). Obrazec platí, když
každá jeho strana leží v orbu z tabulky výše; jiné orby se nezavádějí.

| Obrazec | Strany |
|---|---|
| velký trigon | 3 trigony |
| T-kvadrát | opozice + 2 kvadráty k vrcholu |
| velký kříž | 2 opozice + 4 kvadráty |
| jod | sextil + 2 kvinkunxy (150°, orb 2°) k vrcholu |
| drak | velký trigon + planeta v opozici k jednomu rohu a v sextilu ke dvěma zbylým |
| kolébka | opozice + 3 sextily + 2 trigony |
| mystický obdélník | 2 opozice + 2 sextily + 2 trigony |

- Kvinkunx se počítá jen pro jod a v tabulce aspektů se neukazuje.
- Konjunkce v rohu: obrazec se najde dvakrát a sloučí se do jednoho, který vypíše
  obě planety (u T-kvadrátu a jodu případně dva vrcholy, každý se svým textem).
- Velký kříž pohltí své čtyři T-kvadráty. Velký trigon uvnitř draka zůstává.
- Živel velkého trigonu a draka, kvalita T-kvadrátu a kříže: většina znamení planet
  obrazce (u obrazce přes hranici znamení), při remíze znamení vrcholu nebo první planety.
- Stellium se tu nehledá, pokrývá ho `emphasis/…`.

Rovnováhy (prahy zvolené tak, aby se každá objevila asi u pětiny horoskopů):

| Rovnováha | Pravidlo | Výskyt (6000 horoskopů 1900–2000) |
|---|---|---|
| přemíra kvality | 6 a více z 10 planet | 21 % |
| nedostatek kvality | nejvýš 1 planeta | 28 % |
| důraz na polokouli | 9 a více z 10 planet | 19 % |
| planeta bez aspektu | žádný hlavní aspekt k jiné planetě (kvinkunx se nepočítá) | 36 % |

Polokoule se určují podle úhlů, ne podle systému domů: nad obzorem leží úsek od
descendentu přes MC k ascendentu, východní polokoule od MC přes ascendent k IC.
Bez času narození se polokoule nepočítají.

## Synastrie (`Synastry.compute`, plán 10.4)

- **Aspekty mezi horoskopy:** každá planeta první osoby proti planetám, ASC a MC
  druhé a planety druhé proti ASC a MC první. Osa proti ose se nepočítá, uzel
  také ne. Orby natální (oddíl Orby): Slunce a Měsíc +2°, ASC a MC 3°.
  `applying` mezi dvěma natálními horoskopy nemá smysl a je vždy false.
- **Domy:** planety první osoby v domech druhé a naopak; jen u hostitele, který
  má čas narození (a domy definované pro svou šířku).
- **Klíče:** dvojice planet jsou neuspořádané (Slunce A–Měsíc B i Měsíc A–Slunce B
  vedou na `synastry/sun/moon/…`), aspekt se skládá do tří druhů jako u os
  (konjunkce, harmonický, napěťový). Výklad ukáže každý text jednou se všemi
  fakty, které na něj vedou.
- **Váha** pro pořadí ve výkladu: aspekty jako natální (průměr váhy bodů ×
  těsnost), dům = váha planety × 0,8 v rohových domech (1, 4, 7, 10), jinak × 0,6.
- **Dvojčata:** všech deset planet blíž než 1° (`twinsMaxPlanetDiff`). Místo
  deseti konjunkcí téže planety appka ukáže rozdíl času narození, ASC, MC,
  rozpětí hrotů domů a planety, které mění dům. Bez času narození jen poznámku.
  Měsíc se pohne o 1° asi za dvě hodiny, takže pravidlo chytí jen skutečná
  dvojčata nebo lidi narozené v týž den blízko sebe.
- **Vrstva `partner`** (přitažlivost, intimita) se zobrazí jen u typu vztahu
  partner (`Relationship.showsPartnerLayer`). Validátor hlídá, že je jen ve
  skupinách `synastry*` a že základní vrstvy (titul, hesla, `text`, `shadow`,
  `hard`) neobsahují milostná a sexuální slova, protože se ukazují i rodiči
  a dítěti. Test appky ověřuje, že se dovětek u ostatních typů nikdy nevykreslí.

## Tranzity (`TransitEngine`)

Hledání: polohy tranzitující planety se spočítají po krocích (Měsíc 1 h; Slunce,
Merkur, Venuše 12 h; Mars 1 den; ostatní 2 dny) a mezi nimi se interpolují
(`LongitudeTrack`, Lagrange 4. řádu). Vstup do orbu a výstup z něj se dohledá
bisekcí na minutu, přesný okamžik na sekundu. Hledá se i před a za zvoleným
obdobím (pomalé planety 400 dní), aby šlo říct, kdy dlouhý tranzit začal.

- **Pobyt v orbu** = jedna událost. Když se planeta v orbu otočí, má událost víc
  přesných okamžiků a zastávku (`station`).
- **Průchody**: přesné okamžiky téže konfigurace bližší než mezera série (Měsíc 2,
  Slunce 30, Merkur a Venuše 90, Mars 150, Jupiter 200, ostatní 300 dní) tvoří
  sérii a číslují se 1., 2., 3. `passTotal` je null, když série sahá za spočítaný
  rozsah.
- **Fáze**: přesný, dokud je odchylka do 0,2° (u Měsíce asi ±20 min, u Saturnu
  asi ±2 dny); před nejbližším přesným okamžikem blíží se, po něm odeznívá.

### Síla 0–100 (`strengthAt`)

| Složka | Body |
|---|---|
| těsnost: 35 × (1 − odchylka / orb) | 0–35 |
| pomalost tranzitující planety | Pluto 25, Neptun 23, Uran 21, Saturn 18, Jupiter 14, Mars 10, Slunce 7, Venuše 6, Merkur 5, Měsíc 2 |
| cíl je Slunce, Měsíc, ASC nebo MC | +15 |
| konjunkce, kvadrát, opozice | +5 |
| zastávka do 10 dní | +10 |
| další tranzit (mimo Měsíc) na týž bod ve stejnou chvíli | +5 za každý, nejvýš +10 |

Akutní = síla ≥ 70.

### Napětí dne (`tensionAt`, `tensionSeries`)

Součet za konjunkce, kvadráty a opozice tranzitujících planet (bez Měsíce) v orbu
v poledne UT: 35 × těsnost + pomalost + 15 u osobního bodu. Pro percentil dne
přes celý život se počítá pro každý den; stopy s hrubším krokem (Slunce 4,
Merkur 2, Venuše 4, Mars 8, ostatní 8–10 dní) dávají proti přímému výpočtu
odchylku do 6 bodů. 80 let trvá na Macu asi 7 s, v appce běží v isolate a výsledek
se ukládá.

Verze vzorce: `tensionFormulaVersion` v `packages/astro_core/lib/src/version.dart`
(teď 1). Při každé změně vzorce ji zvyš; deník předpovědí pak napětí starších
záznamů pro vyhodnocení přepočítá.

## Měsíc a planetární hodiny (R2)

Bez bodů: denní osa jen ukazuje. Pravidla jsou v `docs/ephemeris.md` (oddíl
Slunce a Měsíc). Texty: `planetary_hour/{planeta}`, `planetary_day/{planeta}`
(sedm tradičních planet), `moon_phase/{fáze}`, `natal_moon_phase/{fáze}`,
`moon_today/{znamení}`, `lunation_in_house/{new, full}/{dům}`, `void_of_course`,
`eclipse/{solar, lunar}`. Fáze při narození je ve výkladu faktor `moonPhase`
s vahou 0,6 (oddíl „Přemíra a nedostatek“).

## Elekce — Najdi termín (R7)

Pravidla jsou data v `content/rules/election.json`; kód (`ElectionSearch`,
`electionPredicates` v `packages/astro_core/lib/src/election.dart`) jen vyhodnocuje
podmínku `when` s parametry `params`. Schéma hlídá `tools/content` (`validateElectionRules`).

**Vzorec.** Skóre okna = součet vah pravidel „plus“ − součet vah pravidel „minus“,
která v okně platí. Pravidlo „exclude“ okno vyřadí bez ohledu na skóre; jediné je
Měsíc bez aspektu. Pásma (`thresholds`): 8 a víc `strong`, 4–7 `good`, 1–3 `weak`.
Okno pod 1 neprojde. Když neprojde žádné, vrátí se jedno nejméně špatné
s verdiktem `none`.

| Pravidlo | Druh | Váha | Podmínka |
|---|---|---|---|
| `moon_void` | exclude | – | Měsíc bez aspektu zasahuje do vzorku (jako R2, `Lunar.voidOfCourse`) |
| `moon_waxing` | plus | 2 | elongace Měsíce od Slunce pod 180° |
| `moon_next_venus` | plus | 3 | příští aspekt Měsíce ve znamení míří na Venuši |
| `moon_next_jupiter` | plus | 3 | příští aspekt Měsíce míří na Jupiter |
| `venus_angle` | plus | 2 | Venuše do 5° od ASC, DSC, MC nebo IC |
| `jupiter_angle` | plus | 2 | Jupiter do 5° od osy |
| `asc_ruler_dignified` | plus | 3 | tradiční vládce ASC v sídle nebo povýšení a přímý |
| `hour_of_intent` | plus | 2 | planetární hodina planety záměru |
| `intent_planet_dignified` | plus | 2 | planeta záměru v sídle nebo povýšení |
| `benefic_in_intent_house` | plus | 1 | Venuše nebo Jupiter v domě záměru |
| `personal_moon_harmonious` | plus | 2 | osobní: Měsíc v konjunkci, sextilu nebo trigonu s natálním Sluncem, Měsícem, ASC (orb 3°) |
| `personal_calm_day` | plus | 1 | osobní: napětí dne 0 |
| `moon_next_mars_hard` | minus | 3 | příští aspekt Měsíce je kvadrát nebo opozice na Mars |
| `moon_next_saturn_hard` | minus | 3 | totéž na Saturn |
| `mars_angle` | minus | 2 | Mars do 5° od osy |
| `saturn_angle` | minus | 2 | Saturn do 5° od osy |
| `intent_planet_retrograde` | minus | 2 | některá planeta záměru retrográdní |
| `intent_planet_fall` | minus | 2 | v pádu |
| `intent_planet_detriment` | minus | 2 | ve zničení |
| `asc_ruler_bad_house` | minus | 2 | vládce ASC v 6., 8. nebo 12. domě |
| `asc_ruler_retrograde` | minus | 1 | vládce ASC retrográdní |
| `eclipse` | minus | 3 | místní den zatmění, den před ním a po něm |
| `via_combusta` | minus | 2 | Měsíc mezi 15° Vah a 15° Štíra (195°–225°) |
| `malefic_in_intent_house` | minus | 1 | Mars nebo Saturn v domě záměru |
| `personal_moon_tense` | minus | 2 | osobní: Měsíc v kvadrátu nebo opozici k natálnímu Slunci, Měsíci, ASC (orb 3°) |
| `personal_tension_high` | minus | 2 | osobní: napětí dne (`tensionSeries`, poledne místního dne) 60 a víc |

Záměry (`ElectionIntent`): domy a planety z tabulky plánu 10.7. Planeta záměru
se počítá, když podmínku splní aspoň jedna z planet záměru. Zdravotní záměry se
nehledají (rozhodnutí 19), appka ukáže heslo `glossary/medical_election`.

**Hledání.** Období od místní půlnoci prvního dne, nejvýš 90 dní, vzorek po
10 minutách. Měsíc se počítá po hodině, ostatní planety po 12 hodinách
(stejné stopy jako `Lunar.voidOfCourse`, proto stejné okamžiky bez aspektu)
a interpolují se (`LongitudeTrack`). ASC, MC a domy (systém podle šířky místa
pobytu, v polárních šířkách Porphyry) se počítají pro každý vzorek. Planetární
hodiny z jednoho průchodu východy a západy (`planetaryHourSpans`, shoda
s `PlanetaryHours.hourAt`). Sousední vzorky se stejnou sadou splněných
pravidel tvoří okno. Omezení na hodiny a dny v týdnu (místní čas) vzorky
vyřadí. Řazení: skóre, pak délka, pak dřívější začátek; nejvýš 10 oken
a nejvýš 3 začínající v jednom dni. 90 dní s profilem trvá asi 0,6 s
(test `election_test.dart`), v appce běží v isolate.

**Pro horární část (R8)** jsou znovupoužitelné: `RuleBook`, `Rule`,
`evaluateRules` (`rules.dart`), `MoonAspectTimeline.nextAspect/lastAspect`
(`moon_aspects.dart`), `isDignified`, `isDebilitated` (`dignities.dart`).

## Progrese a solár (R5, plán 10.5)

Zvolená metoda (`Progression`, `SolarReturn` v `progressions.dart`):

- **Sekundární progrese:** jeden den po narození = jeden rok života, rok je
  střední tropický rok 365,242189 dne. Progresní okamžik = narození (UT) +
  věk v letech jako počet dní.
- **Osy:** progresní MC = natální MC + sluneční oblouk (progresní − natální délka
  Slunce). ASC se z něj dopočítá: RAMC = rektascenze progresního MC, z ní
  ascendent pro zeměpisnou šířku narození a sklon ekliptiky progresního okamžiku
  (stejný systém domů jako natál). Bez času narození se osy nepočítají.
- **Domy progresního Měsíce:** natální domy.
- **Progresní aspekty:** jen Slunce, Měsíc, Merkur, Venuše a Mars (Jupiter–Pluto se
  za život posunou o pár stupňů a jejich natální aspekty jen trvají), hlavní aspekty
  k natálním planetám, ASC a MC, orb 1°. Planeta ke své vlastní natální poloze jen
  u Měsíce (progresní návrat Měsíce kolem 27 let). Sbíhavost podle rychlosti
  progresní planety. Text: `transit/…` nebo `transit_point/…` stejné dvojice
  s úvodní větou `progressed/modifier/{applying, separating}`.
- **Progresní fáze Měsíce:** elongace progresního Měsíce od progresního Slunce,
  osm 45° výsečí jako u fází Měsíce (R2); celý cyklus trvá asi 29,5 roku.
- **Časová osa života:** vstupy progresního Měsíce do znamení a natálních domů,
  progresního Slunce do znamení a změny progresní fáze; krok 0,1 progresního dne
  a půlení. K tomu soláry na každé narozeniny, 100 let.
- **Solár:** okamžik, kdy zdánlivá délka Slunce (tropická, k datu, bez sidereální
  korekce) dosáhne natální délky; Newtonovy kroky a pak půlení pod 0,5 s. Horoskop
  pro místo pobytu, přepínač na místo narození (rozhodnutí 17); systém domů jako
  u profilu, jinak výchozí podle šířky místa. Rok soláru = rok narození + věk
  (narozeniny 1. 1. se mohou vrátit 31. 12. UT předchozího roku).
- **Texty soláru:** `solar_return/asc/{znamení}`, `solar_return/sun_in_house/{dům}`
  (domy soláru) a `solar_return/planet_on_angle/{planeta}/{asc, ic, dsc, mc}`
  pro planetu do 5° od osy soláru.
## Deník předpovědí (`package:astro_core/journal.dart`, plán 10.3)

Metodika převzatá z projektu heliograf: hypotéza zapsaná předem, srovnání se
základním odhadem, záznam bez přepisování. Výsledek se uvádí větou a velikostí
efektu, nikdy slovem „důkaz“; „žádná souvislost“ se ukazuje stejně výrazně.

### Záznam

- Hodnocení dne −2 až +2, volitelně štítky ze slovníku rysů a poznámka.
- Uloží se hodnocení, napětí dne (`tensionAt` v místním poledni, převedeném na UT),
  verze enginu (`engineVersion`) a verze vzorce. Tranzity se neukládají.
- Den (místní kalendářní datum) jde hodnotit od svého začátku do konce
  následujícího dne. Novější záznam téhož dne v tom okně platí místo staršího,
  starší v logu zůstává. Pak je den uzavřený a jde k němu jen **oprava**: nový
  záznam s odkazem na poslední původní. Vyhodnocuje se vždy původní hodnocení;
  oprava může být ovlivněná zpětným pohledem.
- Obecný log (`AppendOnlyLog` + `ClosePolicy`) nese i horární otázky (R8).
- Úložiště: jeden šifrovaný soubor na profil (AES-GCM, klíč v klíčence), dokument
  se `schema`. Soubor s novějším schématem appka odmítne a nepřepíše; chybějící
  pole starších záznamů dostanou „neznámá verze“ a napětí se přepočítá.

### Slepý test

Dobrovolný, 90 dní (rozhodnutí 16: výchozí vypnuto). Záložka Tranzity je zamčená,
dokud není ohodnocený dnešek. Hodnocení je slepé, když test běží a pohled byl
ještě zamčený (hodnotí se dnešek, nebo včerejšek před dneškem). Ostatní nesou
příznak „předpověď byla vidět“. Obě skupiny se vyhodnocují zvlášť, každá s vlastním
prahem 60 dní.

### Vyhodnocení (od 60 ohodnocených dní)

1. **Pořadová korelace** (Spearmanovo ρ, shody průměrným pořadím) mezi napětím
   a hodnocením. Tradice čeká záporné ρ: vyšší napětí, horší den.
2. **Test proti náhodě**: hodnocení se rozdělí do bloků po 7 kalendářních dnech
   od prvního ohodnoceného dne. Bloky se 10 000× náhodně přeházejí (uvnitř bloku
   zůstává pořadí) a položí zpět na ohodnocené dny v pořadí; napětí zůstává.
   p = podíl přeházení, kde ρ vyjde stejně nebo víc záporné než pozorované (bez
   korekce +1). Souvislost „napjaté dny hůř“ platí při p ≤ 0,05; obrácená
   („napjaté dny líp“) při p ≤ 0,05 pro opačný směr; jinak „souvislost se
   neukázala“. Týdny místo dnů: pomalé tranzity i nálada drží několik dní, přeházení
   po dnech by shodu nadhodnotilo.
3. **Velikost efektu**: |ρ| pod 0,1 zanedbatelný, pod 0,3 malý, pod 0,5 střední,
   jinak velký.
4. **Kontrola cizím horoskopem**: 20 náhodných osob z katalogu (bez profilu
   samého), stejné dny, napětí jejich tranzitů. Počítá se, kolik cizích horoskopů
   dá ρ stejné nebo zápornější než vlastní. Vlastní sedí líp, když je to nejvýš 5 %
   z nich (u 20 osob nejvýš jedna). Pod 5 osobami se kontrola nedělá a appka to
   řekne; pod 20 uvede, kolik jich je.
5. **Vlastní hypotézy** („tranzit X aspekt natální Y → štítek Z“): jen dny po dni
   zápisu. Tranzit platí pro den, když je v orbu kdykoli během místního dne
   (poledne ± 12 h). Výsledek: podíl dní se štítkem při tranzitu proti podílu bez
   tranzitu (základní odhad) a jednostranný Fisherův exaktní test; potřeba aspoň
   5 dní s tranzitem i bez něj.

Náhodu řídí seed odvozený z id hodnocených záznamů, takže tentýž deník dá vždy
tatáž čísla; testy seed zadávají přímo. Výpočet běží v isolate.

Testy (`packages/astro_core/test/journal_test.dart`): syntetický deník s náhodným
hodnocením nevyjde jako souvislost (20 seedů, nejvýš 3 falešné poplachy, a pevný
seed vyjde „žádná souvislost“); deník odvozený ze skóre vyjde jako souvislost
s p < 0,01 a líp než šest cizích horoskopů.
