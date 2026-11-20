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
