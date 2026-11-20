# Výpočet poloh a domů

## Polohy

Všechny polohy jsou zdánlivé geocentrické ekliptikální souřadnice k datu
(tropický zvěrokruh), stejně jako ve starém Astromatu.

| Těleso | Zdroj |
|---|---|
| Slunce, Merkur–Neptun | VSOP87B (J2000) z balíčku `astronomia` 1.1.1, vlastní řetězec: světelný čas, precese na datum, aberace, nutace |
| Měsíc | Meeus, kap. 47 (`astronomia`), + nutace v délce |
| Pluto | tabulka z JPL DE440 (`lib/src/pluto_table.dart`), 1550–2200, krok 30 dní, kubická interpolace; mimo ni řada Meeus kap. 37 (1885–2099); jinak se Pluto nepočítá |
| Střední uzel | Meeus (`moon.node`) |
| Pravý uzel | oskulační uzel z polohy a rychlosti Měsíce |

DE440 začíná koncem roku 1549, proto tabulka Pluta nesahá do roku 1300, jak
počítal plán. Pro starší data je Pluto v horoskopu vynechané (`Chart.missing`).

Denní změna = rozdíl poloh ±6 h, převedený na den; záporná = retrográdní.

## Čas

- Místní čas → UT přes IANA tzdb (balíček `timezone`), včetně historického
  letního času.
- Před zavedením pásmového času tzdb vrací střední čas města (LMT, v Praze PMT).
  Ten se pozná podle posunu, který není násobkem 15 minut, a nahradí se místním
  středním časem **místa narození**: `UT = čas − délka/15 h`.
- Juliánský kalendář: u dat před 15. 10. 1582 výchozí, jinak přepínač. Juliánské
  datum se vždy počítá v místním středním čase.
- Čas, který při změně letního času neexistuje nebo nastane dvakrát, nese
  příznak `dstAmbiguous`; appka se má zeptat.
- ΔT: polynomy Espenak & Meeus (NASA 2006), úsek 2005–2030 nahrazený přímkou
  podle naměřených hodnot. Proti modelu skyfield do 1,5 s pro 1955–2030,
  do 5 s pro 1800–1955.

## Domy

`housesFromRamc(system, ramc, šířka, sklon)` nezávisí na čase, takže jde testovat
proti Swiss Ephemeris se stejnými vstupy.

| Systém | Postup |
|---|---|
| Placidus | iterace trojdělení polodenního oblouku (60 kroků) |
| Koch | ascendenty pro posunuté RAMC podle polodenního oblouku MC |
| Regiomontanus | ascendenty pro póly `atan(tan φ · sin 30°/60°)` |
| Campanus | ascendenty pro póly `asin(sin φ · sin 30°/60°)` |
| Porphyry | trojdělení obou kvadrantů na ekliptice |
| Equal, Whole sign | od ascendentu, resp. od začátku jeho znamení |
| Meridian | `λ = atan2(sin α, cos α · cos ε)`, α = RAMC + (n − 10) · 30° |
| Morinus | `λ = atan2(sin α · cos ε, cos α)`, totéž α |

Za polárním kruhem (|φ| ≥ 90° − ε) Placidus a Koch nejsou definované
(`HouseResult.cusps == null`). Ascendent i mezilehlé hroty se drží do 180° za MC
(konvence Swiss Ephemeris). Regiomontanus a Campanus tam Swiss Ephemeris
počítá s prohozeným MC a IC; tady MC zůstává nahoře. Výchozí systém je tam
Porphyry, viz `defaultHouseSystem`.

## Stálice (R6)

32 hvězd z plánu 10.6 (rozhodnutí 18), tabulka `lib/src/star_catalog.dart`.
Soubor je generovaný skriptem `tools/golden/gen_stars.py`, ručně se needituje.

- **Zdroj:** Hipparcos Main Catalogue (ESA 1997, ESA SP-1200; CDS I/239),
  staženo z VizieR. Praesepe je hvězdokupa, ne hvězda: střed a střední vlastní
  pohyb jsou z Cantat-Gaudin et al. 2018, A&A 618, A93 (CDS J/A+A/618/A93,
  NGC 2632).
- **Licence:** CDS/VizieR data volně šíří s podmínkou citace zdroje (licence
  VizieR, `rights_uri` v hlavičce odpovědi). Appka nese jen 32 řádků čísel
  a citaci výše.
- **Uložené hodnoty:** RA a Dec pro J2000.0 (ICRS), lineárně posunuté z epochy
  katalogu (Hipparcos J1991.25, Gaia DR2 J2015.5), vlastní pohyb μα·cos δ a μδ
  v mas/rok, jasnost V.
- **Výpočet k datu:** vlastní pohyb lineárně + precese Meeus kap. 21
  (`astronomia` `precess.position`), převod na ekliptiku se středním sklonem
  k datu, roční aberace (Meeus 23.2) a nutace v délce. Paralaxa (pod 0,4″)
  a gravitační ohyb se zanedbávají.
- **Konjunkce:** jen podle ekliptikální délky, orb 1° (`starOrb`), s planetami
  Slunce až Pluto, s ASC a MC (`findStarContacts`, `Chart.starContacts`).
  Šířka hvězdy se nebere v úvahu, takže Sírius, Vega nebo Algol se počítají
  stejně jako hvězdy u ekliptiky. Uzly, parany, tranzity na hvězdy a hvězdy
  v synastrii se nepočítají.
- **Obsah:** `star/{hvězda}` (32) a `star_target/{bod}` (12). Ve výkladu je jeden
  faktor na hvězdu podle nejtěsnějšího dotyku.

Přegenerování (potřebuje `data/de440.bsp`; složku dat lze přesměrovat proměnnou
`GOLDEN_DATA`):

```
tools/golden/.venv/bin/python tools/golden/gen_stars.py
```

## Ověření

`tools/golden/gen_golden.py` (skyfield + DE440, pyswisseph) zapíše
`packages/astro_core/test/golden/*.json` a tabulku Pluta. Testy:

| Co | Proti | Tolerance |
|---|---|---|
| 10 planet, 42 dat 1600–2150 | DE440 | 1′ v délce i šířce |
| střední a pravý uzel | Swiss Ephemeris | 1′ |
| hvězdný čas, sklon ekliptiky | Swiss Ephemeris | 3″, 1″ |
| 9 systémů domů, 8 šířek × 7 RAMC | Swiss Ephemeris | 1′ |
| 32 stálic, roky 1800, 1900, 2000, 2050 (`gen_stars.py`) | skyfield + DE440 + katalog | 5″ (pět hvězd 1800 a 2000: 2″); skutečně do 0,9″ |

Proti Astromatu (1. 1. 2000 12:00 UT, Praha): planety do 1,6′, domy do 0,6′,
Pluto 4,5′. DE440 ukázalo, že se mýlí Astromat, ne tento engine.
