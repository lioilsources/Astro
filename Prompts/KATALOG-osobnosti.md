# KATALOG osobností — zadání a výchozí seznam

Příloha k `PLAN-astro-app.md` (oddíl 4.3). Stav: návrh, 2026-11-19.

## 1. Účel

Katalog známých lidí s datem, časem a místem narození, aby šel jejich horoskop
otevřít jedním ťuknutím a ptát se na události z jejich života („co se dělo na
nebi v den bitvy u Waterloo“).

## 2. Záznam

`content/people/<id>.json`:

```json
{"id": "napoleon-bonaparte", "name": "Napoleon Bonaparte",
 "categories": ["history", "politics", "military"], "living": false,
 "wikidata": "Q517",
 "birth": {"date": "1769-08-15", "calendar": "gregorian", "time": "11:30",
           "time_basis": "lmt", "place": "Ajaccio", "lat": 41.92, "lon": 8.74},
 "reliability": "A",
 "source": {"note": "…", "url": "…"},
 "events": [{"date": "1815-06-18", "label": "bitva u Waterloo", "source": "…"}]}
```

Spolehlivost času podle Roddenové stupnice:

| Stupeň | Význam | V appce |
|---|---|---|
| AA | rodný list nebo matrika | „potvrzeno“ |
| A | z paměti osoby, rodiny, oficiální oznámení | „potvrzeno“ |
| B | životopis | s upozorněním |
| C | nejistý, bez původu | s výrazným upozorněním |
| DD | protichůdné údaje | nezařazovat |
| X | jen datum, čas neznámý | horoskop bez domů |

Bez ověřeného zdroje se záznam do `content/people/` nedostane.

## 3. Zdroje

| Zdroj | Co dává | Omezení |
|---|---|---|
| Zveřejněné rodné listy, matriky, oficiální oznámení | čas stupně AA nebo A | ruční dohledání po jednom |
| Open Gauquelin Database (opengauquelin.org) | 25 872 osob, z toho 24 542 s časem; narození 1572–1959; 25 zemí; 4 384 sportovců | licence Creative Commons (přesnou verzi ověřit na stránce About); sami většinu časů hodnotí „k ověření“ → brát jako stupeň B; žádné současné osobnosti |
| Astro-Databank (astro.com) | největší sbírka s Roddenovým hodnocením, i současníci | blokuje automatický přístup; výslovná licence k datům nenalezena; hromadné převzetí naráží na právo pořizovatele databáze → jen ruční nahlédnutí k jednotlivým záznamům, nebo písemné svolení Astrodienstu |
| Wikidata (CC0) | data narození a úmrtí, místa, souřadnice, události | časy narození neobsahuje |

Česká specifika: český rodný list čas narození neuvádí, takže u českých osobností
bývá veřejně doložený čas vzácný. Počítej s tím, že velká část vyjde jako X.

Země, kde rodný list nebo matrika čas uvádí (snáz dohledatelné): Francie, Itálie,
Německo, Rakousko, Švýcarsko, Belgie, Nizozemsko, Skotsko, většina států USA,
Brazílie, Argentina. Anglie a Wales čas neuvádějí.

## 4. Postup sestavení (`tools/people/`)

1. Výchozí seznam jmen podle kategorií (oddíl 5) → doplnit z Wikidat datum, místo,
   souřadnice, identifikátor a události.
2. Spárovat s Open Gauquelin Database (jméno + datum).
3. Fronta k ručnímu ověření: ke každému času dohledat zdroj a stupeň.
4. Validátor: schéma, existence zdroje, kalendář (juliánský před zavedením
   gregoriánského v dané zemi), časová základna (místní střední čas před zavedením
   pásmového).
5. Cíl první verze: 150–300 osob, v každé kategorii aspoň 15.

## 5. Výchozí seznam kandidátů

**Časy v tabulkách jsou z paměti jazykového modelu a nejsou ověřené.** Slouží jen
jako vodítko, co hledat. Data narození jsou spolehlivější, i ta ale ověřit.
Otazník znamená, že čas neznám.

### Historie

| Jméno | Narození | Čas (neověřeno) | Údajný původ času |
|---|---|---|---|
| Napoleon Bonaparte | 15. 8. 1769, Ajaccio | 11:30 | rodinná tradice |
| Johann Wolfgang Goethe | 28. 8. 1749, Frankfurt | 12:00 | vlastní životopis |
| Wolfgang Amadeus Mozart | 27. 1. 1756, Salzburg | 20:00 | otcův dopis |
| Isaac Newton | 25. 12. 1642 (jul.), Woolsthorpe | krátce po půlnoci | tradice |
| Karel IV. | 14. 5. 1316 (jul.), Praha | ? | kroniky |
| T. G. Masaryk | 7. 3. 1850, Hodonín | ? | |
| Sigmund Freud | 6. 5. 1856, Příbor | 18:30 | rodinný záznam |
| Carl Gustav Jung | 26. 7. 1875, Kesswil | kolem 19:30 | více verzí |
| Albert Einstein | 14. 3. 1879, Ulm | 11:30 | rodný list |
| Mahátma Gándhí | 2. 10. 1869, Porbandar | ? | sporné |
| Winston Churchill | 30. 11. 1874, Blenheim | 1:30 | otcův dopis |
| Adolf Hitler | 20. 4. 1889, Braunau | 18:30 | matrika |
| John F. Kennedy | 29. 5. 1917, Brookline | 15:00 | matka |
| Alžběta II. | 21. 4. 1926, Londýn | 2:40 | oficiální oznámení |
| Václav Havel | 5. 10. 1936, Praha | ? | |

### Politici současnosti

| Jméno | Narození | Čas (neověřeno) | Údajný původ času |
|---|---|---|---|
| Barack Obama | 4. 8. 1961, Honolulu | 19:24 | zveřejněný rodný list |
| Donald Trump | 14. 6. 1946, New York | 10:54 | zveřejněný rodný list |
| Joe Biden | 20. 11. 1942, Scranton | 8:30 | ? |
| Emmanuel Macron | 21. 12. 1977, Amiens | 10:40 | rodný list |
| Angela Merkelová | 17. 7. 1954, Hamburk | 18:00 | ? |
| Karel III. | 14. 11. 1948, Londýn | 21:14 | oficiální oznámení |
| Vladimir Putin | 7. 10. 1952, Leningrad | 9:30 | sporné |
| Volodymyr Zelenskyj | 25. 1. 1978, Kryvyj Rih | ? | |
| Petr Pavel | 1. 11. 1961, Planá | ? | |

### Herci a celebrity

| Jméno | Narození | Čas (neověřeno) | Údajný původ času |
|---|---|---|---|
| Marilyn Monroe | 1. 6. 1926, Los Angeles | 9:30 | rodný list |
| Audrey Hepburnová | 4. 5. 1929, Brusel | 3:00 | rodný list |
| Elvis Presley | 8. 1. 1935, Tupelo | 4:35 | rodný list |
| John Lennon | 9. 10. 1940, Liverpool | 18:30 | rodina |
| Arnold Schwarzenegger | 30. 7. 1947, Thal | 4:10 | rodný list |
| Steve Jobs | 24. 2. 1955, San Francisco | 19:15 | rodný list |
| Madonna | 16. 8. 1958, Bay City | 7:05 | rodný list |
| princezna Diana | 1. 7. 1961, Sandringham | 19:45 | matka |
| Brad Pitt | 18. 12. 1963, Shawnee | 6:31 | rodný list |
| Leonardo DiCaprio | 11. 11. 1974, Los Angeles | 2:47 | rodný list |
| Angelina Jolie | 4. 6. 1975, Los Angeles | 9:09 | rodný list |
| Taylor Swift | 13. 12. 1989, West Reading | ? | sporné |
| Miloš Forman | 18. 2. 1932, Čáslav | ? | |
| Karel Gott | 14. 7. 1939, Plzeň | ? | |

### Fotbalisté

| Jméno | Narození | Čas (neověřeno) | Údajný původ času |
|---|---|---|---|
| Pelé | 23. 10. 1940, Três Corações | 3:00 | ? |
| Diego Maradona | 30. 10. 1960, Lanús | 7:05 | rodný list |
| Zinédine Zidane | 23. 6. 1972, Marseille | 3:00 | rodný list |
| David Beckham | 2. 5. 1975, Londýn | 6:17 | životopis |
| Cristiano Ronaldo | 5. 2. 1985, Funchal | 5:25 | ověřit, existuje víc verzí |
| Lionel Messi | 24. 6. 1987, Rosario | 6:05 | rodný list |
| Kylian Mbappé | 20. 12. 1998, Paříž | ? | francouzský rodný list čas uvádí |
| Josef Masopust | 9. 2. 1931, Střimice | ? | |
| Pavel Nedvěd | 30. 8. 1972, Cheb | ? | |

### Hokejisté

U hokejistů si žádný doložený čas nevybavuji; všechny je třeba dohledat.

| Jméno | Narození |
|---|---|
| Wayne Gretzky | 26. 1. 1961, Brantford |
| Mario Lemieux | 5. 10. 1965, Montréal |
| Dominik Hašek | 29. 1. 1965, Pardubice |
| Jaromír Jágr | 15. 2. 1972, Kladno |
| Alexandr Ovečkin | 17. 9. 1985, Moskva |

### Ostatní sportovci

| Jméno | Narození | Čas (neověřeno) | Údajný původ času |
|---|---|---|---|
| Emil Zátopek | 19. 9. 1922, Kopřivnice | ? | |
| Muhammad Ali | 17. 1. 1942, Louisville | 18:35 | rodný list |
| Martina Navrátilová | 18. 10. 1956, Praha | 16:40 | ověřit |
| Michael Jordan | 17. 2. 1963, New York | 13:40 | rodný list |
| Michael Schumacher | 3. 1. 1969, Hürth | 13:43 | rodný list |
| Tiger Woods | 30. 12. 1975, Cypress | 22:50 | rodný list |
| Roger Federer | 8. 8. 1981, Basilej | 8:40 | ? |
| Serena Williamsová | 26. 9. 1981, Saginaw | 20:28 | ? |
| Usain Bolt | 21. 8. 1986, Sherwood Content | ? | |
| Novak Djoković | 22. 5. 1987, Bělehrad | 23:25 | ověřit |
| Ester Ledecká | 23. 3. 1995, Praha | ? | |

## 6. Události, kterými jsou osobnosti známé, a ověření tranzity

Zadání vlastníka: ke každé osobnosti seznam událostí s daty, kvůli kterým je známá,
s odkazem na tranzitní horoskop toho dne, aby šlo ověřit, jak planety stály a jestli
popisy odpovídají tomu, co víme z historie.

### Schéma události

```json
{"date": "1815-06-18", "label": "porážka u Waterloo", "type": "battle", "defining": true,
 "source": "Wikipedia: Napoleon", "url": "https://en.wikipedia.org/wiki/Napoleon",
 "quote": "… on 18 June 1815 …", "date_julian": null}
```

| Pole | Význam |
|---|---|
| `date` | den události, vždy na den přesně, v gregoriánském kalendáři |
| `date_julian` | datum tak, jak ho píše pramen v juliánském kalendáři (před reformou); jinak chybí |
| `label` | krátký český popis |
| `type` | druh: office, election, coronation, abdication, award, title, record, work, premiere, publication, discovery, breakthrough, battle, treaty, founding, scandal, arrest, trial, assassination_attempt, assassination, resignation, event, marriage, club, death, other |
| `defining` | `true` = událost, kvůli které je osobnost známá (zvolení, premiéra, titul, objev, abdikace, atentát…); `false` = běžná životní událost (sňatek, klub, úmrtí) |
| `source` | `Wikidata <QID> <vlastnost> [<QID hodnoty>]` nebo `Wikipedia: <název článku>` |
| `url` | odkaz na výrok ve Wikidatech nebo na článek |
| `quote` | u Wikipedie věta z článku, která datum uvádí |

Starší záznamy bez `type` a `defining` zůstávají platné; appka je čte jako běžné
události, kromě úřadů, ocenění a děl.

### Postup (`tools/people/`)

1. `build_people.py` bere z Wikidat (CC0) s přesností na den: nástup do funkce (P39 +
   P580), ocenění (P166 + P585), významná díla s datem vydání nebo premiéry (P800 →
   P577/P1191), významné události (P793), vyhrané soutěže (P2522, P1344 s umístěním 1;
   datum finále). To jsou zlomové události. Sňatky (P26), kluby (P54) a úmrtí (P570) jsou
   běžné. Nominace (P1411) se neberou.
2. `wiki_sentences.py` stáhne anglické články Wikipedie (TextExtracts, postupně, s
   pauzou, cache v `run/people-cache/wiki/`) a vypíše věty s datem na den přesně do
   `run/people-events/<id>.txt`.
   S `--cs` stáhne české články lidí, kterým zatím chybí dvě zlomové události, do
   `run/people-events/cs-<id>.txt` (data ve tvaru „16. ledna 1969“).
3. Z těch vět se ručně vyberou hlavní události do `tools/people/defining.json`
   (klíč je anglický název článku; datum, jak ho věta píše, český popis, druh, doslovná
   věta; u české Wikipedie navíc `"lang": "cs"` a `"article"`). Data se nikdy nedoplňují
   z paměti. `check_defining.py` výběr ověří proti cache.
4. Builder ověří, že věta v článku doslova je a že datum v ní napsané odpovídá; data
   před 15. 10. 1582 převede z juliánského kalendáře (jinak `"calendar"` u položky).
5. Validátor (`tools/content/lib/people.dart`): skutečný den, ne před narozením, zdroj,
   odkaz u zlomových, u Wikipedie věta s datem; test hlídá aspoň dvě zlomové události
   na osobnost.

### V appce

- Detail osobnosti: nejdřív zlomové události, pak ostatní, obojí chronologicky.
- „Tranzity v den události“: postavení planet toho dne, aktivní tranzity k horoskopu
  narození s orby a texty (`transit/…`, `transit_point/…`, `transit_in_house/…` jen
  tam, kde jsou domy). Hodina události není známá: počítá se poledne v časovém pásmu
  místa narození (u starých dat místní střední čas). U stupně X bez domů a os.
- Poctivá kontrola: napětí dne (`TransitEngine.tensionProfile`, stejné jako
  `tensionAt`) a jeho percentil v celém životě (od narození do úmrtí nebo do dneška,
  nejvýš 100 let), slovy: klidnější / běžný / napjatější / jeden z nejnapjatějších.
  Poznámka: shoda výkladu se známou událostí je čtení zpětně, férové je srovnání
  s ostatními dny téhož života.
- Souhrn katalogu (ikona v seznamu osobností): pro všechny zlomové události
  percentil dne v jeho životě. Percentil je střední pořadí (shody dostanou průměr),
  takže náhodný den má očekávání přesně 50 a do horních 20 % padne přesně pětina
  (shody se dělí poměrem). Test: každý den události se nahradí náhodným dnem života
  téže osobnosti (10 000 opakování, pevné semínko), p oboustranně pro průměr
  a jednostranně pro podíl v horních 20 %. Výsledek věta + velikost účinku (rozdíl
  percentilových bodů, podíl proti očekávání); „souvislost se neukázala“ se ukazuje
  stejně výrazně jako opak. Výpočet běží ve čtyřech isolatech s dvojnásobným krokem
  efemeridy. Kód: `astro_core/lib/src/journal/event_days.dart`,
  `app/lib/logic/people_events.dart`.

### Stav (2026-11-20)

- 1 722 událostí, z toho 1 169 zlomových: 711 z anglické Wikipedie, 52 z české,
  406 z Wikidat (P39 116, P800 105, P166 89, P793 77, vítězství 19). 23 dat převedeno
  z juliánského kalendáře.
- Aspoň dvě zlomové události má 262 z 298 osobností. Zbylých 36 (hlavně malíři,
  modelky, část českých herců a sportovců) nemá v žádném z pramenů větu s celým datem;
  test hlídá, aby jich bylo pod 15 %.
- Souhrn katalogu: 1 168 zlomových událostí u 280 osobností, průměrný percentil napětí
  dne 50,2 (náhodně 50), v horních 20 % 19,2 % událostí (náhodně 20,0 %), p = 0,85
  oboustranně, pro horních 20 % p = 0,78. Souvislost se neukázala.
