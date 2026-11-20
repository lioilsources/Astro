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
