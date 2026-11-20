# Horární astrologie (R8, plán 10.8)

Horoskop okamžiku otázky a verdikt podle pravidel Williama Lillyho. Engine:
`packages/astro_core/lib/src/horary/`, pravidla jako data: `content/rules/horary.json`,
tabulky důstojností: `lilly_tables.dart`. Appka: režim „Horární“ na obrazovce
Zeptej se (`app/lib/ui/horary/`).

## Pramen

William Lilly, *Christian Astrology*, Londýn 1647 (volné dílo). Čísla stran jsou
tištěné strany vydání 1647, „CA I.XVIII s. 104“ = kniha I, kapitola XVIII, strana 104.

- Hlavní kopie: výtisk Wellcome Collection na archive.org, identifikátor `b30338724`.
  List skenu = tištěná strana + 34 (pro s. 50–205). Tabulky se četly ze stránkových
  obrázků, ne z OCR.
- Kontrolní kopie: sken EEBO/ProQuest na archive.org,
  `bim_early-english-books-1641-1700_christian-astrology-_lilly-william_1647`
  (s. 104 = list 133).
- Nepoužito: přepis „Mithras93“ (2. vydání 1659, novodobé tabulky pod copyrightem).
  Přepis EEBO-TCP Christian Astrology neexistuje (ověřeno v indexu TCP).

| Tabulka nebo pravidlo | Kde v knize | V kódu |
|---|---|---|
| sídla, povýšení, trojice den/noc, ptolemaiovské termy, tváře, zničení, pád | CA I.XVIII s. 104 („A Table of the Essentiall Dignities … according to Ptolomy“), výklad s. 105 | `lillyTerms`, `lillyFaces`, `lillyTriplicity`; sídla a povýšení z `dignities.dart` (shodná s tabulkou) |
| body síly a slabosti | CA I s. 115 („A ready Table … Fortitudes and Debilities“) | `lillyFortitudes` |
| orientální a okcidentální planety, Měsíc | CA I.XIX s. 114 | `strengthOf` |
| orby (Lillyho sloupec) a polovina orbu | CA I.XIX s. 107, s. 110 | `lillyOrbs`, `lillyMoiety` |
| spálení 8°30′ ve stejném znamení, pod paprsky 17°, cazimi 17′ | CA I.XIX s. 113–114 | `solarCondition` |
| střední denní pohyb (rychlý/pomalý) | CA I.VIII–XIV: ♄ s. 57, ♃ s. 61, ♂ s. 65, ☉ s. 69, ♀ s. 72–73, ☿ s. 76, ☽ s. 80 | `lillyMeanMotion` |
| aplikace, separace | CA I.XIX s. 107–110 | `HorarySky.aspectNow` |
| zábrana, ústup (refrenace) | CA I.XIX s. 110–111 | `HoraryEngine.facts`, krok 4 |
| přenos světla | CA I.XIX s. 111; II.XXI s. 126 | krok 2 |
| přijetí | CA I.XIX s. 112; s. 171 | `receives`, `mutualReceptionByHouse` |
| Měsíc bez aspektu, peregrinní planeta, zmaření | CA I.XIX s. 112–113 | R2 `MoonAspectTimeline` (jen sedm planet), krok 4 |
| obležení | CA I.XIX s. 114 | `besieged` |
| radikalita, výhrady před soudem | CA II.XX s. 121–123 | `considerations` v JSON |
| čtyři cesty dokonání, Měsíc jako spoluukazatel, kvadrát a opozice | CA II.XXI s. 124–126 | krok 2–5, `HoraryEngine._verdict` |
| sběr světla | CA II.XXI s. 126 | krok 3 |
| čas: stupně do dokonání, jednotka podle domů | CA II s. 171–172 | `timing` v JSON |
| směr ztracené věci podle znamení | CA II.XXXII s. 204 | `lost.signs` v JSON |
| směr podle domu | CA II s. 364 (Theft, „Whither is the Thief gone“) | `lost.houses` v JSON |
| druh místa podle znamení | CA I.XVI s. 93–99 (oddíl Places) | `lost.places` (vstup pro texty) |
| domy témat a osob, konsignifikátoři domů | CA I.VII s. 51–56 | `topics`, `persons` v JSON |

## Výchozí varianty (rozhodnutí 21)

- Sedm planet, tradiční vládci (`traditionalRuler`).
- Domy Regiomontanus vždy, bez ohledu na profil; za polárním kruhem Porphyry.
  Ověřeno na Lillyho figuře „Fish stolen“: hroty sedí na 0,5°.
- Ptolemaiovské termy a trojice pro den a noc podle tabulky s. 104
  (oheň ☉/♃, země ♀/☽, vzduch ♄/☿, voda ♂/♂).
- Orby: Lillyho vlastní sloupec s. 107 (♄ 10°, ♃ 12°, ♂ 7°30′, ☉ 17°, ♀ 8°, ☿ 7°,
  ☽ 12°30′). Dvě planety jsou v aspektu do součtu polovin. Druhý sloupec („others“:
  9, 9, 7, 15, 7, 7, 12) Lilly používá v příkladu na s. 110; appka ho nepoužívá.
- Den a noc: Slunce nad obzorem (mezi descendentem a ascendentem přes MC).

## Postup (strom rozhodnutí)

1. **Horoskop:** okamžik potvrzení otázky, místo pobytu z profilu.
2. **Ukazatelé:** tazatel = vládce ascendentu + Měsíc (s. 124); věc = vládce domu
   tématu, přirozený ukazatel = konsignifikátor domu (s. 51–56). Otázka o jiné osobě:
   osoba = vládce jejího domu, věc = dům počítaný od domu osoby (bratrova práce
   = 10. od 3. = 12.). Měsíc je spoluukazatel jen u otázek o sobě. Když tazatele
   i věc zastupuje stejná planeta, zastoupí tazatele Měsíc; jinak „nelze říct“.
3. **Síla:** body z tabulky s. 115, bytostné i nahodilé. Svědectví „silný/slabý“
   je součet bodů nad nulou, nebo pod ní (práh je volba appky, Lilly jen srovnává).
4. **Dokonání:** obloha se posouvá dopředu po hodině (Měsíc vzorkovaný po hodině,
   ostatní planety po 12 h až 2 dnech, kubická interpolace), přesnost se dohledá
   půlením. Platí jen dokonání dřív, než jeden z ukazatelů opustí znamení.
   Pořadí: přímé dokonání, pak Měsíc s ukazatelem věci, pak přenos, pak sběr.
5. **Co dokonání ruší:**
   - zábrana: třetí planeta dojde k jednomu z ukazatelů dřív. Appka bere jen planetu,
     která už je v orbu a blíží se (volba appky, `obstacleWithinOrb`);
   - zmaření: pomalejší ukazatel se dřív spojí s ještě těžší planetou;
   - ústup: ukazatelé se blíží, ale jeden se zastaví a obrátí dřív, než aspekt
     dokoná;
   - spálení ukazatele (s. 123: „If the Lord of the Ascendant be Combust, neither
     question propounded will take“).
   Planeta rychlostí mezi oběma ukazateli, která se nejdřív spojí s pomalejším
   a pak k ní dojde rychlejší, není zábrana, ale přenos (Lillyho vlastní úsudek
   o ♃ v příkladu s. 387–388).
6. **Kvadrát a opozice (s. 125):** kvadrát dokoná, jen když mají oba ukazatele
   bytostnou důstojnost; opozice jen při vzájemném přijetí domem („the Querent had
   been better the thing had been undone“). Jinak verdikt „ne“.
7. **Verdikt:** ano / ano s potížemi (kvadrát bez přijetí, každá opozice) / ne /
   už je to pryč (ukazatelé se v orbu rozcházejí) / nic z toho nebude (zrušené
   dokonání) / nelze říct.
8. **Čas (s. 171–172):** stupně, které ukazatelům chybí do přesného aspektu;
   jednotka podle domů obou ukazatelů: oba padající = dny, oba následné = týdny,
   oba úhlové = měsíce; úhlový + následný = měsíce; následný + padající = týdny;
   úhlový + padající = měsíce. Roky jen „discretion“ astrologa, appka je nevolí.
9. **Ztracená věc:** směr podle znamení (s. 204) a domu (s. 364) ukazatele věci.

Otázky o zdraví, smrti a těhotenství (rozhodnutí 20) verdikt nedostanou: appka ukáže
výhrady a heslo slovníčku `glossary/medical_horary`.

Výhrady (s. 121–123) jsou jen varování: ascendent pod 3° nebo od 27°, Měsíc bez
aspektu, Měsíc ve spálené cestě (15° ♎ – 15° ♏, Lilly: „as some say“), Saturn
v 1. nebo 7. domě, vládce hodiny nesouhlasí s vládcem ascendentu.

## Kontrolní příklady (testy `horary_test.dart`)

Čas je místní pravý (sluneční) čas, kalendář juliánský.

| Příklad | Data | Shoda poloh | Postup |
|---|---|---|---|
| „Fish stolen“, CA II.LIV s. 397–399 | 10. 2. 1637/8, 8:45, Walton-on-Thames | ASC ♉4:02 proti 4:27; hroty do 0,5°; planety do 0,2° | ☽ sextilem k ☿ (vládce 2.); ☿ v pádu a zničení, ale ve vlastním termu; ♃ peregrinní v 7. domě; verdikt ano (Lilly: část ryb našel) |
| „A Lady, if marry the Gentleman desired?“, CA II.LIX s. 385–388 | 16. 6. 1646, 19:26 astronomicky (17. 6. 7:26), Londýn (místo v knize neuvedené) | ASC ♌16:11 proti 17:11, MC 1,4°; ☽ 0,9°, ☿ 0,5°, ostatní do 0,3° | ☉ (vládce ASC) sextilem k ♄ (vládce 7.) 27./28. června, bez přijetí; ♃ přenáší světlo; hodina ♄; ☽ bez aspektu; verdikt ano (Lilly: sňatek do 20 dnů) |

Rozdíl u příkladu Lady: Lilly má ♃ 13′ před sextilem ♄, přepočet 8′ za ním. Engine
proto vidí ♃ jako planetu, která se od ♄ právě odpojila a dojde ke ☉ – stejný přenos,
jen v obráceném pořadí kroků.

Ústup se testuje na skutečné zastávce Merkuru: 26. 6. 2026 se ☿ (25°55′ ♋) blíží
ke konjunkci s ♃ (29°15′ ♋), 29. 6. se zastaví a obrátí, konjunkce v ♋ nenastane.

## Nevyřešené a volby appky

- **Láska v 5. domě.** Plán 10.8 dává lásku do 5. domu; Lilly píše „all manner of Love
  questions“ do 7. domu (s. 54). Appka drží plán; rozhodne vlastník.
- **„Same nature“ v radikalitě (s. 121).** Shoda vládce hodiny s vládcem ascendentu
  „stejnou povahou“ není implementovaná (povahy planet z knihy I nebyly opsány).
  Shoda „of one Triplicity“ se čte jako dvě planety vládnoucí téže trojici.
- **Orby hvězd Regulus a Spica.** Lilly dává 5° jen u Algolu; u Regula a Spiky orb
  neuvádí. Appka bere 1° (rozhodnutí 18).
- **Přirození ukazatelé v knize II** (♀ pro sňatek, ☿ pro dopisy atd.) nebyli opsáni
  kapitolu po kapitole; přirozený ukazatel tématu je zatím konsignifikátor domu
  (s. 51–56), jen jako svědectví, verdikt neovlivní.
- **Čas podle znamení.** Lilly jinde dává jednotku podle znamení (s. 152: pohyblivé dny,
  společné týdny, pevné měsíce; s. 307: společné měsíce, pevné roky). Rozporné, appka
  používá jen pravidlo podle domů ze s. 171–172.
- **Pravidlo 5° k následujícímu hrotu**, retrográdní aplikace jako „ill“ (s. 107–108),
  „dexter“ silnější než „sinister“ (s. 108–109), výhrada pozdního Měsíce ve ♊ ♏ ♑
  (s. 122) a výhrada o 7. domě astrologa (s. 122–123) nejsou implementované.
- **Zábrana jen v orbu** a **práh síly** (součet nad/pod nulou) jsou volby appky.
- **Přijetí** se ve svědectvích počítá jen sídlem a povýšením (s. 112 dovoluje
  i trojici, term a tvář, s. 171 varuje, že samo povýšení „profiteth not“). Pro přenos
  (s. 126: dům, trojice, term) a sběr (jakákoli důstojnost) platí Lillyho výčet.
- Texty `horary/*` zatím chybí (kromě hesel slovníčku); generují se dávkou později.
